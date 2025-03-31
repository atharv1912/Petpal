import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/SupabaseServices.dart';
import 'package:flutter_application_1/screens/users/permission_handler.dart';
import 'package:flutter_application_1/screens/users/HomePage.dart';

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
      Navigator.pop(context, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      ); // Return success
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: _imageFile == null,
      appBar: AppBar(
        title: Text(
          'Report Animal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: _imageFile == null ? 0 : 2,
        backgroundColor: _imageFile == null
            ? Colors.transparent.withOpacity(0.2)
            : theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: _imageFile == null ? Colors.white : null,
        ),
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
      floatingActionButton: _imageFile == null
          ? Container(
              height: 70,
              width: 70,
              margin: EdgeInsets.only(bottom: 16),
              child: _buildCameraButton(),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    if (!_isCameraInitialized && _imageFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return _imageFile == null ? _buildCameraPreview() : _buildReportForm();
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview that fills the screen but maintains aspect ratio
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),

          // Grid overlay
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),

          // Guidance text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Align animal within the grid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return FloatingActionButton(
      onPressed: _takePhoto,
      tooltip: 'Take photo',
      elevation: 5,
      highlightElevation: 8,
      child: const Icon(
        Icons.camera_alt,
        size: 32,
      ),
    );
  }

  Widget _buildReportForm() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade100],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 24),
              Text(
                'Report Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnimalTypeField(),
              const SizedBox(height: 16),
              _buildConditionField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildLocationInfo(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_imageFile!.path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAnimalTypeField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Animal Type*',
        hintText: 'e.g., Dog, Cat, Bird',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.pets),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      onChanged: (value) => _animalType = value,
    );
  }

  Widget _buildConditionField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Condition*',
        hintText: 'e.g., Injured, Healthy, Needs help',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.healing),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      onChanged: (value) => _animalCondition = value,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Additional Notes',
        hintText: 'Any other details to help responders...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.note),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      onChanged: (value) => _notes = value,
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'Location Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentPosition != null
                  ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                  : 'Location not available',
              style: TextStyle(fontSize: 15),
            ),
          ),
          if (!_locationPermissionGranted)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: _checkLocationPermission,
                icon: Icon(Icons.my_location),
                label: Text('Enable Location'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _submitReport,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: _isUploading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('UPLOADING...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text(
                  'SUBMIT REPORT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
    );
  }
}

// Custom painter for drawing the camera grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    final int horizontalLines = 2;
    final double horizontalSpacing = size.height / (horizontalLines + 1);
    for (int i = 1; i <= horizontalLines; i++) {
      final double y = horizontalSpacing * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical lines
    final int verticalLines = 2;
    final double verticalSpacing = size.width / (verticalLines + 1);
    for (int i = 1; i <= verticalLines; i++) {
      final double x = verticalSpacing * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw a center focus area (rule of thirds)
    final double focusSize = size.width * 0.5;
    final double focusX = (size.width - focusSize) / 2;
    final double focusY = (size.height - focusSize) / 2;

    final focusRect = Rect.fromLTWH(focusX, focusY, focusSize, focusSize);
    canvas.drawRect(focusRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
