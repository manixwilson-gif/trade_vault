import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // Used for generating unique timestamp strings
import 'package:image/image.dart' as img; // Pure Dart image processing

class ScanCardScreen extends StatefulWidget {
  final bool isSingleShot; // ◄ Make sure this is declared here
  const ScanCardScreen({super.key, required this.isSingleShot});

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
  String? _lastCapturedPath;

  // ◄ ADD THIS OVERRIDE FLAG so the instruction dialog says 'Scan Card' instead of 'Front/Back'
  bool get _isSingleShotMode => widget.isSingleShot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraSystem();
    });
  }

  Future<void> _initializeCameraSystem() async {
    try {
      // 1. Explicit Camera Permission Check
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to scan cards.')),
          );
          Navigator.pop(context);
          return;
        }
      }

      // 2. Show Instruction Dialog
      if (!mounted) return;
      await showInstructionDialog();

      // 3. Initialize Camera Controller
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) throw Exception('No cameras found on device.');

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      // ◄ FORCE the flash mode completely off instantly upon initialization
      try {
        await _controller!.setFlashMode(FlashMode.off);
      } catch (e) {
        // Fail silently if the specific device hardware doesn't permit software flash overrides
      }
      
      // Verify flash stays off on the hardware layer right after the preview mounts
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_controller != null && _controller!.value.isInitialized) {
          try {
            await _controller!.setFlashMode(FlashMode.off);
          } catch (_) {}
        }
      });
      
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

 Future<void> showInstructionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: Text(
            _isSingleShotMode 
                ? 'Scan Card' 
                : (isScanningFront ? 'Scan Front of Card' : 'Scan Back of Card'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            _isSingleShotMode
                ? 'Hold phone vertically. Align the card within the orange frame, then tap capture.'
                : (isScanningFront 
                    ? 'Hold phone vertically. Align the FRONT of the card within the orange frame, then tap capture.' 
                    : 'Flip the card over. Align the BACK of the card within the orange frame, then tap capture.'),
            style: const TextStyle(color: Colors.white70),
          ),
         // ◄ ADD THE PROCEED BUTTON BACK IN HERE:
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B00)),
            child: const Text('Proceed'),
            onPressed: () => Navigator.of(context).pop(), // Closes the dialog so camera initializes
          ),
        ],
      );
    },
  );
}

  Future<String> _getUniquePersistPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmssSSS').format(DateTime.now());
    final sideLabel = isScanningFront ? 'front' : 'back';
    return p.join(directory.path, 'vault_card_${sideLabel}_$timestamp.jpg');
  }

  Future<void> _captureImage() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      XFile imageFile = await _controller!.takePicture();

      if (!mounted) {
        setState(() { _isProcessing = false; });
        return;
      }

      // 1. Copy full-frame image to unique location using standard I/O
      final persistPath = await _getUniquePersistPath();
      final savedFile = await File(imageFile.path).copy(persistPath);

      // 2. Pure Dart processing: Decode and re-encode to ensure data stability across OS versions
      final rawImageInput = img.decodeImage(await savedFile.readAsBytes());
      if (rawImageInput != null) {
        final stabilizedBytes = img.encodeJpg(rawImageInput, quality: 90);
        await File(savedFile.path).writeAsBytes(stabilizedBytes);
      }

      // 3. FREEZE PREVIEW: Show the captured image on screen immediately
      setState(() {
        _lastCapturedPath = savedFile.path;
        _isProcessing = false;
      });

      // 4. HUMAN CONFIRMATION PAUSE: Hold the freeze for 1200 milliseconds
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      // ◄ NEW LOGIC: If we are in single-shot mode, just pop the screen and return the single path!
      if (_isSingleShotMode) {
        setState(() {
          _lastCapturedPath = null;
        });
        Navigator.pop(context, {
          'frontImage': savedFile.path, // We drop it cleanly into the front/only slot
          'backImage': null,
        });
        return;
      }

      // Otherwise, run your standard two-sided flow
      if (isScanningFront) {
        setState(() {
          frontImagePath = savedFile.path;
          isScanningFront = false;
          _lastCapturedPath = null; // Clear the freeze so the camera preview returns
        });
        
        await showInstructionDialog();
      } else {
        setState(() {
          backImagePath = savedFile.path;
          _lastCapturedPath = null;
        });
        
        if (!mounted) return;
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
        _lastCapturedPath = null;
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
          // 1. Live Camera Preview (Only show if we aren't freezing a preview)
          if (_lastCapturedPath == null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
          // 2. Frozen Shutter Flash Preview
            Positioned.fill(
              child: Image.file(
                File(_lastCapturedPath!),
                fit: BoxFit.cover,
              ),
            ),
          
          // Darken the surrounding area (Skip during actual freeze to keep it clear)
          if (_lastCapturedPath == null) ...[
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

          // Shutter Capture Button (Hide during freeze so it doesn't overlap the preview)
          if (_lastCapturedPath == null)
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

          // Subtext guide (Properly nested inside the main Stack children array)
          if (_lastCapturedPath == null)
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
            
        ], // Terminates your Stack children list!
      ), // Closes the Stack
    ); // Closes the Scaffold
  } // Closes the build method
} // Closes the _ScanCardScreenState class