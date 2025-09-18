import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

enum NotificationStatus {
  fullyEnabled,           // System granted + App enabled
  systemGrantedAppDisabled, // System granted + App disabled
  systemDenied,           // System denied (any reason)
  disabled,               // General disabled state
}

class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  static NotificationPermissionService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Check current notification permission status using multiple methods for accuracy
  Future<PermissionStatus> checkNotificationPermission() async {
    try {
      Logger.instance.info('🔍 === COMPREHENSIVE PERMISSION DEBUG ===');

      // FIRST: Try the most reliable method - flutter_local_notifications
      final directStatus = await _checkDirectNotificationStatus();
      Logger.instance.info('🎯 Direct notification check: $directStatus');

      // SECOND: Basic permission_handler check as fallback
      final basicStatus = await Permission.notification.status;
      Logger.instance.info('📱 Permission.notification.status: $basicStatus');

      // THIRD: Try checking if permission is permanently denied
      final isPermanentlyDenied = await Permission.notification.isPermanentlyDenied;
      Logger.instance.info('📱 Permission.notification.isPermanentlyDenied: $isPermanentlyDenied');

      // FOURTH: Platform-specific detailed checks
      PermissionStatus platformSpecificStatus;
      if (Platform.isIOS) {
        platformSpecificStatus = await _debugiOSNotificationPermission();
      } else if (Platform.isAndroid) {
        platformSpecificStatus = await _debugAndroidNotificationPermission();
      } else {
        platformSpecificStatus = basicStatus;
      }

      Logger.instance.info('🔍 Final comparison:');
      Logger.instance.info('  - Direct check: $directStatus');
      Logger.instance.info('  - Basic check: $basicStatus');
      Logger.instance.info('  - Platform check: $platformSpecificStatus');
      Logger.instance.info('  - Permanently denied: $isPermanentlyDenied');

      // PRIORITY ORDER: Direct > Platform > Basic
      // If the direct check (most reliable) shows granted, trust it
      if (directStatus == PermissionStatus.granted) {
        Logger.instance.info('✅ RESULT: GRANTED (via DIRECT check - most reliable)');
        return PermissionStatus.granted;
      }

      // If platform check shows granted, trust it
      if (platformSpecificStatus == PermissionStatus.granted) {
        Logger.instance.info('✅ RESULT: GRANTED (via PLATFORM check)');
        return PermissionStatus.granted;
      }

      // If basic check shows granted, trust it
      if (basicStatus == PermissionStatus.granted) {
        Logger.instance.info('✅ RESULT: GRANTED (via BASIC check)');
        return PermissionStatus.granted;
      }

      // If none show granted, use the most detailed result
      Logger.instance.info('❌ RESULT: NOT GRANTED - using direct result: $directStatus');
      return directStatus;
    } catch (error) {
      Logger.instance.error('❌ Failed to check notification permission: $error');
      return PermissionStatus.denied;
    }
  }

  /// Most reliable direct check using flutter_local_notifications
  Future<PermissionStatus> _checkDirectNotificationStatus() async {
    try {
      Logger.instance.info('🎯 === DIRECT NOTIFICATION CHECK ===');

      if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          final settings = await iosImplementation.checkPermissions();
          Logger.instance.info('🎯 iOS direct check - isEnabled: ${settings?.isEnabled}');

          if (settings?.isEnabled == true) {
            return PermissionStatus.granted;
          }
        }
      } else if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          final areEnabled = await androidImplementation.areNotificationsEnabled();
          Logger.instance.info('🎯 Android direct check - areEnabled: $areEnabled');

          if (areEnabled == true) {
            return PermissionStatus.granted;
          }
        }
      }

      Logger.instance.info('🎯 Direct check result: DENIED/UNKNOWN');
      return PermissionStatus.denied;
    } catch (error) {
      Logger.instance.error('🎯 Direct check failed: $error');
      return PermissionStatus.denied;
    }
  }

  /// Comprehensive iOS notification permission debugging
  Future<PermissionStatus> _debugiOSNotificationPermission() async {
    try {
      Logger.instance.info('🍎 === iOS NOTIFICATION DEBUG ===');

      // 1. Check with permission_handler
      final permissionHandlerStatus = await Permission.notification.status;
      Logger.instance.info('🍎 permission_handler status: $permissionHandlerStatus');

      // 2. Check with flutter_local_notifications
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        try {
          // Check current notification settings
          final settings = await iosImplementation.checkPermissions();
          Logger.instance.info('🍎 flutter_local_notifications settings: $settings');
          Logger.instance.info('🍎 settings.isEnabled: ${settings?.isEnabled}');

          // Try to get more detailed information
          Logger.instance.info('🍎 Attempting to get detailed iOS settings...');

          if (settings != null) {
            Logger.instance.info('🍎 Settings breakdown:');
            Logger.instance.info('  - isEnabled: ${settings.isEnabled}');
            // Note: The exact properties depend on the version of flutter_local_notifications
          }

          // If flutter_local_notifications says enabled, trust it
          if (settings?.isEnabled == true) {
            Logger.instance.info('🍎 ✅ iOS flutter_local_notifications confirms ENABLED');
            return PermissionStatus.granted;
          } else {
            Logger.instance.info('🍎 ❌ iOS flutter_local_notifications says NOT enabled');
          }
        } catch (e) {
          Logger.instance.error('🍎 ❌ iOS flutter_local_notifications check failed: $e');
        }
      } else {
        Logger.instance.warning('🍎 ⚠️ iOS implementation not available');
      }

      Logger.instance.info('🍎 Falling back to permission_handler result: $permissionHandlerStatus');
      return permissionHandlerStatus;
    } catch (error) {
      Logger.instance.error('🍎 ❌ iOS debug check failed: $error');
      return PermissionStatus.denied;
    }
  }

  /// Comprehensive Android notification permission debugging
  Future<PermissionStatus> _debugAndroidNotificationPermission() async {
    try {
      Logger.instance.info('🤖 === ANDROID NOTIFICATION DEBUG ===');

      // 1. Check with permission_handler
      final permissionHandlerStatus = await Permission.notification.status;
      Logger.instance.info('🤖 permission_handler status: $permissionHandlerStatus');

      // 2. Check with flutter_local_notifications
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          // Check if notifications are enabled
          final bool? areEnabled = await androidImplementation.areNotificationsEnabled();
          Logger.instance.info('🤖 flutter_local_notifications areNotificationsEnabled: $areEnabled');

          // If flutter_local_notifications says enabled, trust it
          if (areEnabled == true) {
            Logger.instance.info('🤖 ✅ Android flutter_local_notifications confirms ENABLED');
            return PermissionStatus.granted;
          } else {
            Logger.instance.info('🤖 ❌ Android flutter_local_notifications says NOT enabled');
          }
        } catch (e) {
          Logger.instance.error('🤖 ❌ Android flutter_local_notifications check failed: $e');
        }
      } else {
        Logger.instance.warning('🤖 ⚠️ Android implementation not available');
      }

      Logger.instance.info('🤖 Falling back to permission_handler result: $permissionHandlerStatus');
      return permissionHandlerStatus;
    } catch (error) {
      Logger.instance.error('🤖 ❌ Android debug check failed: $error');
      return PermissionStatus.denied;
    }
  }

  /// Check iOS notification permissions using multiple methods
  Future<PermissionStatus> _checkiOSNotificationPermission() async {
    try {
      // First try permission_handler which is more reliable for checking status
      final permissionStatus = await Permission.notification.status;
      Logger.instance.info('🍎 iOS permission_handler status: $permissionStatus');

      // If permission_handler says granted, double-check with flutter_local_notifications
      if (permissionStatus == PermissionStatus.granted) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          // Check current settings without requesting
          try {
            final permissions = await iosImplementation.checkPermissions();
            Logger.instance.info('🍎 iOS flutter_local_notifications check: $permissions');

            // Check if notifications are enabled (any permission granted)
            final isEnabled = permissions?.isEnabled == true;

            if (isEnabled) {
              return PermissionStatus.granted;
            } else {
              // Permissions might have been revoked in settings
              return PermissionStatus.denied;
            }
          } catch (e) {
            Logger.instance.warning('⚠️ iOS checkPermissions failed, using permission_handler result: $e');
            return permissionStatus;
          }
        }
      }

      return permissionStatus;
    } catch (error) {
      Logger.instance.error('❌ iOS permission check failed: $error');
      return PermissionStatus.denied;
    }
  }

  /// Check Android notification permissions using flutter_local_notifications
  Future<PermissionStatus> _checkAndroidNotificationPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.areNotificationsEnabled();
        Logger.instance.info('🤖 Android notifications enabled: $granted');

        if (granted == true) {
          return PermissionStatus.granted;
        } else {
          // Check more detailed status with permission_handler
          final permissionStatus = await Permission.notification.status;
          Logger.instance.info('🤖 Android permission_handler status: $permissionStatus');
          return permissionStatus;
        }
      } else {
        Logger.instance.warning('⚠️ Android implementation not available, using fallback');
        return await Permission.notification.status;
      }
    } catch (error) {
      Logger.instance.error('❌ Android permission check failed: $error');
      return await Permission.notification.status;
    }
  }

  /// Request notification permission with platform-specific handling
  Future<PermissionStatus> requestNotificationPermission() async {
    try {
      Logger.instance.info('📝 Requesting notification permissions...');

      if (Platform.isIOS) {
        return await _requestiOSNotificationPermission();
      } else if (Platform.isAndroid) {
        return await _requestAndroidNotificationPermission();
      } else {
        final status = await Permission.notification.request();
        Logger.instance.info('📱 Fallback permission request result: $status');
        return status;
      }
    } catch (error) {
      Logger.instance.error('❌ Failed to request notification permission: $error');
      return PermissionStatus.denied;
    }
  }

  /// Request iOS notification permissions
  Future<PermissionStatus> _requestiOSNotificationPermission() async {
    try {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );

        Logger.instance.info('🍎 iOS permission request result: $granted');

        if (granted == true) {
          return PermissionStatus.granted;
        } else {
          return PermissionStatus.denied;
        }
      } else {
        return await Permission.notification.request();
      }
    } catch (error) {
      Logger.instance.error('❌ iOS permission request failed: $error');
      return PermissionStatus.denied;
    }
  }

  /// Request Android notification permissions
  Future<PermissionStatus> _requestAndroidNotificationPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        Logger.instance.info('🤖 Android permission request result: $granted');

        if (granted == true) {
          return PermissionStatus.granted;
        } else {
          return PermissionStatus.denied;
        }
      } else {
        return await Permission.notification.request();
      }
    } catch (error) {
      Logger.instance.error('❌ Android permission request failed: $error');
      return await Permission.notification.request();
    }
  }

  /// Check if notifications are enabled (system permission + app setting)
  Future<bool> areNotificationsEnabled() async {
    final systemStatus = await checkNotificationPermission();
    final appSetting = NotificationService.instance.notificationsEnabled;
    final enabled = systemStatus == PermissionStatus.granted && appSetting;
    Logger.instance.info('🔔 Notifications enabled: $enabled (system: $systemStatus, app: $appSetting)');
    return enabled;
  }

  /// Get effective notification status (combines system permission and app setting)
  Future<NotificationStatus> getEffectiveNotificationStatus() async {
    final systemStatus = await checkNotificationPermission();
    final appSetting = NotificationService.instance.notificationsEnabled;

    Logger.instance.info('📊 System permission: $systemStatus, App setting: $appSetting');

    if (systemStatus == PermissionStatus.granted && appSetting) {
      return NotificationStatus.fullyEnabled;
    } else if (systemStatus == PermissionStatus.granted && !appSetting) {
      return NotificationStatus.systemGrantedAppDisabled;
    } else if (systemStatus != PermissionStatus.granted) {
      return NotificationStatus.systemDenied;
    } else {
      return NotificationStatus.disabled;
    }
  }

  /// Toggle app-level notification setting
  Future<void> toggleAppNotificationSetting() async {
    final currentSetting = NotificationService.instance.notificationsEnabled;
    await NotificationService.instance.setNotificationsEnabled(!currentSetting);
    Logger.instance.info('🔄 Toggled app notification setting: ${!currentSetting}');
  }

  /// Simple test method to debug permission detection
  Future<void> debugPermissionDetection() async {
    Logger.instance.info('🔧 === MANUAL PERMISSION DEBUG TEST ===');
    final result = await checkNotificationPermission();
    Logger.instance.info('🔧 Final permission result: $result');
    Logger.instance.info('🔧 App setting: ${NotificationService.instance.notificationsEnabled}');
    Logger.instance.info('🔧 Combined status: ${await getEffectiveNotificationStatus()}');
    Logger.instance.info('🔧 === END DEBUG TEST ===');
  }

  /// Open app settings for notification permissions
  Future<bool> openNotificationSettings() async {
    try {
      Logger.instance.info('Opening app notification settings...');
      final opened = await openAppSettings();
      Logger.instance.info('App settings opened: $opened');
      return opened;
    } catch (error) {
      Logger.instance.error('Failed to open app settings: $error');
      return false;
    }
  }

  /// Get user-friendly permission status text
  String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Enabled';
      case PermissionStatus.denied:
        return 'Disabled';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  /// Get icon for permission status
  String getPermissionStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅';
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return '❌';
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        return '⚠️';
      case PermissionStatus.provisional:
        return '🔔';
    }
  }

  /// Check if we should show the request permission button
  bool shouldShowRequestButton(PermissionStatus status) {
    return status != PermissionStatus.granted;
  }

  /// Check if we should direct user to settings instead of requesting
  bool shouldOpenSettings(PermissionStatus status) {
    return status == PermissionStatus.permanentlyDenied;
  }
}