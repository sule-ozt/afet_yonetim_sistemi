import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyResponsesScreen extends StatelessWidget {
  const EmergencyResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gönüllü Yanıtları"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_responses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final responses = snapshot.data!.docs;

          if (responses.isEmpty) {
            return const Center(child: Text("Henüz yanıt verilmedi."));
          }

          return ListView.builder(
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final data = responses[index].data() as Map<String, dynamic>;
              final accepted = data['accepted'] == true;
              final disasterType = data['disasterType'] ?? 'Bilinmiyor';
              final location = data['location'] ?? 'Bilinmiyor';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = timestamp != null
                  ? '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute}'
                  : 'Zaman yok';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    accepted ? Icons.check_circle : Icons.cancel,
                    color: accepted ? Colors.green : Colors.red,
                  ),
                  title: Text("Afet: $disasterType - Bölge: $location"),
                  subtitle: Text("Yanıt: ${accepted ? 'Evet' : 'Hayır'}\n$formattedTime"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
