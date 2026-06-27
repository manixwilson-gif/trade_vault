import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';


// Zoomable Image Preview (perfect for inspecting certification small print)
class FullScreenImageView extends StatelessWidget {
  final String filePath;
  const FullScreenImageView({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Image Preview'),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(filePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}