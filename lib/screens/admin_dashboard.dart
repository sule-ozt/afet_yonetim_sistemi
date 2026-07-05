import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _saveFcmToken(); // 🔐 Admin token'ı Firestore'a kaydedilir
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userEmail = doc.data()?['email'] ?? user.email ?? 'Admin';
      });
    }
  }

  Future<void> _saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await FirebaseMessaging.instance.getToken();
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
      print("✅ Admin fcmToken kaydedildi: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userEmail == null
            ? 'Admin Paneli'
            : 'Hoş geldiniz, $userEmail'),
        centerTitle: true,
      ),
      body: userEmail == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildDashboardItem(
            icon: Icons.people,
            label: 'Gönüllüler',
            onTap: () {
              // Gönüllü listesi varsa açılabilir
            },
          ),
          _buildDashboardItem(
            icon: Icons.warning,
            label: 'Afet Oluştur',
            onTap: () {
              Navigator.pushNamed(context, '/create-disaster');
            },
          ),
          _buildDashboardItem(
            icon: Icons.map,
            label: 'Harita',
            onTap: () {
              Navigator.pushNamed(context, '/map');
            },
          ),
          _buildDashboardItem(
            icon: Icons.notifications_active,
            label: 'Bildirim Gönder',
            onTap: () {
              Navigator.pushNamed(context, '/send-emergency');
            },
          ),
          _buildDashboardItem(
            icon: Icons.list,
            label: 'Afet Listesi',
            onTap: () {
              Navigator.pushNamed(context, '/disasters');
            },
          ),
          _buildDashboardItem(
            icon: Icons.assignment_turned_in,
            label: 'Görev Ata',
            onTap: () {
              Navigator.pushNamed(context, '/assign-task');
            },
          ),
          _buildDashboardItem(
            icon: Icons.feedback,
            label: 'Yanıtları Gör',
            onTap: () {
              Navigator.pushNamed(context, '/emergency-responses');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.blue.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.orangeAccent),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
