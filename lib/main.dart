import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    firebaseInitialized = false;
  }
  
  // Initialize services
  await NotificationService().init();
  
  runApp(
    ProviderScope(
      child: MyApp(isFirebaseAvailable: firebaseInitialized),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isFirebaseAvailable;
  const MyApp({super.key, required this.isFirebaseAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    if (!isFirebaseAvailable) {
      return MaterialApp(
        title: 'Obsidian AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Obsidian AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, st) => const LoginScreen(), // Fallback
      ),
    );
  }
}
