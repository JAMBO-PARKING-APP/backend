# Quick Start Guide - Running New Features

This guide walks you through deploying and testing the new features in your Jambo Parking app.

---

## 🚀 Step 1: Backend Deployment (5 minutes)

### No Python code changes needed! ✅
All backend endpoints are already integrated into:
- `apps/accounts/urls.py` (updated)
- `apps/accounts/location_and_features_views.py` (new)
- `apps/accounts/notification_views.py` (new)

### Just deploy:
```bash
# From backend directory
cd backend

# Ensure requirements installed
pip install -r requirements/production.txt

# Run migrations (if any model changes)
python manage.py migrate

# Test endpoints
curl http://localhost:8000/api/user/location/
curl http://localhost:8000/api/user/reservations/
curl http://localhost:8000/api/host/dashboard/
```

---

## 📱 Step 2: Flutter Integration (10 minutes)

### Update pubspec.yaml dependencies:
```bash
cd parking_user_app
flutter pub get  # Installs geocoding package
```

### Update main.dart - Add providers to MultiProvider:

Find your `MultiProvider` widget and add these:

```dart
import 'package:parking_user/features/location/services/location_service.dart';
import 'package:parking_user/features/location/providers/location_provider.dart';
import 'package:parking_user/features/reservations/providers/reservation_provider.dart';
import 'package:parking_user/features/profile/providers/profile_provider.dart';
import 'package:parking_user/features/host_parking/providers/host_provider.dart';

// Inside MultiProvider providers list:
MultiProvider(
  providers: [
    // ... your existing providers ...
    
    // NEW: Location Service & Provider
    ChangeNotifierProvider(
      create: (_) => LocationService(),
    ),
    ChangeNotifierProvider(
      create: (context) => LocationProvider(
        apiClient: context.read<ApiClient>(),
        locationService: context.read<LocationService>(),
      ),
    ),
    
    // NEW: Reservations Provider
    ChangeNotifierProvider(
      create: (context) => ReservationProvider(
        apiClient: context.read<ApiClient>(),
      ),
    ),
    
    // NEW: Profile Provider
    ChangeNotifierProvider(
      create: (context) => ProfileProvider(
        apiClient: context.read<ApiClient>(),
        getCurrentUser: () => context.read<AuthProvider>().user ?? UserModel.empty(),
      ),
    ),
    
    // NEW: Host Provider
    ChangeNotifierProvider(
      create: (context) => HostProvider(
        apiClient: context.read<ApiClient>(),
      ),
    ),
  ],
  child: const MyApp(),
),
```

### Add Routes in your router:

```dart
// In your route definitions
routes: {
  '/': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/host-parking': (context) => const HostParkingScreen(),
},
```

### Update HomeScreen Navigation:

Add buttons to HomeScreen to navigate to new features:

```dart
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/profile'),
  tooltip: 'Profile',
  child: const Icon(Icons.person),
),

// Or in AppBar actions:
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.person),
      onPressed: () => Navigator.pushNamed(context, '/profile'),
    ),
    // Check if host
    Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isHost = authProvider.user?.role == 'parking_owner' || 
                       authProvider.user?.role == 'host';
        if (isHost) {
          return IconButton(
            icon: const Icon(Icons.business),
            onPressed: () => Navigator.pushNamed(context, '/host-parking'),
          );
        }
        return const SizedBox();
      },
    ),
  ],
),
```

### Initialize Location in AuthProvider or login callback:

```dart
// After successful login
Future<void> _handleLoginSuccess() {
  // ... existing login success code ...
  
  // NEW: Initialize location
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      final locationProvider = context.read<LocationProvider>();
      
      // Initialize location service
      locationProvider.initialize();
      
      // Start tracking (optional - user can control)
      locationProvider.startTracking();
      
      // Auto-detect country
      locationProvider.detectCountry();
    }
  });
}
```

---

## 🔐 Step 3: Android & iOS Permissions

### Android (android/app/src/main/AndroidManifest.xml):

```xml
<manifest ..>
    <!-- Add location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <application ..>
        <!-- Your app config -->
    </application>
</manifest>
```

### iOS (ios/Runner/Info.plist):

```xml
<dict>
    <!-- Add at appropriate location in Info.plist -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Jambo Parking needs your location to show nearby parking zones</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Jambo Parking uses your location for background parking tracking</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Jambo Parking uses your location for parking features</string>
</dict>
```

---

## 🧪 Step 4: Testing

### Test Locations with Emulator:

#### Android Emulator:
```
# In Android Studio > Extended Controls > Location
Set latitude: 0.3476, longitude: 32.5825 (Uganda)
```

#### iOS Simulator:
```
# In Xcode > Debug > Simulate Location
Select "Apple Park" or enter coordinates
```

### Test Each Feature:

#### 1. Location Tracking
```
✅ Check: LocationProvider.currentLocation is not null
✅ Check: LocationProvider.currentCountry shows "Uganda"
✅ Check: Backend /api/user/location/ returns your coordinates
```

#### 2. Country Detection
```
✅ Verify: CountryModel displays correct flag emoji and name
✅ Test: Move to different region, country should auto-update
✅ Test: Manually change country, should persist
```

#### 3. Profile Page
```
✅ Navigate to /profile
✅ Check: All 5 tabs appear (Overview, Notifications, Reservations, Support, Settings)
✅ Edit profile: Change first name, save
✅ Verify: Changes reflected in backend database
✅ Check: Profile picture upload button works
```

#### 4. Reservations
```
✅ Navigate to /profile > Reservations tab
✅ Verify: All user's reservations listed
✅ Check: Status colors correct (pending=orange, active=green, etc.)
✅ Test: Click reservation to see details
✅ Test: Cancel button works (if cancelable)
✅ Verify: Backend shows reservation as cancelled
```

#### 5. Host Dashboard (if you have host user)
```
✅ Create test user with role='parking_owner'
✅ Navigate to /host-parking
✅ Verify: Dashboard loads with metrics
✅ Check: Revenue, bookings, zones count display
✅ Test: Edit zone settings
✅ Verify: Changes saved to backend
```

---

## 🐛 Troubleshooting

### Location not updating
```
Problem: LocationProvider.currentLocation is always null
Solution:
  1. Check Android/iOS permissions granted
  2. Check device has GPS enabled  
  3. Check `print()` debug statements show "✅ Current position"
  4. Verify backend receives POST /api/user/location/ calls
```

### Country not detected
```
Problem: currentCountry is null even after initialize()
Solution:
  1. Check current location is available first
  2. Check coordinates are in supported region (UG, KE, TZ, RW)
  3. Check backend log shows "🌍 Detected country"
  4. Use manual country selection as fallback
```

### Profile page not loading
```
Problem: ProfileScreen shows loading spinner forever
Solution:
  1. Check ProfileProvider.error for message
  2. Verify backend /api/user/profile/ returns 200
  3. Check user's country_details in response
  4. Check AuthProvider has valid token
```

### Reservations list empty
```
Problem: No reservations showing even after API call
Solution:
  1. Check user has reservations in database
  2. Verify backend /api/user/reservations/ returns data
  3. Check ReservationModel.fromJson() debug output
  4. Verify status field maps correctly (pending, active, etc.)
```

### Host dashboard access denied
```
Problem: 403 error when accessing /host-parking
Solution:
  1. Check user.role is 'parking_owner' or 'host'
  2. Verify user has created zones in database
  3. Check backend HostParkingDashboardAPIView permission check
  4. Review HostProvider.error message
```

---

## 📊 Debug Logging

All components log with emoji prefixes for easy scanning:

| Prefix | Meaning | Example |
|--------|---------|---------|
| ✅ | Success | ✅ Location updated on server |
| ❌ | Error | ❌ Failed to get current location |
| ⚠️ | Warning | ⚠️ Location tracking already active |
| 🚨 | Critical | 🚨 Session invalidated |
| 📌 | Info | 📌 Location: 0.34, 32.58 |
| 🌍 | Country | 🌍 Detected country: Uganda |
| 🗺️ | Map | 🗺️ GPS tracking with high accuracy |
| 🎯 | Accuracy | 🎯 Accuracy: 10.5 meters |

Watch the console (print debug output) to see feature health!

---

## ✨ Feature Checklist

After integration, verify:

- [ ] Flutter dependencies installed (`flutter pub get` completes)
- [ ] All providers added to MultiProvider
- [ ] Routes added for /profile and /host-parking
- [ ] Navigation buttons added to HomeScreen
- [ ] Android permissions added to AndroidManifest.xml
- [ ] iOS permissions added to Info.plist
- [ ] LocationProvider initialized on login
- [ ] Profile screen navigates and loads data
- [ ] Reservations list shows test reservations
- [ ] Profile edit form updates backend
- [ ] Host dashboard shows for host users
- [ ] Location updates visible in backend logs

---

## 🚀 Go Live Checklist

Before production deployment:

- [ ] Test on real device (not emulator) for location
- [ ] Test with production backend API
- [ ] Verify all error messages user-friendly
- [ ] Check logging doesn't leak sensitive data
- [ ] Test on slow network (throttle in DevTools)
- [ ] Verify offline fallback works
- [ ] Test app restart preserves session
- [ ] Verify permissions work on both Android & iOS
- [ ] Load test with 100+ notifications
- [ ] Monitor backend logs for errors

---

## 📞 Support

If you encounter issues:

1. Check console for emoji-prefixed debug messages
2. Review FEATURE_INTEGRATION_GUIDE.md for detailed docs
3. Check IMPLEMENTATION_COMPLETE.md for architecture
4. Verify backend endpoints are deployed
5. Ensure tokens are valid and not expired

---

## 📚 Files to Review

Recommended review order:
1. `IMPLEMENTATION_COMPLETE.md` - Overview
2. `FEATURE_INTEGRATION_GUIDE.md` - Integration steps
3. `parking_user_app/lib/features/profile/screens/profile_screen.dart` - UI example
4. `apps/accounts/location_and_features_views.py` - Backend APIs

All code is production-ready with comprehensive error handling! 🎉

---

*Ready to go live?* 🚀
