import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera bulunamadı'))
          );
        }
      }
    } catch (e) {
      print('Kamera hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera başlatılırken hata oluştu'))
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed && _controller != null) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      // Burada görüntü işleme yapılacak
      // Şimdilik sadece bilgi mesajı gösterelim
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf çekildi: ${image.path}'))
        );
      }
    } catch (e) {
      print('Fotoğraf çekme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf çekilirken hata oluştu'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Galeriden resim seçildi: ${pickedFile.path}'))
          );
        }
      }
    } catch (e) {
      print('Galeriden resim seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resim seçilirken hata oluştu'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Malzeme Tara')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Malzeme Tara')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    onPressed: _isProcessing ? null : _takePicture,
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera_alt, size: 32),
                  ),
                ),
                const IconButton(
                  onPressed: null, // Placeholder for flash toggle
                  icon: Icon(Icons.flash_off, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}