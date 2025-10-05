# Quran Wrapped Feature Documentation

## Overview
Fitur **Quran Wrapped** adalah fitur annual report yang mirip dengan Spotify Wrapped, menampilkan ringkasan aktivitas membaca Al-Quran pengguna selama satu tahun.

## Features

### 1. **Availability Logic**
- **Current Year Wrapped**: Tersedia **setelah tanggal 31 Desember**
- **Last Year Wrapped**: Selalu tersedia untuk melihat data tahun sebelumnya
- Countdown timer menunjukkan berapa hari lagi sampai wrapped tersedia

### 2. **Data Shown**
- **Top 5 Surahs**: Surah yang paling sering dibaca (sorted by count descending)
- **Total Stats**:
  - Hari Aktif: Jumlah hari unik user membaca Al-Quran
  - Surah Dibaca: Jumlah surah unique yang dibaca
  - Total Sesi: Total semua sesi bacaan (sum of all counts)

### 3. **UI/UX Features**
- Beautiful animated cards with fade + slide + scale animations
- Gradient rank badges:
  - **#1**: Gold gradient 🥇
  - **#2**: Silver gradient 🥈
  - **#3**: Bronze gradient 🥉
  - **#4-5**: Dark gradient
- Trophy icons for top 3 surahs
- Year toggle button (switch between current/last year)
- Empty states:
  - **Wrapped Unavailable**: Shows countdown and button to view last year
  - **No Data**: Encourages user to start reading

## Technical Implementation

### 1. Database Query
```sql
SELECT surat_number, count, last_read_at
FROM surat_activity
WHERE user_id = [current_user]
  AND last_read_at >= [start_date]
  AND last_read_at <= [end_date]
ORDER BY count DESC
LIMIT 5;
```

### 2. Period Calculation
**Current Year Period**:
- Start: Dec 31, [last_year] 23:59:59
- End: Dec 31, [current_year] 23:59:59

**Last Year Period**:
- Start: Dec 31, [year-2] 23:59:59
- End: Dec 31, [year-1] 23:59:59

### 3. Availability Check
```dart
bool isWrappedAvailable() {
  final now = DateTime.now();
  final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
  return now.isAfter(yearEnd);
}
```

## Files Structure

### Services
- **`lib/services/wrapped_service.dart`**
  - `getCurrentYearPeriod()`: Get date range for current year
  - `getLastYearPeriod()`: Get date range for last year
  - `isWrappedAvailable()`: Check if wrapped is available
  - `getDaysUntilWrapped()`: Get countdown days
  - `getTopSurahs()`: Fetch top 5 surahs for a period
  - `getWrappedStats()`: Calculate all statistics
  - `getCurrentYearWrapped()`: Get current year data
  - `getLastYearWrapped()`: Get last year data

### Utils
- **`lib/utils/surah_names.dart`**
  - Static map of surah number → surah name (1-114)
  - Helper methods to get surah names

### Screens
- **`lib/screens/wrapped_screen.dart`**
  - Main UI with animations
  - Loading state
  - Unavailable state (with countdown)
  - No data state
  - Wrapped display with stats and top surahs

## Usage

### Navigate to Wrapped Screen
```dart
// Show current year (if available) or unavailable state
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const QuranWrappedScreen(),
  ),
);

// Show last year wrapped
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const QuranWrappedScreen(
      showLastYear: true,
    ),
  ),
);
```

### Expected User Flow

#### Scenario 1: Before Dec 31
1. User opens wrapped
2. Shows "Unavailable" state with countdown
3. Button to view last year's wrapped

#### Scenario 2: After Dec 31
1. User opens wrapped
2. Shows current year's top surahs and stats
3. Year toggle button to switch to last year

#### Scenario 3: No Reading Activity
1. User opens wrapped
2. Shows "No Data" empty state
3. Encourages user to start reading

## Data Dependencies

### Required Tables
- **`surat_activity`**:
  - `user_id` (uuid, FK to auth.users)
  - `surat_number` (integer, 1-114)
  - `count` (integer, nullable)
  - `last_read_at` (timestamp)

### Reading Activity Tracking
Activity is recorded when:
- User highlights 5+ unique ayahs in a surah
- Triggers `SuratActivityService.recordSuratActivity()`
- If existing: increment count
- If new: insert with count=null

## Best Practices

### 1. **Performance**
- Query only necessary date range
- Limit results to top 5 surahs
- Cache wrapped data in state (no repeated queries)

### 2. **UX**
- Progressive animations (header → stats → items)
- Staggered item animations (300ms delay between items)
- Smooth transitions between years
- Clear empty states with actionable CTAs

### 3. **Error Handling**
- Graceful fallback if database query fails
- Loading indicators during data fetch
- Empty states for no data scenarios

### 4. **Scalability**
- Service layer abstracts business logic
- Reusable period calculation methods
- Flexible to add more stats in future

## Future Enhancements

### Potential Features
1. **Share Feature**: Share wrapped as image to social media
2. **More Stats**:
   - Longest reading streak
   - Favorite time to read (morning/night)
   - Total ayahs highlighted
   - Most improved surah
3. **Achievements/Badges**: Unlock badges for milestones
4. **Comparison**: Compare with previous years
5. **Download PDF**: Export wrapped as PDF report
6. **Global Stats**: Anonymous aggregated community stats

### Technical TODOs
- [ ] Add caching for better performance
- [ ] Implement share functionality
- [ ] Add analytics tracking
- [ ] Support multiple themes
- [ ] Add unit tests for WrappedService
- [ ] Add integration tests for UI

## Testing Checklist

### Manual Testing
- [ ] Test before Dec 31: Shows unavailable state
- [ ] Test after Dec 31: Shows current year wrapped
- [ ] Test year toggle: Switches between current/last year
- [ ] Test with no data: Shows empty state
- [ ] Test with 1-4 surahs: Shows correct count
- [ ] Test with 5+ surahs: Shows top 5 only
- [ ] Test animations: All animations smooth
- [ ] Test loading state: Shows spinner correctly
- [ ] Test error handling: Graceful fallbacks

### Edge Cases
- [ ] User created account mid-year
- [ ] User read only 1 surah
- [ ] User has equal counts on multiple surahs
- [ ] Database connection fails
- [ ] Invalid date ranges
- [ ] Timezone differences

## Conclusion
Quran Wrapped provides users with engaging, visual feedback on their reading habits, encouraging continued engagement with the app throughout the year.
