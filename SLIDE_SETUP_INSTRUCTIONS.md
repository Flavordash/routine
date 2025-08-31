# Tutorial Slide Setup Instructions

## ✅ What I've Already Done

1. **Added video player support** to the app
2. **Updated the tutorial slides** to support both video and image files
3. **Created the assets directory structure** at `assets/animations/slides/`
4. **Updated pubspec.yaml** to include the new assets and video_player dependency

## 📁 Your Files Should Go Here

```
assets/animations/slides/
├── slide2.mp4    ← Your Slide 2 video
├── slide2.png    ← Your Slide 2 fallback image  
├── slide3.mp4    ← Your Slide 3 video
├── slide3.png    ← Your Slide 3 fallback image
├── slide4.mp4    ← Your Slide 4 video
├── slide4.png    ← Your Slide 4 fallback image
├── slide5.mp4    ← Your Slide 5 video
└── slide5.png    ← Your Slide 5 fallback image
```

## 🎯 What You Need To Do

1. **Copy your video files** to `assets/animations/slides/` with these exact names:
   - `slide2.mp4` (or .mov)
   - `slide3.mp4` (or .mov) 
   - `slide4.mp4` (or .mov)
   - `slide5.mp4` (or .mov)

2. **Copy your PNG files** to the same directory with these exact names:
   - `slide2.png`
   - `slide3.png`
   - `slide4.png` 
   - `slide5.png`

3. **Run these commands**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🎬 How It Works Now

- **Slide 1**: Shows the existing logo image
- **Slides 2-5**: Will show your videos with PNG fallbacks
- **Auto-loop**: Videos will automatically loop
- **Fallback**: If a video fails, it shows the PNG image
- **Final fallback**: If both fail, shows the original icon

## 📱 Tutorial Flow

1. User opens the app tutorial
2. Slide 1: Shows logo (unchanged)  
3. Slide 2: Shows your "Creating Time Slots" video/image
4. Slide 3: Shows your "Managing Schedule" video/image
5. Slide 4: Shows your "Settings" video/image
6. Slide 5: Shows your "PRO Benefits" video/image

The tutorial slides will automatically use your media files once you place them in the correct directory with the correct names!