# Flutter App - Build & Test Guide

## Prerequisites

```bash
# Ensure Flutter SDK is installed
flutter --version

# Check doctor for setup issues
flutter doctor

# Expected output should show:
# - Flutter SDK: OK
# - Android SDK: OK (for Android)
# - Xcode: OK (for iOS)
# - VS Code/Android Studio: OK
```

## Build & Run Commands

### Android (Emulator)

```bash
# List available Android emulators
flutter emulators

# Start Android emulator
flutter emulators --launch <emulator-name>
# Example: flutter emulators --launch Pixel_4_API_30

# Run app on Android emulator
cd parking_user_app
flutter run

# Or specify release build
flutter run -d emulator-5554 --release
```

### Android (Physical Device)

```bash
# Enable USB Debugging on phone
# Connect phone via USB

# List connected devices
flutter devices

# Run app
flutter run -d <device-id>
```

### iOS (Simulator)

```bash
# List available iOS simulators
xcrun simctl list devices

# Run on iPhone Simulator
flutter run -d "iPhone 15"
```

### iOS (Physical Device)

See iOS_DEPLOYMENT_GUIDE.md for detailed instructions.

## Testing Checklist

### Authentication Flow
- [ ] Open app → Login screen appears
- [ ] Enter phone number (e.g., +254712345678)
- [ ] Enter password
- [ ] Click login
- [ ] OTP verification screen appears
- [ ] Enter OTP code (check Django logs for code)
- [ ] Home screen loads successfully
- [ ] Token appears in device secure storage

### Core Features
- [ ] **Zones**: Tap Zones tab → List of parking zones loads
- [ ] **Parking**: Start parking → Select zone → Confirm
- [ ] **History**: View parking history with times
- [ ] **Wallet**: Check balance → Top up → Browse transactions
- [ ] **Chat**: Tap chat icon → Create/view conversations
- [ ] **Settings**: Change language (en, sw, fr, es) → Theme toggle

### Chat Features (Real-Time Polling)
- [ ] Create new conversation (Subject, Category, Priority)
- [ ] Send message → appears immediately
- [ ] Wait 3 seconds → new agent response appears
- [ ] Messages marked as read automatically
- [ ] Unread count updates
- [ ] Close conversation (marks resolved)

### Multi-Language Support
- [ ] Settings → Language selector
- [ ] Select "Swahili" → UI changes to Kiswahili
- [ ] Select "French" → UI changes to French
- [ ] Select "Spanish" → UI changes to Español
- [ ] Select "English" → back to English
- [ ] Language persists after app restart

### Performance
- [ ] App loads in < 3 seconds
- [ ] Database queries fast (indexes applied)
- [ ] Chat polling smooth (3 sec intervals)
- [ ] No memory leaks
- [ ] Battery impact minimal

## Build Outputs

### APK (Android)

```bash
# Debug APK
flutter build apk --debug
# Output: build/app/outputs/apk/debug/app-debug.apk

# Release APK
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# Install on device
flutter install
```

### App Bundle (Android Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS App Store Package

See iOS_DEPLOYMENT_GUIDE.md

## Console Debugging

### View Logs

```bash
# Real-time logs from device
flutter logs

# Filter by tag
flutter logs | grep "[ApiClient]"
# Shows auth token logs

flutter logs | grep "[ChatService]"
# Shows chat service logs
```

### Example Logs to Expect After Login

```
[ApiClient] Added auth token for /api/user/zones/
[ApiClient] Added auth token for /api/user/vehicles/
[ApiClient] Added auth token for /api/user/wallet/balance/
[ChatService] Chat polling started
```

## Common Issues & Solutions

### Issue: "Unauthorized: 401" errors

**Solution**: User must login first. Tokens are stored after successful login.

```dart
// Debug: Check token storage
final token = await StorageManager().getAccessToken();
print('Token: $token');
```

### Issue: "Cannot reach localhost API"

**Solution**: Update AppConstants.baseUrl

```dart
// For Android emulator: 10.0.2.2:8000
// For iOS simulator: 127.0.0.1:8000  
// For device: Use ngrok or actual IP
static bool useNgrok = false; // Change to true for ngrok
```

### Issue: "intl package error"

**Solution**: Already fixed in pubspec.yaml (intl ^0.20.2)

```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: "Localizations not working"

**Solution**: Already fixed - abstract classes implemented correctly

```bash
flutter pub get
flutter run --no-fast-start
```

### Issue: Chat not updating in real-time

**Solution**: Polling is automatic. Check logs:

```bash
flutter logs | grep "ChatService"
# Should show: "Chat polling started" message every 3 seconds
```

## Build Performance

### Incremental Builds
- First build: 3-5 minutes (slower)
- Rebuilds: 30-60 seconds

### Profile Build
```bash
flutter build apk --profile
# Similar performance to release, with profiling info
```

### Release Build
```bash
flutter build apk --release
# Optimized, minified, ready for distribution
# ~ 2-3 MB file size
```

## Testing on Real Devices

### Setup Test User

```bash
# Create test user via Django admin
python manage.py createsuperuser

# Or register via app:
# Phone: +254712345678
# Password: TestPass123!
# Email: test@example.com
```

### Test Scenarios

1. **Fresh Install**
   - Uninstall previous builds: `flutter uninstall`
   - `flutter run` → Full build
   - Login → Home screen

2. **Update**
   - `flutter run` → Hot reload
   - Changes appear without rebuilding

3. **On Device with Poor Connection**
   - Use airplane mode → WiFi
   - Chat polling handles disconnections gracefully
   - Offline messages queue automatically

## Deployment Checklist

Before submitting to app stores:

- [ ] All tests pass
- [ ] No console errors or warnings
- [ ] App icon properly configured
- [ ] Splash screen ready
- [ ] Version number bumped (pubspec.yaml)
- [ ] Privacy Policy reviewed
- [ ] Terms of Service reviewed
- [ ] API endpoints point to production
- [ ] Logging disabled/minimized
- [ ] Performance optimized

## Next Steps

1. **For Android**: Build release APK → Upload to Google Play Store
2. **For iOS**: Follow iOS_DEPLOYMENT_GUIDE.md
3. **Backend**: Ensure Django API is deployed on production
4. **Database**: Run migrations on production database
5. **Monitoring**: Set up error tracking (Sentry, Firebase Crashlytics)

## References

- Flutter Docs: https://flutter.dev/docs
- Deployment: https://flutter.dev/docs/deployment
- Performance: https://flutter.dev/docs/perf/rendering
- Testing: https://flutter.dev/docs/testing
