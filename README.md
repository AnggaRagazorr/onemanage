# Sekuriti Mobile

Aplikasi manajemen keamanan untuk monitoring patroli security, manajemen carpool, dan administrasi dokumen.

## 📱 Fitur

### Untuk Security
- **Patroli** - Scan barcode di area patroli untuk mencatat kehadiran
- **Clock In/Out Shift** - Mulai dan selesaikan shift kerja (pagi/malam)
- **Laporan Kejadian** - Catat dan laporkan kejadian
- **Carpool** - Lihat history penggunaan kendaraan

### Untuk Admin
- **Dashboard** - Ringkasan statistik semua aktivitas
- **Statistik Security** - Monitoring performa dan skor security
- **Manajemen User** - Kelola akun security dan admin
- **Manajemen Carpool** - Kelola kendaraan dan driver
- **Dokumen Masuk** - Catat dokumen yang diterima

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter |
| Backend API | Laravel 11 |
| Database | MySQL |
| Authentication | Laravel Sanctum |

## 📁 Struktur Project

```
sekuriti-mobile/
├── backend/          # Laravel API
│   ├── app/
│   ├── database/
│   └── routes/
└── mobile/           # Flutter App
    ├── lib/
    │   ├── services/
    │   └── ui/
    └── pubspec.yaml
```

## 🚀 Cara Menjalankan

### Backend (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

## ⚙️ Konfigurasi

### API URL
Edit file `mobile/lib/services/api_config.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8000/api';
```

## 📄 License

Private - All rights reserved.
