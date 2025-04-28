import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class RescueOperationScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const RescueOperationScreen({super.key, required this.report});

  @override
  State<RescueOperationScreen> createState() => _RescueOperationScreenState();
}

class _RescueOperationScreenState extends State<RescueOperationScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _notesController = TextEditingController();
  String _currentStatus = 'assigned';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['status'] ?? 'assigned';
    _notesController.text = widget.report['notes'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final String createdAt =
        widget.report['created_at'] ?? DateTime.now().toIso8601String();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rescue Operation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF4E0),
        foregroundColor: Colors.deepOrange,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF4E0)],
          ),
        ),
        child: Column(
          children: [
            if (widget.report['image_url'] != null)
              Hero(
                tag: 'report-image-${widget.report['id']}',
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.network(
                      widget.report['image_url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepOrange,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                size: 50, color: Colors.deepOrange),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_currentStatus)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _currentStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_currentStatus),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Report Details
                    Text(
                      widget.report['type'] ?? 'Unknown Type',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.report['condition'] ?? 'Unknown Condition',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Reported ${_getTimeAgo(createdAt)}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Location Section
                    _buildDetailSection(
                      icon: Icons.location_on,
                      title: 'Location',
                      content:
                          '${widget.report['lat']}, ${widget.report['lng']}',
                      action: () => _openMaps(
                        widget.report['lat'] ?? 0.0,
                        widget.report['lng'] ?? 0.0,
                      ),
                    ),

                    if (widget.report['address'] != null)
                      _buildDetailSection(
                        icon: Icons.place,
                        title: 'Address',
                        content: widget.report['address'],
                      ),

                    if (widget.report['notes'] != null &&
                        widget.report['notes'].toString().isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.notes,
                        title: 'Original Notes',
                        content: widget.report['notes'],
                      ),

                    const SizedBox(height: 24),

                    // Status Update Section
                    const Text(
                      'Update Rescue Status:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStatusButton('In Progress', 'in_progress'),
                        _buildStatusButton('Completed', 'completed'),
                        _buildStatusButton('Failed', 'failed'),
                        _buildStatusButton('Cancelled', 'cancelled'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Additional Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.deepOrange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.deepOrange, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        hintText: 'Enter any updates about the rescue...',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUpdates,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              )
                            : const Text(
                                'SAVE UPDATES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMaps(
          widget.report['lat'] ?? 0.0,
          widget.report['lng'] ?? 0.0,
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 4,
        child: const Icon(Icons.directions, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: action,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: action != null
                    ? Colors.deepOrange.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: action != null
                      ? Colors.deepOrange.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: action != null ? Colors.deepOrange : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status) {
    final bool isSelected = _currentStatus == status;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentStatus = status;
          });
        }
      },
      selectedColor: _getStatusColor(status),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.deepOrange;
    }
  }

  String _getTimeAgo(String createdAt) {
    try {
      final DateTime dateTime = DateTime.parse(createdAt);
      return timeago.format(dateTime);
    } catch (e) {
      return 'recently';
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    // Validate coordinates first
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid coordinates'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Format coordinates to 6 decimal places
    final latStr = lat.toStringAsFixed(6);
    final lngStr = lng.toStringAsFixed(6);

    try {
      // Platform-specific map URLs
      Uri uri;
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // Apple Maps URL for iOS
        uri = Uri.parse('https://maps.apple.com/?q=$latStr,$lngStr');
      } else {
        // Google Maps URL for Android and other platforms
        uri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$latStr,$lngStr');
      }

      // Try to launch the URL
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to web URL if platform-specific fails
        final webUri =
            Uri.parse('https://www.google.com/maps?q=$latStr,$lngStr');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showCopyableUrlDialog(webUri.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Show dialog with copyable URL as a fallback
        _showCopyableUrlDialog('https://www.google.com/maps?q=$latStr,$lngStr');
      }
    }
  }

  void _showCopyableUrlDialog(String url) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Open Maps', style: TextStyle(color: Colors.deepOrange)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not open maps automatically.'),
            const SizedBox(height: 10),
            SelectableText(url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUpdates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting update process...');

      // Update report status
      await _supabaseService.updateReportStatus(
        reportId: widget.report['id'].toString(),
        status: _currentStatus,
      );
      print('Report status updated to $_currentStatus');

      // Add rescue update notes if they exist
      if (_notesController.text.isNotEmpty) {
        await _supabaseService.addRescueUpdate(
          reportId: widget.report['id'].toString(),
          status: _currentStatus,
          updateNotes: _notesController.text,
        );
        print('Added rescue update notes');
      }

      // If status is completed, send appreciation message
      if (_currentStatus == 'completed') {
        print('Rescue completed - preparing appreciation message');

        final volunteerId = _supabaseService.supabase.auth.currentUser?.id;
        final reporterId = widget.report['user_id'];

        print('Volunteer ID: $volunteerId, Reporter ID: $reporterId');

        if (volunteerId != null && reporterId != null) {
          try {
            await _supabaseService.sendAppreciationMessage(
              reportId: widget.report['id'].toString(),
              volunteerId: volunteerId,
              reporterId: reporterId.toString(), // Ensure string type
            );
            print('Appreciation message sent successfully');
          } catch (e) {
            print('Error sending appreciation message: $e');
            // Show error but don't block the success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Rescue completed but could not send community message'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          print('Missing IDs - Volunteer: $volunteerId, Reporter: $reporterId');
        }
      }

      if (mounted) {
        // Show a more elegant success dialog instead of just a snackbar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Success!',
              style: TextStyle(
                  color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('Rescue status updated successfully'),
              ],
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to previous screen
                },
                child: const Text('OK',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error in _saveUpdates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
