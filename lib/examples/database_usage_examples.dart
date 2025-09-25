import 'package:afdyl/services/auth_service.dart';
import 'package:afdyl/services/database_service.dart';
import 'package:afdyl/models/user_model.dart';

class ExampleUsage {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  // Contoh penggunaan Authentication
  Future<void> exampleAuthUsage() async {
    try {
      // Register user baru
      final newUser = await _authService.register(
        'test@example.com', // email
        'testuser', // username
        'password123', // password
      );
      print('User registered: ${newUser?.username}');

      // Login
      final loggedInUser = await _authService.login(
        'test@example.com', // usernameOrEmail
        'password123', // password
      );
      print('User logged in: ${loggedInUser?.username}');

      // Get current user profile
      final currentUser = await _authService.getCurrentUserProfile();
      print('Current user: ${currentUser?.email}');

      // Update profile
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(username: 'newusername');
        await _authService.updateUserProfile(updatedUser);
        print('Profile updated');
      }

      // Check username availability
      final isAvailable = await _authService.isUsernameAvailable('anothername');
      print('Username available: $isAvailable');

      // Logout
      await _authService.signOut();
      print('User signed out');
    } catch (e) {
      print('Auth error: $e');
    }
  }

  // Contoh penggunaan Database Service untuk tabel kustom
  Future<void> exampleDatabaseUsage() async {
    try {
      // Insert data ke tabel kustom
      final insertedData = await _databaseService
          .insertData('hijaiyah_progress', {
            'user_id': _databaseService.getCurrentUserId(),
            'letter': 'alif',
            'progress': 75,
            'last_practiced': DateTime.now().toIso8601String(),
          });
      print('Data inserted: $insertedData');

      // Select data dengan kondisi
      final progressData = await _databaseService.selectData(
        'hijaiyah_progress',
        whereColumn: 'user_id',
        whereValue: _databaseService.getCurrentUserId(),
        orderBy: 'last_practiced',
        ascending: false,
      );
      print('Progress data: ${progressData.length} records');

      // Update data
      if (progressData.isNotEmpty) {
        final updated = await _databaseService.updateData(
          'hijaiyah_progress',
          {'progress': 90, 'last_practiced': DateTime.now().toIso8601String()},
          'id',
          progressData.first['id'],
        );
        print('Data updated: $updated');
      }

      // Search data
      final searchResults = await _databaseService.searchData(
        'hijaiyah_progress',
        'letter',
        'ali',
        limit: 10,
      );
      print('Search results: ${searchResults.length} records');

      // Get paginated data
      final paginatedData = await _databaseService.getPaginatedData(
        'hijaiyah_progress',
        page: 1,
        pageSize: 5,
        orderBy: 'progress',
        ascending: false,
      );
      print('Paginated data: ${paginatedData['pagination']}');

      // Count records
      final count = await _databaseService.countRecords(
        'hijaiyah_progress',
        whereColumn: 'user_id',
        whereValue: _databaseService.getCurrentUserId(),
      );
      print('Total records: $count');

      // Check if record exists
      final exists = await _databaseService.recordExists(
        'hijaiyah_progress',
        'letter',
        'alif',
      );
      print('Record exists: $exists');
    } catch (e) {
      print('Database error: $e');
    }
  }

  // Contoh penggunaan Real-time subscription
  void exampleRealtimeUsage() {
    try {
      final channel = _databaseService.subscribeToTable(
        'users',
        onInsert: (data) {
          print('New user inserted: ${data['username']}');
        },
        onUpdate: (data) {
          print('User updated: ${data['username']}');
        },
        onDelete: (data) {
          print('User deleted: ${data['id']}');
        },
      );

      // Unsubscribe later
      // await _databaseService.unsubscribeChannel(channel);
    } catch (e) {
      print('Realtime error: $e');
    }
  }

  // Contoh penggunaan dengan multiple conditions
  Future<void> exampleMultipleConditions() async {
    try {
      final results = await _databaseService.selectDataWithMultipleConditions(
        'hijaiyah_progress',
        {
          'user_id': _databaseService.getCurrentUserId(),
          'progress': 100, // Only completed letters
        },
        orderBy: 'last_practiced',
        ascending: false,
        limit: 10,
      );
      print('Completed letters: ${results.length}');
    } catch (e) {
      print('Multiple conditions error: $e');
    }
  }

  // Contoh bulk operations
  Future<void> exampleBulkOperations() async {
    try {
      // Bulk insert hijaiyah letters progress
      final hijaiyahLetters = [
        'alif',
        'ba',
        'ta',
        'tsa',
        'jim',
        'ha',
        'kha',
        'dal',
        'dzal',
        'ra',
        'za',
        'sin',
        'syin',
        'shad',
        'dhad',
        'tha',
        'zha',
        'ain',
        'ghain',
        'fa',
        'qaf',
        'kaf',
        'lam',
        'mim',
        'nun',
        'waw',
        'ha2',
        'ya',
      ];

      final bulkData =
          hijaiyahLetters
              .map(
                (letter) => {
                  'user_id': _databaseService.getCurrentUserId(),
                  'letter': letter,
                  'progress': 0,
                  'last_practiced': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      final insertedBulk = await _databaseService.bulkInsert(
        'hijaiyah_progress',
        bulkData,
      );
      print('Bulk inserted: ${insertedBulk.length} records');
    } catch (e) {
      print('Bulk operations error: $e');
    }
  }

  // Contoh export data
  Future<void> exampleExportData() async {
    try {
      final allUsers = await _databaseService.exportTableData('users');
      print('Exported users: ${allUsers.length} records');

      // Bisa disimpan ke file atau dikirim ke server
      // File exportFile = File('users_backup.json');
      // await exportFile.writeAsString(jsonEncode(allUsers));
    } catch (e) {
      print('Export error: $e');
    }
  }
}
