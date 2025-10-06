# Konfigurasi Password Reset dengan Deep Link

## Setup Supabase

### 1. Konfigurasi Redirect URLs di Supabase Dashboard

1. Buka Supabase Dashboard: https://app.supabase.com
2. Pilih project Anda
3. Klik **Authentication** di sidebar
4. Klik **URL Configuration**
5. Tambahkan URL berikut ke **Redirect URLs**:

```
afdylquran://reset-password
```

6. Jika menggunakan custom domain, tambahkan juga:
```
https://yourapp.com/reset-password
```

7. Klik **Save**

### 2. Konfigurasi Email Templates (Opsional)

1. Masih di **Authentication** → Klik **Email Templates**
2. Pilih **Reset Password**
3. Edit template untuk menambahkan instruksi yang jelas:

```html
<h2>Reset Password</h2>
<p>Klik link di bawah untuk reset password Anda:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
<p>Link ini akan expired dalam 1 jam.</p>
<p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
```

## Testing Flow

### Android Testing

1. **Build dan Install App**
```bash
flutter clean
flutter pub get
flutter run
```

2. **Test Flow**:
   - Buka app → Login screen
   - Masukkan email yang terdaftar
   - Klik "Lupa password?"
   - Dialog konfirmasi akan muncul
   - Buka email Anda
   - Klik link "Reset Password" di email
   - App akan terbuka otomatis (deep link)
   - Halaman Reset Password akan muncul
   - Masukkan password baru
   - Klik "Reset Password"
   - Redirect ke Login screen
   - Login dengan password baru

### iOS Testing (Tambahan)

Untuk iOS, tambahkan konfigurasi di `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>afdylquran</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.afdyl</string>
    </dict>
</array>

<!-- Universal Links (jika menggunakan domain) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:yourapp.com</string>
</array>
```

## Troubleshooting

### Deep Link Tidak Bekerja

1. **Cek AndroidManifest.xml**
   - Pastikan intent-filter sudah ditambahkan
   - Pastikan scheme dan host sesuai

2. **Cek Supabase Redirect URLs**
   - URL harus exact match: `afdylquran://reset-password`
   - Tidak ada trailing slash

3. **Clear App Data**
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter run
```

4. **Test Deep Link Manual**
```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "afdylquran://reset-password"
```

### Email Tidak Terkirim

1. **Cek Email Settings di Supabase**
   - Authentication → Settings → SMTP Settings
   - Pastikan email provider sudah dikonfigurasi

2. **Cek Spam Folder**
   - Email mungkin masuk ke spam

3. **Cek Logs di Supabase**
   - Dashboard → Logs → Auth Logs

### Session Expired

Jika user mendapat error "Sesi tidak valid":
- Link reset password expired (default 1 jam)
- User harus request link baru dari "Lupa password?"

## Security Notes

1. **Link Expiration**: Link reset password expired dalam 1 jam (konfigurasi Supabase)
2. **One-time Use**: Link hanya bisa dipakai sekali
3. **Secure Password**: Minimal 6 karakter (sesuaikan di validator)
4. **Rate Limiting**: Supabase secara default membatasi request reset password

## File yang Diubah

1. `lib/screens/reset_password_screen.dart` - Screen untuk reset password
2. `lib/services/auth_service.dart` - Method resetPassword()
3. `lib/services/deep_link_service.dart` - Handler deep links
4. `lib/routes/app_routes.dart` - Route baru untuk reset password
5. `lib/main.dart` - Initialize deep link service
6. `lib/screens/login_screen.dart` - Dialog konfirmasi yang lebih jelas
7. `android/app/src/main/AndroidManifest.xml` - Deep link configuration
8. `pubspec.yaml` - Package app_links

## Next Steps (Optional)

1. **Custom Domain**: Setup universal links dengan domain sendiri
2. **Email Customization**: Design email template yang lebih menarik
3. **Password Strength**: Tambah validator password yang lebih kuat
4. **2FA**: Implementasi two-factor authentication
5. **Password History**: Prevent reuse of recent passwords
