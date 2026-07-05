import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _role = '';
  bool _isLoading = true;
  bool _emailVerified = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();
    _emailVerified = user.emailVerified;
    _emailController.text = user.email ?? '';

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _role = data['role'] ?? '';
      _photoUrl = data['photoUrl'];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newEmail = _emailController.text.trim();
    if (newEmail != user.email) {
      try {
        await user.updateEmail(newEmail);
        await user.sendEmailVerification();
        _emailVerified = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-posta güncellendi. Lütfen doğrulayın.")),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("E-posta hatası: ${e.message}")),
        );
        return;
      }
    }

    await _firestore.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      if (_photoUrl != null) 'photoUrl': _photoUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil güncellendi ✅")),
    );
  }

  Future<void> _sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doğrulama e-postası gönderildi.")),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        print("❌ Fotoğraf seçilmedi.");
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      print("📂 Dosya seçildi, bayt boyutu: ${bytes.length}");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ Kullanıcı giriş yapmamış.");
        return;
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      print("🚀 Fotoğraf yükleniyor...");
      await ref.putData(bytes);
      print("✅ Yükleme tamamlandı.");

      final downloadUrl = await ref.getDownloadURL();
      print("🌐 URL alındı: $downloadUrl");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fotoğraf yüklendi ✅")),
      );
    } catch (e) {
      print("❌ Yükleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yükleme hatası: $e")),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : const AssetImage("assets/avatar_placeholder.png") as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Ad Soyad",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Telefon",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "E-posta",
                prefixIcon: const Icon(Icons.email),
                suffixIcon: _emailVerified
                    ? const Icon(Icons.verified, color: Colors.green)
                    : IconButton(
                  icon: const Icon(Icons.verified_outlined, color: Colors.red),
                  onPressed: _sendEmailVerification,
                ),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            Card(
              margin: const EdgeInsets.only(top: 12),
              color: Colors.grey[100],
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text("Rol"),
                subtitle: Text(_role),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Profili Kaydet"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _updateUserData,
            ),
          ],
        ),
      ),
    );
  }
}
