import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisasterListScreen extends StatelessWidget {
  const DisasterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Afet Listesi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('disasters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Hiç afet bildirimi yok."));
          }

          final disasters = snapshot.data!.docs;

          return ListView.builder(
            itemCount: disasters.length,
            itemBuilder: (context, index) {
              final data =
                  disasters[index].data() as Map<String, dynamic>? ?? {};

              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(data['type'] ?? "Bilinmeyen"),
                subtitle: Text("Şiddet: ${data['severity'] ?? '-'}\n${data['description'] ?? ''}"),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/disaster-detail',
                    arguments: disasters[index].id, // belge ID'sini gönder
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
