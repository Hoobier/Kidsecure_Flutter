import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'core/constants/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('FCM permission status: ${settings.authorizationStatus}');

  final token = await messaging.getToken();
  debugPrint('FCM TOKEN: $token');

  final databaseUrl = DefaultFirebaseOptions.currentPlatform.databaseURL;
  if (databaseUrl != null && databaseUrl.isNotEmpty) {
    FirebaseDatabase.instance.databaseURL = databaseUrl;
  }

  runApp(const KidSecureApp());
}

class KidSecureApp extends StatelessWidget {
  const KidSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KidSecure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
