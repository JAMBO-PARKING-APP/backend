import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/location_service.dart';
import 'package:parking_officer_app/core/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/fcm_service.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_officer_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_officer_app/features/auth/screens/login_screen.dart';
import 'package:parking_officer_app/features/settings/screens/language_selection_screen.dart';
import 'package:parking_officer_app/features/settings/screens/force_update_screen.dart';
import 'package:parking_officer_app/core/system_config_service.dart';
import 'package:parking_officer_app/core/constants.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/screens/user_dashboard_screen.dart';
import 'package:parking_officer_app/core/settings_provider.dart';
import 'package:parking_officer_app/core/country_payment_config_provider.dart';
import 'package:parking_officer_app/core/localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parking_officer_app/core/providers/connectivity_provider.dart';
import 'package:parking_officer_app/core/widgets/network_error_widget.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Main] WidgetsFlutterBinding initialized');

    // Initialize Firebase first (mandatory for Firebase services)
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[Main] Firebase initialization timed out');
        throw Exception('Firebase initialization timed out');
      },
    );

    unawaited(
      FCMService().initialize().catchError((e) {
        debugPrint('[Main] Error initializing FCM: $e');
      }),
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ZoneProvider()),
          ChangeNotifierProvider(create: (_) => VehicleProvider()),
          ChangeNotifierProvider(create: (_) => ReservationProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CountryPaymentConfigProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ],
        child: const SpaceUserApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('[Main] FATAL ERROR: $e');
    debugPrint(stack.toString());
    // Fallback if something fails before runApp
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error starting app: $e'))),
      ),
    );
  }
}

void unawaited(Future<void> future) {}

class SpaceUserApp extends StatelessWidget {
  const SpaceUserApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SPACE',
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
          home: const AppBootstrapper(),
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, _) {
                    if (connectivity.isOffline) {
                      return const NetworkErrorWidget();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _checkingUpdate = false;
  bool _updateChecked = false;
  bool _updateRequired = false;
  Map<String, dynamic>? _systemConfig;

  bool _isLanguageValid(Locale? locale) {
    if (locale == null) return false;
    return const ['en', 'fr', 'de'].contains(locale.languageCode);
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    try {
      final config = await SystemConfigService().fetchSystemConfig();
      final forceUpdate = config['force_update'] == true;
      final minAndroid = config['min_android_version']?.toString();

      // Wording: show update screen when API version doesn't match current version.
      final current = AppConstants.appVersion;
      final requiredVersion = minAndroid;

      final required = forceUpdate ||
          (requiredVersion != null &&
              requiredVersion.isNotEmpty &&
              current != requiredVersion);

      setState(() {
        _systemConfig = config;
        _updateRequired = required;
        _updateChecked = true;
      });
    } catch (e) {
      // If the config call fails, don't block login.
      setState(() {
        _updateRequired = false;
        _updateChecked = true;
      });
    } finally {
      setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLanguageValid(settings.currentLocale)) {
      return const LanguageSelectionScreen();
    }

    if (!_updateChecked && !_checkingUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }

    if (!_updateChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_updateRequired) {
      return ForceUpdateScreen(
        systemConfig: _systemConfig ?? const {},
      );
    }

    return const AuthWrapper();
  }
}

/// Loads country + payment gateway metadata once after login (Django admin driven).
class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell();

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountryPaymentConfigProvider>().refresh();
      
      // Initialize real-time location tracking services
      WebSocketService().connect();
      LocationService().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const UserDashboardScreen();
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
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.authenticating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.status == AuthStatus.authenticated) {
      return const _AuthenticatedShell();
    }

    return const LoginScreen();
  }
}
