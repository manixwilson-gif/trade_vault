import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_document_screen.dart';
import 'document_model.dart';
import 'category_detail_screen.dart';
import 'attention_required_screen.dart';
import 'home_screen.dart';

const String SUPABASE_URL = 'https://nuhtspjhmsurhanuzjtm.supabase.co';
const String SUPABASE_ANON_KEY = 'sb_publishable_tENzkYPcCCiFIyitM1LMWA_KK3qxEKj';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
  FlutterError.dumpErrorToConsole(details);
  print('CRITICAL STARTUP ERROR: ${details.exception}');
};  
 
  // 2. Initialise Hive (The Offline Vault)
  await Hive.initFlutter();
    Hive.registerAdapter(DocumentAdapter()); 
  await Hive.openBox<Document>('vaultBox'); 

   // 3. Initialise Supabase (The Cloud Database)
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  // 4. Run Trade Vault!
  runApp(const TradeVaultApp()); // (Ensure this matches your main widget name)
}

class TradeVaultApp extends StatelessWidget {
  const TradeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trade Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await supabase.auth.signUp(email: email, password: password);
        _showSnackBar('Registration successful!', Colors.green);
      } else {
        final response = await supabase.auth.signInWithPassword(email: email, password: password);
        if (response.user != null) {
          _checkOnboardingState(response.user!.id);
        }
      }
    } on AuthException catch (error) {
      _showSnackBar(error.message, Colors.red);
    } catch (error) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkOnboardingState(String userId) async {
    try {
      final data = await supabase.from('users').select('first_name').eq('id', userId).single();
      
      if (!mounted) return;

      if (data['first_name'] == null || data['first_name'].toString().isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen(userId: userId)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainVaultHomeScreen()),
        );
      }
    } catch (error) {
      _showSnackBar('Error loading profile state.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp ? 'Create Vault Account' : 'Welcome to Trade Vault',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isSignUp ? 'Register' : 'Login'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up Here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PROFILE ONBOARDING SCREEN ─────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final String userId;
  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isSaving = false;
  final supabase = Supabase.instance.client;

  void _saveProfile() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();

    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first and last name.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await supabase.from('users').update({
        'first_name': first,
        'last_name': last,
      }).eq('id', widget.userId);

      await supabase.from('subscriptions').insert({
        'user_id': widget.userId,
        'tier': 'free',
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_trial': true,
        'status': 'active'
      });

      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainVaultHomeScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save setup: $error'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete Your Wallet Setup',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your details to register your digital site card vault.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Activate Your Trade Vault 30 Day Trial'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
