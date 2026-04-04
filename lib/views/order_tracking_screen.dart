import 'package:appthuetho/services/job_service.dart';
import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String jobId;
  final bool isProvider; // true nếu là thợ xem

  const OrderTrackingScreen({super.key, required this.jobId, this.isProvider = false});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String currentStatus = 'pending';
  final JobService _jobService = JobService();

  final List<Map<String, dynamic>> _steps = [
    {'status': 'accepted', 'title': 'Thợ đã nhận đơn', 'icon': Icons.check_circle},
    {'status': 'moving', 'title': 'Thợ đang di chuyển', 'icon': Icons.directions_walk},
    {'status': 'arrived', 'title': 'Thợ đã đến nơi', 'icon': Icons.location_on},
    {'status': 'repairing', 'title': 'Đang sửa chữa', 'icon': Icons.build},
    {'status': 'completed', 'title': 'Hoàn thành', 'icon': Icons.done_all},
  ];

  @override
  void initState() {
    super.initState();
    _loadJobStatus();
  }

  Future<void> _loadJobStatus() async {
    // Giả lập load status (sau có thể gọi API /api/jobs/:id)
    setState(() => currentStatus = 'accepted'); // demo
  }

  Future<void> _updateStatus(String newStatus) async {
    bool success = await _jobService.updateJobStatus(widget.jobId, newStatus);
    if (success) {
      setState(() => currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cập nhật trạng thái thành công')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi tiến độ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Job info
            Card(
              child: ListTile(
                title: Text('Đơn #${widget.jobId.substring(0, 8)}'),
                subtitle: const Text('Sửa tủ lạnh • Q.1, TP.HCM'),
              ),
            ),
            const SizedBox(height: 24),

            // Timeline
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final isDone = _steps.indexWhere((s) => s['status'] == currentStatus) >= index;
                  final isCurrent = step['status'] == currentStatus;

                  return Row(
                    children: [
                      Column(
                        children: [
                          Icon(step['icon'], color: isDone || isCurrent ? const Color(0xFF00AEEF) : Colors.grey, size: 28),
                          if (index < _steps.length - 1)
                            Container(width: 4, height: 40, color: isDone ? const Color(0xFF00AEEF) : Colors.grey[300]),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: isCurrent ? const Color(0xFF00AEEF).withOpacity(0.1) : null,
                          child: ListTile(
                            title: Text(step['title'], style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                            trailing: isCurrent && widget.isProvider
                                ? ElevatedButton(
                              onPressed: () => _updateStatus(_steps[index + 1]['status']),
                              child: const Text('Tiếp theo'),
                            )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}