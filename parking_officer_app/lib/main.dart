import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/fcm_service.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/features/auth/screens/login_screen.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/providers/vehicle_search_provider.dart';
import 'package:parking_officer_app/features/parking/screens/dashboard_screen.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/features/chat/providers/chat_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Main] WidgetsFlutterBinding initialized');

    // Initialize FCM for push notifications without blocking runApp
    // This prevents the black screen issue if Firebase hangs
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
          ChangeNotifierProvider(create: (_) => OfficerProvider()),
          ChangeNotifierProvider(create: (_) => VehicleSearchProvider()),
          ChangeNotifierProvider(create: (_) => EnforcementProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const JamboOfficerApp(),
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

// Helper to make unawaited calls explicit
void unawaited(Future<void> future) {}

class JamboOfficerApp extends StatelessWidget {
  const JamboOfficerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jambo Officer',
      theme: AppTheme.officerTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
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
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
