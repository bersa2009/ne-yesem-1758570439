import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};

  // Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  // End timing an operation and log the duration
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      if (!_operationDurations.containsKey(operationName)) {
        _operationDurations[operationName] = [];
      }
      _operationDurations[operationName]!.add(duration);
      
      _operationStartTimes.remove(operationName);
      
      if (kDebugMode) {
        debugPrint('Operation "$operationName" took ${duration.inMilliseconds}ms');
      }
    }
  }

  // Get average duration for an operation
  Duration? getAverageOperationDuration(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) return null;
    
    final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  // Memory optimization helpers
  static void optimizeMemory() {
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // This is mainly for debugging purposes
      debugPrint('Requesting garbage collection...');
    }
  }

  // Image caching and optimization
  static ImageProvider optimizeImageProvider(String imagePath) {
    return ResizeImage(
      AssetImage(imagePath),
      width: 512,
      height: 512,
    );
  }

  // Debounce helper for search inputs
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Throttle helper for frequent operations
  static DateTime? _lastThrottleTime;
  static bool throttle(Duration interval) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      return true;
    }
    return false;
  }

  // Preload critical assets
  static Future<void> preloadAssets(BuildContext context) async {
    try {
      // Preload common images
      await Future.wait([
        precacheImage(const AssetImage('assets/icons/app_icon.png'), context),
        // Add more assets as needed
      ]);
    } catch (e) {
      debugPrint('Error preloading assets: $e');
    }
  }

  // Lazy loading helper for lists
  static Widget buildLazyList<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    int initialItemCount = 20,
    int loadMoreThreshold = 5,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        int displayCount = initialItemCount.clamp(0, items.length);
        
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= 
                scrollInfo.metrics.maxScrollExtent - (loadMoreThreshold * 100)) {
              if (displayCount < items.length) {
                setState(() {
                  displayCount = (displayCount + 10).clamp(0, items.length);
                });
              }
            }
            return false;
          },
          child: ListView.builder(
            itemCount: displayCount,
            itemBuilder: (context, index) => itemBuilder(items[index], index),
          ),
        );
      },
    );
  }

  // Performance monitoring widget
  static Widget buildPerformanceOverlay({required Widget child}) {
    if (!kDebugMode) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Batch operations helper
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
      
      if (i + batchSize < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }

  // Network request caching
  static final Map<String, CacheEntry> _cache = {};
  
  static T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }
    return null;
  }

  static void setCachedData<T>(String key, T data, {Duration expiry = const Duration(minutes: 5)}) {
    _cache[key] = CacheEntry(data, DateTime.now().add(expiry));
  }

  static void clearCache() {
    _cache.clear();
  }

  // Background task management
  static final List<Timer> _backgroundTasks = [];
  
  static void scheduleBackgroundTask(Duration interval, VoidCallback task) {
    final timer = Timer.periodic(interval, (_) => task());
    _backgroundTasks.add(timer);
  }

  static void cancelAllBackgroundTasks() {
    for (final timer in _backgroundTasks) {
      timer.cancel();
    }
    _backgroundTasks.clear();
  }

  // Resource cleanup
  void dispose() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _debounceTimer?.cancel();
    cancelAllBackgroundTasks();
    clearCache();
  }

  // Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _operationDurations.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        final avgDuration = getAverageOperationDuration(entry.key);
        final minDuration = durations.reduce((a, b) => a < b ? a : b);
        final maxDuration = durations.reduce((a, b) => a > b ? a : b);
        
        stats[entry.key] = {
          'count': durations.length,
          'average_ms': avgDuration?.inMilliseconds,
          'min_ms': minDuration.inMilliseconds,
          'max_ms': maxDuration.inMilliseconds,
        };
      }
    }
    
    return stats;
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  CacheEntry(this.data, this.expiry);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}

// Performance monitoring mixin
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  final PerformanceService _performance = PerformanceService();
  
  @override
  void initState() {
    super.initState();
    _performance.startOperation('${widget.runtimeType}_init');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performance.endOperation('${widget.runtimeType}_init');
  }
  
  @override
  void dispose() {
    _performance.endOperation('${widget.runtimeType}_dispose');
    super.dispose();
  }
  
  void trackOperation(String name, VoidCallback operation) {
    _performance.startOperation(name);
    operation();
    _performance.endOperation(name);
  }
}