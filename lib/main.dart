import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';
import 'selectable_clock_widget.dart';
import 'services/auth_service.dart';
import 'services/routine_slot_service.dart';
import 'services/language_service.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'models/routine_slot_model.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widgets/template/template_gallery_dialog.dart';
import 'widgets/settings/settings_dialog.dart';
import 'widgets/dialogs/hamburger_menu_dialog.dart';
import 'widgets/common/error_boundary.dart';
import 'utils/error_handler.dart';
import 'utils/lazy_loader.dart';
import 'services/notification_service.dart';
import 'widgets/splash/image_splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Try to get user's timezone, fallback to device timezone
  try {
    final String timeZoneName = DateTime.now().timeZoneName;
    final locations = tz.timeZoneDatabase.locations;

    // Try to find a matching timezone
    tz.Location? userLocation;
    for (final location in locations.values) {
      if (location.name.contains(timeZoneName) ||
          location.zones.any((zone) => zone.abbreviation == timeZoneName)) {
        userLocation = location;
        break;
      }
    }

    // Set timezone (fallback to UTC if not found)
    tz.setLocalLocation(userLocation ?? tz.UTC);
  } catch (e) {
    // Fallback to UTC if anything goes wrong
    tz.setLocalLocation(tz.UTC);
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  await AdService.instance.initialize();
  await SubscriptionService.instance.initialize();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  bool isInitializing = true;
  bool showSplashScreen = true;
  final LanguageService languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  void _initializeLanguage() async {
    print('Initializing language...'); // Debug log
    await languageService.loadSavedLanguage();
    print(
      'Language loaded, current locale: ${languageService.locale}',
    ); // Debug log
    languageService.addListener(_onLanguageChanged);
    if (mounted) {
      setState(() {
        isInitializing = false;
      });
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        print(
          'Language changed, rebuilding app with locale: ${languageService.locale}',
        );
      });
    }
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('App rebuilding with locale: ${languageService.locale}'); // Debug log
    
    if (isInitializing) {
      return MaterialApp(
        title: 'Routine - 24-Hour Clock Selector',
        debugShowCheckedModeBanner: false,
        theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
        home: const Scaffold(
          body: LoadingWidget(
            message: 'Initializing app...',
            size: 48.0,
          ),
        ),
      );
    }
    
    return ErrorBoundary(
      child: MaterialApp(
        title: 'Routine - 24-Hour Clock Selector',
        debugShowCheckedModeBanner: false,
        theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
        locale: languageService.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: languageService.supportedLocales,
        home: showSplashScreen
            ? ImageSplashScreen(
                onSplashComplete: () {
                  setState(() {
                    showSplashScreen = false;
                  });
                },
                splashDuration: const Duration(milliseconds: 1500),
                backgroundColor: Colors.white,
              )
            : ErrorBoundary(
                errorMessage: 'Unable to load the main screen',
                onRetry: () {
                  setState(() {});
                },
                child: MyHomePage(
                  title: '24-Hour Clock Selector',
                  isDarkMode: isDarkMode,
                  onThemeToggle: toggleTheme,
                  languageService: languageService,
                ),
              ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFE9CD),
        secondary: Color(0xFFFFE9CD),
        surface: Color(0xFF2D2C46),
        onPrimary: Color(0xFF2D2C46),
        onSecondary: Color(0xFF2D2C46),
        onSurface: Color(0xFFFFE9CD),
      ),
      scaffoldBackgroundColor: const Color(0xFF2D2C46),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2C46),
        foregroundColor: Color(0xFFFFE9CD),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFFFE9CD)),
        bodyMedium: TextStyle(color: Color(0xFFFFE9CD)),
        titleLarge: TextStyle(color: Color(0xFFFFE9CD)),
        titleMedium: TextStyle(color: Color(0xFFFFE9CD)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2C46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFE9CD), width: 1),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF003F62),
        secondary: Color(0xFF003F62),
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF003F62),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF003F62),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF003F62)),
        bodyMedium: TextStyle(color: Color(0xFF003F62)),
        titleLarge: TextStyle(color: Color(0xFF003F62)),
        titleMedium: TextStyle(color: Color(0xFF003F62)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF003F62), width: 1),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.languageService,
  });

  final String title;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final LanguageService languageService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  StateMachineController? _stateMachineController;
  bool isProUser = false;
  late AnimationController _menuAnimationController;
  late AnimationController _settingsAnimationController;
  bool isLoggedIn = false;
  final AuthService _authService = AuthService();
  final RoutineSlotService _routineSlotService = RoutineSlotService();
  List<RoutineSlot> routineSlots = [];
  RoutineSlot? activeSlot;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addObserver(this);
    _checkAuthState();
    _loadRoutineSlots();
    _setupAuthStateListener();
  }

  void _setupAuthStateListener() {
    _authStateSubscription = _authService.authStateChanges.listen((User? user) {
      print(
        'Auth state changed - User: ${user?.email}, Current Pro status: $isProUser',
      );

      if (mounted) {
        setState(() {
          isLoggedIn = user != null;
          if (user == null) {
            isProUser = false;
            routineSlots = [];
            activeSlot = null;
            print('User logged out - Pro status reset to false');
          }
        });

        if (user != null) {
          // Reset Pro status first, then load fresh data after delay
          setState(() {
            isProUser = false;
          });
          print('User logged in - Pro status temporarily reset to false');

          // Add delay to ensure Firebase user data is available
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _loadUserData();
              _loadRoutineSlots();
            }
          });
        } else {
          _loadRoutineSlots();
        }
      }
    });
  }

  void _checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
      });
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final result = await ErrorHandler.safeAsyncCall<Map<String, dynamic>?>(
      operation: () => _authService.getUserData(),
      errorMessage: 'Failed to load user data',
      onError: (error) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Unable to load user data. Using default settings.');
        }
      },
    );
    
    final newProStatus = result?['isPro'] ?? false;
    print('Loading user data - Pro status: $newProStatus, UserData: $result');

    if (mounted) {
      setState(() {
        isProUser = newProStatus;
      });
    }

    print('Pro status updated to: $isProUser');
  }

  Future<void> _loadRoutineSlots() async {
    final result = await ErrorHandler.safeAsyncCall<List<RoutineSlot>>(
      operation: () => _routineSlotService.getRoutineSlots(),
      errorMessage: 'Failed to load routine slots',
      onError: (error) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Unable to load your routines. Please try again.');
        }
      },
    );
    
    if (result != null && mounted) {
      setState(() {
        routineSlots = result;
        activeSlot = _routineSlotService.getActiveSlot(result);
      });
      
      // Schedule notifications for the active routine on app start
      _scheduleNotificationsForActiveRoutine();
    }
  }

  Future<void> _saveRoutineSlots() async {
    await ErrorHandler.safeAsyncCall<void>(
      operation: () => _routineSlotService.saveRoutineSlots(routineSlots),
      errorMessage: 'Failed to save routine slots',
      onError: (error) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Unable to save your changes. Please try again.');
        }
      },
    );
  }

  void _onTimeSlotsChanged(List<RoutineTimeSlot> timeSlots) {
    if (activeSlot != null) {
      setState(() {
        routineSlots = _routineSlotService.updateTimeSlots(
          routineSlots,
          activeSlot!.id,
          timeSlots,
        );
        activeSlot = _routineSlotService.getActiveSlot(routineSlots);
      });
      _saveRoutineSlots();
      
      // Schedule notifications for the active routine only
      _scheduleNotificationsForActiveRoutine();
    }
  }

  // Schedule notifications for active routine only
  Future<void> _scheduleNotificationsForActiveRoutine() async {
    await NotificationService.instance.scheduleActiveRoutineNotifications(routineSlots);
  }

  // Debug method to run notification system verification
  Future<void> _runNotificationTests() async {
    print('🔧 DEBUG: Running notification system verification...');
    
    // Verify day-of-week calculations
    final dayCalculationCorrect = NotificationService.instance.verifyDayOfWeekCalculation();
    print('✅ Day-of-week calculations: ${dayCalculationCorrect ? 'PASSED' : 'FAILED'}');
    
    // Run all test scenarios
    final testResults = await NotificationService.instance.runAllTests();
    
    print('📊 Test Results Summary:');
    for (final result in testResults) {
      print('${result.passed ? '✅' : '❌'} ${result.scenario}: ${result.details}');
    }
    
    final passedCount = testResults.where((r) => r.passed).length;
    print('🎯 Overall: $passedCount/${testResults.length} tests passed');
    
    // Test current routine state
    print('📱 Current App State:');
    print('  - Total routines: ${routineSlots.length}');
    print('  - Active routine: ${activeSlot?.name ?? 'None'}');
    if (activeSlot != null) {
      print('  - Selected days: ${activeSlot!.selectedDays}');
      print('  - Time slots with alarms: ${activeSlot!.timeSlots.where((ts) => ts.hasAlarm).length}');
    }
  }

  void _initializeTriggerInputs(StateMachineController controller) {
    // Try to find triggers with many possible names
    final triggerNames = [
      'toLight',
      'light',
      'lightMode',
      'switchToLight',
      'goLight',
      'lightOn',
      'toDark',
      'dark',
      'darkMode',
      'switchToDark',
      'goDark',
      'darkOn',
      'toggle',
      'switch',
      'change',
      'flip',
      'press',
      'tap',
      'click',
    ];

    SMITrigger? lightTrigger;
    SMITrigger? darkTrigger;
    SMITrigger? generalTrigger;

    for (String name in triggerNames) {
      final trigger = controller.findSMI(name) as SMITrigger?;
      if (trigger != null) {
        debugPrint('🎯 Found trigger: "${trigger.name}"');

        // Categorize triggers by name
        if (name.toLowerCase().contains('light')) {
          lightTrigger = trigger;
        } else if (name.toLowerCase().contains('dark')) {
          darkTrigger = trigger;
        } else {
          generalTrigger = trigger; // toggle, switch, etc.
        }
      }
    }

    // Fire appropriate trigger to SHOW current theme state (not switch to it)
    if (widget.isDarkMode && darkTrigger != null) {
      darkTrigger.fire();
      debugPrint(
        '✅ Dark trigger "${darkTrigger.name}" fired (showing dark theme: moon/star)',
      );
    } else if (!widget.isDarkMode && lightTrigger != null) {
      lightTrigger.fire();
      debugPrint(
        '✅ Light trigger "${lightTrigger.name}" fired (showing light theme: sun/cloud)',
      );
    } else if (generalTrigger != null) {
      // Use general toggle trigger if specific ones aren't found
      generalTrigger.fire();
      debugPrint('✅ General trigger "${generalTrigger.name}" fired');
    } else {
      debugPrint(
        '❌ No suitable triggers found among: ${triggerNames.join(", ")}',
      );
    }
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation when theme changes from parent
    if (oldWidget.isDarkMode != widget.isDarkMode &&
        _stateMachineController != null) {
      _updateAnimationState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload routine slots when app becomes active again
      // This ensures data consistency if changes were made externally
      _loadRoutineSlots();
    }
  }

  void _updateAnimationState() {
    if (_stateMachineController == null) return;

    final boolInput =
        _stateMachineController!.findInput<bool>('isDark') ??
        _stateMachineController!.findInput<bool>('darkMode') ??
        _stateMachineController!.findInput<bool>('isLightMode');

    if (boolInput != null) {
      // Set the correct value based on input name
      if (boolInput.name.toLowerCase().contains('light')) {
        boolInput.value = !widget.isDarkMode; // Light mode when NOT dark
      } else {
        boolInput.value = widget.isDarkMode; // Dark mode when IS dark
      }
      debugPrint(
        'Navbar animation state updated - ${boolInput.name}: ${boolInput.value} (isDarkMode: ${widget.isDarkMode})',
      );
    } else {
      // Use trigger inputs to update state
      _initializeTriggerInputs(_stateMachineController!);
    }
  }

  void _showHamburgerMenu(BuildContext context) {
    LazyDialog.show(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: () => HamburgerMenuDialog(
        routineSlots: routineSlots,
        activeSlot: activeSlot,
        routineSlotService: _routineSlotService,
        onSlotsChanged: (slots, active) {
          setState(() {
            routineSlots = slots;
            activeSlot = active;
          });
          _saveRoutineSlots();
          
          // Reschedule notifications when routine slots change
          _scheduleNotificationsForActiveRoutine();
        },
        isProUser: isProUser,
      ),
      loadingWidget: const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingWidget(message: 'Loading menu...'),
        ),
      ),
    ).then((_) {
      // Reset hamburger menu animation when dialog closes
      _menuAnimationController.reverse();
    });
  }

  void _showSettings(BuildContext context) {
    LazyDialog.show(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: () => SettingsDialog(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        languageService: widget.languageService,
      ),
      loadingWidget: const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingWidget(message: 'Loading settings...'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight:
            65, // Reduced from 80 to 64 to give more space for circle
        leading: Container(
          margin: const EdgeInsets.only(left: 19.0),
          child: IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _menuAnimationController,
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () {
              if (_menuAnimationController.isCompleted) {
                _menuAnimationController.reverse();
              } else {
                _menuAnimationController.forward();
              }
              _showHamburgerMenu(context);
            },
          ),
        ),
        title: activeSlot != null
            ? Text(
                activeSlot!.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 19.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                _showSettings(context);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 0),
          Expanded(
            child: ErrorBoundary(
              errorMessage: 'Unable to load the clock widget',
              onRetry: () {
                _loadRoutineSlots();
              },
              child: SelectableClockWidget(
                isDarkMode: widget.isDarkMode,
                isProUser: isProUser,
                timeSlots: activeSlot?.timeSlots ?? [],
                onTimeSlotsChanged: _onTimeSlotsChanged,
                onShowTemplateGallery: _showTemplateGallery,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTemplateGallery() {
    LazyDialog.show(
      context: context,
      barrierColor: Colors.black54,
      builder: () => TemplateGalleryDialog(onTemplateImport: _importTemplate),
      loadingWidget: const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingWidget(message: 'Loading templates...'),
        ),
      ),
    );
  }

  void _importTemplate(
    String templateName,
    List<Map<String, dynamic>> templateTimeSlots,
  ) async {
    try {
      // Use the safer import method from the service
      final updatedSlots = await _routineSlotService.importTemplateAsNewSlot(
        currentSlots: routineSlots,
        templateName: templateName,
        templateTimeSlots: templateTimeSlots,
        isPaid: isProUser,
        setAsActive: true,
      );

      // Update state with the new slots
      setState(() {
        routineSlots = updatedSlots;
        activeSlot = _routineSlotService.getActiveSlot(updatedSlots);
      });

      // Schedule notifications for the newly active routine
      _scheduleNotificationsForActiveRoutine();

      // Show success message
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Template "$templateName" imported successfully!');
      }
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to import template: ${ErrorHandler.handleGenericError(error)}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuAnimationController.dispose();
    _settingsAnimationController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}



