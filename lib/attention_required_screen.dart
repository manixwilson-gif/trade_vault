import 'package:flutter/material.dart';
import 'document_model.dart'; // Make sure this import is correct

class AttentionRequiredScreen extends StatefulWidget {
  final List<Document> docs;

  const AttentionRequiredScreen({super.key, required this.docs});

  @override
  State<AttentionRequiredScreen> createState() => _AttentionRequiredScreenState();
}

class _AttentionRequiredScreenState extends State<AttentionRequiredScreen> {
  
  @override
  Widget build(BuildContext context) {
    // Sorting happens here, keeping the UI logic clean
    final sortedDocs = List<Document>.from(widget.docs);
    sortedDocs.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Attention Required'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: sortedDocs.isEmpty
          ? const Center(child: Text('No documents need attention.', style: TextStyle(color: Colors.white)))
          : ListView.builder(
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final doc = sortedDocs[index];
                return Card(
                  color: const Color(0xFF2A2A2A),
                  child: ListTile(
                    title: Text(doc.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Expires: ${doc.expiryDate.toString().split(' ')[0]}', 
                                   style: const TextStyle(color: Colors.orange)),
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  ),
                );
              },
            ),
    );
  }
}