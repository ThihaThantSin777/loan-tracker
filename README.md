# Loan Tracker

A full-stack mobile application for tracking loans between friends. Built with Flutter (mobile) and Laravel (backend).

---

## Features

- Track money lent and borrowed between friends
- Two payment methods: Cash (auto-accepted) and E-Wallet (with screenshot verification)
- Flexible due dates with reminders
- Push notifications for payments, reminders, and due dates
- Analytics dashboard
- Dark/Light theme support
- Beautiful animated UI with modern design

---

## Project Structure

```
loan-tracker/
├── mobile/          # Flutter mobile app
│   ├── android/     # Android-specific files
│   ├── ios/         # iOS-specific files
│   └── lib/         # Dart source code
├── backend/         # Laravel API
│   ├── app/         # Application code
│   ├── config/      # Configuration files
│   ├── database/    # Migrations & seeders
│   └── routes/      # API routes
└── README.md        # This file
```

---

## What's Done

| Feature | Mobile | Backend |
|---------|--------|---------|
| Authentication | ✅ | ✅ |
| Friends Management | ✅ | ✅ |
| Loans CRUD | ✅ | ✅ |
| Payments (Cash/E-Wallet) | ✅ | ✅ |
| Screenshot Upload | ✅ | ✅ (Cloudinary) |
| Push Notifications | ✅ | ✅ (Firebase) |
| Notifications List | ✅ | ✅ |
| Auto-Reminders | - | ✅ (Scheduler) |
| Dark/Light Theme | ✅ | - |
| App Icons | ✅ | - |
| Analytics | ✅ | ✅ |
| Verify E-Wallet Payments | ✅ | ✅ |
| Edit Profile | ✅ | ✅ |
| Rate Limiting | - | ✅ |
| Error Handling | ✅ | ✅ |
| Animated UI | ✅ | - |

---

## All Features Complete

The app is feature-complete and ready for testing/deployment.

---

## UI/UX Features

### Animations
- **Splash Screen:** Elastic bounce logo, rotating entrance, animated loading dots
- **Page Transitions:** Smooth slide and fade transitions between screens
- **Staggered Animations:** Sequential loading for lists and cards
- **Micro-interactions:** Press feedback with scale effects on all buttons
- **Number Counters:** Animated counting for amounts and balances

### Design System
- **Gradients:** Primary to secondary color gradients throughout
- **Glassmorphism:** Semi-transparent card overlays
- **Shadows:** Soft, colored shadows for depth
- **Rounded Corners:** Consistent 12-20px border radius
- **Color Coding:** Success (green), Danger (red), Warning (orange)

### Components
- `GradientCard` - Cards with gradient backgrounds
- `GlassCard` - Glassmorphism effect cards
- `GradientButton` - Buttons with gradient and shadows
- `AnimatedBadge` - Status badges with animations
- `SummaryCard` - Dashboard cards with number animation
- `TapScale` - Press feedback wrapper

### Screens Enhanced
- Splash Screen with logo animation
- Login/Register with glass cards and progress indicator
- Dashboard with animated balance cards
- Profile with gradient header and menu sections
- Custom bottom navigation with expanding labels

---

## What Needs To Be Done

### For Local Development

#### Backend
```bash
cd backend
cp .env.example .env
php artisan key:generate
# Configure database in .env
php artisan migrate
php artisan serve
```

#### Mobile
```bash
cd mobile
flutter pub get
# Update API URL in lib/config/api_config.dart
flutter run
```

### For Production

#### Backend Deployment
1. Upload to server (VPS/shared hosting with PHP 8.2+)
2. Configure `.env` for production
3. Run migrations: `php artisan migrate --force`
4. Cache config: `php artisan config:cache`
5. Setup cron for auto-reminders:
   ```bash
   * * * * * cd /path-to-project && php artisan schedule:run >> /dev/null 2>&1
   ```

#### Mobile Deployment
1. Update API URL to production server
2. **Android:**
   - Generate signing keystore
   - Build: `flutter build appbundle --release`
   - Upload to Play Console
3. **iOS:**
   - Configure signing in Xcode
   - Archive and upload to App Store Connect

### Store Requirements
- [ ] Google Play Developer Account ($25 one-time)
- [ ] Apple Developer Account ($99/year)
- [ ] Privacy Policy URL
- [ ] App screenshots
- [ ] App description

---

## Tech Stack

### Mobile (Flutter)
- **State Management:** Provider
- **HTTP Client:** http package
- **Storage:** flutter_secure_storage, shared_preferences
- **Push Notifications:** firebase_messaging
- **Image Picker:** image_picker

### Backend (Laravel 12)
- **Authentication:** Laravel Sanctum
- **Database:** MySQL
- **File Storage:** Cloudinary
- **Push Notifications:** Firebase Admin SDK
- **Scheduler:** Laravel Task Scheduling

---

## Third-Party Services

| Service | Purpose | Status |
|---------|---------|--------|
| Cloudinary | Screenshot storage | ✅ Configured |
| Firebase | Push notifications | ✅ Configured |
| MySQL | Database | ✅ Configured |

---

## Environment Variables

### Backend (.env)
```env
# App
APP_NAME=LoanTracker
APP_ENV=local
APP_URL=http://localhost

# Database
DB_CONNECTION=mysql
DB_DATABASE=loan_tracker
DB_USERNAME=root
DB_PASSWORD=

# Cloudinary
CLOUDINARY_CLOUD_NAME=dxsx0phwi
CLOUDINARY_API_KEY=261579122291842
CLOUDINARY_API_SECRET=***

# Firebase
FIREBASE_CREDENTIALS=storage/firebase-credentials.json
FIREBASE_PROJECT_ID=loan-tracker-a45bc
```

### Mobile (lib/config/api_config.dart)
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

---

## Quick Start

### 1. Start Backend
```bash
cd backend
php artisan serve
# Server runs at http://127.0.0.1:8000
```

### 2. Run Mobile App
```bash
cd mobile
flutter run
```

### 3. Test Auto-Reminders
```bash
cd backend
php artisan loans:send-reminders
```

---

## API Documentation

See [backend/README.md](backend/README.md) for full API endpoint documentation.

## Mobile Documentation

See [mobile/README.md](mobile/README.md) for Flutter app documentation.

---

## License

Private project - All rights reserved.
