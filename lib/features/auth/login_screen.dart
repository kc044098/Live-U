import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../locale_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_auth_service.dart'; // 改成實際路徑
import '../../../l10n/l10n.dart'; // 根據你的 S.of(context) 的來源
import '../../../locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final user = await _googleAuthService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google 登入失敗')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => localeProvider.toggleLocale(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: S.of(context).email,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: S.of(context).password,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text(S.of(context).login),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: Image.asset(
                'assets/icon_google.jpg',
                height: 40,
              ),
              label: const Text('使用 Google 登入'),
              onPressed: _handleGoogleLogin,
            ),
          ],
        ),
      ),
    );
  }
}