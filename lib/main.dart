import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: AuthStore.isLoggedIn
          ? (AuthStore.isDriver ? const DriverHomeScreen() : const HomeScreen())
          : const LoginScreen(),
    );
  }
}
