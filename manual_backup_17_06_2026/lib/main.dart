import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_document_screen.dart';
import 'document_model.dart';
import 'category_detail_screen.dart';
import 'attention_required_screen.dart';

const String SUPABASE_URL = 'https://nuhtspjhmsurhanuzjtm.supabase.co';
const String SUPABASE_ANON_KEY = 'sb_publishable_tENzkYPcCCiFIyitM1LMWA_KK3qxEKj';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialise Supabase (The Cloud Database)
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  // 3. Initialise Hive (The Offline Vault)
  await Hive.initFlutter();
    Hive.registerAdapter(DocumentAdapter()); 
  await Hive.openBox<Document>('vaultBox'); 

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

// ─── MAIN APP DASHBOARD (BRANDED UI) MAIN VAULT HOME SCREEN───────────────────────────────────
class MainVaultHomeScreen extends StatefulWidget {
  const MainVaultHomeScreen({super.key});

  @override
  State<MainVaultHomeScreen> createState() => _MainVaultHomeScreenState();
}

class _MainVaultHomeScreenState extends State<MainVaultHomeScreen> {
  int _currentTab = 0;
  String _userName = 'Loading...'; 
  String _daysLeft = '--'; // ◄ ADD THIS LINE to track the countdown
  final supabase = Supabase.instance.client;

  static const Color brandBlack = Color(0xFF121212);     
  static const Color brandCharcoal = Color(0xFF1E1E1E);  
  static const Color brandOrange = Color(0xFFFF7A00);    
  static const Color textMuted = Color(0xFF9E9E9E);      

@override
  void initState() {
    super.initState();
    _fetchUserData();// ◄ This wakes up the fetch command on launch!
    performAutoPurge(); 
  }

  void _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 1. Fetch the user's first name
        final nameData = await supabase
            .from('users')
            .select('first_name')
            .eq('id', user.id)
            .single();
        
        // 2. Fetch the user's active subscription expiry date
        final subData = await supabase
            .from('subscriptions')
            .select('expires_at')
            .eq('user_id', user.id)
            .eq('status', 'active')
            .maybeSingle(); // Uses maybeSingle in case no active sub exists yet
        
        if (mounted) {
          setState(() {
            // Update name if found
            if (nameData['first_name'] != null) {
              _userName = nameData['first_name'].toString();
            }
            
            // Calculate remaining trial days
            if (subData != null && subData['expires_at'] != null) {
              DateTime expiryDate = DateTime.parse(subData['expires_at'].toString());
              DateTime today = DateTime.now();
              
              // Calculate the difference in days
              int difference = expiryDate.difference(today).inDays;
              
              // Ensure we don't display a negative number if it expires
              _daysLeft = difference < 0 ? '0' : difference.toString();
            } else {
              _daysLeft = '0'; // Fallback if no subscription records found
            }
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = 'Trade Worker';
          _daysLeft = '0';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBlack,
      // We start the Master Window here!
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Document>('vaultBox').listenable(),
        builder: (context, Box<Document> box, _) {
  print("Box contains ${box.length} documents"); // ◄ Add this print statement
  return SafeArea(
            child: Column(
              children: [
               // 1. TOP HEADER BANNER
Container(
  height: 80,
  color: brandCharcoal,
  child: Stack(
    clipBehavior: Clip.none, // Allows the logo to float freely
    children: [
      // Left side: The Greeting Text (pushed right to avoid logo)
      Positioned(
        left: 100, // Adjust this to match the space your logo needs
        top: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hello...,', style: TextStyle(color: textMuted, fontSize: 12)),
            Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      
      // Right side: The IconButtons (pinned to the right)
      Positioned(
        right: 0,
        top: 10,
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.logout_rounded, color: brandOrange, size: 26), onPressed: () async {}),
          ],
        ),
      ),
      // Floating Logo: Positioned wherever you want independently
      Positioned(
        left: -14, 
        top: -10, // Adjust this vertically to align with your text
        child: Image.asset(
          'assets/Trade Vault TV Logo.png',
          width: 136,
          height: 136,
        ),
      ),
    ],
  ),
),
const SizedBox(height: 24),

// 2. STAT CARDS
Row(
  children: [
    _buildStatCard(box.length.toString(), 'Documents'),
    const SizedBox(width: 12),
    
    // NEW: Interactive Expiring Soon Button
    Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate to the filtered list here
          final attentionDocs = getAttentionRequiredCards(box.values.toList());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AttentionRequiredScreen(docs: attentionDocs)),
          );
        },
        child: _buildStatCard(
          getAttentionRequiredCards(box.values.toList()).length.toString(), 
          'Attention', 
          isHighlight: true // Makes it stand out as an action
        ),
      ),
    ),
    const SizedBox(width: 12),
    _buildStatCard(_daysLeft, 'Days Left'), 
  ],
),
const SizedBox(height: 24),

                // 3. MAIN SCROLLABLE CONTENT
                Expanded(
                  child: Container(
                    color: brandBlack,
                    child: ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(Icons.add_circle_outline, 'Add Document', context),
                            _buildQuickAction(Icons.qr_code_scanner, 'Scan Card', context),
                            _buildQuickAction(Icons.share_outlined, 'Share Docs', context),
                            _buildQuickAction(Icons.folder_open, 'View All', context),
                                   
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text('Document Categories', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // NOW THESE WORK BECAUSE THEY ARE INSIDE THE BUILDER!
                        InkWell(
                          onTap: () {
                             Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Safety Cards'),
                                ),
                                );
                                 },
                        child: _buildCategoryTile(Icons.badge_outlined, 'Safety Cards', 'CSCS & CCNSG, etc.', box),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Competencies'),
                                ),
                                );
                                 },
                                child: _buildCategoryTile(Icons.psychology, 'Competencies', 'Skill validations', box)),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Access'),
                                ),
                                );
                                 },
                              child: _buildCategoryTile(Icons.link, 'Access', 'Site access permits', box),
                              ),
                        
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Licence'),
                              ),
                            );
                          },
                          child: _buildCategoryTile(Icons.gavel_outlined, 'Licence', 'Driving & plant operator', box)),
                          InkWell(
                          onTap: () {
                             Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Medical'),
                        ),
                           );
                          },
                          child: _buildCategoryTile(Icons.medical_services_outlined, 'Medical', 'Fitness to work records', box),
     ),
                        InkWell(                                              
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailScreen(categoryTitle: 'Insurance'),
                              ),
                            );
                          },
                          child: _buildCategoryTile(Icons.verified_outlined, 'Insurance', 'Public liability Van Fleet', box)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
      // 4. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: brandCharcoal,
        selectedItemColor: brandOrange,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_outlined), label: 'Documents'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: isHighlight ? Border.all(color: brandOrange.withValues(alpha: 0.5), width: 1) : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isHighlight ? brandOrange : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, BuildContext context) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque, // This makes the whole button area clickable
    onTap: () {
      if (label == 'Add Document') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddDocumentScreen()),
        );
      } else if (label == 'View All') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CategoryDetailScreen(categoryTitle: null),
          ),
        );
      }
      // Future actions like 'Scan Card' or 'Share Docs' will go here
    },
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: brandOrange, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

  Widget _buildCategoryTile(IconData icon, String title, String subtitle, Box<Document> box) {
  // Automatically count how many docs are in this specific category
  final count = box.values.where((doc) => doc.category == title).length;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: brandCharcoal,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: brandOrange, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: brandBlack,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count docs', // Now shows the live count!
            style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: textMuted),
      ],
    ),
  );
}}

// Place this at the very bottom of main.dart, OUTSIDE the class brackets
List<Document> getAttentionRequiredCards(List<Document> allDocs) {
  final now = DateTime.now();
  final thirtyDaysAhead = now.add(const Duration(days: 30));
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  
  return allDocs.where((doc) {
    // Safety check: ensure expiryDate is not null
    final expiry = doc.expiryDate;
    return expiry.isBefore(thirtyDaysAhead) && expiry.isAfter(thirtyDaysAgo);
  }).toList();
}

void performAutoPurge() {
  final box = Hive.box<Document>('vaultBox');
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

  final toDelete = box.values.where((doc) => doc.expiryDate.isBefore(thirtyDaysAgo)).toList();

  for (var doc in toDelete) {
    box.delete(doc.id);
  }
  
  if (toDelete.isNotEmpty) {
    print("Auto-Purge: Cleaned up ${toDelete.length} expired documents.");
  }
}