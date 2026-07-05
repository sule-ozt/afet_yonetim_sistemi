import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool usePhone = false;

  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordOrCodeController = TextEditingController();

  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  final auth = FirebaseAuth.instance;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (usePhone) {
        if (_verificationId != null) {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _passwordOrCodeController.text.trim(),
          );
          await auth.signInWithCredential(credential);
          await _navigateBasedOnRole();
        } else {
          await auth.verifyPhoneNumber(
            phoneNumber: _emailOrPhoneController.text.trim(),
            timeout: const Duration(seconds: 60),
            verificationCompleted: (PhoneAuthCredential credential) async {
              await auth.signInWithCredential(credential);
              await _navigateBasedOnRole();
            },
            verificationFailed: (FirebaseAuthException e) {
              setState(() => _errorMessage = e.message);
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _verificationId = verificationId;
              });
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              _verificationId = verificationId;
            },
          );
        }
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailOrPhoneController.text.trim(),
          password: _passwordOrCodeController.text.trim(),
        );
        await _navigateBasedOnRole();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Bilinmeyen bir hata oluştu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final role = doc.data()?['role'] ?? 'Gönüllü';

    if (role == 'Gönüllü') {
      Navigator.pushReplacementNamed(context, '/volunteer');
    } else if (role == 'Yönetici') {
      Navigator.pushReplacementNamed(context, '/manager');
    } else if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                usePhone = !usePhone;
                _emailOrPhoneController.clear();
                _passwordOrCodeController.clear();
                _verificationId = null;
              });
            },
            child: Text(
              usePhone ? "E-posta ile giriş" : "Telefon ile giriş",
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _emailOrPhoneController,
              decoration: InputDecoration(
                labelText: usePhone ? "Telefon Numarası (+90...)" : "E-posta",
              ),
              keyboardType: usePhone ? TextInputType.phone : TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordOrCodeController,
              decoration: InputDecoration(
                labelText: usePhone ? "SMS Kodu" : "Şifre",
              ),
              obscureText: !usePhone,
              keyboardType: usePhone ? TextInputType.number : TextInputType.text,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: Text(usePhone ? "Telefonla Giriş" : "Giriş Yap"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("Hesabın yok mu? Kayıt ol"),
            )
          ],
        ),
      ),
    );
  }
}
