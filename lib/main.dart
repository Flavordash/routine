import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:rive/rive.dart';
import 'selectable_clock_widget.dart';
import 'services/auth_service.dart';
import 'services/routine_slot_service.dart';
import 'services/language_service.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'models/user_model.dart';
import 'models/routine_slot_model.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
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
  
  // Initialize monetization services
  await AdService.instance.initialize();
  await SubscriptionService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
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
      setState(() {});
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
    return MaterialApp(
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
      home: MyHomePage(
        title: '24-Hour Clock Selector',
        isDarkMode: isDarkMode,
        onThemeToggle: toggleTheme,
        languageService: languageService,
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
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
      print('Auth state changed - User: ${user?.email}, Current Pro status: $isProUser');
      
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
    final userData = await _authService.getUserData();
    final newProStatus = userData?['isPro'] ?? false;
    print('Loading user data - Pro status: $newProStatus, UserData: $userData');
    
    setState(() {
      // Always update isProUser, defaulting to false for new users or null data
      isProUser = newProStatus;
    });
    
    print('Pro status updated to: $isProUser');
  }

  Future<void> _loadRoutineSlots() async {
    try {
      final slots = await _routineSlotService.getRoutineSlots();
      setState(() {
        routineSlots = slots;
        activeSlot = _routineSlotService.getActiveSlot(slots);
      });
    } catch (error) {
      print('Error loading routine slots: $error');
    }
  }

  Future<void> _saveRoutineSlots() async {
    try {
      await _routineSlotService.saveRoutineSlots(routineSlots);
    } catch (error) {
      print('Error saving routine slots: $error');
    }
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return HamburgerMenuDialog(
          routineSlots: routineSlots,
          activeSlot: activeSlot,
          routineSlotService: _routineSlotService,
          onSlotsChanged: (slots, active) {
            setState(() {
              routineSlots = slots;
              activeSlot = active;
            });
            _saveRoutineSlots();
          },
          isProUser: isProUser,
        );
      },
    ).then((_) {
      // Reset hamburger menu animation when dialog closes
      _menuAnimationController.reverse();
    });
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SettingsDialog(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
          languageService: widget.languageService,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 64, // Reduced from 80 to 64 to give more space for circle
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
          const SizedBox(height: 10),
          Expanded(
            child: SelectableClockWidget(
              isDarkMode: widget.isDarkMode,
              isProUser: isProUser,
              timeSlots: activeSlot?.timeSlots ?? [],
              onTimeSlotsChanged: _onTimeSlotsChanged,
              onShowTemplateGallery: _showTemplateGallery,
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  void _showTemplateGallery() {
    showDialog(
      context: context,
      builder: (context) => _TemplateGalleryDialog(
        onTemplateImport: _importTemplate,
      ),
    );
  }

  void _importTemplate(String templateName, List<Map<String, dynamic>> templateTimeSlots) {
    // Create new routine slot with template name and time slots
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      timeSlots: templateTimeSlots.map((slot) => RoutineTimeSlot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: slot['label'],
        description: slot['description'],
        startTime: slot['startTime'],
        endTime: slot['endTime'],
        color: slot['color'],
        hasAlarm: false,
        snoozeDuration: 10,
        maxSnoozeCount: 3,
        snoozeEnabled: true,
        hasPreAlarm: false,
        preAlarmMinutes: 15,
        startAngle: slot['startAngle'],
        endAngle: slot['endAngle'],
        createdAt: DateTime.now(),
      )).toList(),
      selectedDays: [1, 2, 3, 4, 5, 6, 7], // All days by default
      createdAt: DateTime.now(),
      isActive: false, // Make it inactive initially
      isPaid: isProUser,
    );

    // Add to routine slots
    setState(() {
      routineSlots.add(newSlot);
    });

    // Save to storage
    _routineSlotService.saveRoutineSlots(routineSlots);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "$templateName" imported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
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

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog>
    with TickerProviderStateMixin {
  int currentSlide = 0;
  final int totalSlides = 5;
  late AnimationController _closeAnimationController;

  List<TutorialSlide> get slides => [
    TutorialSlide(
      title: AppLocalizations.of(context)!.welcomeToRoutine,
      content: AppLocalizations.of(context)!.planYourDay,
      imagePath: 'assets/animations/Logo.png',
    ),
    TutorialSlide(
      title: AppLocalizations.of(context)!.creatingTimeSlots,
      content: AppLocalizations.of(context)!.creatingTimeSlotsDesc,
      videoPath: 'assets/Slides/Slide2.mp4',
    ),
    TutorialSlide(
      title: AppLocalizations.of(context)!.managingYourSchedule,
      content: AppLocalizations.of(context)!.managingYourScheduleDesc,
      videoPath: 'assets/Slides/Slide3.mp4',
    ),
    TutorialSlide(
      title: AppLocalizations.of(context)!.settingsCustomization,
      content: AppLocalizations.of(context)!.settingsCustomizationDesc,
      videoPath: 'assets/Slides/Slide4.mp4',
    ),
    TutorialSlide(
      title: AppLocalizations.of(context)!.proSubscriptionBenefits,
      content: AppLocalizations.of(context)!.proSubscriptionBenefitsDesc,
      videoPath: 'assets/Slides/Slide5.mp4',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _closeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _closeAnimationController.dispose();
    super.dispose();
  }

  void nextSlide() {
    if (currentSlide < totalSlides - 1) {
      setState(() {
        currentSlide++;
      });
    }
  }

  void previousSlide() {
    if (currentSlide > 0) {
      setState(() {
        currentSlide--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlideData = slides[currentSlide];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tutorial',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Slide indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlides, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentSlide
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Slide content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 350,
                        maxHeight: 300,
                        minHeight: 250,
                      ),
                      child: SlideMediaWidget(slideData: currentSlideData),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    currentSlideData.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentSlideData.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: currentSlide > 0 ? previousSlide : null,
                  child: Text(AppLocalizations.of(context)!.previous),
                ),
                Text(
                  '${currentSlide + 1} / $totalSlides',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: currentSlide < totalSlides - 1 ? nextSlide : null,
                  child: Text(
                    currentSlide < totalSlides - 1
                        ? AppLocalizations.of(context)!.next
                        : '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Done button
            if (currentSlide == totalSlides - 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.getStarted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TutorialSlide {
  final String title;
  final String content;
  final IconData? icon;
  final String? imagePath;
  final String? videoPath;

  TutorialSlide({
    required this.title,
    required this.content,
    this.icon,
    this.imagePath,
    this.videoPath,
  });
}

class SlideMediaWidget extends StatefulWidget {
  final TutorialSlide slideData;

  const SlideMediaWidget({super.key, required this.slideData});

  @override
  State<SlideMediaWidget> createState() => _SlideMediaWidgetState();
}

class _SlideMediaWidgetState extends State<SlideMediaWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(SlideMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideData != widget.slideData) {
      _disposeVideo();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (widget.slideData.videoPath != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        widget.slideData.videoPath!,
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _hasVideoError = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If video is available and initialized, show video
    if (widget.slideData.videoPath != null &&
        _isVideoInitialized &&
        _videoController != null) {
      return Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        ),
      );
    }

    // If video failed and we have a fallback image, show image
    if ((_hasVideoError || widget.slideData.videoPath == null) &&
        widget.slideData.imagePath != null) {
      return Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widgets.Image.asset(
              widget.slideData.imagePath!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildIconFallback();
              },
            ),
          ),
        ),
      );
    }

    // If no video or image, show icon or placeholder
    return _buildIconFallback();
  }

  Widget _buildIconFallback() {
    if (widget.slideData.icon != null) {
      return Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Icon(
              widget.slideData.icon!,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: Text('Media not found', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}

class HamburgerMenuDialog extends StatefulWidget {
  const HamburgerMenuDialog({
    super.key,
    required this.routineSlots,
    required this.activeSlot,
    required this.routineSlotService,
    required this.onSlotsChanged,
    required this.isProUser,
  });

  final List<RoutineSlot> routineSlots;
  final RoutineSlot? activeSlot;
  final RoutineSlotService routineSlotService;
  final Function(List<RoutineSlot>, RoutineSlot?) onSlotsChanged;
  final bool isProUser;

  @override
  State<HamburgerMenuDialog> createState() => _HamburgerMenuDialogState();
}

class _HamburgerMenuDialogState extends State<HamburgerMenuDialog>
    with TickerProviderStateMixin {
  late List<RoutineSlot> routineSlots;
  late RoutineSlot? activeSlot;
  bool isLoggedIn = false;
  String userEmail = '';
  final AuthService _authService = AuthService();
  late AnimationController _editAnimationController;
  late AnimationController _addAnimationController;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    routineSlots = List.from(widget.routineSlots);
    activeSlot = widget.activeSlot;
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        userEmail = user.email ?? '';
      });
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    if (userData != null) {
      setState(() {
        // isProUser comes from parent widget
      });
    }
  }

  Future<void> _updateAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        userEmail = user.email ?? '';
      });
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.routineSlots,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Authentication Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: isLoggedIn ? _buildUserProfile() : _buildLoginPrompt(),
            ),
            const SizedBox(height: 16),

            // Pro status indicator
            if (!widget.isProUser)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.freeUsersOneSlot,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Routine slots list
            Expanded(
              child: ListView.builder(
                itemCount: routineSlots.length,
                itemBuilder: (context, index) {
                  final slot = routineSlots[index];
                  return _buildRoutineSlotCard(slot);
                },
              ),
            ),

            // Browse Templates Button
            const SizedBox(height: 16),
            if (widget.isProUser)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showTemplateGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 18),
                      const SizedBox(width: 8),
                      Text('Browse Templates'),
                    ],
                  ),
                ),
              ),

            // Add new slot button
            if (widget.isProUser) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.isProUser || routineSlots.length < 2)
                    ? () {
                        _addAnimationController.forward().then((_) {
                          _addAnimationController.reverse();
                        });
                        _addNewSlot();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedIcon(
                      icon: AnimatedIcons.add_event,
                      progress: _addAnimationController,
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.addNewRoutineSlot),
                  ],
                ),
              ),
            ),

            if (!widget.isProUser && routineSlots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    // Show upgrade dialog
                    _showUpgradeDialog();
                  },
                  child: Text(AppLocalizations.of(context)!.upgradeToProUnlimited),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSlotCard(RoutineSlot slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: slot.isActive
          ? (Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1))
          : null,
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _showColorSettingsDialog(slot),
          child: CircleAvatar(
            backgroundColor: slot.color != null 
                ? Color(slot.color!)
                : (slot.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
            radius: 12,
            child: slot.isActive
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          slot.name == 'Default Routine'
              ? AppLocalizations.of(context)!.defaultRoutine
              : slot.name,
          style: TextStyle(
            fontWeight: slot.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.isActive
                  ? AppLocalizations.of(context)!.currentlyActive
                  : AppLocalizations.of(context)!.tapToActivate,
              style: TextStyle(
                color: slot.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            if (widget.isProUser && slot.selectedDays.length < 7)
              Text(
                _getDaysText(slot.selectedDays),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isPaid)
              const Icon(Icons.star, color: Colors.orange, size: 16),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _renameSlot(slot);
                    break;
                  case 'duplicate':
                    _duplicateSlot(slot);
                    break;
                  case 'delete':
                    _deleteSlot(slot);
                    break;
                  case 'daySettings':
                    _showDaySettingsDialog(slot);
                    break;
                  case 'colorSettings':
                    _showColorSettingsDialog(slot);
                    break;
                  case 'shareTemplate':
                    _showShareTemplateDialog(slot);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit, size: 16),
                    title: Text('Rename'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'colorSettings',
                  child: ListTile(
                    leading: Icon(Icons.palette, size: 16),
                    title: Text('Color Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (widget.isProUser) ...[
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy, size: 16),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'daySettings',
                    child: ListTile(
                      leading: Icon(Icons.date_range, size: 16),
                      title: Text('Day Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'shareTemplate',
                    child: ListTile(
                      leading: Icon(Icons.share, size: 16),
                      title: Text('Share as Template'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (routineSlots.length > 1)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, size: 16, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!slot.isActive) {
            _activateSlot(slot);
          }
        },
      ),
    );
  }

  void _addNewSlot() {
    if (!widget.isProUser && routineSlots.isNotEmpty) {
      _showUpgradeDialog();
      return;
    }

    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Routine ${routineSlots.length + 1}',
      isActive: false,
      isPaid: !widget.isProUser ? false : true,
    );

    setState(() {
      routineSlots.add(newSlot);
    });
  }

  void _activateSlot(RoutineSlot slot) {
    setState(() {
      routineSlots = widget.routineSlotService.activateSlot(
        routineSlots,
        slot.id,
      );
      activeSlot = widget.routineSlotService.getActiveSlot(routineSlots);
    });

    widget.onSlotsChanged(routineSlots, activeSlot);
    Navigator.of(context).pop();
  }

  void _renameSlot(RoutineSlot slot) {
    final controller = TextEditingController(text: slot.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Routine'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Routine Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final index = routineSlots.indexOf(slot);
                setState(() {
                  routineSlots[index] = RoutineSlot(
                    id: slot.id,
                    name: controller.text.trim(),
                    isActive: slot.isActive,
                    isPaid: slot.isPaid,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _duplicateSlot(RoutineSlot slot) {
    if (!widget.isProUser) {
      _showUpgradeDialog();
      return;
    }

    final duplicatedSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${slot.name} (Copy)',
      isActive: false,
      isPaid: slot.isPaid,
      color: slot.color,
      selectedDays: List.from(slot.selectedDays),
    );

    setState(() {
      routineSlots.add(duplicatedSlot);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.duplicate} "${slot.name}" successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteSlot(RoutineSlot slot) {
    if (routineSlots.length <= 1) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${slot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                routineSlots.remove(slot);

                // If the deleted slot was active, activate the first remaining slot
                if (slot.isActive && routineSlots.isNotEmpty) {
                  routineSlots[0] = RoutineSlot(
                    id: routineSlots[0].id,
                    name: routineSlots[0].name,
                    isActive: true,
                    isPaid: routineSlots[0].isPaid,
                  );
                }
              });
              
              // Save the updated routine slots to persistent storage
              await widget.routineSlotService.saveRoutineSlots(routineSlots);
              
              // Notify the parent component about the changes
              widget.onSlotsChanged(routineSlots, activeSlot);
              
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getDaysText(List<int> selectedDays) {
    if (selectedDays.length == 7) return 'Every day';
    if (selectedDays.isEmpty) return 'No days selected';

    final dayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedAbbreviations = selectedDays
        .map((dayIndex) => dayAbbreviations[dayIndex - 1])
        .toList();
    
    return selectedAbbreviations.join(', ');
  }

  void _showDaySettingsDialog(RoutineSlot slot) {
    List<int> selectedDays = List.from(slot.selectedDays);
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Day Settings for ${slot.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select which days this routine should be active:'),
                const SizedBox(height: 16),
                ...dayNames.asMap().entries.map((entry) {
                  final dayIndex = entry.key + 1; // 1-7 for Monday-Sunday
                  final dayName = entry.value;
                  final isSelected = selectedDays.contains(dayIndex);

                  return CheckboxListTile(
                    title: Text(dayName),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (!selectedDays.contains(dayIndex)) {
                            selectedDays.add(dayIndex);
                            selectedDays.sort();
                          }
                        } else {
                          selectedDays.remove(dayIndex);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final index = routineSlots.indexWhere((s) => s.id == slot.id);
                    if (index != -1) {
                      routineSlots[index] = slot.copyWith(selectedDays: selectedDays);
                    }
                  });
                  widget.onSlotsChanged(routineSlots, activeSlot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Day settings updated for ${slot.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorSettingsDialog(RoutineSlot slot) {
    final colors = [
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFF44336, // Red
      0xFF9C27B0, // Purple
      0xFFFF9800, // Orange
      0xFF009688, // Teal
      0xFFE91E63, // Pink
      0xFF3F51B5, // Indigo
      0xFFFFC107, // Amber
      0xFFFF5722, // Deep Orange
      0xFF03A9F4, // Light Blue
      0xFFCDDC39, // Lime
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Color for ${slot.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length + 1, // +1 for default option
            itemBuilder: (context, index) {
              if (index == 0) {
                // Default color option
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final slotIndex = routineSlots.indexWhere((s) => s.id == slot.id);
                      if (slotIndex != -1) {
                        routineSlots[slotIndex] = slot.copyWith(color: null);
                      }
                    });
                    widget.onSlotsChanged(routineSlots, activeSlot);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Color reset to default for ${slot.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                      color: Colors.transparent,
                    ),
                    child: const Center(
                      child: Text(
                        'Default',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              final colorValue = colors[index - 1];
              final color = Color(colorValue);
              final isSelected = slot.color == colorValue;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    final slotIndex = routineSlots.indexWhere((s) => s.id == slot.id);
                    if (slotIndex != -1) {
                      routineSlots[slotIndex] = slot.copyWith(color: colorValue);
                    }
                  });
                  widget.onSlotsChanged(routineSlots, activeSlot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Color updated for ${slot.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: isSelected 
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 20),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showShareTemplateDialog(RoutineSlot slot) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Student';
    String selectedLifestyle = 'Flexible';

    final categories = ['Student', 'Office Worker', 'Night Shift', 'Healthcare', 'Fitness', 'Freelancer', 'Parent', 'Senior', 'Other'];
    final lifestyles = ['Morning Person', 'Night Owl', 'Flexible'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share as Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Template Name *', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter template name...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe this routine...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('Lifestyle Type', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedLifestyle,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: lifestyles.map((lifestyle) {
                    return DropdownMenuItem(
                      value: lifestyle,
                      child: Text(lifestyle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedLifestyle = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a template name')),
                  );
                  return;
                }
                
                // Convert routine slot time slots to template format
                final templateTimeSlots = slot.timeSlots.map((timeSlot) => {
                  'startTime': timeSlot.startTime,
                  'endTime': timeSlot.endTime,
                  'label': timeSlot.label,
                  'description': timeSlot.description,
                  'color': timeSlot.color,
                }).toList();

                // TODO: Save template to community template system
                // For now, show success message
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template "${titleController.text}" shared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.upgradeToProButton),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.proFeatures),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.unlimitedSlots),
            Text('• Schedule routines for specific days (Mon-Sun)'),
            Text(AppLocalizations.of(context)!.duplicateRoutines),
            Text('• Advanced notifications with vibration'),
            Text(AppLocalizations.of(context)!.prioritySupport),
            Text(AppLocalizations.of(context)!.advancedCustomization),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.later),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionDialog();
            },
            child: Text(AppLocalizations.of(context)!.upgradeNow),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 20,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail.isNotEmpty ? userEmail : 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isProUser ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isProUser
                          ? AppLocalizations.of(context)!.proMember
                          : AppLocalizations.of(context)!.freeUser,
                      style: TextStyle(
                        color: widget.isProUser ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'upgrade':
                    if (!widget.isProUser) _showUpgradeDialog();
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!widget.isProUser)
                  PopupMenuItem(
                    value: 'upgrade',
                    child: ListTile(
                      leading: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.upgradeToProButton,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout, size: 16),
                    title: Text(AppLocalizations.of(context)!.logout),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.isProUser) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.thanksForSupporting,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.signInToSync,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showSignInDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.signIn,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _showSignUpDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.signUp,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSignInDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.signIn),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });
                          try {
                            await _authService.signInWithGoogle();
                            await _updateAuthState();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed in with Google!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign in failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.continueWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.or,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        await _authService.signInWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text,
                        );

                        await _updateAuthState();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully signed in!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign in failed: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
              child: Text(AppLocalizations.of(context)!.signInWithEmail),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignUpDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.signUp),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });
                          try {
                            await _authService.signInWithGoogle();
                            await _updateAuthState();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed up with Google!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign up failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.continueWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.or,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPassword,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        await _authService.registerWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text,
                        );

                        await _updateAuthState();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Registration failed: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(AppLocalizations.of(context)!.signUpWithEmail),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    try {
      await _authService.signOut();
      setState(() {
        isLoggedIn = false;
        userEmail = '';
        // isProUser managed by parent
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed out')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.upgradeToProButton,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get unlimited access and remove ads!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pro Features List
                _buildProFeature(context, Icons.block, 'Remove all advertisements'),
                _buildProFeature(context, Icons.all_inclusive, AppLocalizations.of(context)!.unlimitedSlots.substring(2)), // Remove the bullet point
                _buildProFeature(context, Icons.calendar_today, 'Schedule routines for specific days'),
                _buildProFeature(context, Icons.notifications_active, 'Advanced notifications with vibration'),
                _buildProFeature(context, Icons.backup, 'Cloud sync backup'),
                _buildProFeature(context, Icons.support, AppLocalizations.of(context)!.prioritySupport.substring(2)), // Remove the bullet point
                
                const SizedBox(height: 20),
                
                // Subscription Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Choose Your Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Monthly Plan
                      _buildSubscriptionOption(
                        context,
                        title: 'Monthly Plan',
                        price: '\$4.99/month',
                        savings: null,
                        isPopular: false,
                        onTap: () => _purchaseSubscription(monthly: true),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Yearly Plan  
                      _buildSubscriptionOption(
                        context,
                        title: 'Yearly Plan',
                        price: '\$6.99/year',
                        savings: 'Save 88%!',
                        isPopular: true,
                        onTap: () => _purchaseSubscription(monthly: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.later,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restorePurchases();
              },
              child: Text(
                'Restore',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProFeature(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
    BuildContext context, {
    required String title,
    required String price,
    String? savings,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPopular 
            ? Colors.amber.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPopular ? Colors.amber : Colors.grey,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  if (savings != null)
                    Text(
                      savings,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseSubscription({required bool monthly}) {
    Navigator.of(context).pop();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing purchase...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    // Attempt purchase
    SubscriptionService.instance.purchaseSubscription(yearly: !monthly).then((_) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Pro! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _restorePurchases() {
    Navigator.of(context).pop();
    
    SubscriptionService.instance.restorePurchases().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showTemplateGallery() {
    showDialog(
      context: context,
      builder: (context) => _TemplateGalleryDialog(
        onTemplateImport: _importTemplate,
      ),
    );
  }

  void _importTemplate(String templateName, List<Map<String, dynamic>> templateTimeSlots) {
    // Create new routine slot with template name and time slots
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      isActive: false,
      isPaid: true, // Templates are a PRO feature
      timeSlots: templateTimeSlots.map((slotData) {
        return RoutineTimeSlot(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startAngle: slotData['startAngle'] ?? 0.0,
          endAngle: slotData['endAngle'] ?? 0.0,
          startTime: slotData['startTime'] ?? '09:00',
          endTime: slotData['endTime'] ?? '10:00',
          label: slotData['label'] ?? 'Activity',
          description: slotData['description'] ?? '',
          color: slotData['color'] ?? 0xFF2196F3,
          createdAt: DateTime.now(),
        );
      }).toList(),
    );

    setState(() {
      routineSlots.add(newSlot);
    });

    // Save the new routine slots
    widget.onSlotsChanged(routineSlots, activeSlot);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "$templateName" imported successfully!'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _editAnimationController.dispose();
    _addAnimationController.dispose();
    super.dispose();
  }
}

// Template Gallery Dialog
class _TemplateGalleryDialog extends StatefulWidget {
  final Function(String templateName, List<Map<String, dynamic>> templateTimeSlots) onTemplateImport;
  
  const _TemplateGalleryDialog({required this.onTemplateImport});
  
  @override
  State<_TemplateGalleryDialog> createState() => _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends State<_TemplateGalleryDialog> {
  String selectedCategory = 'All';
  String sortBy = 'Popular';
  Set<String> likedTemplates = {};
  
  final categories = [
    'All',
    'Student', 
    'Office Worker',
    'Night Shift',
    'Healthcare',
    'Retail',
    'Freelancer',
    'Parent',
    'Fitness',
    'Custom'
  ];
  final sortOptions = ['Popular', 'Newest', 'Most Liked'];
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 400,
          maxWidth: 500,
          maxHeight: 700,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse Templates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Filters
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        hint: const Text('Category'),
                        isExpanded: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sortBy,
                        hint: const Text('Sort'),
                        isExpanded: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        items: sortOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            sortBy = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Templates Grid
            Expanded(
              child: _buildTemplatesGrid(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTemplatesGrid() {
    // Mock data for now - this would come from backend later
    final templates = _getMockTemplates()
        .map((template) => template.copyWith(isLiked: likedTemplates.contains(template.id)))
        .where((template) =>
            selectedCategory == 'All' || template.category == selectedCategory)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,  // Better aspect ratio to prevent overflow
        crossAxisSpacing: 6,     // Reduced spacing
        mainAxisSpacing: 6,      // Reduced spacing
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          onImport: () => _importTemplate(template),
          onLike: () => _toggleLike(template),
        );
      },
    );
  }
  
  void _toggleLike(_RoutineTemplate template) {
    setState(() {
      if (likedTemplates.contains(template.id)) {
        likedTemplates.remove(template.id);
      } else {
        likedTemplates.add(template.id);
      }
    });
  }
  
  List<_RoutineTemplate> _getMockTemplates() {
    return [
      _RoutineTemplate(
        id: '1',
        name: 'Student Life',
        category: 'Student',
        description: 'Perfect schedule for students',
        author: 'Routine 24',
        likes: 245,
        isOfficial: true,
        timeSlots: [
          {
            'startTime': '07:00',
            'endTime': '08:00',
            'label': 'Morning Routine',
            'description': 'Get ready for the day',
            'color': 0xFF2196F3,
            'startAngle': 105.0,
            'endAngle': 120.0,
          },
          {
            'startTime': '09:00',
            'endTime': '12:00',
            'label': 'Study Session',
            'description': 'Focused learning time',
            'color': 0xFF4CAF50,
            'startAngle': 135.0,
            'endAngle': 180.0,
          },
        ],
      ),
      _RoutineTemplate(
        id: '2',
        name: 'Office Worker',
        category: 'Office Worker',
        description: 'Standard office schedule',
        author: 'Routine 24',
        likes: 189,
        isOfficial: true,
        timeSlots: [
          {
            'startTime': '09:00',
            'endTime': '17:00',
            'label': 'Work Hours',
            'description': 'Professional work time',
            'color': 0xFFFF9800,
            'startAngle': 135.0,
            'endAngle': 255.0,
          },
        ],
      ),
      _RoutineTemplate(
        id: '3',
        name: 'Fitness Focus',
        category: 'Fitness',
        description: 'Health and fitness routine',
        author: 'FitLife',
        likes: 324,
        timeSlots: [
          {
            'startTime': '06:00',
            'endTime': '07:00',
            'label': 'Morning Workout',
            'description': 'Start the day strong',
            'color': 0xFFF44336,
            'startAngle': 90.0,
            'endAngle': 105.0,
          },
          {
            'startTime': '18:00',
            'endTime': '19:00',
            'label': 'Evening Exercise',
            'description': 'End of day fitness',
            'color': 0xFF9C27B0,
            'startAngle': 270.0,
            'endAngle': 285.0,
          },
        ],
      ),
    ];
  }
  
  void _importTemplate(_RoutineTemplate template) {
    widget.onTemplateImport(template.name, template.timeSlots);
    Navigator.of(context).pop(); // Close dialog
  }
}

class _TemplateCard extends StatelessWidget {
  final _RoutineTemplate template;
  final VoidCallback onImport;
  final VoidCallback? onLike;
  
  const _TemplateCard({
    required this.template,
    required this.onImport,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showTemplatePreview(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Circle (mini routine visualization)
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              // Template Name with official badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (template.isOfficial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 10,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            'OFFICIAL',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Stats - Fixed at bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: template.isOfficial 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${template.likes}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: onLike,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                template.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: template.isLiked 
                                  ? Colors.red 
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${template.likes + (template.isLiked ? 1 : 0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                  Flexible(
                    child: Text(
                      template.author,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTemplatePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${template.category}'),
            const SizedBox(height: 8),
            Text('Description: ${template.description}'),
            const SizedBox(height: 8),
            Text('By: ${template.author}'),
            const SizedBox(height: 16),
            Text(
              'This template contains ${template.timeSlots.length} time slot(s) that you can import and customize.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close preview
              onImport(); // Import template
            },
            child: const Text('Import Template'),
          ),
        ],
      ),
    );
  }
}

// Template Model
class _RoutineTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final String author;
  final int likes;
  final List<Map<String, dynamic>> timeSlots;
  final bool isOfficial;
  final bool isLiked;

  _RoutineTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.author,
    required this.likes,
    required this.timeSlots,
    this.isOfficial = false,
    this.isLiked = false,
  });

  _RoutineTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? author,
    int? likes,
    List<Map<String, dynamic>>? timeSlots,
    bool? isOfficial,
    bool? isLiked,
  }) {
    return _RoutineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      timeSlots: timeSlots ?? this.timeSlots,
      isOfficial: isOfficial ?? this.isOfficial,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final LanguageService languageService;

  const SettingsDialog({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.languageService,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Toggle Section
                    _buildSettingsSection(
                      title: l10n.appearance,
                      children: [
                        ListTile(
                          leading: Icon(
                            widget.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.theme),
                          subtitle: Text(
                            widget.isDarkMode ? l10n.darkMode : l10n.lightMode,
                          ),
                          trailing: Switch(
                            value: widget.isDarkMode,
                            onChanged: (value) {
                              widget.onThemeToggle();
                            },
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Language Section
                    _buildSettingsSection(
                      title: l10n.language,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.language),
                          subtitle: Text(
                            '${widget.languageService.getCurrentLanguageName()} (${widget.languageService.locale.languageCode})',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showLanguageSelector(l10n),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Help & Support Section
                    _buildSettingsSection(
                      title: l10n.helpAndSupport,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.tutorial),
                          subtitle: Text(l10n.learnHowToUse),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showTutorial();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // About Section
                    _buildSettingsSection(
                      title: l10n.about,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Routine 24',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.developedBy,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                l10n.copyright,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showLanguageSelector(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: widget.languageService.supportedLocales.length,
            itemBuilder: (context, index) {
              final locale = widget.languageService.supportedLocales[index];
              final languageName = widget.languageService.getLanguageName(
                locale.languageCode,
              );
              final nativeName = widget.languageService.getNativeName(
                locale.languageCode,
              );
              final isSelected = locale == widget.languageService.locale;

              return ListTile(
                title: Text(languageName),
                subtitle: Text(nativeName),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.languageService.changeLanguage(locale);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Language changed to $languageName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const TutorialDialog();
      },
    );
  }
}
