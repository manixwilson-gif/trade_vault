import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});

  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  bool isScanningFront = true;
  bool _isInitializing = true;
  bool _isProcessing = false;
  
  String? frontImagePath;
  String? backImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraFlow();
    });
  }

  Future<void> _initializeCameraFlow() async {
    try {
      // 1. Explicit Camera Permission
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required.')),
          );
          Navigator.pop(context);
          return;
        }
      }

      // 2. Show instruction dialog before initializing viewfinder
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: Text(
              isScanningFront ? 'Scan Front of Card' : 'Scan Back of Card',
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              isScanningFront 
                  ? 'Hold phone vertically. Align the FRONT of the card within the orange frame, then tap capture.' 
                  : 'Flip the card over. Align the BACK of the card within the orange frame, then tap capture.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B00)),
                child: const Text('Proceed'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );

      // 3. Find available cameras and initialize the controller
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) throw Exception('No cameras found on device.');

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      // ◄◄ ADD A SLIGHT ZOOM TO MAGNIFY THE CARD IN THE VIEWFINDER ◄◄
      
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization error: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<String> _getTempFilePath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, fileName);
  }

  Future<void> _captureImage() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take high-resolution picture
      XFile imageFile = await _controller!.takePicture();

      if (!mounted) return;

      // Hand off to Cropper
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 70,
        aspectRatio: const CropAspectRatio(ratioX: 1.586, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Card Bounds',
            toolbarColor: const Color(0xFF121212),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Adjust Card Bounds',
          ),
        ],
      );

      if (!mounted) {
        setState(() { _isProcessing = false; });
        return;
      }

      if (croppedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crop cancelled')),
        );
        setState(() { _isProcessing = false; });
        return;
      }

      // Save cropped file locally to temporary directory
      final fileName = isScanningFront ? 'temp_front.jpg' : 'temp_back.jpg';
      final savePath = await _getTempFilePath(fileName);
      final savedFile = await File(croppedFile.path).copy(savePath);

      if (isScanningFront) {
        setState(() {
          frontImagePath = savedFile.path;
          isScanningFront = false;
          _isProcessing = false;
        });
        // Re-initialize viewfinder for the back of the card
        _initializeCameraFlow();
      } else {
        setState(() {
          backImagePath = savedFile.path;
        });
        // Complete workflow, pass paths back to parent form
        Navigator.pop(context, {
          'frontImage': frontImagePath,
          'backImage': backImagePath,
        });
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture error: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preparing Viewfinder...'),
          backgroundColor: const Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF121212),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isScanningFront ? 'Scan Front of Card' : 'Scan Back of Card'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Preview stretching across the available space
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Darken the surrounding area to make the framing guide pop
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54, 
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // Transparent cutout window matching the credit card aspect ratio
                Center(
                  child: Container(
                    width: 414,
                    height: 286,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Glowing orange border overlay highlighting the credit card bounds
          Center(
            child: IgnorePointer(
              child: Container(
                width: 414,
                height: 286,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF6B00),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Shutter Capture Button at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40),
              child: _isProcessing
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture Image', style: TextStyle(fontSize: 16)),
                      onPressed: _captureImage,
                    ),
            ),
          ),

          // Subtext guide
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 110),
              child: Text(
                'Fit the card completely inside the orange frame',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}