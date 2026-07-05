import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  String _selectedRole = 'Gönüllü';
  final List<String> _roles = ['Gönüllü', 'Yönetici', 'Admin'];

  bool _isLoading = false;
  bool _smsSent = false;
  String? _errorMessage;

  Future<void> _register() async {
    await FirebaseAuth.instance.signOut();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user!.sendEmailVerification();

      await _saveUserInfo();

      if (_phoneController.text.trim().isNotEmpty) {
        await _startPhoneVerification();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-posta doğrulama bağlantısı gönderildi.")),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Bilinmeyen hata: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startPhoneVerification() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
        await _saveUserInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarılı! Lütfen giriş yapın.")),
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/login');
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _errorMessage = e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _smsSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifySmsCodeAndLink() async {
    if (_verificationId == null || _smsCodeController.text.isEmpty) {
      setState(() => _errorMessage = "SMS kodu girilmedi.");
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );

      try {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          throw e;
        }
      }

      await _saveUserInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı! Lütfen giriş yapın.")),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() => _errorMessage = "SMS doğrulama başarısız: $e");
    }
  }

  Future<void> _saveUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'role': _selectedRole,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kullanıcı Kayıt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-posta"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value != null && value.contains('@') ? null : "Geçerli e-posta girin",
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Şifre"),
                obscureText: true,
                validator: (value) =>
                value != null && value.length >= 6 ? null : "Şifre en az 6 karakter olmalı",
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: "Şifre Tekrar"),
                obscureText: true,
                validator: (value) => value == _passwordController.text
                    ? null
                    : "Şifreler uyuşmuyor",
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Telefon Numarası (+90...)"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value != null && value.length >= 10 ? null : "Geçerli telefon girin",
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
                decoration: const InputDecoration(labelText: "Rol Seçiniz"),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _register,
                child: const Text("Kaydol"),
              ),
              if (_smsSent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _smsCodeController,
                  decoration: const InputDecoration(labelText: "SMS Kodu"),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: _verifySmsCodeAndLink,
                  child: const Text("SMS Kodunu Doğrula"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
