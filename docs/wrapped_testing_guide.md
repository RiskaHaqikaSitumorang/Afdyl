# Quran Wrapped - Testing Mode Guide

## 🧪 Current Configuration (TESTING MODE)

### Testing Period Setup
Untuk memudahkan testing tanpa menunggu sampai 31 Desember, wrapped sudah dikonfigurasi dengan:

### **Current Week (Default View)**
- **Period**: 7 hari terakhir dari hari ini
- **Start Date**: 5 Oktober 2025 - 7 hari = **28 September 2025**
- **End Date**: **5 Oktober 2025** (hari ini)
- **Label**: "7 Hari Terakhir"
- **Availability**: ✅ Selalu tersedia

### **Last Week (Toggle View)**
- **Period**: 14-7 hari yang lalu
- **Start Date**: **21 September 2025**
- **End Date**: **28 September 2025**
- **Label**: "7 Hari Lalu"
- **Availability**: ✅ Selalu tersedia

### Visual Indicators
- 🟠 **Orange banner** di atas screen: "TESTING MODE - Data 7 Hari"
- 📅 **Year toggle button** berubah jadi period toggle (7 Hari Terakhir ↔ 7 Hari Lalu)

## 📋 Testing Checklist

### 1. Persiapan Data
Untuk melihat hasil wrapped, pastikan Anda sudah:
- [ ] Login ke aplikasi
- [ ] Baca minimal 1 surah (highlight 5+ ayat) dalam 7 hari terakhir
- [ ] Tunggu 2 detik setelah highlight (debouncing)
- [ ] Activity tercatat di database `surat_activity`

### 2. Test Cases

#### Test Case 1: View Current Week Wrapped ✅
**Steps:**
1. Buka Wrapped screen (default view)
2. Verify banner "TESTING MODE" muncul
3. Verify title "Top Surah 7 Hari Terakhir"
4. Verify stats ditampilkan:
   - Hari Aktif
   - Surah Dibaca
   - Total Sesi
5. Verify top surahs muncul dengan ranking

**Expected:**
- Data dari 28 Sep - 5 Okt 2025 ditampilkan
- Animasi berjalan smooth (fade, slide, scale)
- Top 3 punya badge gradient (gold, silver, bronze)

#### Test Case 2: Toggle to Last Week ✅
**Steps:**
1. Dari current week view
2. Tap button period toggle (7 Hari Terakhir)
3. Screen refresh dengan data minggu lalu

**Expected:**
- Title berubah jadi "Top Surah 7 Hari Lalu"
- Data dari 21-28 Sep 2025 ditampilkan
- Button toggle jadi "7 Hari Lalu"

#### Test Case 3: No Data State ✅
**Steps:**
1. Login dengan user yang belum pernah baca
2. Buka Wrapped screen

**Expected:**
- Icon book outlined muncul
- Text "Belum Ada Data"
- Encouragement message muncul

#### Test Case 4: Multiple Surahs ✅
**Steps:**
1. Baca 5+ surah berbeda (highlight 5+ ayat each)
2. Buka Wrapped screen

**Expected:**
- Max 5 surah ditampilkan
- Sorted by count (paling sering dibaca di atas)
- Setiap surah show count: "Dibaca X kali"

#### Test Case 5: Same Surah Multiple Sessions ✅
**Steps:**
1. Baca Al-Fatihah (highlight 5+ ayat)
2. Tutup app
3. Buka lagi, baca Al-Fatihah lagi (highlight 5+ ayat)
4. Buka Wrapped

**Expected:**
- Al-Fatihah muncul dengan count = 2
- Text: "Dibaca 2 kali"

## 🔍 Database Verification

### Check Activity Records
```sql
-- View your activity in last 7 days
SELECT 
  surat_number,
  count,
  last_read_at,
  created_at
FROM surat_activity
WHERE user_id = '[your_user_id]'
  AND last_read_at >= NOW() - INTERVAL '7 days'
ORDER BY count DESC;
```

### Expected Data Structure
```json
{
  "surat_number": 1,  // Al-Fatihah
  "count": 3,         // Read 3 times
  "last_read_at": "2025-10-05T10:30:00Z",
  "created_at": "2025-10-01T08:00:00Z"
}
```

## 🐛 Troubleshooting

### Problem 1: "Belum Ada Data" muncul padahal sudah baca
**Solution:**
- Check apakah Anda highlight minimal 5 ayat berbeda
- Check database: apakah record ada di `surat_activity`
- Check timestamp: apakah `last_read_at` dalam range 7 hari terakhir
- Pastikan sudah tunggu 2 detik (debouncing)

### Problem 2: Count tidak bertambah saat baca ulang
**Solution:**
- Pastikan Anda tutup app atau ganti surah dulu (new session)
- Session ID berubah saat app dibuka ulang
- Check `_currentSessionId` di ReadingPage state

### Problem 3: Wrapped tidak muncul
**Solution:**
- Check login status (must be authenticated)
- Check console logs untuk error messages
- Verify Supabase connection

### Problem 4: Animasi tidak smooth
**Solution:**
- Check device performance
- Reduce animation duration di code
- Test di release build (lebih smooth dari debug)

## 🎯 Expected Behavior Flow

### Scenario: New User Testing
```
Day 1 (29 Sep): Baca Al-Fatihah (highlight 5 ayat)
  └─> Record created: Al-Fatihah, count=null

Day 2 (30 Sep): Baca An-Nas (highlight 5 ayat)
  └─> Record created: An-Nas, count=null

Day 3 (1 Okt): Baca Al-Fatihah lagi (new session)
  └─> Record updated: Al-Fatihah, count=1

Day 5 (5 Okt): Buka Wrapped
  └─> Shows:
      #1 Al-Fatihah - Dibaca 1 kali
      #2 An-Nas - Dibaca 1 kali
      
      Stats:
      - 3 Hari Aktif
      - 2 Surah Dibaca
      - 2 Total Sesi
```

## 📊 Success Metrics

After testing, verify:
- [ ] ✅ Wrapped screen loads without errors
- [ ] ✅ Data akurat sesuai activity 7 hari terakhir
- [ ] ✅ Animations smooth dan engaging
- [ ] ✅ Toggle period works correctly
- [ ] ✅ Empty states handled gracefully
- [ ] ✅ Count increments properly on re-read
- [ ] ✅ Top 5 sorting correct (by count DESC)
- [ ] ✅ Stats calculation accurate
- [ ] ✅ UI responsive di berbagai ukuran screen

## 🔄 Reverting to Production Mode

Setelah testing selesai, ubah kembali ke production configuration:

### File: `lib/services/wrapped_service.dart`

**Change from:**
```dart
// TESTING MODE: Period is last 7 days
final startDate = now.subtract(const Duration(days: 7));
final endDate = now;
```

**Back to:**
```dart
// PRODUCTION: Period is Jan 1 to Dec 31
final startDate = DateTime(currentYear - 1, 12, 31, 23, 59, 59);
final endDate = DateTime(currentYear, 12, 31, 23, 59, 59);
```

**Remove testing banner** in `wrapped_screen.dart`:
```dart
// Remove this entire block:
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  color: Colors.orange.withOpacity(0.9),
  child: Row(...),
),
```

**Update period labels**:
```dart
// Change from:
_periodYear = widget.showLastYear ? '7 Hari Lalu' : '7 Hari Terakhir';

// Back to:
_periodYear = widget.showLastYear 
    ? (now.year - 1).toString() 
    : now.year.toString();
```

## 📝 Notes

- Testing mode menggunakan data **real** dari database
- Tidak ada mock data, semua query actual
- Period calculation saja yang disesuaikan untuk testing
- Perfect untuk demo dan user acceptance testing
- Easy revert ke production mode

---

**Happy Testing! 🎉**
