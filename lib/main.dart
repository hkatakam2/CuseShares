
import 'dart:io'; // For Platform check
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart'; // Import LocationService
import 'repositories/auth_repository.dart';
import 'repositories/post_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'utils/theme_notifier.dart'; // Import ThemeNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check (Recommended for security)
   try {
     await FirebaseAppCheck.instance.activate(
       // Use reCAPTCHA v3 provider for web
       // webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), // Replace with your key
       // Use Play Integrity provider for Android
       androidProvider: AndroidProvider.playIntegrity,
       // Use App Attest provider for iOS
       appleProvider: AppleProvider.appAttest,
     );
     print('Firebase App Check activated.');
   } catch (e) {
      print('Firebase App Check activation failed: $e');
      // Handle activation failure if necessary
   }


  // Initialize Services
  final notificationService = NotificationService();
  await notificationService.initialize();
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  final locationService = LocationService(); // Create location service

  // Create Repositories
  final authRepository = AuthRepository(authService: authService);
  final postRepository = PostRepository(
    firestoreService: firestoreService,
    storageService: storageService,
    authService: authService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Provide Services
        Provider<NotificationService>.value(value: notificationService),
        Provider<LocationService>.value(value: locationService), // Provide LocationService

        // Provide Repositories
        Provider<AuthRepository>.value(value: authRepository),
        Provider<PostRepository>.value(value: postRepository),

        // Provide ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authRepository: authRepository),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(postRepository: postRepository),
        ),
        // Provide ThemeNotifier
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(),
        ),
      ],
      child: CuseApp(), // Use a new root widget
    ),
  );
}

// New root widget to handle theme and platform app type
class CuseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Consume the ThemeNotifier to rebuild when theme changes
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // Define Themes
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.orange,
      primaryColor: Colors.orange[800],
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: Colors.grey[100], // Lighter background
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        elevation: Platform.isIOS ? 0 : 4.0, // No elevation for Cupertino style
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          )
       ),
       floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: Colors.orange[700],
           foregroundColor: Colors.white,
       ),
       inputDecorationTheme: InputDecorationTheme(
           filled: true,
           fillColor: Colors.white.withOpacity(0.9),
           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
           focusedBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12.0),
               borderSide: BorderSide(color: Colors.orange[900]!, width: 2.0),
           ),
           hintStyle: TextStyle(color: Colors.grey[500]),
           contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
       ),
       chipTheme: ChipThemeData(
          backgroundColor: Colors.orange[100],
          labelStyle: TextStyle(color: Colors.orange[900]),
          secondarySelectedColor: Colors.orange[700],
          secondaryLabelStyle: TextStyle(color: Colors.white),
          selectedColor: Colors.orange[700],
       ),
       dividerColor: Colors.grey[300],
       hintColor: Colors.grey[600],
       textTheme: Typography.englishLike2021.apply(
          bodyColor: Colors.grey[800],
          displayColor: Colors.black87,
       ),
       // Add other theme properties
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.orange,
      primaryColor: Colors.orange[800], // Keep primary color consistent? Or use a darker shade?
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: Colors.grey[900], // Dark background
      cardColor: Colors.grey[850], // Slightly lighter card
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900], // Darker AppBar
        foregroundColor: Colors.orange[400], // Orange text on dark AppBar
        elevation: Platform.isIOS ? 0 : 4.0,
        titleTextStyle: TextStyle(
            color: Colors.orange[400], fontSize: 20, fontWeight: FontWeight.w500),
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700], // Keep button color vibrant
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          )
       ),
       floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: Colors.orange[700],
           foregroundColor: Colors.white,
       ),
       inputDecorationTheme: InputDecorationTheme(
           filled: true,
           fillColor: Colors.grey[800],
           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
           focusedBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12.0),
               borderSide: BorderSide(color: Colors.orange[600]!, width: 2.0),
           ),
           hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
       ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[700],
          labelStyle: TextStyle(color: Colors.white70),
          secondarySelectedColor: Colors.orange[700],
          secondaryLabelStyle: TextStyle(color: Colors.white),
           selectedColor: Colors.orange[700],
       ),
       dividerColor: Colors.grey[700],
       hintColor: Colors.grey[500],
       textTheme: Typography.englishLike2021.apply(
          bodyColor: Colors.grey[300], // Lighter body text
          displayColor: Colors.white,
       ).copyWith( // Adjust specific styles if needed
          titleMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
       ),
       // Add other dark theme properties
    );

    // Choose Material or Cupertino App based on Platform
    if (Platform.isIOS) {
      // Apply Material theme concepts to Cupertino theme data
      final CupertinoThemeData cupertinoTheme = MaterialBasedCupertinoThemeData(
          materialTheme: themeNotifier.themeMode == ThemeMode.dark ? darkTheme : lightTheme,
      );

      return CupertinoApp(
        title: 'CuseFoodShare',
        debugShowCheckedModeBanner: false,
        theme: cupertinoTheme, // Apply the generated Cupertino theme
        home: AuthWrapper(),
      );
    } else {
      // Use MaterialApp for Android and other platforms
      return MaterialApp(
        title: 'CuseFoodShare',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeNotifier.themeMode, // Control light/dark mode
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      );
    }
  }
}


// AuthWrapper remains largely the same, deciding between LoginScreen and HomeScreen
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    switch (authViewModel.status) {
      case AuthStatus.authenticated:
        return HomeScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return LoginScreen();
      case AuthStatus.authenticating:
      case AuthStatus.uninitialized:
      default:
        // Platform-aware loading indicator
        return Platform.isIOS
          ? CupertinoPageScaffold(child: Center(child: CupertinoActivityIndicator(radius: 15)))
          : Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
