import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure to add this to pubspec.yaml for date formatting!
import 'package:hive_flutter/hive_flutter.dart';
import 'document_model.dart';

class AddDocumentScreen extends StatefulWidget {
  final Document? documentToEdit;
  const AddDocumentScreen({super.key, this.documentToEdit});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

// Define your brand colours to match the main screen
const Color brandBlack = Color(0xFF121212);
const Color brandCharcoal = Color(0xFF1E1E1E);
const Color brandOrange = Color(0xFFFF6B00);
const Color textMuted = Color(0xAAFFFFFF);

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _numberController = TextEditingController();
  final _nameOnCardController = TextEditingController();
  final _learnerNumberController = TextEditingController();
  
  String _selectedCategory = 'Safety Cards';
  DateTime? _expiryDate;
  
  // PASTE THE INITSTATE CODE RIGHT HERE:
  @override
  void initState() {
    super.initState();
    // Check if we are editing
    if (widget.documentToEdit != null) {
      final doc = widget.documentToEdit!;
      _titleController.text = doc.title;
      _numberController.text = doc.cardNumber;
      _nameOnCardController.text = doc.nameOnCard;      // ADD THIS
      _learnerNumberController.text = doc.learnerNumber; // ADD THIS
      _selectedCategory = doc.category;
      _expiryDate = doc.expiryDate;
    }
  }
  
  final List<String> _categories = [
  'Safety Cards',
  'Competencies',
  'Access',
  'Licence',
  'Medical',
  'Insurance',
];

  // Function to pop open the calendar picker
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)), // Default to 1 year from now
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years out
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: brandOrange,
              onPrimary: Colors.white,
              surface: brandCharcoal,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _nameOnCardController.dispose();     // ADD THIS
    _learnerNumberController.dispose();  // ADD THIS
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBlack,
      appBar: AppBar(
        backgroundColor: brandCharcoal,
        title: const Text('Add New Vault Item', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Details',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 1. DOCUMENT TITLE INPUT
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Document Title (e.g., CSCS Card)',
                  labelStyle: const TextStyle(color: textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandCharcoal, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: brandCharcoal,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // 2. NAME ON CARD INPUT
              TextFormField(
  controller: _nameOnCardController,
  style: const TextStyle(color: Colors.white),
  decoration: _inputDecoration('Name on Card'), // Helper to keep code clean
),
const SizedBox(height: 20),
              // 3. LEARNER NUMBER INPUT
              TextFormField(
  controller: _learnerNumberController,
  style: const TextStyle(color: Colors.white),
  decoration: _inputDecoration('Learner Number'),
),
const SizedBox(height: 20),

               // 4. CARD NUMBER INPUT
              TextFormField(
                controller: _numberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: const TextStyle(color: textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandCharcoal, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: brandCharcoal,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
                  
              // 5. CATEGORY DROPDOWN
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: brandCharcoal,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandCharcoal, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: brandCharcoal,
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 6. EXPIRY DATE PICKER FIELD
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: brandCharcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brandCharcoal, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate == null 
                            ? 'Select Expiry Date' 
                            : 'Expires: ${DateFormat('dd/MM/yyyy').format(_expiryDate!)}',
                        style: TextStyle(
                          color: _expiryDate == null ? textMuted : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, color: brandOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

                // 7. SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
  if (_formKey.currentState!.validate()) {
    // 1. Existing date check
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date!')),
      );
      return;
    }
// 2. DUPLICATE CHECK: Look through existing docs
    final vaultBox = Hive.box<Document>('vaultBox');
    final newNumber = _numberController.text.trim();
    final newTitle = _titleController.text.trim(); // Get the title too

    bool isDuplicate = vaultBox.values.any((doc) {
      // Check if both the number AND the title match
      // AND ensure it's not the same document we are currently editing
      return doc.cardNumber.toLowerCase() == newNumber.toLowerCase() && 
             doc.title.toLowerCase() == newTitle.toLowerCase() && 
             doc.id != widget.documentToEdit?.id;
    });

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A document with this same Name and Number already exists!'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop the save process here
    }

    // 2. Open our offline filing cabinet
    
    // 3. Determine if we are editing or adding
    // If editing, use the existing ID; if adding, generate a new one
    final docId = widget.documentToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 4. Bundle the data into our Document blueprint
    final document = Document(
      id: docId,
      title: _titleController.text.trim(),
      category: _selectedCategory,
      expiryDate: _expiryDate!,
      cardNumber: _numberController.text.trim(),
      nameOnCard: _nameOnCardController.text.trim(),     // ADD THIS
      learnerNumber: _learnerNumberController.text.trim(), // ADD THIS
    );

    // 5. Lock it in the vault! (put works for both new and existing keys)
    vaultBox.put(docId, document);

    // 6. Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.documentToEdit != null ? 'Document Updated!' : 'Document Secured to Vault!'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
    );

    // 7. Clear the title text so it's ready for the next one
    _titleController.clear(); 
    _numberController.clear();
    _nameOnCardController.clear();
    _learnerNumberController.clear();
  }
  },
  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Secure to Vault',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
        ),
        ),
      ),
    );
  }
}
InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: textMuted),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: brandCharcoal, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: brandOrange, width: 2),
    ),
    filled: true,
    fillColor: brandCharcoal,
  );
}