import 'package:flutter/material.dart';
import 'theme.dart';
import 'ui/auth/login_page.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding
  
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); // Initialize Firebase
    await NotificationService().initialize(); // Initialize Notifications
  } catch (e, stackTrace) {
    print('ERROR IN MAIN INITIALIZATION: $e');
    print(stackTrace);
  }
  
  runApp(const SekuritiV2App());
}

class SekuritiV2App extends StatelessWidget {
  const SekuritiV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}