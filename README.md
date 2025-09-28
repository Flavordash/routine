# Routine 24

A visual time management iOS app featuring an innovative 24-hour circular interface for building daily routines.

[![App Store](https://img.shields.io/badge/Download_on_the-App_Store-black?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/app/routine24)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](#)
[![Platform](https://img.shields.io/badge/Platform-Cross_Platform-green?style=for-the-badge)](#)

## Overview

Routine 24 revolutionizes daily planning with its unique circular time visualization. Unlike traditional linear schedulers, the app presents your entire day as an intuitive 24-hour circle, making it easier to understand time flow and build sustainable routines.

<img width="250" alt="1" src="https://github.com/user-attachments/assets/ccbbd424-db2c-49a4-a615-366e5797a0bc" />
<img width="250" alt="2" src="https://github.com/user-attachments/assets/315675af-6d3c-4fea-b00c-9dc8f5332e12" />
<img width="250" alt="3" src="https://github.com/user-attachments/assets/454d3c2e-7563-4c51-b0d7-69f6db5ec21b" />
<img width="250" alt="4" src="https://github.com/user-attachments/assets/e7969fd1-755c-4681-8123-a1798b0e13f1" />
<img width="250" alt="5" src="https://github.com/user-attachments/assets/83e0824f-dfa9-4834-a0f5-08d59fd2519e" />
<img width="250" alt="6" src="https://github.com/user-attachments/assets/b0226b30-f9e6-482f-a181-581b3602e409" />

**"Circle Your Time"** - See your perfect day take shape.

## Key Features

### Core Functionality
- **24-Hour Circle Interface** - Interactive Rive-animated circular time visualization
- **Cross-Platform Sync** - Seamless routine synchronization across iOS, Android, macOS, and Web
- **Drag-to-Select** - Intuitive touch interactions for time range selection
- **Weekly Variations** - Different routines for each day of the week
- **Smart Time Zones** - Automatic time zone detection and adjustment
- **Haptic Feedback** - Enhanced touch interactions with vibration responses

### Advanced Notification System
- **Local Notifications** - Flutter-based cross-platform notification system
- **Smart Intervals** - PRO feature with customizable reminder frequencies
- **Pre-Alarms** - Early warnings before routine starts
- **Snooze Support** - Native iOS and Android snooze functionality
- **Time Zone Aware** - Notifications adapt to device location and time changes

### Internationalization & Accessibility
- **Multi-Language Support** - Korean, English, Spanish, Chinese
- **RTL Language Support** - Right-to-left reading languages
- **Dynamic Language Switching** - Change language without app restart
- **Theme System** - Dark and light modes with animated transitions
- **Responsive Design** - Adaptive layouts for tablets and phones

### Template & Community System
- **Template Gallery** - Pre-built routines for different lifestyles
- **One-Click Import** - Instant routine setup from templates
- **Professional Templates** - Curated routines for students, professionals, shift workers
- **Custom Routine Builder** - Visual routine creation with circular interface

### Subscription & Monetization
- **Freemium Model** - Core features free, advanced features via subscription
- **Cross-Platform Purchases** - iOS App Store and Google Play integration
- **PRO Features:**
  - Unlimited routine creation
  - Smart interval notifications
  - Ad-free experience
- **Google AdMob Integration** - Non-intrusive ads for free users

## Project Architecture

### File Structure (36 Dart Files)
```
lib/
├── main.dart                    # App entry point with Riverpod setup
├── selectable_clock_widget.dart # Main 24-hour circular widget
├── l10n/                       # Internationalization (4 languages)
├── constants/                  # App-wide constants and configurations
├── providers/                  # Riverpod state management providers
├── models/                     # Data models and entities
│   ├── RoutineSlot             # Routine container model
│   ├── RoutineTimeSlot         # Time-based routine model
│   └── TimeSlot                # UI time slot representation
├── services/                   # Business logic and external service integration
│   ├── notification_service.dart    # Notification scheduling and management
│   ├── routine_slot_service.dart    # Routine CRUD operations
│   ├── auth_service.dart            # Firebase authentication
│   ├── subscription_service.dart    # In-app purchase management
│   └── ad_service.dart             # Ad display and management
└── widgets/                    # UI components and screens
    ├── settings/               # Settings and preferences UI
    ├── routine/                # Routine creation and editing
    ├── template/               # Template gallery and import
    ├── common/                 # Reusable UI components
    └── dialogs/                # Modal dialogs and overlays
```

### Key Dependencies
**Core Framework:**
- `flutter: 3.9.0+` - UI framework
- `riverpod` - State management
- `firebase_core` - Backend infrastructure
- `cloud_firestore` - Real-time database

**Features:**
- `flutter_local_notifications` - Cross-platform notifications
- `rive` - Interactive vector animations
- `geolocator` - Location-based time zone detection
- `google_mobile_ads` - Advertisement integration
- `in_app_purchase` - Subscription management

**Utilities:**
- `timezone` - Time zone calculations
- `intl` - Internationalization
- `vibration` - Haptic feedback
- `url_launcher` - External link handling

## Technical Stack

### iOS Development
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Minimum iOS Version:** iOS 14.0

### Frameworks & Services
- **StoreKit** - In-App Purchases and Subscriptions
- **UserNotifications** - Smart Alarm System
- **CoreData** - Local Data Storage
- **CloudKit** - Cross-Device Data Sync
- **Google AdMob** - Advertisement Integration

## Development Timeline

### Project History
- **Project Start:** August 27, 2024
- **Development Period:** 2 months (August - September 2024)
- **Current Version:** 1.0.0+1
- **Platform Support:** iOS, Android, macOS, Web (Flutter framework)
- **Last Updated:** September 26, 2024

### Recent Development Activity
```
fa96665 - support
cab6a33 - latest update  
27d66b6 - update
4ba0024 - sofar
```

## Implementation Highlights

### Circular Interface Innovation
- **Rive Animation Integration:** Custom interactive animations for 24-hour circle
- **Complex Touch Handling:** Mathematical coordinate conversion for circular gestures
- **Performance Optimization:** 60fps smooth animations across all platforms
- **Responsive Scaling:** Dynamic sizing based on screen dimensions

### Cross-Platform Notification System
- **Flutter Local Notifications:** Unified API for iOS and Android notifications
- **Timezone Awareness:** Automatic adjustment for user location and travel
- **Smart Scheduling:** Pre-alarms and interval reminders with conflict resolution
- **Native Integration:** iOS and Android notification channels and categories

### Real-Time Data Synchronization
- **Firebase Firestore:** Real-time multi-device synchronization
- **Offline-First Design:** Local data persistence with cloud sync
- **Conflict Resolution:** Automatic handling of concurrent edits across devices
- **Authentication Integration:** Google Sign-In with secure data isolation

### Subscription Management
- **Cross-Platform Purchases:** iOS App Store and Google Play Store integration
- **Receipt Validation:** Server-side verification for subscription status
- **Feature Gating:** Dynamic UI based on subscription tier
- **Restore Purchases:** Cross-device subscription recovery

## Challenges & Solutions

### Cross-Platform Development
**Challenge:** Maintaining consistent UI/UX across iOS, Android, macOS, and Web  
**Solution:** Flutter's widget system with platform-specific adaptations  
**Result:** Native-feeling experience on each platform with shared codebase

**Challenge:** Platform-specific notification behavior differences  
**Solution:** Abstraction layer with flutter_local_notifications and platform channels  
**Result:** Consistent notification experience across all supported platforms

### Complex UI Implementation
**Challenge:** Interactive circular interface with precise touch handling  
**Solution:** Custom gesture detectors with mathematical coordinate transformation  
**Result:** Smooth, intuitive time selection with proper visual feedback

**Challenge:** Rive animation integration with Flutter state management  
**Solution:** Custom Rive controllers synchronized with Riverpod state  
**Result:** Seamless animation state synchronization with app logic

### Real-Time Data Management
**Challenge:** Offline-first architecture with cloud synchronization  
**Solution:** Local storage with Firebase Firestore real-time listeners  
**Result:** Instant app responsiveness with automatic cloud backup

**Challenge:** Cross-device subscription state consistency  
**Solution:** Server-side receipt validation with Firebase Functions  
**Result:** Reliable subscription status across all user devices

### Performance Optimization
**Challenge:** Smooth 60fps animations on older devices  
**Solution:** Optimized rendering pipeline and efficient widget rebuilds  
**Result:** Consistent performance across device generations

## Technical Decisions & Trade-offs

### Flutter vs Native Development
**Decision:** Choose Flutter for cross-platform development  
**Trade-offs:** 
- ✅ Single codebase for multiple platforms
- ✅ Faster development and maintenance
- ✅ Consistent UI across platforms
- ❌ Slightly larger app size
- ❌ Platform-specific features require additional work

### State Management Choice
**Decision:** Flutter Riverpod over other solutions  
**Rationale:** 
- Compile-time safety and better debugging
- Excellent testing support
- Modern async programming patterns
- Provider disposal and lifecycle management

### Animation Framework Selection
**Decision:** Rive for complex animations, Flutter for simple ones  
**Benefits:**
- Designer-developer workflow with Rive editor
- Interactive animations with state machines
- Smaller file sizes compared to video
- Vector-based scalability

## App Store & Distribution

### Current Status
- **App Store Submission:** In Review
- **Bundle ID:** com.dashpill.routine24
- **Target Platforms:** iOS App Store, Google Play Store
- **Future Platforms:** macOS App Store, Web deployment

### Monetization Strategy
- **Freemium Model:** Core features free, advanced features paid
- **Subscription Tiers:**
  - Monthly: $3.99
  - Annual: $7.99 (83% savings)
- **Ad Integration:** Google AdMob for free tier users
- **Revenue Streams:** Subscriptions (primary), advertisements (secondary)

### Marketing & ASO
- **Primary Category:** Productivity
- **Keywords:** routine, schedule, planner, 24hour, circle, habit, productivity
- **Target Audience:** Students, professionals, shift workers, wellness enthusiasts
- **USP:** "Circle Your Time" - unique circular time visualization

## Lessons Learned

### Flutter Development Insights
- **State Management:** Riverpod's compile-time safety significantly reduced runtime errors
- **Animation Performance:** Rive animations provide better performance than traditional Flutter animations for complex interactions
- **Cross-Platform Considerations:** Platform-specific features require careful abstraction and testing
- **Firebase Integration:** Real-time listeners can cause unnecessary rebuilds if not properly managed

### Business & Product Development
- **Feature Scope:** Started with MVP focused on core circular interface before expanding
- **User Feedback:** Early template system validation led to improved user onboarding
- **Monetization Timing:** Freemium model allowed user base growth before subscription introduction
- **Platform Strategy:** Flutter enabled rapid multi-platform launch with single development effort

### App Store Submission Process
- **Documentation Importance:** Comprehensive privacy policy and review notes prevented submission delays
- **Testing Coverage:** Cross-platform testing revealed platform-specific edge cases
- **Metadata Optimization:** ASO research influenced keyword selection and app description
- **Compliance Preparation:** GDPR and privacy label requirements needed early consideration

## Future Roadmap

### Version 1.1 Features
- **Apple Watch Companion** - Routine overview and quick notifications
- **Widget Support** - Home screen widgets for iOS and Android
- **Siri Shortcuts & Google Assistant** - Voice-activated routine management
- **Enhanced Templates** - Community-contributed routine sharing

### Platform Expansion
- **macOS App Store** - Native desktop experience with menu bar integration
- **Web Application** - Progressive Web App for browser-based access
- **Windows Store** - UWP app for Windows 10/11 users
- **Linux Support** - Snap package for Ubuntu and other distributions

### Advanced Features
- **AI-Powered Suggestions** - Machine learning for routine optimization
- **Team Collaboration** - Shared family/workplace routines with role-based permissions
- **Calendar Integration** - Two-way sync with Google Calendar, Outlook, Apple Calendar
- **Health App Integration** - Sleep tracking and wellness metrics correlation

### Technical Improvements
- **Offline-First Enhancement** - Better offline experience with local-first architecture
- **Performance Optimization** - Reduced memory usage and faster startup times
- **Accessibility Improvements** - Screen reader support and keyboard navigation
- **Analytics Dashboard** - User routine insights and productivity metrics

## Contact & Support

- **Developer:** Flavordash (GitHub: @Flavordash)
- **Support Email:** kwanapps2025@gmail.com
- **Privacy Policy:** [View Documentation](https://flavordash.github.io/routine24-privacy/)
- **Issues & Bug Reports:** [GitHub Issues](https://github.com/Flavordash/routine/issues)

## Contributing

This project showcases a complete Flutter app development lifecycle from conception to App Store submission. While the source code is proprietary, the documentation and architectural decisions are shared to benefit the Flutter development community.

**Areas of Interest for Community Discussion:**
- Cross-platform state management patterns
- Complex animation integration with Rive
- Firebase real-time synchronization strategies  
- Flutter app performance optimization techniques

## License

**Proprietary License** - All rights reserved. This repository contains documentation and architectural insights for educational purposes. The actual app source code and assets are not open source.

---

*This project demonstrates comprehensive Flutter development skills including cross-platform architecture, real-time data synchronization, complex UI animations, subscription management, and successful App Store submission processes.*
