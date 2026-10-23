import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_officer_app/core/analytics_service.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/fcm_service.dart';
import 'package:parking_officer_app/core/startup_permission_service.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/features/auth/screens/login_screen.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/providers/vehicle_search_provider.dart';
import 'package:parking_officer_app/features/parking/screens/dashboard_screen.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/core/settings_provider.dart';
import 'package:parking_officer_app/core/localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => OfficerProvider()),
        ChangeNotifierProvider(create: (_) => VehicleSearchProvider()),
        ChangeNotifierProvider(create: (_) => EnforcementProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const SpaceOfficerApp(),
    ),
  );

  unawaited(_initializeFirebaseServices());
}

Future<void> _initializeFirebaseServices() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    await FCMService().initialize().timeout(const Duration(seconds: 10));
  } catch (error) {
    debugPrint(
      '[Main] Firebase or push notifications are unavailable; '
      'the app will continue without them: $error',
    );
  }
}

class SpaceOfficerApp extends StatelessWidget {
  const SpaceOfficerApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: AnalyticsService.navigatorObservers,
          title: 'Space Officer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.officerTheme,
          locale: settings.currentLocale,
          supportedLocales: settings.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      await StartupPermissionService.requestOnFirstLaunch(context);
    } on PlatformException catch (error) {
      debugPrint('Startup permission setup failed: $error');
    }
    if (mounted) {
      await context.read<AuthProvider>().checkAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.authenticating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.status == AuthStatus.authenticated) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
