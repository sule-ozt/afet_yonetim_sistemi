import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

class CreateDisasterScreen extends StatefulWidget {
  const CreateDisasterScreen({super.key});

  @override
  State<CreateDisasterScreen> createState() => _CreateDisasterScreenState();
}

class _CreateDisasterScreenState extends State<CreateDisasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _severityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Location location = Location();
      final locData = await location.getLocation();

      final double? latitude = locData.latitude;
      final double? longitude = locData.longitude;

      // 1. Afeti Firestore'a yaz
      await FirebaseFirestore.instance.collection('disasters').add({
        'type': _typeController.text.trim(),
        'severity': _severityController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': Timestamp.now(),
        'latitude': latitude,
        'longitude': longitude,
      });

      // 2. Kullanıcının konumunu da users koleksiyonuna yaz
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && latitude != null && longitude != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Afet bildirimi oluşturuldu ✅")),
      );

      _typeController.clear();
      _severityController.clear();
      _descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Afet Bildirimi Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "Afet Türü"),
                validator: (value) =>
                value == null || value.isEmpty ? "Bu alan zorunlu" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _severityController,
                decoration: const InputDecoration(labelText: "Şiddet (1-5)"),
                validator: (value) =>
                value == null || value.isEmpty ? "Bu alan zorunlu" : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Açıklama"),
                maxLines: 3,
                validator: (value) =>
                value == null || value.isEmpty ? "Bu alan zorunlu" : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                child: const Text("Kaydet"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
