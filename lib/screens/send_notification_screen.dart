import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  String? selectedUserToken;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendNotification() async {
    if (selectedUserToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FCM token alınamadı ❌")),
      );
      return;
    }

    const String serverKey = 'YOUR_SERVER_KEY_HERE'; // 🔐 Buraya kendi Firebase Cloud Messaging server key’ini gir

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=AIzaSyBNKR6d9SbnoMRYnyzAJcRCDSl0LQrLbNg',
      },
      body: jsonEncode({
        'to': selectedUserToken,
        'notification': {
          'title': _titleController.text.trim(),
          'body': _messageController.text.trim(),
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bildirim gönderildi ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gönderim hatası: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bildirim Gönder")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final users = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  items: users.map<DropdownMenuItem<String>>((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final token = data['fcmToken'] ?? '';
                    return DropdownMenuItem<String>(
                      value: token,
                      child: Text(data['name'] ?? data['email'] ?? 'Kullanıcı'),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedUserToken = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Kullanıcı Seçin"),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Başlık"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: "Mesaj"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendNotification,
              child: const Text("Gönder"),
            )
          ],
        ),
      ),
    );
  }
}
