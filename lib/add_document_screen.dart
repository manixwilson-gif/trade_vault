import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart'; // Make sure to add this to pubspec.yaml for date formatting!
import 'package:hive_flutter/hive_flutter.dart';
import 'document_model.dart';
import 'dart:io';
import 'scan_card.dart'; // Import the ScanCardScreen

class AddDocumentScreen extends StatefulWidget {
  final Document? documentToEdit;
  // New paths coming from the ScanCardScreen
  final String? preloadedFrontImagePath;
  final String? preloadedBackImagePath;

  const AddDocumentScreen({
    super.key, 
    this.documentToEdit,
    this.preloadedFrontImagePath,
    this.preloadedBackImagePath,
  });

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
  
  // Local state variables to hold the image paths during this session
  String? _frontImagePath;
  String? _backImagePath;

  @override
  void initState() {
    super.initState();

    // 1. Check if we are editing an existing card and populate fields
    if (widget.documentToEdit != null) {
      final doc = widget.documentToEdit!;
      _titleController.text = doc.title;
      _numberController.text = doc.cardNumber;
      _nameOnCardController.text = doc.nameOnCard;
      _learnerNumberController.text = doc.learnerNumber;
      _selectedCategory = doc.category;
      _expiryDate = doc.expiryDate;
      
      // Load existing images if editing a previously scanned/uploaded card
      _frontImagePath = doc.frontImagePath;
      _backImagePath = doc.backImagePath;
    } else {
      // 2. Otherwise, check if new scanned images are arriving from the camera flow
      _frontImagePath = widget.preloadedFrontImagePath;
      _backImagePath = widget.preloadedBackImagePath;
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
      lastDate: DateTime.now().add(const Duration(days: 14600)), // 40 years out
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
// ◄ STEP 3 CODE DROPPED HERE
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: brandCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: brandOrange),
                title: const Text('Scan Trade Card (Front & Back)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context); // Dismiss the bottom sheet
                  
                  // Make sure ScanCardScreen matches your physical scanner class name
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanCardScreen()),
                  );

                  if (result != null && result is Map<String, String?>) {
                    setState(() {
                      _frontImagePath = result['frontImage'];
                      _backImagePath = result['backImage'];
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.white70),
                title: const Text('Select PDF, JPEG, or PNG', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context); // Dismiss the bottom sheet
                       
                  final typeGroup = XTypeGroup(
                    label: 'documents',
                    extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );

                  final file = await openFile(acceptedTypeGroups: [typeGroup]);

                  if (file != null) {
                    setState(() {
                      _frontImagePath = file.path;
                      _backImagePath = null;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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

              // ◄ IMAGE SAVE PREVIEW SECTION:
            if (_frontImagePath != null || _backImagePath != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Scanned Cards Preview', 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_frontImagePath != null) ...[
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_frontImagePath!),
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Front', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ],
                  if (_backImagePath != null) ...[
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_backImagePath!),
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Back', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 24),
              // ◄ The New Combined Attachment Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandOrange, width: 1.5),
                  foregroundColor: brandOrange,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach Trade Card or Document'),
                onPressed: () => _showAttachmentOptions(context),
              ),
              const SizedBox(height: 24),
            ],

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
      frontImagePath: _frontImagePath, // ◄ Add the front image path
      backImagePath: _backImagePath,   // ◄ Add the back image path
      manualFilePath: "", // Assuming no manual file path for now
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
    setState(() {
                      // 1. Clear text controllers
                      _titleController.clear(); 
                      _numberController.clear();
                      _nameOnCardController.clear();
                      _learnerNumberController.clear();
                      
                      // 2. Wipe image paths and reset defaults
                      _frontImagePath = null;
                      _backImagePath = null;
                      _expiryDate = null;
                      _selectedCategory = 'Safety Cards'; 
                    });

                    // 3. Pop back to the home screen immediately
                    Navigator.pop(context);
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
              ), // ◄ Closes the ElevatedButton or Padding
            ), // ◄ Closes the Expanded or Container wrapping the button
          ], // ◄ Closes the children array of your Column/Row
        ), // ◄ Closes the Column or Form
      ), // ◄ Closes the SingleChildScrollView or Padding
      ),
    ); // ◄ Closes the Scaffold and requires the semicolon here!
  } // ◄ Closes the build method
} // ◄ Closes the _AddDocumentScreenState class

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