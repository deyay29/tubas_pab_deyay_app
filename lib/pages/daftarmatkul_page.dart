import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DaftarMatkulPage extends StatefulWidget {
  const DaftarMatkulPage({super.key});

  @override
  State<DaftarMatkulPage> createState() => _DaftarMatkulPageState();
}

class _DaftarMatkulPageState extends State<DaftarMatkulPage> {
  List<DocumentSnapshot> matkulList = [];
  bool isLoading = true;

  final TextEditingController namaMatkulController = TextEditingController();
  String? editDocId;

  // Inisialisasi FlutterLocalNotificationsPlugin
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    fetchMatkul();
  }

  Future<void> fetchMatkul() async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('matkul').get();

      setState(() {
        matkulList = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('Gagal memuat data mata kuliah: $e');
    }
  }

  Future<void> submitMatkul() async {
    final namaMatkul = namaMatkulController.text.trim();
    if (namaMatkul.isEmpty) {
      _showMessage('Nama mata kuliah wajib diisi');
      return;
    }

    try {
      if (editDocId == null) {
        // Tambah data baru
        await FirebaseFirestore.instance.collection('matkul').add({
          'nama_matkul': namaMatkul,
        });
        _showNotification('Berhasil', 'Mata kuliah baru berhasil ditambahkan');
      } else {
        // Update data
        await FirebaseFirestore.instance
            .collection('matkul')
            .doc(editDocId)
            .update({'nama_matkul': namaMatkul});
        _showNotification('Berhasil', 'Data mata kuliah berhasil diupdate');
      }

      namaMatkulController.clear();
      editDocId = null;
      fetchMatkul();
      _showMessage('Berhasil menyimpan data mata kuliah');
    } catch (e) {
      _showMessage('Gagal menyimpan data mata kuliah: $e');
    }
  }

  Future<void> deleteMatkul(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('matkul').doc(docId).delete();
      fetchMatkul();
      _showNotification('Berhasil', 'Data mata kuliah berhasil dihapus');
      _showMessage('Berhasil menghapus data mata kuliah');
    } catch (e) {
      _showMessage('Gagal menghapus data mata kuliah: $e');
    }
  }

  void _editMatkul(DocumentSnapshot doc) {
    setState(() {
      namaMatkulController.text = doc['nama_matkul'] ?? '';
      editDocId = doc.id;
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Fungsi untuk menampilkan notifikasi lokal
  Future<void> _showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'matkul_channel', // channel id
      'Mata Kuliah Notifications', // channel name
      channelDescription: 'Notifikasi untuk operasi mata kuliah',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mata Kuliah'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        editDocId == null
                            ? 'Tambah Mata Kuliah Baru'
                            : 'Edit Mata Kuliah',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: namaMatkulController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Mata Kuliah',
                                  prefixIcon: Icon(Icons.book),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: submitMatkul,
                                icon: Icon(
                                  editDocId == null ? Icons.add : Icons.save,
                                ),
                                label: Text(
                                  editDocId == null
                                      ? 'Tambah Matkul'
                                      : 'Update Matkul',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'List Mata Kuliah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matkulList.length,
                      itemBuilder: (context, index) {
                        final doc = matkulList[index];
                        final matkul = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
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
                            leading: const Icon(
                              Icons.book,
                              color: Colors.green,
                            ),
                            title: Text(
                              matkul['nama_matkul'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _editMatkul(doc),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteMatkul(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
