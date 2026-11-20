import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/models.dart';
import 'screens/seller_home_screen.dart';
import 'screens/seller_reg_screen.dart';
import 'services/image_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Siapkan folder gocatering/ sebelum layar pertama muncul.
  await ImageStorageService.instance.init();
  runApp(const GoCateringApp());
}

class GoCateringApp extends StatelessWidget {
  const GoCateringApp({super.key});

  static const Color teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'goCatering',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: teal,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: teal,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
      },
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
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Lanjutkan sesi penjual yang belum logout.
    final row = await DatabaseHelper().getSession();
    if (!mounted) return;

    final ownerKey = row?['ownerKey'];
    if (row != null && (row['role'] == 'seller') && ownerKey != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SellerHomeScreen(ownerKey: ownerKey)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                    color: GoCateringApp.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Go Catering',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: GoCateringApp.teal,
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _db = DatabaseHelper();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('goCatering'),
        backgroundColor: GoCateringApp.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text('Selamat Datang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () {
                  // Alur pembeli (beli tanpa daftar) — fase berikutnya.
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Alur pembeli belum diaktifkan.')));
                },
                child: const Text('Lanjut sebagai Pembeli'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Pendaftaran pembeli belum diaktifkan.')));
                },
                child: const Text('Daftar sebagai Pembeli'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Login sebagai Penjual',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _loginSeller,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('LOGIN PENJUAL'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellerRegScreen()),
                ),
                child: const Text('Belum punya toko? Daftar sebagai penjual'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginSeller() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      _err('Isi email terlebih dahulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      final row = await _db.getOwnerByEmail(email);
      final owner = row == null ? null : Owner.fromMap(row);
      if (owner == null || owner.password != _pass.text) {
        _err('Email atau password salah.');
        return;
      }
      await _db.saveSession({
        'id': 1,
        'email': owner.email,
        'name': owner.nama,
        'role': 'seller',
        'ownerKey': owner.key,
        'phone': owner.phone,
        'sellerShop': null,
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SellerHomeScreen(ownerKey: owner.key)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String msg) {
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }
}
