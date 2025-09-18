# Tutorial Slides

This directory contains assets for the tutorial system in the Routine 24 app.

## Overview

The tutorial videos are located in the `assets/Slides/` directory (parent level) and are used by the tutorial dialog to guide new users through the app's features.

## Current Tutorial Structure

The tutorial consists of 5 slides:

1. **Slide 1**: Welcome screen with app logo (`assets/animations/Logo.png`)
2. **Slide 2**: Creating Time Slots (`assets/Slides/Slide2.mp4`)
3. **Slide 3**: Managing Your Schedule (`assets/Slides/Slide3.mp4`)
4. **Slide 4**: Settings & Customization (`assets/Slides/Slide4.mp4`)
5. **Slide 5**: PRO Subscription Benefits (`assets/Slides/Slide5.mp4`)

## File Format Support

The tutorial system supports both `.mp4` and `.mov` video formats through Flutter's `video_player` package.

## Adding New Tutorial Content

To update tutorial content:

1. Replace video files in `assets/Slides/` directory
2. Update file references in `lib/widgets/dialogs/tutorial_dialog.dart`
3. Run `flutter clean` and `flutter pub get` to refresh assets
4. Update localization strings in `lib/l10n/app_en.arb` if needed

## Technical Notes

- Videos should be optimized for mobile playback
- Keep file sizes reasonable for app bundle size
- Test on both iOS and Android devices
- Videos auto-play and loop during tutorial display