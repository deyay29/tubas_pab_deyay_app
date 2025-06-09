import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../route/routes.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!doc.exists || doc.data()?['role'] != 'Admin') {
      _redirectToLogin();
      return;
    }

    setState(() {
      isAdmin = true;
      isLoading = false;
    });
  }

  void _redirectToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await FirebaseAuth.instance.signOut();

    _redirectToLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('Akses ditolak')));
    }

    final cards = [
      _DashboardItem(
        'Daftar Dosen',
        Icons.person,
        Routes.daftarDosen,
        Colors.deepPurple,
      ),
      _DashboardItem(
        'Daftar Mahasiswa',
        Icons.school,
        Routes.daftarMahasiswa,
        Colors.teal,
      ),
      _DashboardItem(
        'Daftar Kelas',
        Icons.class_,
        Routes.daftarKelas,
        Colors.indigo,
      ),
      _DashboardItem(
        'Daftar Matkul',
        Icons.book,
        Routes.daftarMatkul,
        Colors.orange,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ), // bottom padding untuk cegah overflow
          child: GridView.builder(
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4 / 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, i) => _DashboardCard(item: cards[i]),
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  _DashboardItem(this.title, this.icon, this.route, this.color);
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;
  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: item.color.withOpacity(0.1),
                radius: 30,
                child: Icon(item.icon, size: 32, color: item.color),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
