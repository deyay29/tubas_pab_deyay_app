import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../route/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  String? error;

  Future<void> loginWithGoogle() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          isLoading = false;
          error = 'Login dibatalkan oleh pengguna';
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();

        // Jika user belum ada di Firestore, buat data baru
        if (!docSnapshot.exists) {
          await userDoc.set({
            'name': user.displayName ?? '',
            'email': user.email,
            'role': 'Mahasiswa', // default role
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final prefs = await SharedPreferences.getInstance();
        final idToken = await user.getIdToken();
        await prefs.setString('access_token', idToken!);

        // Ambil role untuk navigasi
        final doc = await userDoc.get();
        final role = doc.data()?['role'] ?? 'Mahasiswa';

        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, Routes.admin);
        } else if (role == 'Dosen') {
          Navigator.pushReplacementNamed(context, Routes.dosen);
        } else {
          Navigator.pushReplacementNamed(context, Routes.mahasiswa);
        }
      }
    } catch (e) {
      setState(() {
        error = 'Login Google gagal: ${e.toString()}';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login, size: 80, color: theme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Silakan masuk menggunakan akun Google Anda',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon:
                      isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Icon(Icons.account_circle),
                  label: Text(
                    isLoading ? 'Sedang masuk...' : 'Login dengan Google',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: isLoading ? null : loginWithGoogle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
