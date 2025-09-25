import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generic method untuk insert data
  Future<Map<String, dynamic>?> insertData(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await _supabase.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      print('Error inserting data to $table: $e');
      throw Exception('Gagal menyimpan data: $e');
    }
  }

  // Generic method untuk update data
  Future<Map<String, dynamic>?> updateData(
    String table,
    Map<String, dynamic> data,
    String whereColumn,
    dynamic whereValue,
  ) async {
    try {
      final response =
          await _supabase
              .from(table)
              .update(data)
              .eq(whereColumn, whereValue)
              .select()
              .single();
      return response;
    } catch (e) {
      print('Error updating data in $table: $e');
      throw Exception('Gagal memperbarui data: $e');
    }
  }

  // Generic method untuk delete data
  Future<void> deleteData(
    String table,
    String whereColumn,
    dynamic whereValue,
  ) async {
    try {
      await _supabase.from(table).delete().eq(whereColumn, whereValue);
    } catch (e) {
      print('Error deleting data from $table: $e');
      throw Exception('Gagal menghapus data: $e');
    }
  }

  // Generic method untuk select data
  Future<List<Map<String, dynamic>>> selectData(
    String table, {
    String? select,
    String? whereColumn,
    dynamic whereValue,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabase.from(table).select(select ?? '*');

      if (whereColumn != null && whereValue != null) {
        query = query.eq(whereColumn, whereValue);
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error selecting data from $table: $e');
      throw Exception('Gagal mengambil data: $e');
    }
  }

  // Method untuk select data dengan kondisi kompleks menggunakan OR
  Future<List<Map<String, dynamic>>> selectDataWithOrFilter(
    String table, {
    String? select,
    String? orFilter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabase.from(table).select(select ?? '*');

      if (orFilter != null) {
        query = query.or(orFilter);
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error selecting filtered data from $table: $e');
      throw Exception('Gagal mengambil data dengan filter: $e');
    }
  }

  // Method untuk count records (simplified)
  Future<int> countRecords(
    String table, {
    String? whereColumn,
    dynamic whereValue,
  }) async {
    try {
      dynamic query = _supabase.from(table).select('id');

      if (whereColumn != null && whereValue != null) {
        query = query.eq(whereColumn, whereValue);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      print('Error counting records in $table: $e');
      return 0;
    }
  }

  // Method untuk bulk insert
  Future<List<Map<String, dynamic>>> bulkInsert(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    try {
      final response = await _supabase.from(table).insert(dataList).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error bulk inserting data to $table: $e');
      throw Exception('Gagal menyimpan data secara bulk: $e');
    }
  }

  // Method untuk upsert (insert or update) - simplified
  Future<List<Map<String, dynamic>>> upsertData(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    try {
      final response = await _supabase.from(table).upsert(dataList).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error upserting data to $table: $e');
      throw Exception('Gagal upsert data: $e');
    }
  }

  // Method untuk execute stored procedure atau function
  Future<dynamic> callFunction(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _supabase.rpc(functionName, params: params);
      return response;
    } catch (e) {
      print('Error calling function $functionName: $e');
      throw Exception('Gagal menjalankan function: $e');
    }
  }

  // Method untuk mendapatkan current user ID dari session
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Method untuk check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Method untuk real-time subscription (simplified)
  RealtimeChannel subscribeToTable(
    String table, {
    String? schema = 'public',
    Function(Map<String, dynamic>)? onInsert,
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onDelete,
  }) {
    final channel = _supabase.channel('$table-changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: schema!,
      table: table,
      callback: (payload) {
        switch (payload.eventType) {
          case PostgresChangeEvent.insert:
            onInsert?.call(payload.newRecord);
            break;
          case PostgresChangeEvent.update:
            onUpdate?.call(payload.newRecord);
            break;
          case PostgresChangeEvent.delete:
            onDelete?.call(payload.oldRecord);
            break;
          default:
            break;
        }
      },
    );

    channel.subscribe();
    return channel;
  }

  // Method untuk unsubscribe channel
  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // Method untuk backup/export table data
  Future<List<Map<String, dynamic>>> exportTableData(String table) async {
    try {
      final data = await selectData(table);
      return data;
    } catch (e) {
      print('Error exporting data from $table: $e');
      throw Exception('Gagal export data: $e');
    }
  }

  // Method untuk text search dengan ilike
  Future<List<Map<String, dynamic>>> searchData(
    String table,
    String column,
    String searchTerm, {
    String? select,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase
          .from(table)
          .select(select ?? '*')
          .ilike(column, '%$searchTerm%');

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching data in $table: $e');
      throw Exception('Gagal mencari data: $e');
    }
  }

  // Method untuk pagination
  Future<Map<String, dynamic>> getPaginatedData(
    String table, {
    String? select,
    int page = 1,
    int pageSize = 10,
    String? orderBy,
    bool ascending = true,
    String? whereColumn,
    dynamic whereValue,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      // Get total count
      final totalCount = await countRecords(
        table,
        whereColumn: whereColumn,
        whereValue: whereValue,
      );

      // Get paginated data
      final data = await selectData(
        table,
        select: select,
        whereColumn: whereColumn,
        whereValue: whereValue,
        orderBy: orderBy,
        ascending: ascending,
        limit: pageSize,
        offset: offset,
      );

      final totalPages = (totalCount / pageSize).ceil();

      return {
        'data': data,
        'pagination': {
          'currentPage': page,
          'pageSize': pageSize,
          'totalCount': totalCount,
          'totalPages': totalPages,
          'hasNextPage': page < totalPages,
          'hasPreviousPage': page > 1,
        },
      };
    } catch (e) {
      print('Error getting paginated data from $table: $e');
      throw Exception('Gagal mengambil data dengan pagination: $e');
    }
  }

  // Method untuk multiple conditions dengan AND
  Future<List<Map<String, dynamic>>> selectDataWithMultipleConditions(
    String table,
    Map<String, dynamic> conditions, {
    String? select,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from(table).select(select ?? '*');

      // Apply all conditions
      conditions.forEach((column, value) {
        query = query.eq(column, value);
      });

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error selecting data with multiple conditions from $table: $e');
      throw Exception('Gagal mengambil data dengan kondisi multiple: $e');
    }
  }

  // Method untuk check if record exists
  Future<bool> recordExists(
    String table,
    String whereColumn,
    dynamic whereValue,
  ) async {
    try {
      final data = await selectData(
        table,
        select: 'id',
        whereColumn: whereColumn,
        whereValue: whereValue,
        limit: 1,
      );
      return data.isNotEmpty;
    } catch (e) {
      print('Error checking if record exists in $table: $e');
      return false;
    }
  }
}
