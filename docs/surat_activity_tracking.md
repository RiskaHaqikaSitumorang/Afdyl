# Surat Activity Tracking Feature

## 📊 Overview
Fitur ini otomatis mencatat aktivitas membaca user ketika mereka telah meng-highlight minimal **5 ayat berbeda** (tidak harus berurutan) dalam satu surat.

## 🎯 Business Logic

### Tracking Rules:
1. ✅ Track setiap ayat yang di-highlight (baik manual tap atau auto-play)
2. ✅ Gunakan **Set** untuk store unique ayat indices (auto-handle duplicates)
3. ✅ Ketika mencapai **5 unique ayahs** → Record ke Supabase
4. ✅ **One record per day per surat** (prevent duplicates)
5. ✅ **Debouncing 2 detik** untuk avoid spam requests
6. ✅ **Session-based tracking** (reset saat buka surat baru)

### User Actions yang Di-track:
- ✅ Tap pada ayah container
- ✅ Tap pada ayah number badge
- ✅ Tap pada individual word
- ✅ Play button (audio) pada ayah
- ✅ Auto-highlight next/previous ayah
- ✅ Navigation dengan next/previous controls

## 🗄️ Database Schema

```sql
CREATE TABLE public.surat_activity (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    surat_number int NOT NULL,
    timestamp date NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_surat_activity_user_id ON public.surat_activity(user_id);
CREATE INDEX idx_surat_activity_timestamp ON public.surat_activity(timestamp);

-- Unique constraint: one record per user per surat per day
CREATE UNIQUE INDEX idx_unique_user_surat_date 
ON public.surat_activity(user_id, surat_number, timestamp);
```

## 📁 File Structure

```
lib/
├── models/
│   └── surat_activity_model.dart       # Data model
├── services/
│   └── surat_activity_service.dart     # Business logic & API calls
└── screens/
    └── reading_page.dart                # UI integration
```

## 🔧 Implementation

### 1. Model (`surat_activity_model.dart`)

```dart
class SuratActivity {
  final String id;
  final String userId;
  final int suratNumber;
  final DateTime timestamp;

  // Factory from JSON (Supabase response)
  // toJson for inserting data
}
```

### 2. Service (`surat_activity_service.dart`)

#### Main Methods:

**`recordSuratActivity(int suratNumber)`**
- Check if user is logged in
- Check if activity already recorded today
- Insert new record if not exists
- Return success/failure

**`getTotalReadingDays()`**
- Count unique dates in user's activity
- Used for statistics/achievements

**`getTotalSuratRead()`**
- Count unique surat numbers
- Show user progress

**`getReadingStreak()`**
- Calculate consecutive days of reading
- Gamification feature

**`hasReadToday()`**
- Quick check for daily goal
- Dashboard indicator

### 3. UI Integration (`reading_page.dart`)

#### State Variables:
```dart
final Set<int> _highlightedAyahs = {};  // Track unique ayahs
bool _activityRecorded = false;          // Prevent duplicate records
Timer? _activityDebounceTimer;           // Debounce mechanism
```

#### Key Methods:

**`_trackHighlightedAyah(int ayahIndex)`**
- Add ayah index to Set
- Check if reached threshold (5 ayahs)
- Trigger recording if threshold met
- Log progress for debugging

**`_recordActivity()`**
- Debounce with 2-second timer
- Call service to record activity
- Show success feedback (SnackBar)
- Prevent multiple recordings

#### Integration Points:
```dart
// Called from:
_playAyahAudio()        // When audio is played
_nextAyah()             // Navigation
_previousAyah()         // Navigation
_buildAyahWidget()      // Ayah container tap
_buildAyahNumberWidget() // Number badge tap
_wordWidget()           // Word tap
```

## 🎨 User Experience

### Success Feedback:
```dart
SnackBar(
  content: 'Progres bacaan tersimpan! 🎉',
  backgroundColor: Colors.green,
  duration: 2 seconds,
)
```

### Logging:
```dart
[ReadingPage] 📊 Highlighted ayahs: 3/5 (0, 2, 5)
[ReadingPage] 🎯 Recording activity for Surat 2
[SuratActivity] 📝 Recording activity for Surat 2
[SuratActivity] ✅ Activity recorded successfully
[ReadingPage] ✅ Activity recorded successfully
```

## 🔒 Security & Validation

### User Authentication:
- ✅ Check if user is logged in before recording
- ✅ Return false/skip if no user
- ✅ No crash if Supabase initialization failed

### Duplicate Prevention:
- ✅ Unique constraint in database (user_id + surat_number + timestamp)
- ✅ Check existing record before insert
- ✅ Session-based `_activityRecorded` flag

### Error Handling:
- ✅ Try-catch in all async operations
- ✅ Comprehensive logging
- ✅ Graceful failure (don't crash app)
- ✅ Return boolean success status

## 📊 Use Cases

### Statistics Dashboard:
```dart
// Show user stats
final totalDays = await SuratActivityService.getTotalReadingDays();
final totalSurat = await SuratActivityService.getTotalSuratRead();
final streak = await SuratActivityService.getReadingStreak();
```

### Daily Goal Indicator:
```dart
// Check if user completed today's reading
final hasRead = await SuratActivityService.hasReadToday();
// Show checkmark or encouragement
```

### Achievements/Badges:
```dart
// Unlock achievements based on activity
if (totalDays >= 7) showBadge('Week Warrior');
if (streak >= 30) showBadge('Month Master');
if (totalSurat >= 114) showBadge('Quran Completer');
```

### Progress Visualization:
```dart
// Calendar heatmap of reading activity
// Graph of daily/weekly/monthly progress
// Surat completion percentage
```

## 🧪 Testing

### Manual Test Cases:

1. **Happy Path:**
   - Open a surat
   - Tap/highlight 5 different ayahs
   - Verify SnackBar appears
   - Check Supabase record created

2. **Duplicate Prevention:**
   - Record activity for Surat 1
   - Close and reopen Surat 1
   - Highlight 5 ayahs again
   - Verify no new record (already exists today)

3. **Non-Sequential Ayahs:**
   - Highlight ayah 1, 5, 10, 3, 7
   - Verify counted as 5 unique ayahs
   - Verify activity recorded

4. **Same Ayah Multiple Times:**
   - Tap ayah 1 five times
   - Verify only counted once (Set behavior)
   - Verify NOT recorded (needs 5 unique)

5. **Session Reset:**
   - Open Surat 1, highlight 3 ayahs
   - Go back, open Surat 2
   - Verify counter reset to 0

6. **No User Logged In:**
   - Logout
   - Open surat, highlight ayahs
   - Verify no error, just logged warning

### Edge Cases:
- ✅ Network timeout → Graceful failure
- ✅ Supabase down → Log error, continue
- ✅ User logs out mid-session → Skip recording
- ✅ Rapid tapping → Debouncing prevents spam

## 🚀 Performance

### Optimization Techniques:

1. **Set for O(1) Lookups:**
   ```dart
   final Set<int> _highlightedAyahs = {};  // Fast duplicate check
   ```

2. **Debouncing:**
   ```dart
   Timer(Duration(seconds: 2), () {
     // Only record after 2s of last highlight
   });
   ```

3. **Session-based Flag:**
   ```dart
   bool _activityRecorded = false;  // Prevent redundant DB calls
   ```

4. **Early Returns:**
   ```dart
   if (_activityRecorded) return;  // Skip processing
   if (user == null) return;        // Skip if not logged in
   ```

5. **Single DB Call:**
   - Check existing + Insert in same transaction would be better
   - Current: 2 calls (check, then insert)
   - Future: Use `ON CONFLICT DO NOTHING` in single query

## 📈 Future Enhancements

### Potential Features:

1. **Time Tracking:**
   - Add `duration` field (how long user spent)
   - Track reading speed

2. **Ayah Range:**
   - Store which ayahs were read (array)
   - Show coverage heatmap

3. **Completion Percentage:**
   - Track % of surat read
   - Unlock badge at 100%

4. **Social Features:**
   - Share achievements
   - Leaderboards
   - Friend activity feed

5. **Analytics:**
   - Favorite surat
   - Most read time of day
   - Reading patterns

## 📝 Notes

### Why 5 Ayahs?
- ✅ Not too easy (prevents gaming)
- ✅ Not too hard (encourages engagement)
- ✅ Meaningful engagement threshold
- ✅ Can be adjusted via config

### Why Debouncing?
- ✅ Prevent spam from rapid taps
- ✅ Ensure user "settles" on 5 ayahs
- ✅ Reduce unnecessary API calls
- ✅ Better UX (one notification vs multiple)

### Why Set Instead of Array?
- ✅ Automatic duplicate handling
- ✅ O(1) add/check operations
- ✅ No need to manually check duplicates
- ✅ Clean, readable code

---

**Status:** ✅ Implemented and tested
**Version:** 1.0.0
**Last Updated:** October 5, 2025
