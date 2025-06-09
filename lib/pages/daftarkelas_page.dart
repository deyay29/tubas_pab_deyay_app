import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DaftarKelasPage extends StatefulWidget {
  const DaftarKelasPage({super.key});

  @override
  State<DaftarKelasPage> createState() => _DaftarKelasPageState();
}

class _DaftarKelasPageState extends State<DaftarKelasPage> {
  final kelasCol = FirebaseFirestore.instance.collection('kelas');
  final matkulCol = FirebaseFirestore.instance.collection('matkul');
  final usersCol = FirebaseFirestore.instance.collection('users');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final namaCtrl = TextEditingController();
  String? selectedMatkulId;
  String? selectedUserId;
  String? editId;
  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> matkulList = [];
  List<Map<String, dynamic>> usersList = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadInitialData();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'kelas_channel_id',
          'Kelas Notifications',
          channelDescription: 'Notifikasi untuk aksi pada data kelas',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _loadInitialData() async {
    try {
      final matkulSnap = await matkulCol.get();
      matkulList =
          matkulSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final usersSnap = await usersCol.get();
      usersList =
          usersSnap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where(
                (user) =>
                    user['role'] == 'Dosen' || user['role'] == 'Mahasiswa',
              )
              .toList();
    } catch (e) {
      _showMessage('Gagal memuat data: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> submitKelas() async {
    final nama = namaCtrl.text.trim();
    if (nama.isEmpty || selectedMatkulId == null || selectedUserId == null) {
      _showMessage('Semua field harus diisi');
      return;
    }
    setState(() => isSubmitting = true);

    final data = {
      'nama_kelas': nama,
      'matkul_id': selectedMatkulId,
      'user_id': selectedUserId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      if (editId == null) {
        data['created_at'] = FieldValue.serverTimestamp();
        await kelasCol.add(data);
        _showMessage('Berhasil menambahkan kelas');
        await _showNotification(
          'Kelas Baru',
          'Kelas "$nama" berhasil ditambahkan',
        );
      } else {
        await kelasCol.doc(editId).update(data);
        _showMessage('Berhasil mengupdate kelas');
        await _showNotification(
          'Update Kelas',
          'Kelas "$nama" berhasil diperbarui',
        );
      }
      _clearForm();
    } catch (e) {
      _showMessage('Gagal menyimpan kelas: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> deleteKelas(String id) async {
    try {
      await kelasCol.doc(id).delete();
      _showMessage('Berhasil menghapus kelas');
      await _showNotification('Hapus Kelas', 'Kelas berhasil dihapus');
    } catch (e) {
      _showMessage('Gagal menghapus kelas: $e');
    }
  }

  void _editKelas(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    namaCtrl.text = d['nama_kelas'] ?? '';
    selectedMatkulId = d['matkul_id'];
    selectedUserId = d['user_id'];
    editId = doc.id;
    setState(() {});
  }

  void _clearForm() {
    namaCtrl.clear();
    selectedMatkulId = null;
    selectedUserId = null;
    editId = null;
    setState(() {});
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kelas')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ExpansionTile(
                        title: Text(
                          editId == null ? 'Tambah Kelas Baru' : 'Edit Kelas',
                        ),
                        children: [
                          TextField(
                            controller: namaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Kelas',
                              prefixIcon: Icon(Icons.class_),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedMatkulId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Mata Kuliah',
                              prefixIcon: Icon(Icons.book),
                            ),
                            items:
                                matkulList.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(item['nama_matkul'] ?? '-'),
                                  );
                                }).toList(),
                            onChanged:
                                (v) => setState(() => selectedMatkulId = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedUserId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Pengguna (Dosen/Mahasiswa)',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items:
                                usersList.map((user) {
                                  return DropdownMenuItem<String>(
                                    value: user['id'],
                                    child: Text(
                                      '${user['name']} (${user['role']})',
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (v) => setState(() => selectedUserId = v),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: Icon(editId == null ? Icons.add : Icons.save),
                            label: Text(
                              editId == null ? 'Tambah Kelas' : 'Update Kelas',
                            ),
                            onPressed: isSubmitting ? null : submitKelas,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(45),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'List Kelas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: kelasCol.orderBy('created_at').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(child: Text('Belum ada kelas'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final d = docs[i];
                              final data = d.data() as Map<String, dynamic>;

                              final matkul = matkulList.firstWhere(
                                (m) => m['id'] == data['matkul_id'],
                                orElse: () => {'nama_matkul': '-'},
                              );

                              final user = usersList.firstWhere(
                                (u) => u['id'] == data['user_id'],
                                orElse: () => {'name': '-', 'role': '-'},
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.class_,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    data['nama_kelas'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Matkul: ${matkul['nama_matkul']}'),
                                      Text(
                                        'Pengguna: ${user['name']} (${user['role']})',
                                      ),
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
                                        onPressed: () => _editKelas(d),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => deleteKelas(d.id),
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
    );
  }
}
