import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'route/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    String targetRoute;

    if (token != null && role != null) {
      if (role == 'Admin') {
        targetRoute = Routes.admin;
      } else if (role == 'Dosen') {
        targetRoute = Routes.dosen;
      } else if (role == 'Mahasiswa') {
        targetRoute = Routes.mahasiswa;
      } else {
        targetRoute = Routes.login;
      }
    } else {
      targetRoute = Routes.login;
    }

    // Pindah ke halaman sesuai role dan hapus splash page dari stack
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
