import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DaftarMahasiswaPage extends StatefulWidget {
  const DaftarMahasiswaPage({super.key});

  @override
  State<DaftarMahasiswaPage> createState() => _DaftarMahasiswaPageState();
}

class _DaftarMahasiswaPageState extends State<DaftarMahasiswaPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? editDocId;
  bool isLoading = false;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Flutter Local Notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          // Jika perlu untuk iOS, tambahkan iOSInitializationSettings di sini
        );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bisa handle tap notifikasi di sini jika perlu
      },
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'mahasiswa_channel', // channel id
          'Mahasiswa Notifications', // channel name
          channelDescription: 'Notifikasi untuk aksi mahasiswa',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // id notifikasi, bisa diganti jadi unik jika mau multiple notif
      title,
      body,
      platformChannelSpecifics,
      payload: 'data', // optional
    );
  }

  Future<void> fetchAndSetMahasiswa() async {
    // Kosong karena StreamBuilder sudah realtime
  }

  Future<void> submitMahasiswa() async {
    final name = nameController.text.trim();
    final nim = nimController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty ||
        nim.isEmpty ||
        email.isEmpty ||
        (editDocId == null && password.isEmpty)) {
      _showMessage('Harap isi semua data');
      return;
    }

    try {
      setState(() => isLoading = true);

      if (editDocId == null) {
        // Buat user baru di Firebase Auth
        UserCredential userCredential = await auth
            .createUserWithEmailAndPassword(email: email, password: password);

        // Simpan data user ke Firestore dengan role 'Mahasiswa'
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'nim': nim,
          'email': email,
          'role': 'Mahasiswa',
          'created_at': FieldValue.serverTimestamp(),
        });

        _showMessage('Berhasil menambah mahasiswa baru dan membuat akun.');
        await showNotification('Sukses', 'Mahasiswa baru berhasil ditambahkan');
      } else {
        // Update data mahasiswa di Firestore (email dan password Firebase Auth tidak diupdate di sini)
        await firestore.collection('users').doc(editDocId).update({
          'name': name,
          'nim': nim,
          'email': email,
        });

        _showMessage('Berhasil mengupdate data mahasiswa');
        await showNotification('Sukses', 'Data mahasiswa berhasil diperbarui');
      }

      _clearForm();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showMessage('Email sudah terdaftar');
      } else if (e.code == 'weak-password') {
        _showMessage('Password terlalu lemah');
      } else {
        _showMessage('Gagal membuat akun: ${e.message}');
      }
    } catch (e) {
      _showMessage('Gagal menyimpan data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteMahasiswa(String docId) async {
    try {
      setState(() => isLoading = true);

      // Hapus data user di Firestore
      await firestore.collection('users').doc(docId).delete();

      // Note: Untuk hapus user dari Firebase Auth, harus pakai Admin SDK (tidak bisa dari client)

      _showMessage('Berhasil menghapus data');
      await showNotification('Sukses', 'Data mahasiswa berhasil dihapus');
    } catch (e) {
      _showMessage('Gagal menghapus data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editMahasiswa(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      nameController.text = data['name'] ?? '';
      nimController.text = data['nim'] ?? '';
      emailController.text = data['email'] ?? '';
      passwordController.clear();
      editDocId = doc.id;
    });
  }

  void _clearForm() {
    setState(() {
      nameController.clear();
      nimController.clear();
      emailController.clear();
      passwordController.clear();
      editDocId = null;
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mahasiswa (Firebase)'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : submitMahasiswa,
        label: Text(
          editDocId == null ? 'Tambah Mahasiswa' : 'Update',
          style: const TextStyle(color: Colors.white),
        ),
        icon: Icon(
          editDocId == null ? Icons.add : Icons.save,
          color: Colors.white,
        ),
        backgroundColor: Colors.green,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchAndSetMahasiswa,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpansionTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            editDocId == null
                                ? 'Tambah Mahasiswa Baru'
                                : 'Edit Mahasiswa',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Mahasiswa',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: nimController,
                                    decoration: const InputDecoration(
                                      labelText: 'NIM',
                                      prefixIcon: Icon(Icons.badge),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText:
                                          editDocId == null
                                              ? 'Password'
                                              : 'Password (Kosongkan jika tidak diubah)',
                                      prefixIcon: const Icon(Icons.lock),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Daftar Mahasiswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              firestore
                                  .collection('users')
                                  .where('role', isEqualTo: 'Mahasiswa')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('Belum ada data mahasiswa'),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.shade100,
                                      child: Text(
                                        (data['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?'),
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      data['name'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('NIM: ${data['nim'] ?? '-'}'),
                                        Text('Email: ${data['email'] ?? '-'}'),
                                      ],
                                    ),
                                    trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () => _editMahasiswa(doc),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => deleteMahasiswa(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
