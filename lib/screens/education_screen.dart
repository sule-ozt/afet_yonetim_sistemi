import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> _progress = {};

  final List<String> _modules = [
    "Afet Bilinci",
    "İlk Yardım",
    "Yangın Güvenliği",
    "Tahliye Prosedürleri",
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final doc = await _firestore
        .collection('education_progress')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _progress = Map<String, bool>.from(doc.data()!);
      });
    } else {
      // boş veri seti oluştur
      final initialData = {for (var m in _modules) m: false};
      await _firestore
          .collection('education_progress')
          .doc(user!.uid)
          .set(initialData);
      setState(() => _progress = initialData);
    }
  }

  Future<void> _markAsCompleted(String module) async {
    await _firestore
        .collection('education_progress')
        .doc(user!.uid)
        .update({module: true});
    setState(() {
      _progress[module] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eğitimler")),
      body: ListView.builder(
        itemCount: _modules.length,
        itemBuilder: (context, index) {
          final module = _modules[index];
          final completed = _progress[module] ?? false;

          return ListTile(
            leading: Icon(completed ? Icons.check_circle : Icons.circle_outlined,
                color: completed ? Colors.green : Colors.grey),
            title: Text(module),
            trailing: ElevatedButton(
              onPressed: completed
                  ? null
                  : () {
                _markAsCompleted(module);
              },
              child: const Text("Tamamla"),
            ),
          );
        },
      ),
    );
  }
}
