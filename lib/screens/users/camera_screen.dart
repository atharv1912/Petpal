import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/users/LoginPage.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/SupabaseServices.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  XFile? _imageFile;
  final _formKey = GlobalKey<FormState>();
  String _animalCondition = '';
  String _animalType = '';
  String _notes = '';
  Position? _currentPosition;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocation();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final image = await _controller!.takePicture();
    setState(() => _imageFile = image);
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _submitReport() async {
    final supabaseService = SupabaseService();
    final user = supabaseService.supabase.auth.currentUser;
    if (user == null) {
      // Redirect to login page if the user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to submit a report')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    if (!_formKey.currentState!.validate() ||
        _imageFile == null ||
        _currentPosition == null) {
      print(
          "Validation failed. Ensure all fields are filled and location is available.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await supabaseService.uploadImage(_imageFile!);

      // Insert report into Supabase
      await supabaseService.insertReport(
        imageUrl: imageUrl,
        condition: _animalCondition,
        type: _animalType,
        notes: _notes,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      print("Report successfully submitted!");

      // Navigate to Home Page
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print("Error submitting report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
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
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Report Animal')),
      body:
          _imageFile == null ? CameraPreview(_controller!) : _buildReportForm(),
      floatingActionButton: _imageFile == null
          ? FloatingActionButton(
              onPressed: _takePhoto,
              child: Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Image.file(File(_imageFile!.path)),
            TextFormField(
              decoration: InputDecoration(labelText: 'Animal Type'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onChanged: (v) => _animalType = v,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Condition'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onChanged: (v) => _animalCondition = v,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Additional Notes'),
              onChanged: (v) => _notes = v,
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitReport,
                    child: Text('Submit Report'),
                  )
          ],
        ),
      ),
    );
  }
}
