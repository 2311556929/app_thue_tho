// lib/views/customer/payment_screen.dart  ← TẠO FILE MỚI
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';

enum PaymentMethod { cash, momo, vnpay, banking }

class PaymentScreen extends StatefulWidget {
  final String jobId;
  final double amount;
  final String serviceType;
  final String technicianName;

  const PaymentScreen({
    super.key,
    required this.jobId,
    required this.amount,
    required this.serviceType,
    required this.technicianName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  bool _processing = false;
  bool _paid = false;
  String? _voucherCode;
  double _discount = 0;
  final _voucherCtrl = TextEditingController();

  double get _finalAmount => (widget.amount - _discount).clamp(0, double.infinity);

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  // ── Áp dụng voucher ──────────────────────────────────────
  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _snack('Mã voucher không hợp lệ hoặc đã hết hạn', isError: true);
        return;
      }

      final v = snap.docs.first.data();
      final minOrder = (v['minOrder'] as num? ?? 0).toDouble();
      if (widget.amount < minOrder) {
        _snack(
            'Đơn tối thiểu ${_fmt(minOrder)} để dùng voucher này',
            isError: true);
        return;
      }

      double discountAmount = 0;
      if (v['type'] == 'percent') {
        discountAmount = widget.amount * (v['value'] as num).toDouble() / 100;
        final maxDiscount = (v['maxDiscount'] as num? ?? 999999999).toDouble();
        discountAmount = discountAmount.clamp(0, maxDiscount);
      } else {
        discountAmount = (v['value'] as num).toDouble();
      }

      setState(() {
        _voucherCode = code;
        _discount = discountAmount;
      });
      _snack('🎉 Áp dụng voucher thành công! Giảm ${_fmt(discountAmount)}');
    } catch (e) {
      _snack('Lỗi kiểm tra voucher: $e', isError: true);
    }
  }

  // ── Xử lý thanh toán ─────────────────────────────────────
  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      switch (_method) {
        case PaymentMethod.cash:
          await _payCash();
          break;
        case PaymentMethod.momo:
          await _payMomo();
          break;
        case PaymentMethod.vnpay:
          await _payVNPay();
          break;
        case PaymentMethod.banking:
          await _payBanking();
          break;
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _payCash() async {
    // Ghi payment record
    await _savePayment(method: 'cash', status: 'pending');
    _showCashDialog();
  }

  Future<void> _payMomo() async {
    // Tích hợp MoMo: Deep link mở app MoMo
    // Trong production, cần gọi MoMo API để lấy payUrl
    // Đây là cách mở thẳng app MoMo với số tiền
    final momoUrl = Uri.parse(
        'momo://app?action=payWithApp'
            '&isSandbox=true'
            '&amount=${_finalAmount.toInt()}'
            '&orderId=${widget.jobId}'
            '&orderLabel=${Uri.encodeComponent(widget.serviceType)}'
            '&merchantname=${Uri.encodeComponent('App Thuê Thợ')}'
            '&partnerCode=MOMO_PARTNER_CODE' // Thay bằng partner code thật
    );

    if (await canLaunchUrl(momoUrl)) {
      await launchUrl(momoUrl);
    } else {
      // MoMo không có → mở trang web
      await launchUrl(Uri.parse('https://momo.vn/payment'),
          mode: LaunchMode.externalApplication);
    }

    // Sau khi redirect về, kiểm tra trạng thái (trong production dùng webhook)
    await _savePayment(method: 'momo', status: 'pending');
    _showPendingVerificationDialog('MoMo');
  }

  Future<void> _payVNPay() async {
    // VNPay: Gọi backend để lấy payment URL
    // Demo: mở thẳng VNPay sandbox
    const vnpayTestUrl =
        'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

    await launchUrl(Uri.parse(vnpayTestUrl),
        mode: LaunchMode.externalApplication);

    await _savePayment(method: 'vnpay', status: 'pending');
    _showPendingVerificationDialog('VNPay');
  }

  Future<void> _payBanking() async {
    await _savePayment(method: 'banking', status: 'pending');
    _showBankingDialog();
  }

  Future<void> _savePayment(
      {required String method, required String status}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.jobId)
        .set({
      'jobId': widget.jobId,
      'customerId': uid,
      'amount': widget.amount,
      'discount': _discount,
      'finalAmount': _finalAmount,
      'method': method,
      'status': status,
      'voucherCode': _voucherCode ?? '',
      'serviceType': widget.serviceType,
      'technicianName': widget.technicianName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _confirmCashPaid() async {
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.jobId)
        .update({'status': 'completed', 'paidAt': FieldValue.serverTimestamp()});

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .update({'paymentStatus': 'paid', 'paymentMethod': 'cash'});

    // Thông báo cho thợ
    final jobDoc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();
    final techId = jobDoc.data()?['technicianId'] as String? ?? '';
    if (techId.isNotEmpty) {
      await NotificationService.saveAndShow(
        userId: techId,
        title: '💰 Khách đã thanh toán',
        body: 'Khách đã thanh toán ${_fmt(_finalAmount)} tiền mặt cho ${widget.serviceType}',
        type: 'payment',
        jobId: widget.jobId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _showSuccessDialog();
  }

  void _showCashDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.payments_rounded, color: Color(0xFF00AEEF)),
          SizedBox(width: 8),
          Text('Thanh toán tiền mặt'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng đưa cho thợ số tiền:',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00AEEF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00AEEF).withOpacity(0.3)),
              ),
              child: Text(
                _fmt(_finalAmount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00AEEF),
                ),
              ),
            ),
            if (_discount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Đã giảm ${_fmt(_discount)} từ voucher',
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AEEF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Đã thanh toán'),
            onPressed: () {
              Navigator.pop(context);
              _confirmCashPaid();
            },
          ),
        ],
      ),
    );
  }

  void _showBankingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chuyển khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _BankRow('Ngân hàng', 'Vietcombank'),
            _BankRow('Số tài khoản', '1234 5678 9012 3456'),
            _BankRow('Chủ tài khoản', 'CONG TY APPTHUETHO'),
            _BankRow('Số tiền', _fmt(_finalAmount), highlight: true),
            _BankRow('Nội dung CK', 'THANHTOAN ${widget.jobId.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(children: const [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sau khi chuyển khoản, đơn sẽ được xác nhận trong 5-10 phút.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(
                      text: '1234 5678 9012 3456'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép số TK')),
                  );
                },
                child: const Text('Sao chép số tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingVerificationDialog(String provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chờ xác nhận $provider'),
        content: const Text(
          'Sau khi thanh toán thành công, trạng thái đơn hàng sẽ được cập nhật tự động trong vài giây.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 56),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cảm ơn bạn đã sử dụng App Thuê Thợ',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AEEF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Về trang chủ'),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tóm tắt đơn hàng ─────────────────────────
            _SectionCard(
              title: 'Chi tiết đơn hàng',
              icon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  _OrderRow('Dịch vụ', widget.serviceType),
                  _OrderRow('Thợ thực hiện', widget.technicianName),
                  _OrderRow('Mã đơn',
                      '#${widget.jobId.substring(0, 8).toUpperCase()}'),
                  const Divider(height: 20),
                  _OrderRow('Tạm tính', _fmt(widget.amount)),
                  if (_discount > 0)
                    _OrderRow('Giảm giá', '- ${_fmt(_discount)}',
                        valueColor: Colors.green),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _fmt(_finalAmount),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00AEEF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Voucher ──────────────────────────────────
            _SectionCard(
              title: 'Mã giảm giá',
              icon: Icons.local_offer_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voucherCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã voucher...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _voucherCode != null
                          ? Colors.grey
                          : const Color(0xFF00AEEF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed:
                    _voucherCode != null ? null : _applyVoucher,
                    child: Text(
                        _voucherCode != null ? 'Đã dùng' : 'Áp dụng'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Phương thức thanh toán ────────────────────
            _SectionCard(
              title: 'Phương thức thanh toán',
              icon: Icons.payment_rounded,
              child: Column(
                children: [
                  _PayMethodTile(
                    method: PaymentMethod.cash,
                    selected: _method,
                    icon: Icons.payments_rounded,
                    label: 'Tiền mặt',
                    subtitle: 'Thanh toán trực tiếp cho thợ',
                    color: Colors.green,
                    onTap: () => setState(() => _method = PaymentMethod.cash),
                  ),
                  _PayMethodTile(
                    method: PaymentMethod.momo,
                    selected: _method,
                    iconAsset: '🟣',
                    label: 'Ví MoMo',
                    subtitle: 'Thanh toán qua ứng dụng MoMo',
                    color: const Color(0xFFAE2070),
                    onTap: () =>
                        setState(() => _method = PaymentMethod.momo),
                  ),
                  _PayMethodTile(
                    method: PaymentMethod.vnpay,
                    selected: _method,
                    iconAsset: '🔵',
                    label: 'VNPay',
                    subtitle: 'Thanh toán qua VNPay / QR Code',
                    color: const Color(0xFF003087),
                    onTap: () =>
                        setState(() => _method = PaymentMethod.vnpay),
                  ),
                  _PayMethodTile(
                    method: PaymentMethod.banking,
                    selected: _method,
                    icon: Icons.account_balance_rounded,
                    label: 'Chuyển khoản ngân hàng',
                    subtitle: 'ATM / Internet Banking',
                    color: Colors.teal,
                    onTap: () =>
                        setState(() => _method = PaymentMethod.banking),
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Nút thanh toán ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _processing
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.lock_rounded, size: 22),
                label: Text(
                  _processing
                      ? 'Đang xử lý...'
                      : 'Thanh toán ${_fmt(_finalAmount)}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: _processing ? null : _pay,
              ),
            ),

            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_rounded,
                      size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Thanh toán an toàn & bảo mật',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Widgets nhỏ ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(icon, size: 18, color: const Color(0xFF00AEEF)),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _OrderRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _BankRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 14,
              fontWeight:
              highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? const Color(0xFF00AEEF) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final PaymentMethod selected;
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _PayMethodTile({
    required this.method,
    required this.selected,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
              bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconAsset != null
                  ? Center(
                  child:
                  Text(iconAsset!, style: const TextStyle(fontSize: 22)))
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                  isSelected ? const Color(0xFF00AEEF) : Colors.grey[300]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF00AEEF) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}