import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:parking_user_app/features/auth/screens/login_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/auth/screens/permissions_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_user_app/core/fcm_service.dart';
import 'package:parking_user_app/core/notification_dialog_service.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/rewards/providers/rewards_provider.dart';
import 'package:parking_user_app/core/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM Service
  await FCMService().initialize();

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
          title: 'Space',
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
              switch (auth.status) {
                case AuthStatus.authenticated:
                  return const HomeScreen();
                case AuthStatus.unauthenticated:
                  if (!auth.hasRequestedPermissions) {
                    return const PermissionsScreen();
                  }
                  return const LoginScreen();
                default:
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
              }
            },
          ),
        );
      },
    );
  }
}
