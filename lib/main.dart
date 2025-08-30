import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:rive/rive.dart';
import 'selectable_clock_widget.dart';

void main() {
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
  bool isProUser = false; // This would come from your subscription system
  bool isLoggedIn = false; // This would come from your auth system

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
        return const HamburgerMenuDialog();
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
      icon: Icons.touch_app,
    ),
    TutorialSlide(
      title: 'Managing Your Schedule',
      content:
          'Your time slots will appear with start and end times. Tap on existing slots to modify or delete them.',
      icon: Icons.edit_calendar,
    ),
    TutorialSlide(
      title: 'Settings & Customization',
      content:
          'Tap the settings button in the top-right corner to access theme toggle, language options, and more customization features.',
      icon: Icons.settings,
    ),
    TutorialSlide(
      title: 'PRO Subscription Benefits',
      content:
          'Subscribe to PRO for \$6.99/year to unlock unlimited routine slots, ad-free experience, and premium features. Free users get 1 slot.',
      icon: Icons.star,
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
                  currentSlideData.imagePath != null
                      ? widgets.Image.asset(
                          currentSlideData.imagePath!,
                          width: 120,
                          height: 120,
                        )
                      : Icon(
                          currentSlideData.icon!,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
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

  TutorialSlide({
    required this.title,
    required this.content,
    this.icon,
    this.imagePath,
  });
}

class HamburgerMenuDialog extends StatefulWidget {
  const HamburgerMenuDialog({super.key});

  @override
  State<HamburgerMenuDialog> createState() => _HamburgerMenuDialogState();
}

class _HamburgerMenuDialogState extends State<HamburgerMenuDialog> {
  List<RoutineSlot> routineSlots = [
    RoutineSlot(id: '1', name: 'Default Routine', isActive: true, isPaid: false),
  ];
  bool isProUser = false; // This would come from your subscription system
  bool isLoggedIn = false; // This would come from your auth system
  String userEmail = ''; // User's email when logged in

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
            if (!isProUser)
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
                onPressed: (isProUser || routineSlots.length < 2) ? _addNewSlot : null,
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
            
            if (!isProUser && routineSlots.isNotEmpty)
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
                if (isProUser)
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
    if (!isProUser && routineSlots.length >= 1) {
      _showUpgradeDialog();
      return;
    }
    
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Routine ${routineSlots.length + 1}',
      isActive: false,
      isPaid: !isProUser ? false : true,
    );
    
    setState(() {
      routineSlots.add(newSlot);
    });
  }

  void _activateSlot(RoutineSlot slot) {
    setState(() {
      // Deactivate all slots
      for (int i = 0; i < routineSlots.length; i++) {
        routineSlots[i] = RoutineSlot(
          id: routineSlots[i].id,
          name: routineSlots[i].name,
          isActive: false,
          isPaid: routineSlots[i].isPaid,
        );
      }
      
      // Activate selected slot
      final index = routineSlots.indexOf(slot);
      routineSlots[index] = RoutineSlot(
        id: slot.id,
        name: slot.name,
        isActive: true,
        isPaid: slot.isPaid,
      );
    });
    
    Navigator.of(context).pop();
    // TODO: Load the routine data for this slot
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
    if (!isProUser) {
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
                      color: isProUser ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isProUser ? 'PRO MEMBER' : 'FREE USER',
                      style: TextStyle(
                        color: isProUser ? Colors.black : Colors.white,
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
                    if (!isProUser) _showUpgradeDialog();
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!isProUser)
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
        if (isProUser) ...[
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual sign-in logic
              setState(() {
                isLoggedIn = true;
                userEmail = emailController.text;
                // Mock: Make user Pro if they sign in (for demo)
                isProUser = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSignUpDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == confirmPasswordController.text) {
                // TODO: Implement actual sign-up logic
                setState(() {
                  isLoggedIn = true;
                  userEmail = emailController.text;
                  // New users start as free users
                  isProUser = false;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
      userEmail = '';
      isProUser = false;
    });
  }
}

class RoutineSlot {
  final String id;
  final String name;
  final bool isActive;
  final bool isPaid;

  RoutineSlot({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPaid,
  });
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
