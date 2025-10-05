# Quick Integration: Add Wrapped Button to Dashboard

## Example: Add Floating Action Button

### Option 1: Floating Action Button (Simple)

Add this to your `dashboard_screen.dart`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... your existing body
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuranWrappedScreen(),
          ),
        );
      },
      icon: const Icon(Icons.emoji_events),
      label: const Text('Wrapped'),
      backgroundColor: Colors.purple,
    ),
  );
}
```

### Option 2: Menu Card (Better UX)

Add this to your dashboard grid/menu:

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QuranWrappedScreen(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            'Quran\nWrapped',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### Option 3: App Bar Action

Add to your app bar:

```dart
AppBar(
  title: const Text('Dashboard'),
  actions: [
    IconButton(
      icon: const Icon(Icons.emoji_events),
      tooltip: 'Quran Wrapped',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuranWrappedScreen(),
          ),
        );
      },
    ),
  ],
)
```

### Don't Forget Import!

Add this at the top of your file:

```dart
import '../screens/wrapped_screen.dart';
```

---

## Testing Navigation

After adding the button:

1. ✅ Hot reload or restart app
2. ✅ Tap the Wrapped button
3. ✅ Verify screen opens with testing banner
4. ✅ Check if data loads correctly
5. ✅ Test period toggle
6. ✅ Test back button

---

**Recommended**: Option 2 (Menu Card) for best user experience!
