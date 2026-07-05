import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisasterDetailScreen extends StatelessWidget {
  const DisasterDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String disasterId =
    ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Afet Detayı")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('disasters')
            .doc(disasterId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Afet verisi bulunamadı."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Afet Türü: ${data['type'] ?? '-'}",
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Şiddet: ${data['severity'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Açıklama:", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['description'] ?? 'Yok'),
                const SizedBox(height: 12),
                if (data['createdAt'] != null)
                  Text(
                    "Oluşturulma: ${data['createdAt'].toDate()}",
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
