import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:rive/rive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import 'selectable_clock_widget.dart';
import 'services/auth_service.dart';
import 'services/routine_slot_service.dart';
import 'models/user_model.dart';
import 'models/routine_slot_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine - 24-Hour Clock Selector',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: MyHomePage(
        title: '24-Hour Clock Selector',
        isDarkMode: isDarkMode,
        onThemeToggle: toggleTheme,
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
  });

  final String title;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StateMachineController? _stateMachineController;
  bool isProUser = false;
  bool isLoggedIn = false;
  final AuthService _authService = AuthService();
  final RoutineSlotService _routineSlotService = RoutineSlotService();
  List<RoutineSlot> routineSlots = [];
  RoutineSlot? activeSlot;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _loadRoutineSlots();
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
    if (userData != null) {
      setState(() {
        isProUser = userData['isPro'] ?? false;
      });
    }
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
          timeSlots
        );
        activeSlot = _routineSlotService.getActiveSlot(routineSlots);
      });
      _saveRoutineSlots();
    }
  }

  Widget _buildThemeToggleButton() {
    return Center(
      child: SizedBox(
        width: 60,
        height: 20,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Animate BEFORE changing theme for better responsiveness
            _animateToggle();
            // Small delay to let animation start, then change theme
            Future.delayed(const Duration(milliseconds: 50), () {
              widget.onThemeToggle();
            });
          },
          child: Container(
            width: 50,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(0, 126, 11, 11),
            ),
            child: RiveAnimation.asset(
              'assets/animations/ThemeToggle.riv',
              fit: BoxFit.fitWidth,
              onInit: (artboard) {
                debugPrint('🔄 Rive onInit called for ThemeToggle');

                // Try different state machine names
                StateMachineController? controller =
                    StateMachineController.fromArtboard(
                      artboard,
                      'Light/Dark Mode Button',
                    );

                if (controller == null) {
                  debugPrint(
                    '⚠️ "Light/Dark Mode Button" not found, trying alternatives...',
                  );
                  controller =
                      StateMachineController.fromArtboard(
                        artboard,
                        'State Machine 1',
                      ) ??
                      StateMachineController.fromArtboard(
                        artboard,
                        'State Machine',
                      ) ??
                      StateMachineController.fromArtboard(artboard, 'Theme') ??
                      StateMachineController.fromArtboard(artboard, 'Toggle') ??
                      StateMachineController.fromArtboard(artboard, 'Button');
                }

                if (controller != null) {
                  artboard.addController(controller);
                  _stateMachineController = controller;
                  debugPrint(
                    '✅ State machine controller initialized successfully',
                  );

                  // Debug: List all available inputs
                  debugPrint('📋 Available inputs:');
                  for (var input in controller.inputs) {
                    debugPrint('  - ${input.name} (${input.runtimeType})');
                  }

                  // Set initial state - try the actual input name we found
                  final boolInput =
                      controller.findInput<bool>('Toggle_Is_Pressed') ??
                      controller.findInput<bool>('isDark') ??
                      controller.findInput<bool>('darkMode') ??
                      controller.findInput<bool>('isLightMode') ??
                      controller.findInput<bool>('dark') ??
                      controller.findInput<bool>('light');

                  if (boolInput != null) {
                    // Handle the specific "Toggle_Is_Pressed" input
                    if (boolInput.name == 'Toggle_Is_Pressed') {
                      // For Toggle_Is_Pressed, we need to test which value shows dark mode
                      // Try setting it to match the current theme state
                      boolInput.value = widget.isDarkMode;
                      debugPrint(
                        '✅ Toggle_Is_Pressed set to: ${boolInput.value} (isDarkMode: ${widget.isDarkMode})',
                      );
                    } else if (boolInput.name.toLowerCase().contains('light')) {
                      boolInput.value =
                          !widget.isDarkMode; // Light mode when NOT dark
                    } else {
                      boolInput.value =
                          widget.isDarkMode; // Dark mode when IS dark
                    }
                    debugPrint(
                      '✅ Boolean input "${boolInput.name}" set to: ${boolInput.value} (isDarkMode: ${widget.isDarkMode})',
                    );
                  } else {
                    debugPrint('⚠️ No boolean input found, trying triggers...');

                    // Debug: List all trigger inputs to find the correct names
                    debugPrint('🔍 All trigger inputs:');
                    for (var input in controller.inputs) {
                      if (input is SMITrigger) {
                        debugPrint('  - TRIGGER: "${input.name}"');
                      }
                    }

                    // Force correct state after short delay to ensure it takes effect
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (controller != null && boolInput != null) {
                        // Double-check the boolean state in case it didn't take effect immediately
                        if (boolInput.name == 'Toggle_Is_Pressed') {
                          debugPrint(
                            '🔧 Double-checking Toggle_Is_Pressed state...',
                          );
                          boolInput.value = widget.isDarkMode;
                          debugPrint(
                            '✅ Toggle_Is_Pressed re-confirmed: ${boolInput.value}',
                          );
                        }
                      }
                    });
                  }
                } else {
                  debugPrint(
                    '❌ No compatible state machine found in ThemeToggle.riv',
                  );
                  debugPrint('💡 Available state machines:');
                  // Try to list available state machines
                  try {
                    final stateMachines = artboard.stateMachines;
                    for (var sm in stateMachines) {
                      debugPrint('  - "${sm.name}"');
                    }
                  } catch (e) {
                    debugPrint('  Could not list state machines: $e');
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
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

  void _animateToggle() {
    debugPrint(
      '🎯 _animateToggle called - current isDarkMode: ${widget.isDarkMode}',
    );

    if (_stateMachineController == null) {
      debugPrint(
        '❌ State machine controller is null! Animation will be skipped.',
      );
      // Still allow the theme toggle to work even without animation
      return;
    }

    // Try boolean input first
    final boolInput =
        _stateMachineController!.findInput<bool>('isDark') ??
        _stateMachineController!.findInput<bool>('darkMode') ??
        _stateMachineController!.findInput<bool>('isLightMode');

    if (boolInput != null) {
      final newValue = !widget.isDarkMode; // What we're switching TO
      // Set the correct value based on input name
      if (boolInput.name.toLowerCase().contains('light')) {
        boolInput.value = newValue; // Light mode = !darkMode
      } else {
        boolInput.value = !newValue; // Dark mode = darkMode
      }
      debugPrint(
        '✅ Navbar boolean input (${boolInput.name}) toggled to: ${boolInput.value} (switching to isDarkMode: ${!widget.isDarkMode})',
      );
    } else {
      debugPrint('⚠️ No boolean input found, trying triggers...');

      // Use the same comprehensive trigger search as initialization
      _findAndFireTrigger();
    }
  }

  void _findAndFireTrigger() {
    if (_stateMachineController == null) return;

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
      final trigger = _stateMachineController!.findSMI(name) as SMITrigger?;
      if (trigger != null) {
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

    debugPrint(
      '🔍 Found triggers - light: ${lightTrigger?.name}, dark: ${darkTrigger?.name}, general: ${generalTrigger?.name}',
    );

    // Fire trigger for what we're switching TO (opposite of current theme)
    if (widget.isDarkMode && lightTrigger != null) {
      lightTrigger.fire();
      debugPrint('✅ Light trigger fired (switching TO light: sun/cloud)');
    } else if (!widget.isDarkMode && darkTrigger != null) {
      darkTrigger.fire();
      debugPrint('✅ Dark trigger fired (switching TO dark: moon/star)');
    } else if (generalTrigger != null) {
      // Use general toggle trigger if specific ones aren't found
      generalTrigger.fire();
      debugPrint('✅ General trigger "${generalTrigger.name}" fired');
    } else {
      debugPrint(
        '❌ No suitable trigger found among: ${triggerNames.join(", ")}',
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

  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const TutorialDialog();
      },
    );
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
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SettingsDialog(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80, // Make navbar taller (default is 56)
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _showHamburgerMenu(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 19.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettings(context);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            SelectableClockWidget(
              isDarkMode: widget.isDarkMode,
              isProUser: isProUser,
              timeSlots: activeSlot?.timeSlots ?? [],
              onTimeSlotsChanged: _onTimeSlotsChanged,
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int currentSlide = 0;
  final int totalSlides = 5;

  final List<TutorialSlide> slides = [
    TutorialSlide(
      title: 'Welcome to Routine 24',
      content: 'Plan your day with our interactive 24-hour clock interface.',
      imagePath: 'assets/animations/Logo.png',
    ),
    TutorialSlide(
      title: 'Creating Time Slots',
      content:
          'Tap and drag on the clock to create time slots for your activities. The outer ring represents hours (0-23).',
      videoPath: 'assets/Slides/Slide2.mp4',
    ),
    TutorialSlide(
      title: 'Managing Your Schedule',
      content:
          'Your time slots will appear with start and end times. Tap on existing slots to modify or delete them.',
      videoPath: 'assets/Slides/Slide3.mp4',
    ),
    TutorialSlide(
      title: 'Settings & Customization',
      content:
          'Tap the settings button in the top-right corner to access theme toggle, language options, and more customization features.',
      videoPath: 'assets/Slides/Slide4.mp4',
    ),
    TutorialSlide(
      title: 'PRO Subscription Benefits',
      content:
          'Subscribe to PRO for \$6.99/year to unlock unlimited routine slots, ad-free experience, and premium features. Free users get 1 slot.',
      videoPath: 'assets/Slides/Slide5.mp4',
    ),
  ];

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
                  onPressed: () => Navigator.of(context).pop(),
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
                      child: SlideMediaWidget(
                        slideData: currentSlideData,
                      ),
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
                  child: const Text('Previous'),
                ),
                Text(
                  '${currentSlide + 1} / $totalSlides',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: currentSlide < totalSlides - 1 ? nextSlide : null,
                  child: Text(currentSlide < totalSlides - 1 ? 'Next' : ''),
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
                  child: const Text('Get Started'),
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

  const SlideMediaWidget({
    super.key,
    required this.slideData,
  });

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
      _videoController = VideoPlayerController.asset(widget.slideData.videoPath!);
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
    if (widget.slideData.videoPath != null && _isVideoInitialized && _videoController != null) {
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
    if ((_hasVideoError || widget.slideData.videoPath == null) && widget.slideData.imagePath != null) {
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
          child: Text(
            'Media not found',
            style: TextStyle(color: Colors.grey),
          ),
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

class _HamburgerMenuDialogState extends State<HamburgerMenuDialog> {
  late List<RoutineSlot> routineSlots;
  late RoutineSlot? activeSlot;
  bool isLoggedIn = false;
  String userEmail = '';
  final AuthService _authService = AuthService();
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
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
                  'Routine Slots',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: isLoggedIn ? _buildUserProfile() : _buildLoginPrompt(),
            ),
            const SizedBox(height: 16),
            
            // Pro status indicator
            if (!widget.isProUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free users can use 1 slot. Upgrade to Pro for unlimited slots.',
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

            // Add new slot button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (widget.isProUser || routineSlots.length < 2) ? _addNewSlot : null,
                icon: const Icon(Icons.add),
                label: Text('Add New Routine Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                  child: const Text('Upgrade to Pro for unlimited slots'),
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
      color: slot.isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: slot.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          radius: 12,
          child: slot.isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        title: Text(
          slot.name,
          style: TextStyle(
            fontWeight: slot.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          slot.isActive ? 'Currently Active' : 'Tap to activate',
          style: TextStyle(
            color: slot.isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
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
                if (widget.isProUser)
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy, size: 16),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (routineSlots.length > 1)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, size: 16, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
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
    if (!widget.isProUser && routineSlots.length >= 1) {
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
      routineSlots = widget.routineSlotService.activateSlot(routineSlots, slot.id);
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
            child: const Text('Cancel'),
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
    
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${slot.name} (Copy)',
      isActive: false,
      isPaid: true,
    );
    
    setState(() {
      routineSlots.add(newSlot);
    });
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pro features include:'),
            SizedBox(height: 8),
            Text('• Unlimited routine slots'),
            Text('• Duplicate routines'),
            Text('• Priority support'),
            Text('• Advanced customization'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement upgrade flow
              Navigator.pop(context);
            },
            child: const Text('Upgrade Now'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isProUser ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isProUser ? 'PRO MEMBER' : 'FREE USER',
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
                  const PopupMenuItem(
                    value: 'upgrade',
                    child: ListTile(
                      leading: Icon(Icons.star, size: 16, color: Colors.amber),
                      title: Text('Upgrade to Pro'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, size: 16),
                    title: Text('Logout'),
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
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Thank you for supporting Routine 24! Enjoy unlimited slots and ad-free experience.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
              'Sign in to sync your routines',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                child: const Text('Sign In', style: TextStyle(fontSize: 12)),
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
                child: const Text('Sign Up', style: TextStyle(fontSize: 12)),
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
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() { isLoading = true; });
                    try {
                      await _authService.signInWithGoogle();
                      await _updateAuthState();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully signed in with Google!')),
                        );
                      }
                    } catch (e) {
                      setDialogState(() { isLoading = false; });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google sign in failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() { isLoading = true; });
                    try {
                      await _authService.signInWithFacebook();
                      await _updateAuthState();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully signed in with Facebook!')),
                        );
                      }
                    } catch (e) {
                      setDialogState(() { isLoading = false; });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Facebook sign in failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text('Continue with Facebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                    child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
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
                      const SnackBar(content: Text('Successfully signed in!')),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                  });
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign in failed: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Sign In with Email'),
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
          title: const Text('Sign Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() { isLoading = true; });
                    try {
                      await _authService.signInWithGoogle();
                      await _updateAuthState();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully signed up with Google!')),
                        );
                      }
                    } catch (e) {
                      setDialogState(() { isLoading = false; });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google sign up failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() { isLoading = true; });
                    try {
                      await _authService.signInWithFacebook();
                      await _updateAuthState();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully signed up with Facebook!')),
                        );
                      }
                    } catch (e) {
                      setDialogState(() { isLoading = false; });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Facebook sign up failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text('Continue with Facebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                    child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
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
                      const SnackBar(content: Text('Account created successfully!')),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                  });
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration failed: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Sign Up with Email'),
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
}


class SettingsDialog extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  
  const SettingsDialog({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String selectedLanguage = 'English';
  
  final List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    Language(code: 'fr', name: 'French', nativeName: 'Français'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                      title: 'Appearance',
                      children: [
                        ListTile(
                          leading: Icon(
                            widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Theme'),
                          subtitle: Text(widget.isDarkMode ? 'Dark Mode' : 'Light Mode'),
                          trailing: Switch(
                            value: widget.isDarkMode,
                            onChanged: (value) {
                              widget.onThemeToggle();
                            },
                            activeThumbColor: Theme.of(context).colorScheme.onSurface,
                            activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Language Section
                    _buildSettingsSection(
                      title: 'Language',
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Language'),
                          subtitle: Text(selectedLanguage),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showLanguageSelector,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Help & Support Section
                    _buildSettingsSection(
                      title: 'Help & Support',
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Tutorial'),
                          subtitle: const Text('Learn how to use the app'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                      title: 'About',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Routine 24',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Developed By Kwanhoon Lee',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '© 2025 - Made For me and YOU',
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

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
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
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = supportedLanguages[index];
              final isSelected = language.name == selectedLanguage;
              
              return ListTile(
                title: Text(language.name),
                subtitle: Text(language.nativeName),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    selectedLanguage = language.name;
                  });
                  Navigator.pop(context);
                  // TODO: Implement actual language change
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${language.name}'),
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
            child: const Text('Cancel'),
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

class Language {
  final String code;
  final String name;
  final String nativeName;

  Language({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
