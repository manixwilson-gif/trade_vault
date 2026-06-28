import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'document_model.dart'; // Ensure your data model is imported
import 'preview_screen.dart';
import 'add_document_screen.dart'; // Points to your edit/creation screen

class ViewDocumentScreen extends StatefulWidget {
  final Document document;

  const ViewDocumentScreen({super.key, required this.document});

  @override
  State<ViewDocumentScreen> createState() => _ViewDocumentScreenState();
}

// Define your brand colours to match the main screen
const Color brandBlack = Color(0xFF121212);
const Color brandCharcoal = Color(0xFF1E1E1E);
const Color brandOrange = Color(0xFFFF6B00);
const Color textMuted = Color(0xAAFFFFFF);

class _ViewDocumentScreenState extends State<ViewDocumentScreen> {
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: brandBlack,
          title: const Text(
            'Permanently Delete?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This action cannot be undone. It will permanently delete this record and any associated images or PDF files stored with it.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeDeletion();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDeletion() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting record and attachments...'),
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );

    try {
      if (widget.document.frontImagePath != null) {
        final frontFile = File(widget.document.frontImagePath!);
        if (await frontFile.exists()) await frontFile.delete();
      }
      if (widget.document.backImagePath != null) {
        final backFile = File(widget.document.backImagePath!);
        if (await backFile.exists()) await backFile.delete();
      }

      // Remove from Hive box
      await widget.document.delete(); 
      
      if (!mounted) return;
      Navigator.pop(context); // Pop back to dashboard/list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record successfully deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReadonlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value, 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(BuildContext context, String filePath) {
    bool isPdf = filePath.toLowerCase().endsWith('.pdf');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (isPdf) {
          OpenFile.open(filePath);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageView(filePath: filePath),
            ),
          );
        }
      },
      child: isPdf 
          ? Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B00)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, color: Color(0xFFFF6B00), size: 32),
                  SizedBox(height: 4),
                  Text('Attached PDF', style: TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                ],
              ),
            ) 
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(filePath), width: 120, height: 80, fit: BoxFit.cover),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Document Details'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadonlyField('Document Title', doc.title),
            const SizedBox(height: 16),
            _buildReadonlyField('Category', doc.category),
            const SizedBox(height: 16),
            _buildReadonlyField('Name on Card', doc.nameOnCard),
            const SizedBox(height: 16),
            _buildReadonlyField('Learner Number', doc.learnerNumber),
            const SizedBox(height: 16),
            _buildReadonlyField('Card Number', doc.cardNumber),
            const SizedBox(height: 16),
            _buildReadonlyField('Expiry Date', DateFormat('dd/MM/yyyy').format(doc.expiryDate)),
            const SizedBox(height: 24),

            if (doc.frontImagePath != null || doc.backImagePath != null) ...[
              const Text('Attachments', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (doc.frontImagePath != null) ...[
                    Column(
                      children: [
                        _buildAttachmentPreview(context, doc.frontImagePath!),
                        const SizedBox(height: 4),
                        const Text('Front / Document', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (doc.backImagePath != null) ...[
                    Column(
                      children: [
                        _buildAttachmentPreview(context, doc.backImagePath!),
                        const SizedBox(height: 4),
                        const Text('Back / Card Scan', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
            ],

            // 1. EDIT BUTTON (Passes the document to the edit screen)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
                foregroundColor: const Color(0xFFFF6B00),
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Unlock Record for Editing'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDocumentScreen(documentToEdit: doc),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // 2. DANGER-ZONE DELETE BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Document & Card'),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}