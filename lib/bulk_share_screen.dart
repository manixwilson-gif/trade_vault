import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'document_model.dart';

class BulkShareScreen extends StatefulWidget {
  const BulkShareScreen({super.key});

  @override
  State<BulkShareScreen> createState() => _BulkShareScreenState();
}

// Define your brand colours to match the main screen
const Color brandBlack = Color(0xFF121212);
const Color brandCharcoal = Color(0xFF1E1E1E);
const Color brandOrange = Color(0xFFFF6B00);
const Color textMuted = Color(0xAAFFFFFF);

class _BulkShareScreenState extends State<BulkShareScreen> {
  String _sortBy = 'Category';
  
  // Track selection state by document ID
  final Map<String, bool> _selectedDocs = {};
  bool _isSelectAll = false;

  void _toggleSelectAll(List<Document> availableDocs) {
    setState(() {
      _isSelectAll = !_isSelectAll;
      for (var doc in availableDocs) {
        _selectedDocs[doc.id] = _isSelectAll;
      }
    });
  }

  void _toggleSingleSelection(String docId, int totalDocs) {
    setState(() {
      _selectedDocs[docId] = !(_selectedDocs[docId] ?? false);
      
      // Check if all are individually selected to update master toggle
      bool allSelected = true;
      for (var docId in _selectedDocs.keys) {
        if (_selectedDocs[docId] == false) {
          allSelected = false;
          break;
        }
      }
      _isSelectAll = allSelected;
    });
  }

  void _processSharing(List<Document> allDocs) async {
    final selectedItems = allDocs.where((doc) => _selectedDocs[doc.id] == true).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No documents selected to share.'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }

    // Compile text summary and collect attachments
    List<String> summaries = [];
    List<XFile> filesToShare = [];

    for (var doc in selectedItems) {
      summaries.add('''
• ${doc.title} (${doc.category})
  Card No: ${doc.cardNumber}
  Expires: ${DateFormat('dd/MM/yyyy').format(doc.expiryDate)}''');

      if (doc.frontImagePath != null && File(doc.frontImagePath!).existsSync()) {
        filesToShare.add(XFile(doc.frontImagePath!));
      }
      if (doc.backImagePath != null && File(doc.backImagePath!).existsSync()) {
        filesToShare.add(XFile(doc.backImagePath!));
      }
    }

    final combinedText = 'Selected Trade Vault Documents:\n\n${summaries.join('\n')}';

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(
        filesToShare,
        text: combinedText,
        subject: 'Trade Vault Export (${selectedItems.length} items)',
      );
    } else {
      await Share.share(
        combinedText,
        subject: 'Trade Vault Export (${selectedItems.length} items)',
      );
    }
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Selected documents successfully dispatched.'),
      backgroundColor: Colors.green,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Document>('vaultBox');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Text('Bulk Share Documents'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Color(0xFFFF7A00)),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Category', child: Text('Sort by Category')),
              const PopupMenuItem(value: 'Expiry', child: Text('Sort by Expiry')),
              const PopupMenuItem(value: 'Title', child: Text('Sort by Title')),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Document> box, _) {
          final docs = box.values.toList();

          // Dynamic Sort Logic
          docs.sort((a, b) {
            if (_sortBy == 'Title') {
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            } else if (_sortBy == 'Category') {
              const customOrder = {
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
              return a.expiryDate.compareTo(b.expiryDate);
            }
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text('No documents available to share.', style: TextStyle(color: Colors.grey)),
            );
          }

          return Column(
            children: [
              // ◄ SELECT ALL CHECKBOX ROW
              Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isSelectAll,
                      activeColor: const Color(0xFFFF7A00),
                      onChanged: (bool? value) => _toggleSelectAll(docs),
                    ),
                    const Text(
                      'Select All Documents',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final isChecked = _selectedDocs[doc.id] ?? false;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFFFF7A00),
                        title: Text(doc.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'No: ${doc.cardNumber}\nExpires: ${DateFormat('dd/MM/yyyy').format(doc.expiryDate)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        value: isChecked,
                        onChanged: (bool? value) {
                          _toggleSingleSelection(doc.id, docs.length);
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Dispatch Selected Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _processSharing(docs),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}