import 'package:flutter/material.dart';
import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoCateringApp());
}

class GoCateringApp extends StatelessWidget {
  const GoCateringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'goCatering',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00897B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'GO',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00897B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'goCatering',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Melayani dengan sepenuh hati',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('goCatering'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to buyer flow
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Lanjut sebagai Pembeli'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                // Navigate to buyer registration
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Daftar sebagai Pembeli'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Login sebagai Penjual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Login seller
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('LOGIN PENJUAL'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Navigate to seller registration
              },
              child: const Text('Daftar sebagai penjual'),
            ),
          ],
        ),
      ),
    );
  }
}
