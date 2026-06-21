import 'package:hive/hive.dart';

// This tells Flutter to expect an auto-generated translator file
part 'document_model.g.dart'; 

@HiveType(typeId: 0)
class Document extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String category;
  @HiveField(3) final DateTime expiryDate;
  @HiveField(4) final String cardNumber;
  @HiveField(5) final String nameOnCard;     // NEW
  @HiveField(6) final String learnerNumber;  // NEW
  @HiveField(7) final String? frontImagePath; // Optional field for storing the path to the scanned image
  @HiveField(8) final String? backImagePath;  // Optional field for storing the path to the scanned image
  @HiveField(9) final String manualFilePath; // Optional field for storing the path to the manually added file


  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.expiryDate,
    required this.cardNumber,
    required this.nameOnCard,    // NEW
    required this.learnerNumber, // NEW
    this.frontImagePath,         // Optional field for storing the path to the scanned image
    this.backImagePath,          // Optional field for storing the path to the scanned image
    required this.manualFilePath, // Optional field for storing the path to the manually added file
  });
}