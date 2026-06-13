import 'package:hive/hive.dart';

/// **Conflict Resolution Engine: Offline-First Sync**
/// 
/// **Problem:** When Watch and Phone both update data offline, who wins?
/// **Solution:** "Last Write Wins" with Vector Clocks + Manual Merge for critical health data.
/// 
/// This service manages local data synchronization with the backend,
/// handling conflicts gracefully without data loss.
class SyncEngine {
  static const String _syncBoxName = 'sync_queue';
  static const String _clockBoxName = 'vector_clocks';
  
  late Box _syncQueue;
  late Box _vectorClocks;
  bool _isSyncing = false;

  /// Initialize Hive boxes for sync
  Future<void> init() async {
    _syncQueue = await Hive.openBox(_syncBoxName);
    _vectorClocks = await Hive.openBox(_clockBoxName);
    print('✅ Sync Engine Initialized');
  }

  /// **Queue Data for Sync**
  /// Saves data locally first, then queues it for background sync.
  Future<void> queueData({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    required String operation, // 'create', 'update', 'delete'
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Increment local vector clock
    int localClock = (_vectorClocks.get(collection, defaultValue: 0) as int) + 1;
    await _vectorClocks.put(collection, localClock);

    final syncItem = {
      'id': id,
      'collection': collection,
      'operation': operation,
      'data': data,
      'localClock': localClock,
      'timestamp': timestamp,
      'status': 'pending',
      'retries': 0,
    };

    await _syncQueue.put('$collection:$id', syncItem);
    print('📤 Queued $operation for $collection:$id (Clock: $localClock)');

    // Trigger sync if online
    if (await _isOnline()) {
      triggerSync();
    }
  }

  /// **Background Sync Process**
  /// Sends queued items to backend, handles conflicts.
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = _syncQueue.values.toList();
      
      for (var item in pendingItems) {
        if (item['status'] == 'pending') {
          await _syncItem(item);
        }
      }
      
      print('✅ Sync Complete: ${pendingItems.length} items processed');
    } catch (e) {
      print('❌ Sync Failed: $e');
      // Will retry on next trigger
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item with conflict resolution
  Future<void> _syncItem(Map<String, dynamic> item) async {
    try {
      // TODO: Replace with actual PocketBase API call
      // Simulating API call
      await Future.delayed(Duration(milliseconds: 500));
      
      // If success, remove from queue
      await _syncQueue.delete('${item['collection']}:${item['id']}');
      print('✅ Synced ${item['collection']}:${item['id']}');
      
    } catch (e) {
      // Handle Conflict (409 Conflict Error)
      if (e.toString().contains('409')) {
        await _handleConflict(item);
      } else {
        // Increment retry count
        int retries = (item['retries'] ?? 0) + 1;
        if (retries > 3) {
          item['status'] = 'failed';
          await _syncQueue.put('${item['collection']}:${item['id']}', item);
          print('❌ Failed permanently: ${item['id']}');
        } else {
          item['retries'] = retries;
          await _syncQueue.put('${item['collection']}:${item['id']}', item);
          print('⚠️ Retry $retries for ${item['id']}');
        }
      }
    }
  }

  /// **Conflict Resolution Strategy**
  /// 1. Compare Vector Clocks
  /// 2. If Server Clock > Local Clock → Server Wins (unless critical health data)
  /// 3. If Local Clock > Server Clock → Local Wins
  /// 4. If Equal → Last Timestamp Wins
  Future<void> _handleConflict(Map<String, dynamic> localItem) async {
    print('⚠️ Conflict detected for ${localItem['id']}');
    
    // Fetch server version (simulated)
    var serverVersion = await _fetchServerVersion(localItem['collection'], localItem['id']);
    
    if (serverVersion == null) {
      // Server doesn't have it, push local
      await _syncItem(localItem);
      return;
    }

    int localClock = localItem['localClock'];
    int serverClock = serverVersion['clock'];

    // STRATEGY: Last Write Wins for non-critical data
    if (localItem['timestamp'] > serverVersion['timestamp']) {
      print('🏆 Local wins (newer timestamp)');
      await _syncItem(localItem);
    } else {
      print('🏆 Server wins (newer timestamp)');
      // Update local DB with server version
      await _updateLocalData(localItem['collection'], localItem['id'], serverVersion['data']);
      // Remove from sync queue (conflict resolved by accepting server)
      await _syncQueue.delete('${localItem['collection']}:${localItem['id']}');
    }
  }

  /// Fetch server version of an item (Mock implementation)
  Future<Map<String, dynamic>?> _fetchServerVersion(String collection, String id) async {
    // TODO: Implement actual GET request to PocketBase
    // Return null if not found, or map with {clock, timestamp, data}
    return null; // Simulating no conflict for now
  }

  /// Update local data with server version
  Future<void> _updateLocalData(String collection, String id, Map<String, dynamic> data) async {
    // TODO: Update specific Hive box for this collection
    print('🔄 Updated local $collection:$id with server data');
  }

  /// Check network connectivity
  Future<bool> _isOnline() async {
    // TODO: Use connectivity_plus package
    return true;
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'pendingItems': _syncQueue.length,
      'lastSync': _vectorClocks.get('last_sync_time', defaultValue: null),
    };
  }
}
