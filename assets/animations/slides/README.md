# Tutorial Slide Media Files

This directory contains the video and image files for the tutorial slides.

## File Structure

For each slide (2-5), you should have:
- `slideX.mp4` - The video file for the slide
- `slideX.png` - A fallback image in case the video fails to load

## Current Slide Mappings

- **Slide 2**: Creating Time Slots
  - Video: `slide2.mp4`
  - Fallback: `slide2.png`

- **Slide 3**: Managing Your Schedule  
  - Video: `slide3.mp4`
  - Fallback: `slide3.png`

- **Slide 4**: Settings & Customization
  - Video: `slide4.mp4`
  - Fallback: `slide4.png`

- **Slide 5**: PRO Subscription Benefits
  - Video: `slide5.mp4`  
  - Fallback: `slide5.png`

## Supported Formats

- **Videos**: MP4, MOV
- **Images**: PNG, JPG

## How It Works

1. The app will try to load the video file first
2. If the video fails to load, it will show the PNG fallback
3. If both fail, it will show the original icon as a final fallback

## To Add Your Files

1. Replace the placeholder files in this directory with your actual video and image files
2. Make sure the filenames match exactly: `slide2.mp4`, `slide2.png`, etc.
3. Run `flutter clean` and `flutter pub get` after adding new assets
4. The tutorial will automatically use your new media files