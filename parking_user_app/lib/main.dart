import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/country_payment_config_provider.dart';
import 'package:parking_user_app/core/fcm_service.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/core/providers/connectivity_provider.dart';
import 'package:parking_user_app/core/settings_provider.dart';
import 'package:parking_user_app/core/system_config_service.dart';
import 'package:parking_user_app/core/websocket_service.dart';
import 'package:parking_user_app/core/widgets/network_error_widget.dart';
import 'package:parking_user_app/features/app/screens/app_shell_screen.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/auth/screens/login_screen.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/parking/providers/country_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_session_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/settings/screens/force_update_screen.dart';
import 'package:parking_user_app/features/settings/screens/language_selection_screen.dart';
import 'package:parking_user_app/features/payments/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
  } catch (_) {}
  await FCMService().initialize().catchError((_) {});

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => CountryProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => ParkingSessionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CountryPaymentConfigProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const SpaceUserApp(),
    ),
  );
}

class SpaceUserApp extends StatelessWidget {
  const SpaceUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'SPACE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.officerTheme,
          locale: settings.currentLocale,
          supportedLocales: settings.supportedLocales,
          localizationsDelegates: const [
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
  bool _updateChecked = false;
  bool _updateRequired = false;

  Future<void> _checkForUpdate() async {
    try {
      final config = await SystemConfigService().fetchSystemConfig();
      
      const currentVersion = '1.0.0';
      bool needsUpdate = config.forceUpdate;
      
      if (!needsUpdate && config.minVersion.isNotEmpty) {
        // App is outdated if minVersion from backend is alphanumerically greater than current
        if (config.minVersion.compareTo(currentVersion) > 0) {
          needsUpdate = true;
        }
      }

      setState(() {
        _updateRequired = config.maintenanceMode || needsUpdate;
        _updateChecked = true;
      });
    } catch (_) {
      setState(() => _updateChecked = true);
    }
  }

  bool _isLanguageValid(Locale? locale) {
    if (locale == null) return false;
    return const ['en', 'fr', 'de', 'sw', 'es', 'ar'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!settings.hasSelectedLanguage || !_isLanguageValid(settings.currentLocale)) {
      return const LanguageSelectionScreen();
    }

    if (!_updateChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_updateRequired) {
      return const ForceUpdateScreen();
    }

    return const AuthWrapper();
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

class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell();

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountryPaymentConfigProvider>().loadConfig('');
      WebSocketService().connect();
      LocationService().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppShellScreen();
  }
}
