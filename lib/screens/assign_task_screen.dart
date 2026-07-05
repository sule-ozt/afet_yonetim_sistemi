import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  String? selectedVolunteerId;
  String? selectedVolunteerName;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _assignTask() async {
    if (selectedVolunteerId == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').add({
      'assignedTo': selectedVolunteerId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'status': 'bekliyor',
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Görev atandı ✅")),
    );

    _titleController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Görev Atama")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Gönüllü Seç", style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Gönüllü')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final volunteers = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedVolunteerId,
                  items: volunteers.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? data['email'] ?? 'Gönüllü'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVolunteerId = value;
                      final volunteerData = volunteers
                          .firstWhere((doc) => doc.id == value!)
                          .data()! as Map<String, dynamic>;

                      selectedVolunteerName = volunteerData['name'] ?? volunteerData['email'] ?? 'Gönüllü';
                    });
                  },
                  decoration: const InputDecoration(labelText: "Gönüllü Seçin"),
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Görev Başlığı"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Görev Açıklaması"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _assignTask,
              child: const Text("Görevi Ata"),
            )
          ],
        ),
      ),
    );
  }
}
