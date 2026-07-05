import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendEmergencyScreen extends StatefulWidget {
  const SendEmergencyScreen({super.key});

  @override
  State<SendEmergencyScreen> createState() => _SendEmergencyScreenState();
}

class _SendEmergencyScreenState extends State<SendEmergencyScreen> {
  final _typeController = TextEditingController();
  final _locationController = TextEditingController();
  final _peopleCountController = TextEditingController();

  Future<void> sendEmergencyNotification() async {
    print("🚨 Bildirim gönderme fonksiyonu çalıştı");

    final title = "🚨 Acil Durum Bildirimi";
    final body =
        "Afet Türü: ${_typeController.text}\nYardım Sayısı: ${_peopleCountController.text}\nBölge: ${_locationController.text}";

    try {
      // 🔴 1. Firestore'a bildirim kaydı
      await FirebaseFirestore.instance.collection('emergency_notifications').add({
        'title': title,
        'body': body,
        'disasterType': _typeController.text,
        'location': _locationController.text,
        'requiredVolunteers': _peopleCountController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔴 2. Tüm kullanıcıların fcmToken'larını al
      final tokensSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

      for (var doc in tokensSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('fcmToken')) {
          final token = data['fcmToken'];
          if (token != null && token.toString().isNotEmpty) {
            final response = await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'key=AIzaSyCrVwpv8ZMIgjaNa_4OwgHGuQalKro-L_g', // Server Key
              },
              body: jsonEncode({
                'to': token,
                'priority': 'high',
                'notification': {
                  'title': title,
                  'body': body,
                  'sound': 'emergency',
                  'android_channel_id': 'emergency_channel',
                },
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'type': 'emergency',
                  'title': title,
                  'body': body,
                  'disasterType': _typeController.text,
                  'location': _locationController.text,
                  'requiredVolunteers': _peopleCountController.text,
                },
              }),
            );


            print("📤 Bildirim gönderildi: ${response.statusCode}");
            if (response.statusCode != 200) {
              print("⚠️ Bildirim hatası: ${response.body}");
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Acil durum bildirimi gönderildi")),
      );
    } catch (e) {
      print("❌ HATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acil Bildirim Gönder")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: "Afet Türü"),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Afet Bölgesi"),
            ),
            TextField(
              controller: _peopleCountController,
              decoration: const InputDecoration(labelText: "Kişi Sayısı"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.notification_important),
              label: const Text("Bildirimi Gönder"),
              onPressed: sendEmergencyNotification,
            )
          ],
        ),
      ),
    );
  }
}
