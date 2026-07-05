import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Giriş yapılmamış")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Bildirimler")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: userId)
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz bildirim yok"));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Başlık yok';
              final message = data['message'] ?? '';
              final sentAt = (data['sentAt'] as Timestamp).toDate();

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(title),
                subtitle: Text(message),
                trailing: Text(
                  "${sentAt.day}/${sentAt.month} ${sentAt.hour}:${sentAt.minute}",
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
