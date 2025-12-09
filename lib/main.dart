import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/bienvenida.dart';
import 'screens/login.dart';

// Notificaciones cuando la app está en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Notificación en segundo plano: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Notificaciones cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📣 Notificación primer plano: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 App abierta desde notificación");
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Préstamos e Inventario',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const BienvenidaScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
