import 'dart:async';
import 'package:flutter/material.dart';

class ImageSplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;
  final Duration splashDuration;
  final Color backgroundColor;

  const ImageSplashScreen({
    super.key,
    required this.onSplashComplete,
    this.splashDuration = const Duration(milliseconds: 1500),
    this.backgroundColor = Colors.black,
  });

  @override
  State<ImageSplashScreen> createState() => _ImageSplashScreenState();
}

class _ImageSplashScreenState extends State<ImageSplashScreen>
    with TickerProviderStateMixin {
  Timer? _splashTimer;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashTimer();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _scaleController.forward();
  }

  void _startSplashTimer() {
    _splashTimer = Timer(widget.splashDuration, () {
      if (mounted) {
        _completeSplash();
      }
    });
  }

  void _completeSplash() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        widget.onSplashComplete();
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildSplashContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    if (_hasError) {
      return _buildFallbackContent();
    }

    return _buildImageContent();
  }

  Widget _buildImageContent() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Image.asset(
        'assets/animations/Logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
          return _buildFallbackContent();
        },
      ),
    );
  }

  Widget _buildFallbackContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Center(
            child: Text(
              'R24',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Routine 24',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Organize Your Perfect Day',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}