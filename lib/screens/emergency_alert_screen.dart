import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlertScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmergencyAlertScreen({super.key, required this.data});

  Future<void> _sendResponse(bool accepted, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('emergency_responses').add({
        'userId': user.uid,
        'accepted': accepted,
        'timestamp': FieldValue.serverTimestamp(),
        'disasterType': data['disasterType'],
        'location': data['location'],
      });
    }

    Navigator.of(context).pop(); // ekranı kapat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade800,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🚨 Acil Durum Bildirimi",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text("Afet Türü: ${data['disasterType']}"),
                  Text("Bölge: ${data['location']}"),
                  Text("Gerekli Kişi Sayısı: ${data['requiredVolunteers']}"),
                  const SizedBox(height: 20),
                  const Text("Yardıma Gider misin?"),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _sendResponse(false, context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Hayır"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _sendResponse(true, context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Evet"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
