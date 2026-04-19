import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/main_navigation.dart';
import 'features/auth/presentation/login_screen.dart';
import 'core/services/notification_service.dart';
import 'core/providers/providers.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';


Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase: Initialized successfully for project: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    return true;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final bool firebaseInitialized = await initializeFirebase();
  
  // Initialize other services
  await NotificationService().init();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(isFirebaseAvailable: firebaseInitialized),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isFirebaseAvailable;
  const MyApp({super.key, required this.isFirebaseAvailable});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isFirebaseAvailable;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _isFirebaseAvailable = widget.isFirebaseAvailable;
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });
    
    final result = await initializeFirebase();
    
    if (mounted) {
      setState(() {
        _isFirebaseAvailable = result;
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirebaseAvailable) {
      return MaterialApp(
        title: 'Zeno',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Connection Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not initialize connection to storage. Please check your internet or configuration.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isRetrying)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _handleRetry,
                      child: const Text('Try Again'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authStateProvider);
        final settings = ref.watch(appSettingsProvider);

        ThemeMode themeMode;
        switch (settings.themeMode) {
          case 'Light':
            themeMode = ThemeMode.light;
            break;
          case 'Dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'Zeno',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: authState.when(
            data: (user) {
              if (user != null) {
                final prefs = ref.watch(sharedPreferencesProvider);
                final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
                
                if (onboardingComplete) {
                  return const MainNavigation();
                } else {
                  return const OnboardingScreen();
                }
              }
              return const LoginScreen();
            },
            loading: () => const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.zap, size: 64, color: Colors.deepPurple),
                    SizedBox(height: 16),
                    Text(
                      'Zeno',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            error: (e, st) => const LoginScreen(), // Fallback
          ),
        );
      },
    );
  }
}
