import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseReady = false;
  String? firebaseError;

  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseReady = true;
    } catch (e) {
      firebaseError = e.toString();
    }
  } else {
    // Development / Demo Mode active for instant previewing
    isFirebaseReady = true;
  }

  runApp(
    ChatFlowApp(
      isFirebaseReady: isFirebaseReady,
      firebaseError: firebaseError,
    ),
  );
}

/// Root Application Widget
class ChatFlowApp extends StatelessWidget {
  final bool isFirebaseReady;
  final String? firebaseError;

  const ChatFlowApp({
    super.key,
    required this.isFirebaseReady,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseReady) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: FirebaseSetupGuideScreen(error: firebaseError),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Configure notification tap navigation callback
          NotificationService.onChatNotificationTap = (roomId) {
            // Can be used to push ChatRoomScreen if required
          };

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: authProvider.themeMode,
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}

/// Informational guide shown if Firebase configuration is missing or throws at startup
class FirebaseSetupGuideScreen extends StatelessWidget {
  final String? error;

  const FirebaseSetupGuideScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppConstants.appSubtitle,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.electrical_services_rounded, color: AppConstants.primaryColor),
                            SizedBox(width: 10),
                            Text(
                              'Firebase Setup Required',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To connect ChatFlow to your real Firebase project, execute the following commands in the project folder:',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        _buildCodeSnippet(
                          context,
                          '1. npm install -g firebase-tools\n'
                          '2. firebase login\n'
                          '3. dart pub global activate flutterfire_cli\n'
                          '4. flutterfire configure',
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Status: $error',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.errorColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    main();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeSnippet(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
