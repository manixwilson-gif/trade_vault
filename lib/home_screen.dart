import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_document_screen.dart';
import 'document_model.dart';
import 'category_detail_screen.dart';
import 'attention_required_screen.dart';
import 'scan_card.dart'; // Import the ScanCardScreen
import 'bulk_share_screen.dart'; // Import the BulkShareScreen

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
    _buildStatCard(_daysLeft, 'FREE Days Left'), 
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
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (label == 'Add Document') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddDocumentScreen()),
          );
        } else if (label == 'Scan Card') {
          // 1. Launch the scanner and wait for it to return paths
          final result = await Navigator.push<Map<String, String?>>(
            context,
            MaterialPageRoute(builder: (context) => const ScanCardScreen(isSingleShot: false)), // Pass false for multi-shot mode
          );

          // 2. If pictures were successfully taken, pass them to AddDocumentScreen
          if (result != null && context.mounted) {
            final frontPath = result['frontImage'];
            final backPath = result['backImage'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddDocumentScreen(
                  preloadedFrontImagePath: frontPath,
                  preloadedBackImagePath: backPath,
                ),
              ),
            );
          }
        } else if (label == 'View All') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CategoryDetailScreen(categoryTitle: null),
            ),
          );
        } else if (label == 'Share Docs') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BulkShareScreen(),
            ),
          );
        }
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