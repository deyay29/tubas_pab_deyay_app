import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DosenPage extends StatefulWidget {
  const DosenPage({super.key});

  @override
  State<DosenPage> createState() => _DosenPageState();
}

class _DosenPageState extends State<DosenPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  DateTime? _selectedDeadline;

  late Future<Map<String, dynamic>> _dosenDataFuture;

  @override
  void initState() {
    super.initState();
    _dosenDataFuture = fetchDosenData();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchDosenData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      throw Exception('Data user tidak ditemukan');
    }

    final data = doc.data()!;
    if (data['role'] != 'Dosen') {
      throw Exception('User bukan dosen');
    }

    return data;
  }

  Future<void> logoutDosen(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan logout: $e')));
    }
  }

  Future<void> kirimTugasKeLaravel({
    required String judul,
    required String deskripsi,
    required String deadline,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final uri = Uri.parse(
      'https://api-tubes-deyay.bimaryan.my.id/api/tugas',
    ); // Ganti dengan URL API kamu

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': user.uid,
        'judul': judul,
        'deskripsi': deskripsi,
        'deadline': deadline,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim tugas: ${response.body}');
    }
  }

  void _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  void _submitTugas() async {
    try {
      final judul = _judulController.text.trim();
      final deskripsi = _deskripsiController.text.trim();
      final deadline = _deadlineController.text.trim();

      if (judul.isEmpty || deadline.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul dan deadline wajib diisi')),
        );
        return;
      }

      await kirimTugasKeLaravel(
        judul: judul,
        deskripsi: deskripsi,
        deadline: deadline,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tugas berhasil dikirim')));

      _judulController.clear();
      _deskripsiController.clear();
      _deadlineController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal kirim tugas: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Dosen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutDosen(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dosenDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data user tidak ditemukan'));
          }

          final dosenData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.primaryColorLight,
                          child: Text(
                            dosenData['name'] != null &&
                                    dosenData['name'].isNotEmpty
                                ? dosenData['name'][0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 32,
                              color: theme.primaryColorDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dosenData['name'] ?? 'Dosen',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dosenData['email'] ?? '-',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${dosenData['role'] ?? '-'}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Tambah Tugas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _judulController,
                  decoration: const InputDecoration(labelText: 'Judul Tugas'),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _deadlineController,
                  readOnly: true,
                  onTap: _pilihTanggal,
                  decoration: const InputDecoration(labelText: 'Deadline'),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _submitTugas,
                  icon: const Icon(Icons.add),
                  label: const Text('Kirim Tugas'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
