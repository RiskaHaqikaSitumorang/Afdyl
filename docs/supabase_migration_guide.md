# Migrasi dari Firebase ke Supabase - Documentation

## Ringkasan Migrasi

Aplikasi AfdylQuran telah berhasil dimigrasi dari Firebase ke Supabase. Migrasi ini meliputi:
- ✅ Authentication system
- ✅ Database operations
- ✅ User management
- ✅ Web compatibility
- ✅ Non-RLS database setup

## Perubahan Utama

### 1. Dependencies
**Sebelum (Firebase):**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
```

**Sesudah (Supabase):**
```yaml
dependencies:
  supabase_flutter: ^2.7.0
  flutter_dotenv: ^5.2.1
```

### 2. Struktur Database
**Sebelum:** Firestore collections
**Sesudah:** PostgreSQL tables dengan struktur:

```sql
-- Tabel users
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    preferences JSONB DEFAULT '{}',
    progress JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. Authentication
**Sebelum:**
```dart
FirebaseAuth.instance.signInWithEmailAndPassword()
```

**Sesudah:**
```dart
Supabase.instance.client.auth.signInWithPassword()
```

### 4. Database Operations
**Sebelum:**
```dart
FirebaseFirestore.instance.collection('users').doc(uid).set(data)
```

**Sesudah:**
```dart
Supabase.instance.client.from('users').insert(data)
```

## Setup Supabase

### 1. Buat Project Supabase
1. Kunjungi [supabase.com](https://supabase.com)
2. Buat account baru atau login
3. Klik "New Project"
4. Isi nama project, password database, dan region
5. Tunggu project selesai dibuat (1-2 menit)

### 2. Setup Database
1. Buka SQL Editor di Supabase dashboard
2. Copy dan jalankan script SQL dari `docs/supabase_schema.sql`
3. Pastikan tabel `users` terbuat dengan benar

### 3. Konfigurasi Environment
1. Copy file `.env.example` menjadi `.env`
2. Buka Supabase dashboard > Settings > API
3. Copy URL dan anon key ke file `.env`:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

### 4. Disable Row Level Security (RLS)
**Penting:** Aplikasi ini menggunakan pendekatan non-RLS untuk simplicity.
1. Buka Supabase dashboard > Authentication > Policies
2. Pastikan RLS dimatikan untuk tabel `users`
3. Atau jalankan: 
```sql
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
```

## Fitur yang Tersedia

### Authentication Service (`lib/services/auth_service.dart`)
- ✅ Register dengan email, username, password
- ✅ Login dengan email/username dan password
- ✅ Logout
- ✅ Get current user profile
- ✅ Update user profile
- ✅ Password reset
- ✅ Check username availability
- ✅ Get user by ID (admin)
- ✅ Search users (admin)
- ✅ Delete user account (admin)

### Database Service (`lib/services/database_service.dart`)
- ✅ Generic CRUD operations
- ✅ Search dengan ILIKE
- ✅ Pagination
- ✅ Bulk operations
- ✅ Real-time subscriptions
- ✅ Multiple conditions query
- ✅ Record existence check
- ✅ Data export
- ✅ Stored procedure calls

### User Model (`lib/models/user_model.dart`)
- ✅ Supabase compatible format
- ✅ fromMap/toMap methods
- ✅ copyWith method untuk updates
- ✅ Backward compatibility dengan Firebase UID

## Contoh Penggunaan

Lihat file `lib/examples/database_usage_examples.dart` untuk contoh lengkap penggunaan:

### Authentication
```dart
final authService = AuthService();

// Register
final user = await authService.register('email@test.com', 'username', 'password');

// Login
final loggedInUser = await authService.login('email@test.com', 'password');

// Update profile
final updatedUser = user.copyWith(username: 'new_username');
await authService.updateUserProfile(updatedUser);
```

### Database Operations
```dart
final dbService = DatabaseService();

// Insert data
await dbService.insertData('table_name', {'column': 'value'});

// Select data
final data = await dbService.selectData('table_name', 
  whereColumn: 'user_id', 
  whereValue: userId
);

// Pagination
final paginatedData = await dbService.getPaginatedData('table_name',
  page: 1, 
  pageSize: 10
);
```

## Security Considerations

**Non-RLS Setup:**
- Database tidak menggunakan Row Level Security
- Security handling dilakukan di application level
- Pastikan validasi input yang ketat
- Gunakan authentication check sebelum operasi database
- Monitor akses database melalui Supabase dashboard

**Best Practices:**
- Selalu check `isAuthenticated` sebelum operasi sensitif
- Validasi user permission di aplikasi
- Log semua operasi penting
- Gunakan environment variables untuk credentials
- Jangan expose service role key di client

## Build & Deploy

### Web Build
```bash
flutter build web
```

### Mobile Build
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Troubleshooting

### Error: Supabase URL/Key tidak valid
- Periksa file `.env` apakah URL dan key sudah benar
- Pastikan `.env` file tidak ter-commit ke git
- Restart aplikasi setelah mengubah `.env`

### Error: Table tidak ditemukan
- Pastikan SQL schema sudah dijalankan di Supabase
- Check nama tabel di database dashboard
- Pastikan user memiliki permission ke tabel

### Error: Authentication gagal
- Periksa email confirmation setting di Supabase
- Check password policy di Auth settings
- Pastikan user table trigger berfungsi

### Error: RLS Policy
- Disable RLS untuk semua tabel yang digunakan
- Atau implementasikan RLS policy yang sesuai
- Check permission grants dalam SQL schema

## Notes

- Build untuk web berhasil ✅
- TensorFlow Lite sudah dimock untuk web compatibility ✅
- Semua Firebase dependencies sudah dihapus ✅
- Real-time features tersedia melalui Supabase channels ✅
- PostgreSQL memungkinkan query yang lebih kompleks dibanding Firestore ✅
