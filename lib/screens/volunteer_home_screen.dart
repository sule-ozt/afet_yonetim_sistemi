import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'emergency_alert_screen.dart';

class VolunteerPanel extends StatefulWidget {
  const VolunteerPanel({super.key});

  @override
  State<VolunteerPanel> createState() => _VolunteerPanelState();
}

class _VolunteerPanelState extends State<VolunteerPanel> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _setupFcm();        // 🔔 Bildirim dinleyicisi
    _saveFcmToken();    // 🟢 Token Firestore'a kaydedilsin
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userEmail = doc.data()?['email'] ?? user.email ?? 'Gönüllü';
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
      print("✅ fcmToken kaydedildi: $token");
    } else {
      print("⚠️ Kullanıcı ya da token null");
    }
  }

  void _setupFcm() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 [Gönüllü] Bildirim alındı!");
      if (message.data['type'] == 'emergency') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyAlertScreen(data: message.data),
          ),
        );
      }
    });
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönüllü Paneli'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                'Hoş Geldiniz ${userEmail ?? '...'}!',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profilim'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Yardımcı Ol'),
              onTap: () {
                Navigator.pushNamed(context, '/tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Eğitim'),
              onTap: () {
                Navigator.pushNamed(context, '/education');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Güvenlik'),
              onTap: () {
                Navigator.pushNamed(context, '/safety');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: userEmail == null
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hoş geldin, $userEmail!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text('Aşağıdaki menüden görevlerini takip edebilirsin.'),
          ],
        ),
      ),
    );
  }
}
