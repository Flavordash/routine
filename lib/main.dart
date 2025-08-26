import 'package:flutter/material.dart';
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

  Widget _buildThemeToggleButton() {
    return Container(
      width: 80, // Smaller width to match toggle size
      height: 80, // Match navbar height
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () {
          // Animate BEFORE changing theme for better responsiveness
          _animateToggle();
          // Small delay to let animation start, then change theme
          Future.delayed(const Duration(milliseconds: 50), () {
            widget.onThemeToggle();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: RiveAnimation.asset(
            'assets/animations/ThemeToggle.riv',
            fit: BoxFit.contain,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80, // Make navbar taller (default is 56)
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showTutorial(context);
          },
        ),
        actions: [
          Transform.translate(
            offset: const Offset(
              0,
              0,
            ), // Move left by reducing offset (was 20, now 10)
            child: _buildThemeToggleButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            SelectableClockWidget(isDarkMode: widget.isDarkMode),
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
  final int totalSlides = 4;

  final List<TutorialSlide> slides = [
    TutorialSlide(
      title: 'Welcome to Routine',
      content: 'Plan your day with our interactive 24-hour clock interface.',
      icon: Icons.schedule,
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
      title: 'Theme & Settings',
      content:
          'Use the toggle in the top-right corner to switch between light and dark themes for comfortable viewing.',
      icon: Icons.palette,
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
                          ).colorScheme.primary.withOpacity(0.3),
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
                  Icon(
                    currentSlideData.icon,
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

            // Credits footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
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
  final IconData icon;

  TutorialSlide({
    required this.title,
    required this.content,
    required this.icon,
  });
}
