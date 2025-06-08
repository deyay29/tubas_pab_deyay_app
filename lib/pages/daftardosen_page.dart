import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DaftarDosenPage extends StatefulWidget {
  const DaftarDosenPage({super.key});

  @override
  State<DaftarDosenPage> createState() => _DaftarDosenPageState();
}

class _DaftarDosenPageState extends State<DaftarDosenPage> {
  final CollectionReference usersCol = FirebaseFirestore.instance.collection(
    'users',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final nameCtrl = TextEditingController();
  final nimCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? editDocId;
  bool isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> submit() async {
    final name = nameCtrl.text.trim();
    final nim = nimCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty ||
        nim.isEmpty ||
        email.isEmpty ||
        (editDocId == null && pass.isEmpty)) {
      showMsg('Harap isi semua data yang diperlukan');
      return;
    }

    if (!_isValidEmail(email)) {
      showMsg('Format email tidak valid');
      return;
    }

    if (editDocId == null && pass.length < 6) {
      showMsg('Password minimal 6 karakter');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (editDocId == null) {
        // Tambah dosen baru
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: pass);

        await usersCol.doc(userCredential.user!.uid).set({
          'name': name,
          'nim': nim,
          'email': email,
          'role': 'Dosen',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        showMsg('Berhasil menambahkan dosen');
      } else {
        // Update data dosen
        await usersCol.doc(editDocId).update({
          'name': name,
          'nim': nim,
          'email': email,
          'updated_at': FieldValue.serverTimestamp(),
        });
        showMsg('Berhasil mengupdate dosen');
      }

      clearForm();
    } on FirebaseAuthException catch (e) {
      showMsg('Gagal: ${e.message}');
    } catch (e) {
      showMsg('Gagal submit data: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteDosen(String docId) async {
    try {
      await usersCol.doc(docId).delete();
      showMsg('Berhasil menghapus data');
      if (editDocId == docId) clearForm();
    } catch (e) {
      showMsg('Gagal menghapus data: $e');
    }
  }

  void clearForm() {
    nameCtrl.clear();
    nimCtrl.clear();
    emailCtrl.clear();
    passCtrl.clear();
    editDocId = null;
    setState(() {});
  }

  void loadForEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    nameCtrl.text = data['name'] ?? '';
    nimCtrl.text = data['nim'] ?? '';
    emailCtrl.text = data['email'] ?? '';
    passCtrl.clear(); // tidak bisa mengedit password dari sini
    editDocId = doc.id;
    setState(() {});
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Dosen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ExpansionTile(
              initiallyExpanded: editDocId != null,
              title: Text(
                editDocId == null ? 'Tambah Dosen Baru' : 'Edit Dosen',
              ),
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Dosen'),
                ),
                TextField(
                  controller: nimCtrl,
                  decoration: const InputDecoration(labelText: 'NIM'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (editDocId == null)
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submit,
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(editDocId == null ? 'Tambah' : 'Update'),
                      ),
                    ),
                    if (editDocId != null) const SizedBox(width: 10),
                    if (editDocId != null)
                      OutlinedButton(
                        onPressed: isLoading ? null : clearForm,
                        child: const Text('Batal'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    usersCol
                        .where('role', isEqualTo: 'Dosen')
                        //.orderBy('created_at') // sementara dinonaktifkan agar data muncul tanpa perlu index
                        .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada dosen'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? ''),
                          subtitle: Text('NIM: ${data['nim'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => loadForEdit(doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text('Konfirmasi'),
                                          content: const Text(
                                            'Yakin ingin menghapus dosen ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                deleteDosen(doc.id);
                                              },
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
