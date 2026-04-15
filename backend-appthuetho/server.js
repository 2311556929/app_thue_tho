const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// ===================== KHỞI TẠO FIREBASE ADMIN (chỉ 1 lần) =====================
const serviceAccount = require('./appthuetho-firebase-adminsdk-fbsvc-cf3864d718.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Dữ liệu
let jobs = [];
let users = {}; // Lưu token theo userId (customer_001, tech_001, ...)

const technicians = [
  { id: 'tech_001', name: 'Nguyễn Văn A', phone: '0987 654 321', serviceTypes: ['Tủ lạnh', 'Máy giặt', 'Thợ điện'], rating: 4.9, avatar: 'https://i.pravatar.cc/150?img=1', latitude: 10.8231, longitude: 106.6297, status: 'available' },
  { id: 'tech_002', name: 'Trần Thị B', phone: '0912 345 678', serviceTypes: ['Điều hòa', 'Sửa xe máy', 'Thợ nước'], rating: 4.8, avatar: 'https://i.pravatar.cc/150?img=2', latitude: 10.8225, longitude: 106.6285, status: 'available' },
  { id: 'tech_003', name: 'Lê Văn C', phone: '0978 123 456', serviceTypes: ['Cửa sắt', 'Sửa nhà'], rating: 4.7, avatar: 'https://i.pravatar.cc/150?img=3', latitude: 10.8250, longitude: 106.6320, status: 'available' }
];

// Hàm tính khoảng cách
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ===================== ĐĂNG KÝ TOKEN =====================
app.post('/api/register-token', (req, res) => {
  const { userId, fcmToken } = req.body;
  if (userId && fcmToken) {
    users[userId] = fcmToken;
    console.log(`🔑 Token đã đăng ký cho ${userId}`);
    res.json({ success: true });
  } else {
    res.status(400).json({ success: false, message: 'Thiếu userId hoặc token' });
  }
});

// ===================== GỬI PUSH NOTIFICATION =====================
async function sendPushToTechnicians(title, body, data = {}) {
  const tokens = Object.values(users).filter(Boolean); // Lấy tất cả token đã đăng ký

  if (tokens.length === 0) {
    console.log('⚠️ Chưa có token nào được đăng ký');
    return;
  }

  const message = {
    notification: { title, body },
    data: data,
    tokens: tokens
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Gửi push thành công: ${response.successCount}/${tokens.length} thiết bị`);
  } catch (error) {
    console.error('❌ Lỗi gửi push:', error);
  }
}

// ===================== API TẠO JOB =====================
app.post('/api/jobs', async (req, res) => {
  const { customerId, serviceType, description, imagePath, latitude, longitude, customerName, customerPhone, customerAddress } = req.body;

  const newJob = {
    id: 'job_' + Date.now(),
    customerId,
    serviceType,
    description,
    imagePath,
    latitude: parseFloat(latitude),
    longitude: parseFloat(longitude),
    customerName: customerName || 'Khách hàng',
    customerPhone: customerPhone || '',
    customerAddress: customerAddress || '',
    status: 'pending',
    createdAt: new Date().toISOString()
  };

  jobs.push(newJob);
  console.log('📨 Nhận job mới:', newJob);

  // Gửi push notification cho tất cả thợ
  await sendPushToTechnicians(
    'Có đơn mới!',
    `${customerName || 'Khách'} cần sửa ${serviceType} - ${description.substring(0, 30)}...`,
    { jobId: newJob.id, type: 'new_job' }
  );

  // AI Matching
  const matchedTechnicians = technicians
    .filter(t => t.serviceTypes.some(s => s.toLowerCase().includes(serviceType.toLowerCase()) || serviceType === 'Khác'))
    .map(t => {
      const distance = calculateDistance(latitude, longitude, t.latitude, t.longitude);
      return { ...t, distance: parseFloat(distance.toFixed(2)) };
    })
    .sort((a, b) => a.distance - b.distance);

  res.status(201).json({
    success: true,
    message: 'Đã tạo yêu cầu thành công!',
    job: newJob,
    suggestedTechnicians: matchedTechnicians.slice(0, 5)
  });
});

// Các API cũ (giữ nguyên)
app.get('/api/technicians', (req, res) => res.json(technicians));
app.get('/', (req, res) => res.send('🚀 Server App Thuê Thợ đang chạy - Push Notification HOÀN THÀNH'));
app.get('/api/jobs/pending', (req, res) => res.json(jobs.filter(j => j.status === 'pending')));
app.put('/api/jobs/:id/accept', (req, res) => { /* code cũ của em */ });
app.put('/api/jobs/:id/status', (req, res) => { /* code cũ của em */ });
app.get('/api/jobs/:id', (req, res) => { /* code cũ của em */ });

app.listen(PORT, () => {
  console.log(`✅ Server chạy tại http://localhost:${PORT}`);
  console.log('📱 Push Notification đã sẵn sàng!');
});