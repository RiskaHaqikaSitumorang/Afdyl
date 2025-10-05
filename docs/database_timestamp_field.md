# Database Schema Update - surat_activity Table

## ✅ Correct Field Name

### Table: `surat_activity`

```sql
CREATE TABLE public.surat_activity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  surat_number integer NOT NULL,
  timestamp date NOT NULL,  -- ✅ CORRECT: Uses 'timestamp' not 'last_read_at'
  count integer NULL,
  created_at timestamp DEFAULT now()
);
```

### Field Details:

#### `timestamp` (date)
- **Format**: `YYYY-MM-DD` (e.g., `2025-10-05`)
- **Type**: `date` (not timestamp with timezone)
- **Purpose**: Track the date when activity was recorded
- **Used for**: 
  - Wrapped period filtering
  - Unique days calculation
  - Date-based queries

#### Why `date` type?
- Simpler comparison (no timezone issues)
- Unique by day (not by exact time)
- Better for daily statistics
- Cleaner date range queries

## 🔧 Code Implementation

### Service Layer (wrapped_service.dart)

```dart
// ✅ CORRECT: Using 'timestamp' field
final response = await _supabase
    .from('surat_activity')
    .select('surat_number, count, timestamp')
    .eq('user_id', userId)
    .gte('timestamp', _formatDate(startDate))  // Date string: '2025-10-05'
    .lte('timestamp', _formatDate(endDate))
    .order('count', ascending: false)
    .limit(5);
```

### Date Format Helper

```dart
// Format DateTime to ISO date string (yyyy-MM-dd)
static String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

### Recording Activity (surat_activity_service.dart)

```dart
// ✅ CORRECT: Insert with timestamp as date string
await _supabase.from('surat_activity').insert({
  'user_id': user.id,
  'surat_number': suratNumber,
  'timestamp': DateTime.now().toIso8601String().split('T')[0], // '2025-10-05'
  'count': null,
});

// ✅ CORRECT: Update with new timestamp
await _supabase.from('surat_activity').update({
  'count': newCount,
  'timestamp': DateTime.now().toIso8601String().split('T')[0],
}).eq('id', existing['id']);
```

## 📊 Query Examples

### Get activities in date range:
```dart
await _supabase
    .from('surat_activity')
    .select('*')
    .eq('user_id', userId)
    .gte('timestamp', '2025-09-28')  // Start date
    .lte('timestamp', '2025-10-05')  // End date
    .order('timestamp', ascending: false);
```

### Count unique days:
```dart
final response = await _supabase
    .from('surat_activity')
    .select('timestamp')
    .eq('user_id', userId);

// timestamp is already string format 'YYYY-MM-DD'
final uniqueDays = response
    .map((e) => e['timestamp'] as String)
    .toSet()
    .length;
```

### Get top surahs by count:
```dart
await _supabase
    .from('surat_activity')
    .select('surat_number, count, timestamp')
    .eq('user_id', userId)
    .gte('timestamp', startDate)
    .lte('timestamp', endDate)
    .order('count', ascending: false)
    .limit(5);
```

## ✅ Benefits of Using `date` Type

1. **Simplicity**: No timezone conversion needed
2. **Uniqueness**: One record per surat (updated by date)
3. **Performance**: Faster date range queries
4. **Clarity**: Clear intent (daily tracking, not hourly)
5. **Storage**: Less space than full timestamp

## 🔄 Migration Notes

If you previously used `last_read_at` with timestamp:

```sql
-- Rename column (if needed)
ALTER TABLE surat_activity 
RENAME COLUMN last_read_at TO timestamp;

-- Change type to date (if needed)
ALTER TABLE surat_activity 
ALTER COLUMN timestamp TYPE date 
USING timestamp::date;
```

## 📝 Summary

- ✅ Use `timestamp` field (type: `date`)
- ✅ Format: `YYYY-MM-DD` string
- ✅ Query with `gte()` and `lte()` for date ranges
- ✅ No timezone issues
- ✅ Clean and simple

---

**Updated**: October 5, 2025
**Status**: ✅ Implemented and working
