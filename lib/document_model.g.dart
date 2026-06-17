// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 0;

  @override
  Document read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Document(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      expiryDate: fields[3] as DateTime,
      cardNumber: fields[4] as String,
      nameOnCard: fields[5] as String,
      learnerNumber: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.cardNumber)
      ..writeByte(5)
      ..write(obj.nameOnCard)
      ..writeByte(6)
      ..write(obj.learnerNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
