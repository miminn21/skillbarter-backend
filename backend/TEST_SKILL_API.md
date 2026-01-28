# Test Script for Skill Management API

## Prerequisites
- Backend server running on http://localhost:5000
- Database populated with categories
- Valid JWT token from login

## 1. Get All Categories
```bash
curl http://localhost:5000/api/categories
```

Expected: List of all active categories

## 2. Login to get token
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"nik\":\"3273010101010001\",\"kata_sandi\":\"password123\"}"
```

Save the token from response!

## 3. Get User Skills (Empty initially)
```bash
curl http://localhost:5000/api/skills \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 4. Add Skill (Dikuasai)
```bash
curl -X POST http://localhost:5000/api/skills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{
    \"nama_keahlian\": \"Web Development\",
    \"id_kategori\": 1,
    \"tipe\": \"dikuasai\",
    \"tingkat\": \"mahir\",
    \"pengalaman\": \"5 tahun\",
    \"deskripsi\": \"Berpengalaman dalam React, Node.js, dan database\",
    \"harga_per_jam\": 50,
    \"link_portofolio\": \"https://github.com/username\"
  }"
```

## 5. Add Skill (Dicari)
```bash
curl -X POST http://localhost:5000/api/skills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{
    \"nama_keahlian\": \"UI/UX Design\",
    \"id_kategori\": 2,
    \"tipe\": \"dicari\",
    \"tingkat\": \"menengah\",
    \"deskripsi\": \"Ingin belajar design thinking dan prototyping\",
    \"harga_per_jam\": 30
  }"
```

## 6. Get User Skills (Filter by tipe)
```bash
# Get dikuasai only
curl "http://localhost:5000/api/skills?tipe=dikuasai" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Get dicari only
curl "http://localhost:5000/api/skills?tipe=dicari" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 7. Get Skill Detail
```bash
curl http://localhost:5000/api/skills/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 8. Update Skill
```bash
curl -X PUT http://localhost:5000/api/skills/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{
    \"tingkat\": \"ahli\",
    \"pengalaman\": \"7 tahun\",
    \"harga_per_jam\": 75
  }"
```

## 9. Delete Skill
```bash
curl -X DELETE http://localhost:5000/api/skills/2 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Expected Results

### Success Response Format
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response Format
```json
{
  "success": false,
  "message": "Error message",
  "errors": [
    {
      "field": "field_name",
      "message": "Validation message"
    }
  ]
}
```

## Validation Tests

### Test 1: Missing required fields
```bash
curl -X POST http://localhost:5000/api/skills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{\"nama_keahlian\": \"Test\"}"
```
Expected: 400 error with validation messages

### Test 2: Invalid tipe
```bash
curl -X POST http://localhost:5000/api/skills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{
    \"nama_keahlian\": \"Test\",
    \"id_kategori\": 1,
    \"tipe\": \"invalid\"
  }"
```
Expected: 400 error "Tipe harus dikuasai atau dicari"

### Test 3: Invalid tingkat
```bash
curl -X POST http://localhost:5000/api/skills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{
    \"nama_keahlian\": \"Test\",
    \"id_kategori\": 1,
    \"tipe\": \"dikuasai\",
    \"tingkat\": \"expert\"
  }"
```
Expected: 400 error for invalid tingkat

### Test 4: Unauthorized access
```bash
curl http://localhost:5000/api/skills
```
Expected: 401 Unauthorized

### Test 5: Update other user's skill
Try to update skill that belongs to another user
Expected: 403 Forbidden
