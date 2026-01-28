# SkillBarter Backend API

Backend API untuk aplikasi SkillBarter menggunakan Node.js + Express + MySQL.

## 🚀 Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` dan sesuaikan konfigurasi:
```bash
cp .env.example .env
```

Edit `.env`:
```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=skillbarter_db
JWT_SECRET=your-secret-key
```

### 3. Setup Database
Jalankan file SQL untuk membuat database:
```bash
mysql -u root -p < skillbarter_db.sql
```

### 4. Run Server
Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

Server akan berjalan di `http://localhost:5000`

## 📚 API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "nik": "3273010101010001",
  "nama_lengkap": "John Doe",
  "nama_panggilan": "John",
  "kata_sandi": "password123",
  "jenis_kelamin": "L",
  "tanggal_lahir": "1990-01-01",
  "alamat_lengkap": "Jl. Merdeka No. 123",
  "kota": "Jakarta",
  "bio": "Saya seorang developer"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "nik": "3273010101010001",
  "kata_sandi": "password123"
}
```

#### Get Profile
```http
GET /api/auth/profile
Authorization: Bearer <token>
```

#### Logout
```http
POST /api/auth/logout
Authorization: Bearer <token>
```

### Profile Management

#### Update Profile
```http
PUT /api/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "nama_panggilan": "Johnny",
  "bio": "Updated bio",
  "pekerjaan": "Software Engineer",
  "preferensi_lokasi": "online"
}
```

#### Change Password
```http
PUT /api/profile/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "kata_sandi_lama": "password123",
  "kata_sandi_baru": "newpassword123",
  "konfirmasi_kata_sandi": "newpassword123"
}
```

#### Upload Photo
```http
POST /api/profile/upload-photo
Authorization: Bearer <token>
Content-Type: multipart/form-data

foto_profil: <file>
```

## 🔐 Authentication

API menggunakan JWT (JSON Web Token) untuk autentikasi. Setelah login, simpan token dan kirim di header:

```
Authorization: Bearer <your-token>
```

Token berlaku selama 24 jam.

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── database.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── upload.js
│   ├── models/
│   │   ├── User.js
│   │   └── UserDetail.js
│   ├── controllers/
│   │   ├── authController.js
│   │   └── profileController.js
│   ├── routes/
│   │   ├── auth.js
│   │   └── profile.js
│   ├── utils/
│   │   ├── validator.js
│   │   └── response.js
│   └── app.js
├── uploads/
├── .env
├── package.json
└── server.js
```

## 🧪 Testing

Test health check:
```bash
curl http://localhost:5000/health
```

## 📝 Notes

- Password di-hash menggunakan bcrypt
- File upload maksimal 5MB
- Format gambar yang diterima: JPEG, JPG, PNG
- Trigger database otomatis memberikan bonus 10 skillcoin saat registrasi
