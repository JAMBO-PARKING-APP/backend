import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parking_user_app/features/splash/screens/version_check_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/parking/providers/violation_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/auth/screens/welcome_screen.dart';
import 'package:parking_user_app/features/auth/screens/splash_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/auth/screens/permissions_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parking_user_app/core/fcm_service.dart';
import 'package:parking_user_app/core/notification_dialog_service.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/rewards/providers/rewards_provider.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/core/services/local_notification_service.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ViolationProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider(ApiClient())),
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
          title: 'Spave Park',
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
                return const SplashScreen();
              }

              // 2. Once initialized, check for app health and auth status
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
                  if (!auth.hasRequestedPermissions) {
                    return const PermissionsScreen();
                  }
                  return const WelcomeScreen();
                case AuthStatus.initial:
                case AuthStatus.authenticating:
                  // This should ideally not be reached after isInitialLoadComplete
                  // but we keep it for safety during transitions.
                  return const SplashScreen();
              }
            },
          ),
        );
      },
    );
  }
}
