import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:convert';
import 'dart:async';

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  const LogLevel(this.value);
  final int value;

  bool operator >(LogLevel other) => value > other.value;
  bool operator >=(LogLevel other) => value >= other.value;
  bool operator <(LogLevel other) => value < other.value;
  bool operator <=(LogLevel other) => value <= other.value;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${timestamp.toIso8601String()} ');
    buffer.write('[${level.name.toUpperCase()}]');
    if (tag != null) buffer.write('[${tag}]');
    buffer.write(' $message');
    if (error != null) buffer.write(' | Error: $error');
    return buffer.toString();
  }
}

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  static Logger get instance => _instance;

  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  final List<LogEntry> _logs = [];
  final List<LogHandler> _handlers = [];
  
  int _maxLogs = 1000;
  String? _sessionId;

  void setMinLevel(LogLevel level) => _minLevel = level;
  void setMaxLogs(int maxLogs) => _maxLogs = maxLogs;
  void setSessionId(String sessionId) => _sessionId = sessionId;

  void addHandler(LogHandler handler) => _handlers.add(handler);
  void removeHandler(LogHandler handler) => _handlers.remove(handler);
  void clearHandlers() => _handlers.clear();

  // Logging methods
  void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, tag: tag, metadata: metadata);
  }

  void info(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, tag: tag, metadata: metadata);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, message, tag: tag, metadata: metadata);
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  // Convenience methods for common scenarios
  void auth(String message, {Map<String, dynamic>? metadata}) {
    info(message, tag: 'AUTH', metadata: metadata);
  }

  void network(String message, {Map<String, dynamic>? metadata}) {
    info(message, tag: 'NETWORK', metadata: metadata);
  }

  void ui(String message, {Map<String, dynamic>? metadata}) {
    debug(message, tag: 'UI', metadata: metadata);
  }

  void performance(String message, {Map<String, dynamic>? metadata}) {
    debug(message, tag: 'PERFORMANCE', metadata: metadata);
  }

  void database(String message, {Map<String, dynamic>? metadata}) {
    info(message, tag: 'DATABASE', metadata: metadata);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    if (level < _minLevel) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    _addLog(entry);

    // Send to all handlers
    for (final handler in _handlers) {
      handler.handle(entry);
    }
  }

  void _addLog(LogEntry entry) {
    _logs.add(entry);
    
    // Keep only the last N logs to prevent memory issues
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  // Query methods
  List<LogEntry> getLogs({
    LogLevel? minLevel,
    String? tag,
    Duration? since,
    int? limit,
  }) {
    var logs = _logs.where((log) {
      if (minLevel != null && log.level < minLevel) return false;
      if (tag != null && log.tag != tag) return false;
      if (since != null) {
        final cutoff = DateTime.now().subtract(since);
        if (log.timestamp.isBefore(cutoff)) return false;
      }
      return true;
    }).toList();

    if (limit != null && logs.length > limit) {
      logs = logs.skip(logs.length - limit).toList();
    }

    return logs;
  }

  void clearLogs() => _logs.clear();

  // Export logs for debugging or analytics
  Map<String, dynamic> exportLogs({Duration? since}) {
    final logs = getLogs(since: since);
    return {
      'sessionId': _sessionId,
      'exportTime': DateTime.now().toIso8601String(),
      'logCount': logs.length,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
  }

  String exportLogsAsString({Duration? since}) {
    final logs = getLogs(since: since);
    return logs.map((log) => log.toString()).join('\n');
  }
}

// Log handlers for different outputs
abstract class LogHandler {
  void handle(LogEntry entry);
}

// Console output handler
class ConsoleLogHandler implements LogHandler {
  @override
  void handle(LogEntry entry) {
    if (kDebugMode) {
      // Use developer.log for better DevTools integration
      developer.log(
        entry.message,
        name: entry.tag ?? 'App',
        level: _getLevelValue(entry.level),
        error: entry.error,
        stackTrace: entry.stackTrace,
      );
    }
  }

  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}

// File output handler (for debugging)
class FileLogHandler implements LogHandler {
  late final String _fileName;
  
  FileLogHandler({String? fileName}) {
    _fileName = fileName ?? 'app_logs_${DateTime.now().millisecondsSinceEpoch}.txt';
  }

  @override
  void handle(LogEntry entry) {
    // Only write to file in debug mode and on supported platforms
    if (!kDebugMode || kIsWeb) return;

    try {
      // Note: This is a simplified implementation
      // In a real app, you'd want to use a proper logging library
      // or implement proper file handling with error management
      final logLine = '${entry}\n';
      // Implementation would depend on platform-specific file handling
    } catch (e) {
      // Silently fail if file writing isn't available
    }
  }
}

// Memory buffer handler (for crash reporting)
class MemoryLogHandler implements LogHandler {
  final List<LogEntry> _buffer = [];
  final int _maxSize;

  MemoryLogHandler({int maxSize = 100}) : _maxSize = maxSize;

  @override
  void handle(LogEntry entry) {
    _buffer.add(entry);
    if (_buffer.length > _maxSize) {
      _buffer.removeAt(0);
    }
  }

  List<LogEntry> getBuffer() => List.unmodifiable(_buffer);
  void clearBuffer() => _buffer.clear();
}

// Filter handler (only handles logs matching criteria)
class FilterLogHandler implements LogHandler {
  final LogHandler _innerHandler;
  final LogLevel? _minLevel;
  final List<String>? _allowedTags;
  final List<String>? _blockedTags;

  FilterLogHandler({
    required LogHandler innerHandler,
    LogLevel? minLevel,
    List<String>? allowedTags,
    List<String>? blockedTags,
  }) : _innerHandler = innerHandler,
       _minLevel = minLevel,
       _allowedTags = allowedTags,
       _blockedTags = blockedTags;

  @override
  void handle(LogEntry entry) {
    // Check minimum level
    if (_minLevel != null && entry.level < _minLevel!) {
      return;
    }

    // Check allowed tags
    if (_allowedTags != null && 
        (entry.tag == null || !_allowedTags!.contains(entry.tag))) {
      return;
    }

    // Check blocked tags
    if (_blockedTags != null && 
        entry.tag != null && 
        _blockedTags!.contains(entry.tag)) {
      return;
    }

    _innerHandler.handle(entry);
  }
}

// Batch handler (collects logs and sends in batches)
class BatchLogHandler implements LogHandler {
  final void Function(List<LogEntry>) _onBatch;
  final Duration _batchInterval;
  final int _batchSize;
  
  final List<LogEntry> _batch = [];
  Timer? _timer;

  BatchLogHandler({
    required void Function(List<LogEntry>) onBatch,
    Duration batchInterval = const Duration(seconds: 30),
    int batchSize = 10,
  }) : _onBatch = onBatch,
       _batchInterval = batchInterval,
       _batchSize = batchSize {
    _startTimer();
  }

  @override
  void handle(LogEntry entry) {
    _batch.add(entry);
    if (_batch.length >= _batchSize) {
      _sendBatch();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_batchInterval, (_) {
      if (_batch.isNotEmpty) {
        _sendBatch();
      }
    });
  }

  void _sendBatch() {
    if (_batch.isEmpty) return;
    
    final batchCopy = List<LogEntry>.from(_batch);
    _batch.clear();
    
    try {
      _onBatch(batchCopy);
    } catch (e) {
      // If batch sending fails, we could add them back to the batch
      // or handle the error appropriately
    }
  }

  void dispose() {
    _timer?.cancel();
    if (_batch.isNotEmpty) {
      _sendBatch();
    }
  }
}

// Convenient logger factory
class LoggerFactory {
  static Logger createDefault() {
    final logger = Logger.instance;
    
    // Add console handler for all environments
    logger.addHandler(ConsoleLogHandler());
    
    // Add memory handler for crash reporting
    logger.addHandler(MemoryLogHandler(maxSize: 50));
    
    // Set appropriate log level
    logger.setMinLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    
    // Generate a session ID
    logger.setSessionId('session_${DateTime.now().millisecondsSinceEpoch}');
    
    return logger;
  }

  static Logger createForProduction() {
    final logger = Logger.instance;
    
    // Only info and above in production
    logger.setMinLevel(LogLevel.info);
    
    // Filter out debug UI logs in production
    logger.addHandler(FilterLogHandler(
      innerHandler: ConsoleLogHandler(),
      minLevel: LogLevel.info,
      blockedTags: ['UI', 'PERFORMANCE'],
    ));
    
    // Memory handler for crash reports
    logger.addHandler(MemoryLogHandler(maxSize: 100));
    
    return logger;
  }
}