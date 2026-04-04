const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Dữ liệu mẫu
let jobs = [];

const technicians = [
  {
    id: 'tech_001',
    name: 'Nguyễn Văn A',
    phone: '0987 654 321',
    serviceTypes: ['Tủ lạnh', 'Máy giặt', 'Thợ điện'],
    rating: 4.9,
    avatar: 'https://i.pravatar.cc/150?img=1',
    latitude: 10.8231,
    longitude: 106.6297,
    status: 'available'
  },
  {
    id: 'tech_002',
    name: 'Trần Thị B',
    phone: '0912 345 678',
    serviceTypes: ['Điều hòa', 'Sửa xe máy', 'Thợ nước'],
    rating: 4.8,
    avatar: 'https://i.pravatar.cc/150?img=2',
    latitude: 10.8225,
    longitude: 106.6285,
    status: 'available'
  },
  {
    id: 'tech_003',
    name: 'Lê Văn C',
    phone: '0978 123 456',
    serviceTypes: ['Cửa sắt', 'Sửa nhà'],
    rating: 4.7,
    avatar: 'https://i.pravatar.cc/150?img=3',
    latitude: 10.8250,
    longitude: 106.6320,
    status: 'available'
  }
];

// Hàm tính khoảng cách (Haversine formula) - km
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Bán kính Trái Đất (km)
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // khoảng cách km
}

// API tạo job mới
app.post('/api/jobs', (req, res) => {
  const { customerId, serviceType, description, imagePath, latitude, longitude } = req.body;

  const newJob = {
    id: 'job_' + Date.now(),
    customerId,
    serviceType,
    description,
    imagePath,
    latitude: parseFloat(latitude),
    longitude: parseFloat(longitude),
    status: 'pending',
    createdAt: new Date().toISOString()
  };

  jobs.push(newJob);
  console.log('📨 Nhận job mới:', newJob);

  // Tìm thợ phù hợp (AI Matching đơn giản)
  const matchedTechnicians = technicians
    .filter(t => t.serviceTypes.some(s => s.toLowerCase().includes(serviceType.toLowerCase()) || serviceType === 'Khác'))
    .map(t => {
      const distance = calculateDistance(latitude, longitude, t.latitude, t.longitude);
      return { ...t, distance: parseFloat(distance.toFixed(2)) };
    })
    .sort((a, b) => a.distance - b.distance); // Sắp xếp gần nhất trước

  res.status(201).json({
    success: true,
    message: 'Đã tạo yêu cầu thành công!',
    job: newJob,
    suggestedTechnicians: matchedTechnicians.slice(0, 5) // Trả về top 5 thợ gần nhất
  });
});

// API lấy tất cả thợ (dùng cho test)
app.get('/api/technicians', (req, res) => {
  res.json(technicians);
});

app.get('/', (req, res) => {
  res.send('🚀 Server App Thuê Thợ đang chạy - Backend v2 với AI Matching!');
});
// API mới: Thợ lấy danh sách job đang chờ
app.get('/api/jobs/pending', (req, res) => {
  const pendingJobs = jobs.filter(job => job.status === 'pending');
  res.json(pendingJobs);
});

// API: Thợ nhận job (cập nhật status)
app.put('/api/jobs/:id/accept', (req, res) => {
  const { id } = req.params;
  const job = jobs.find(j => j.id === id);
  if (job) {
    job.status = 'accepted';
    job.technicianId = req.body.technicianId || 'tech_001';
    console.log(`✅ Thợ nhận job: ${id}`);
    res.json({ success: true, job });
  } else {
    res.status(404).json({ success: false, message: 'Không tìm thấy job' });
  }
});
// API: Cập nhật trạng thái job
app.put('/api/jobs/:id/status', (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'accepted', 'moving', 'arrived', 'repairing', 'completed'

  const job = jobs.find(j => j.id === id);
  if (job) {
    job.status = status;
    job.updatedAt = new Date().toISOString();
    console.log(`📌 Job ${id} cập nhật trạng thái: ${status}`);
    res.json({ success: true, job });
  } else {
    res.status(404).json({ success: false, message: 'Không tìm thấy job' });
  }
});

// API: Lấy chi tiết 1 job (dùng cho tracking)
app.get('/api/jobs/:id', (req, res) => {
  const job = jobs.find(j => j.id === req.params.id);
  if (job) res.json(job);
  else res.status(404).json({ success: false });
});
app.listen(PORT, () => {
  console.log(`✅ Server chạy tại http://localhost:${PORT}`);
  console.log('📱 Kết nối từ Flutter Emulator: http://10.0.2.2:3000');
});