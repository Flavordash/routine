import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  static PerformanceMonitor get instance => _instance;

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _metrics = {};
  final List<PerformanceEvent> _events = [];
  
  bool _isEnabled = kDebugMode;
  int _maxEvents = 1000;

  void enable() => _isEnabled = true;
  void disable() => _isEnabled = false;
  bool get isEnabled => _isEnabled;

  void setMaxEvents(int maxEvents) => _maxEvents = maxEvents;

  // Timer methods
  void startTimer(String operationName) {
    if (!_isEnabled) return;
    _startTimes[operationName] = DateTime.now();
  }

  int? endTimer(String operationName) {
    if (!_isEnabled) return null;
    
    final startTime = _startTimes.remove(operationName);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    
    _metrics[operationName] ??= [];
    _metrics[operationName]!.add(duration);

    _addEvent(PerformanceEvent(
      type: EventType.timing,
      name: operationName,
      duration: duration,
      timestamp: DateTime.now(),
    ));

    return duration;
  }

  // Measure any operation
  static Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    instance.startTimer(operationName);
    try {
      final result = await operation();
      final duration = instance.endTimer(operationName);
      
      if (kDebugMode && duration != null) {
        developer.log(
          '$operationName completed in ${duration}ms',
          name: 'Performance',
        );
      }
      
      return result;
    } catch (error) {
      instance.endTimer(operationName);
      instance.recordError(operationName, error);
      rethrow;
    }
  }

  static T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    instance.startTimer(operationName);
    try {
      final result = operation();
      final duration = instance.endTimer(operationName);
      
      if (kDebugMode && duration != null) {
        developer.log(
          '$operationName completed in ${duration}ms',
          name: 'Performance',
        );
      }
      
      return result;
    } catch (error) {
      instance.endTimer(operationName);
      instance.recordError(operationName, error);
      rethrow;
    }
  }

  // Memory usage tracking
  void recordMemoryUsage(String context) {
    if (!_isEnabled) return;

    _addEvent(PerformanceEvent(
      type: EventType.memory,
      name: context,
      timestamp: DateTime.now(),
    ));
  }

  // Error tracking
  void recordError(String context, dynamic error) {
    if (!_isEnabled) return;

    _addEvent(PerformanceEvent(
      type: EventType.error,
      name: context,
      error: error.toString(),
      timestamp: DateTime.now(),
    ));

    if (kDebugMode) {
      developer.log(
        'Error in $context: $error',
        name: 'Performance',
        error: error,
      );
    }
  }

  // Network request tracking
  void recordNetworkRequest(String url, int duration, int? statusCode) {
    if (!_isEnabled) return;

    _addEvent(PerformanceEvent(
      type: EventType.network,
      name: url,
      duration: duration,
      metadata: {'statusCode': statusCode},
      timestamp: DateTime.now(),
    ));
  }

  // User interaction tracking
  void recordUserInteraction(String interaction) {
    if (!_isEnabled) return;

    _addEvent(PerformanceEvent(
      type: EventType.userInteraction,
      name: interaction,
      timestamp: DateTime.now(),
    ));
  }

  // Widget rebuild tracking
  void recordWidgetRebuild(String widgetName) {
    if (!_isEnabled) return;

    _addEvent(PerformanceEvent(
      type: EventType.widgetRebuild,
      name: widgetName,
      timestamp: DateTime.now(),
    ));
  }

  void _addEvent(PerformanceEvent event) {
    _events.add(event);
    
    // Keep only the last N events to prevent memory leaks
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
  }

  // Analytics methods
  PerformanceStats getStats(String operationName) {
    final durations = _metrics[operationName] ?? [];
    
    if (durations.isEmpty) {
      return PerformanceStats(
        operationName: operationName,
        count: 0,
        averageDuration: 0,
        minDuration: 0,
        maxDuration: 0,
      );
    }

    durations.sort();
    final sum = durations.reduce((a, b) => a + b);
    
    return PerformanceStats(
      operationName: operationName,
      count: durations.length,
      averageDuration: sum / durations.length,
      minDuration: durations.first.toDouble(),
      maxDuration: durations.last.toDouble(),
      p95Duration: durations[(durations.length * 0.95).floor().clamp(0, durations.length - 1)].toDouble(),
    );
  }

  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final operationName in _metrics.keys) {
      stats[operationName] = getStats(operationName);
    }
    return stats;
  }

  List<PerformanceEvent> getEvents({
    EventType? type,
    Duration? since,
  }) {
    var events = _events.toList();
    
    if (type != null) {
      events = events.where((e) => e.type == type).toList();
    }
    
    if (since != null) {
      final cutoff = DateTime.now().subtract(since);
      events = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }
    
    return events;
  }

  void clearStats() {
    _metrics.clear();
    _events.clear();
    _startTimes.clear();
  }

  // Export data for external analytics
  Map<String, dynamic> exportData() {
    return {
      'stats': getAllStats().map((k, v) => MapEntry(k, v.toJson())),
      'events': _events.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

// Performance monitoring widget wrapper
class PerformanceTracker extends StatefulWidget {
  const PerformanceTracker({
    super.key,
    required this.child,
    required this.name,
    this.trackRebuilds = true,
  });

  final Widget child;
  final String name;
  final bool trackRebuilds;

  @override
  State<PerformanceTracker> createState() => _PerformanceTrackerState();
}

class _PerformanceTrackerState extends State<PerformanceTracker> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.trackRebuilds) {
      _buildCount++;
      PerformanceMonitor.instance.recordWidgetRebuild('${widget.name}(#$_buildCount)');
    }

    return widget.child;
  }
}

// Auto-tracking mixin for StatefulWidgets
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  String get trackingName => T.toString();
  late DateTime _initTime;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now();
    PerformanceMonitor.instance.startTimer('${trackingName}_init');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceMonitor.instance.endTimer('${trackingName}_init');
  }

  @override
  void dispose() {
    final totalLifetime = DateTime.now().difference(_initTime).inMilliseconds;
    PerformanceMonitor.instance._addEvent(PerformanceEvent(
      type: EventType.widgetLifetime,
      name: trackingName,
      duration: totalLifetime,
      timestamp: DateTime.now(),
    ));
    super.dispose();
  }
}

// Data classes
enum EventType {
  timing,
  memory,
  error,
  network,
  userInteraction,
  widgetRebuild,
  widgetLifetime,
}

class PerformanceEvent {
  final EventType type;
  final String name;
  final int? duration;
  final String? error;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  PerformanceEvent({
    required this.type,
    required this.name,
    this.duration,
    this.error,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'duration': duration,
      'error': error,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PerformanceStats {
  final String operationName;
  final int count;
  final double averageDuration;
  final double minDuration;
  final double maxDuration;
  final double? p95Duration;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    this.p95Duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'count': count,
      'averageDuration': averageDuration,
      'minDuration': minDuration,
      'maxDuration': maxDuration,
      'p95Duration': p95Duration,
    };
  }

  @override
  String toString() {
    return 'PerformanceStats($operationName: ${averageDuration.toStringAsFixed(2)}ms avg, ${count}x)';
  }
}

// Performance overlay widget for development
class PerformanceOverlay extends StatefulWidget {
  const PerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  final Widget child;
  final bool enabled;

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  bool _showOverlay = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_showOverlay && mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled && _showOverlay)
          Positioned(
            top: 100,
            right: 16,
            child: _buildPerformancePanel(),
          ),
        if (widget.enabled)
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'performance_toggle',
              onPressed: () {
                setState(() {
                  _showOverlay = !_showOverlay;
                });
              },
              child: Icon(_showOverlay ? Icons.close : Icons.speed),
            ),
          ),
      ],
    );
  }

  Widget _buildPerformancePanel() {
    final stats = PerformanceMonitor.instance.getAllStats();
    final recentErrors = PerformanceMonitor.instance.getEvents(
      type: EventType.error,
      since: const Duration(minutes: 1),
    );

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Performance Monitor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (stats.isEmpty)
            const Text(
              'No performance data yet',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...stats.entries.take(5).map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${entry.key}: ${entry.value.averageDuration.toStringAsFixed(1)}ms',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )),
          if (recentErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recent Errors: ${recentErrors.length}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}