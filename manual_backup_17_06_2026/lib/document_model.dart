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

  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.expiryDate,
    required this.cardNumber,
    required this.nameOnCard,    // NEW
    required this.learnerNumber, // NEW
  });
}