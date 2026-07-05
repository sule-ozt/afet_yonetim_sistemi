import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerPanel extends StatefulWidget {
  const ManagerPanel({super.key});

  @override
  State<ManagerPanel> createState() => _ManagerPanelState();
}

class _ManagerPanelState extends State<ManagerPanel> {
  String? userEmail;
  final Color afadBlue = const Color(0xFF003366);
  final Color afadOrange = const Color(0xFFFF6600);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userEmail = doc.data()?['email'] ?? user.email ?? 'Yönetici';
      });
    }
  }

  final List<_PanelItem> panelItems = [
    _PanelItem(title: "Gönüllüler", icon: Icons.people, route: '/volunteer'),
    _PanelItem(title: "Afet Oluştur", icon: Icons.warning, route: '/create-disaster'),
    _PanelItem(title: "Harita", icon: Icons.map, route: '/map'),
    _PanelItem(title: "Sohbet", icon: Icons.chat, route: '/chat'),
    _PanelItem(title: "Afet Listesi", icon: Icons.list_alt, route: '/disaster-list'),
    _PanelItem(title: "Bildirim Gönder", icon: Icons.notifications_active, route: '/send-notification'),
    _PanelItem(title: "Görev Ata", icon: Icons.assignment_turned_in, route: '/assign-task'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userEmail == null
            ? 'Yönetici Paneli'
            : 'Hoş geldiniz, $userEmail'),
        backgroundColor: afadBlue,
      ),
      body: userEmail == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: panelItems.map((item) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, item.route);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: afadBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(3, 3),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 40, color: afadOrange),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PanelItem {
  final String title;
  final IconData icon;
  final String route;

  const _PanelItem({required this.title, required this.icon, required this.route});
}
