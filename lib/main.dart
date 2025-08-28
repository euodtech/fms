import 'package:flutter/material.dart';
import 'package:fms/core/theme/app_theme.dart';
import 'package:fms/page/auth/presentation/login_page.dart';
import 'package:fms/core/constants/variables.dart';
import 'package:fms/nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-FMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  Future<bool> _hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Variables.prefApiKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasToken = snapshot.data == true;
        return hasToken ? const NavBar() : const LoginPage();
      },
    );
  }
}
