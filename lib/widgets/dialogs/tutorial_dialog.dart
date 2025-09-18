import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:video_player/video_player.dart';
import '../../l10n/app_localizations.dart';

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
      print('🎥 DEBUG: Attempting to load video: ${widget.slideData.videoPath}');
      print('🎥 DEBUG: Full video path: ${widget.slideData.videoPath}');

      // Test if asset exists using different methods
      try {
        await DefaultAssetBundle.of(context).load(widget.slideData.videoPath!);
        print('🎥 DEBUG: Asset bundle can access the file');
      } catch (bundleError) {
        print('🎥 DEBUG: Asset bundle error: $bundleError');
      }

      _videoController = VideoPlayerController.asset(
        widget.slideData.videoPath!,
      );

      print('🎥 DEBUG: VideoPlayerController created, initializing...');
      await _videoController!.initialize();
      print('🎥 DEBUG: Video controller initialized successfully');

      _videoController!.setLooping(true);
      _videoController!.play();
      print('🎥 ✅ Video loaded successfully: ${widget.slideData.videoPath}');
      print('🎥 ✅ Video size: ${_videoController!.value.size}');
      print('🎥 ✅ Video duration: ${_videoController!.value.duration}');

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
      }
    } catch (e) {
      print('🎥 ❌ Video loading failed: ${widget.slideData.videoPath}');
      print('🎥 ❌ Error type: ${e.runtimeType}');
      print('🎥 ❌ Error details: $e');
      print('🎥 ❌ Stack trace: ${StackTrace.current}');
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