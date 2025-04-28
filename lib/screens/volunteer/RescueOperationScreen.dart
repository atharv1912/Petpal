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
        title: const Text('Rescue Operation'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          if (widget.report['image_url'] != null)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.network(
                widget.report['image_url'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
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
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_currentStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Report Details
                  Text(
                    widget.report['type'] ?? 'Unknown Type',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.report['condition'] ?? 'Unknown Condition',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Reported ${_getTimeAgo(createdAt)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location Section
                  _buildDetailSection(
                    icon: Icons.location_on,
                    title: 'Location',
                    content: '${widget.report['lat']}, ${widget.report['lng']}',
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

                  const SizedBox(height: 20),

                  // Status Update Section
                  const Text(
                    'Update Rescue Status:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusButton('In Progress', 'in_progress'),
                      _buildStatusButton('Completed', 'completed'),
                      _buildStatusButton('Failed', 'failed'),
                      _buildStatusButton('Cancelled', 'cancelled'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Additional Notes
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Enter any updates about the rescue...',
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUpdates,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE UPDATES'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMaps(
          widget.report['lat'] ?? 0.0,
          widget.report['lng'] ?? 0.0,
        ),
        backgroundColor: Colors.orange,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: action,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action != null
                    ? Colors.orange.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: action != null
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: action != null ? Colors.orange[800] : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status) {
    return ChoiceChip(
      label: Text(label),
      selected: _currentStatus == status,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentStatus = status;
          });
        }
      },
      selectedColor: _getStatusColor(status),
      labelStyle: TextStyle(
        color: _currentStatus == status ? Colors.white : Colors.black,
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
        return Colors.orange;
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
        title: const Text('Open Maps'),
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
                const SnackBar(content: Text('URL copied to clipboard')),
              );
            },
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rescue status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
