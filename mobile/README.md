# Loan Tracker - Mobile App (Flutter)

## Overview
A Flutter mobile application for tracking loans between friends with support for cash and e-wallet payments.

---

## What's Done

### Core Features
- [x] User Authentication (Login/Register/Logout)
- [x] Session persistence with secure storage
- [x] Dashboard with loan summaries
- [x] Loans management (Create, View, List)
- [x] Friends management (Add, Accept, Reject, Remove)
- [x] Payment submission (Cash & E-Wallet with screenshot)
- [x] Loan detail with payment history
- [x] Due date display and overdue status

### UI/UX
- [x] Dark/Light theme with toggle
- [x] Theme persistence (saves preference)
- [x] Custom app icon (Android & iOS)
- [x] App name: "Loan Tracker"
- [x] Bottom navigation (Dashboard, Loans, Friends, Profile)
- [x] Pull to refresh on lists
- [x] Loading states and error handling
- [x] Beautiful animated UI with modern design
- [x] Gradient cards and buttons
- [x] Glassmorphism effects
- [x] Staggered list animations
- [x] Micro-interactions (tap feedback)
- [x] Animated number counters
- [x] Custom page transitions

### Notifications
- [x] Notifications screen with list
- [x] Unread badge on notification icon
- [x] Mark as read (single & all)
- [x] Delete notification (swipe to dismiss)
- [x] Pagination (infinite scroll)
- [x] Color-coded notification types

### Firebase
- [x] Firebase Core integration
- [x] Firebase Messaging setup
- [x] FCM token management
- [x] Push notification handling (foreground/background)

### Providers (State Management)
- [x] AuthProvider
- [x] LoanProvider
- [x] FriendProvider
- [x] ThemeProvider
- [x] NotificationProvider
- [x] PaymentProvider

### Models
- [x] User
- [x] Loan
- [x] Payment
- [x] Friendship
- [x] LoanNotification

### Additional Features
- [x] Verify E-Wallet payments screen (Lender accept/reject UI)
- [x] Edit Profile screen functionality
- [x] Comprehensive error handling with user-friendly messages

---

## What Needs To Be Done

### For Local Development

1. **Update API URL**
   ```dart
   // lib/config/api_config.dart
   static const String baseUrl = 'http://10.0.2.2:8000/api';  // Android Emulator
   // OR
   static const String baseUrl = 'http://127.0.0.1:8000/api';  // iOS Simulator
   // OR
   static const String baseUrl = 'http://YOUR_IP:8000/api';    // Real Device
   ```

2. **Run the app**
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

### For Production

1. **Update API URL to production server**
   ```dart
   static const String baseUrl = 'https://your-domain.com/api';
   ```

2. **Android Release Build**
   ```bash
   # Generate keystore (first time only)
   keytool -genkey -v -keystore ~/loan-tracker-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias loan-tracker

   # Create key.properties in android/
   storePassword=<password>
   keyPassword=<password>
   keyAlias=loan-tracker
   storeFile=/path/to/loan-tracker-key.jks

   # Build release APK
   flutter build apk --release

   # Build App Bundle (for Play Store)
   flutter build appbundle --release
   ```

3. **iOS Release Build**
   ```bash
   # Open in Xcode
   open ios/Runner.xcworkspace

   # Configure signing in Xcode
   # Product > Archive > Distribute App
   ```

4. **Play Store Submission**
   - [ ] Create Google Play Developer account ($25 one-time)
   - [ ] Prepare app screenshots (phone & tablet)
   - [ ] Write app description
   - [ ] Create privacy policy URL
   - [ ] Upload AAB file
   - [ ] Fill store listing
   - [ ] Submit for review

5. **App Store Submission**
   - [ ] Create Apple Developer account ($99/year)
   - [ ] Prepare app screenshots (all iPhone sizes)
   - [ ] Write app description
   - [ ] Create privacy policy URL
   - [ ] Upload via Xcode/Transporter
   - [ ] Fill App Store Connect listing
   - [ ] Submit for review

---

## Animations & UI Components

### Animation Utilities (`lib/utils/animations.dart`)
| Component | Description |
|-----------|-------------|
| `FadeInAnimation` | Simple fade-in effect |
| `SlideUpFadeIn` | Slide up with fade effect |
| `ScaleAnimation` | Elastic scale animation |
| `BounceIn` | Bounce entrance effect |
| `PulseAnimation` | Pulsing attention effect |
| `ShimmerLoading` | Loading shimmer effect |
| `TapScale` | Press feedback wrapper |
| `SlidePageRoute` | Custom page transitions |
| `AnimatedCounter` | Number counting animation |

### Reusable Widgets (`lib/widgets/`)
| Widget | Description |
|--------|-------------|
| `GradientCard` | Card with gradient background |
| `GlassCard` | Glassmorphism effect card |
| `GradientButton` | Button with gradient and shadow |
| `AnimatedBadge` | Animated status badge |
| `SummaryCard` | Dashboard card with animations |
| `AnimatedListTile` | Interactive list item |

### Screen Animations
- **Splash Screen:** Elastic logo bounce, rotating entrance, animated loading dots
- **Login/Register:** Glass cards, staggered form animations, progress indicator
- **Dashboard:** SliverAppBar, animated balance cards, staggered activity list
- **Profile:** Gradient header, floating card, animated menu items
- **Bottom Navigation:** Expanding labels, haptic feedback

---

## Project Structure

```
mobile/
├── lib/
│   ├── config/
│   │   ├── api_config.dart      # API endpoints
│   │   └── theme.dart           # App themes
│   ├── models/
│   │   ├── user.dart
│   │   ├── loan.dart
│   │   ├── payment.dart
│   │   ├── friendship.dart
│   │   └── notification.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── loan_provider.dart
│   │   ├── friend_provider.dart
│   │   ├── theme_provider.dart
│   │   ├── notification_provider.dart
│   │   └── payment_provider.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   └── firebase_service.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── loans/
│   │   ├── payments/
│   │   ├── profile/
│   │   └── notifications/
│   ├── widgets/
│   │   ├── summary_card.dart
│   │   └── gradient_card.dart
│   ├── utils/
│   │   ├── animations.dart
│   │   └── error_handler.dart
│   └── main.dart
├── android/
│   └── app/
│       ├── google-services.json  # Firebase config
│       └── src/main/res/         # App icons
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist  # Firebase config
│       └── Assets.xcassets/          # App icons
└── pubspec.yaml
```

---

## Dependencies

```yaml
dependencies:
  provider: ^6.1.5+1
  http: ^1.6.0
  image_picker: ^1.2.1
  shared_preferences: ^2.5.4
  intl: ^0.20.2
  flutter_secure_storage: ^10.0.0
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.4
```

---

## Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Analyze code
flutter analyze

# Clean build
flutter clean && flutter pub get
```
