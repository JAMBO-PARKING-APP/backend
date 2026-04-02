import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parking_user_app/features/splash/screens/version_check_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/rewards/providers/rewards_provider.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/auth/screens/permissions_screen.dart';
import 'package:parking_user_app/features/auth/screens/language_selection_screen.dart';
import 'package:parking_user_app/features/auth/screens/splash_screen.dart';
import 'package:parking_user_app/features/auth/screens/welcome_screen.dart';
import 'package:parking_user_app/features/auth/screens/country_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parking_user_app/core/fcm_service.dart';
import 'package:parking_user_app/core/notification_dialog_service.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/rewards/providers/rewards_provider.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/core/services/local_notification_service.dart';

// NEW: Location tracking imports
import 'package:parking_user_app/features/location/services/location_service.dart';
import 'package:parking_user_app/features/location/providers/location_provider.dart';

// NEW: Profile management imports
import 'package:parking_user_app/features/profile/providers/profile_provider.dart';
import 'package:parking_user_app/features/profile/screens/profile_screen.dart'
    as new_profile;
import 'package:parking_user_app/features/auth/models/user_model.dart';

// NEW: Reservations management imports
import 'package:parking_user_app/features/reservations/providers/reservation_provider.dart'
    as reservations_provider;
import 'package:parking_user_app/features/reservations/screens/reservations_list_screen.dart';

// NEW: Host parking imports
import 'package:parking_user_app/features/host_parking/providers/host_provider.dart';
import 'package:parking_user_app/features/host_parking/screens/host_parking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();


  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize FCM Service (Non-blocking)
  FCMService().initialize();

  // Initialize Local Notifications
  await LocalNotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        // API Client - provide first so others can use it
        ChangeNotifierProvider(create: (_) => ApiClient()),
        
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider(PaymentService(context.read<ApiClient>()))),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => RewardsProvider(context.read<ApiClient>())),
        
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
        
        // NEW: Profile Provider
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(
            apiClient: context.read<ApiClient>(),
            getCurrentUser: () {
              try {
                return context.read<AuthProvider>().user ?? UserModel.empty();
              } catch (e) {
                return UserModel.empty();
              }
            },
          ),
        ),
        
        // NEW: Reservations Provider (from features/reservations)
        ChangeNotifierProvider(
          create: (context) => reservations_provider.ReservationProvider(
            apiClient: context.read<ApiClient>(),
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
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // Set context for notification dialogs
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationDialogService().setContext(context);
        });

        return MaterialApp(
          navigatorKey: DialogService.navigatorKey,
          title: 'SPACE',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.currentLocale,
          supportedLocales: settings.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // 1. Always show splash until initialization is explicitly marked as complete
              if (!auth.isInitialLoadComplete) {
                return SplashScreen();
              }

              switch (auth.status) {
                case AuthStatus.needsUpdate:
                  final settings = context.read<SettingsProvider>();
                  return VersionCheckScreen(
                    updateUrl: settings.systemConfig.appUpdateUrl,
                    isMandatory: settings.systemConfig.forceUpdate,
                  );
                case AuthStatus.authenticated:
                  return const HomeScreen();
                case AuthStatus.unauthenticated:
                  if (!settings.hasSelectedLanguage) {
                    return SplashScreen(); // Will show language selection
                  }
                  if (!auth.hasRequestedPermissions) {
                    return const PermissionsScreen();
                  }
                  if (!settings.hasSelectedCountry) {
                    return CountrySelectionScreen();
                  }
                  return WelcomeScreen();
                case AuthStatus.initial:
                case AuthStatus.authenticating:

                  return SplashScreen();
              }
            },
          ),
        );
      },
    );
  }
}
