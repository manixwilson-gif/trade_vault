import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'document_model.dart'; // Ensure this points to where your Document model lives
import 'view_document_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String? categoryTitle;
  const CategoryDetailScreen({super.key, this.categoryTitle});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String _sortBy = 'Category'; // Default setting

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Document>('vaultBox');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.categoryTitle ?? 'All Documents', style: const TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Color(0xFFFF7A00)),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Category', child: Text('Sort by Category')),
              const PopupMenuItem(value: 'Expiry', child: Text('Sort by Expiry')),
              const PopupMenuItem(value: 'Title', child: Text('Sort by Title')),
            ],
          ),
        ],
      ),
      // ... now you keep the rest of your original 'body' code exactly as it was
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Document> box, _) {
          // Filter logic
          final docs = widget.categoryTitle == null 
              ? box.values.toList() 
              : box.values.where((doc) => doc.category == widget.categoryTitle).toList();

          // Apply the sort logic dynamically
          docs.sort((a, b) {
            if (_sortBy == 'Title') {
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            } else if (_sortBy == 'Category') {
              final customOrder = {
                'Safety Cards': 1,
                'Competencies': 2,
                'Access': 3,
                'Licence': 4,
                'Medical': 5,
                'Insurance': 6,
              };

              int weightA = customOrder[a.category] ?? 99;
              int weightB = customOrder[b.category] ?? 99;

              return weightA.compareTo(weightB);
            } else {
              // Sort by Expiry (soonest first)
              return a.expiryDate.compareTo(b.expiryDate);
            }
          });

          if (docs.isEmpty) {
            return const Center(child: Text('No documents found.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
  padding: const EdgeInsets.all(20),
  itemCount: docs.length,
  itemBuilder: (context, index) {
    final doc = docs[index];
    return InkWell(
      onTap: () {
        // ◄ LAUNCH THE SECURE, READ-ONLY VIEW INSTEAD
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewDocumentScreen(document: doc),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(doc.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            'No: ${doc.cardNumber}\nExpires: ${doc.expiryDate.day}/${doc.expiryDate.month}/${doc.expiryDate.year}', 
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF7A00)),
        ),
      ),
    );
},
          );
        },
      ),
    );
  }
}