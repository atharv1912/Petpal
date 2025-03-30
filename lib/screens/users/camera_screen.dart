import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/SupabaseServices.dart';
import 'package:flutter_application_1/screens/users/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  XFile? _imageFile;
  final _formKey = GlobalKey<FormState>();
  String _animalCondition = '';
  String _animalType = '';
  String _notes = '';
  Position? _currentPosition;
  bool _isUploading = false;
  bool _isCameraInitialized = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller?.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = _controller?.value.isInitialized ?? false;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to initialize camera: ${e.toString()}');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await checkLocationPermission();
      setState(() {
        _locationPermissionGranted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });

      if (_locationPermissionGranted) {
        await _getCurrentLocation();
      }
    } catch (e) {
      _showErrorSnackbar('Location permission error: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to get location: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showErrorSnackbar('Camera not ready');
      return;
    }

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;

      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Please fill all required fields');
      return;
    }

    if (_imageFile == null) {
      _showErrorSnackbar('Please take a photo first');
      return;
    }

    if (!_locationPermissionGranted) {
      final permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        _showErrorSnackbar('Location permission is required');
        return;
      }
      await _getCurrentLocation();
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final supabaseService = SupabaseService();
      final user = supabaseService.supabase.auth.currentUser;

      if (user == null) {
        _showErrorSnackbar('Please log in to submit a report');
        return;
      }

      final imageUrl = await supabaseService.uploadReportImage(
        File(_imageFile!.path),
      );

      await supabaseService.insertReport(
        imageUrl: imageUrl,
        condition: _animalCondition,
        type: _animalType,
        notes: _notes,
        lat: _currentPosition?.latitude ?? 0,
        lng: _currentPosition?.longitude ?? 0,
      );

      if (!mounted) return;
      Navigator.pop(context, true); // Return success
    } catch (e) {
      _showErrorSnackbar('Failed to submit report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Animal'),
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _retakePhoto,
              tooltip: 'Retake photo',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _imageFile == null ? _buildCameraButton() : null,
    );
  }

  Widget _buildBody() {
    if (!_isCameraInitialized && _imageFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _imageFile == null ? _buildCameraPreview() : _buildReportForm();
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildCameraButton() {
    return FloatingActionButton(
      onPressed: _takePhoto,
      tooltip: 'Take photo',
      child: const Icon(Icons.camera_alt),
    );
  }

  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildAnimalTypeField(),
            const SizedBox(height: 16),
            _buildConditionField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 24),
            _buildLocationInfo(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
      ),
    );
  }

  Widget _buildAnimalTypeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Animal Type*',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      onChanged: (value) => _animalType = value,
    );
  }

  Widget _buildConditionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Condition*',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      onChanged: (value) => _animalCondition = value,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Additional Notes',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (value) => _notes = value,
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentPosition != null
                  ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                  : 'Location not available',
            ),
            if (!_locationPermissionGranted)
              TextButton(
                onPressed: _checkLocationPermission,
                child: const Text('Enable Location'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _submitReport,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isUploading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text('SUBMIT REPORT'),
    );
  }
}
