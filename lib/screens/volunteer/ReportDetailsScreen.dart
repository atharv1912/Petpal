import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:flutter/services.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final SupabaseService _supabaseService = SupabaseService();

  ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final String createdAt =
        report['created_at'] ?? DateTime.now().toIso8601String();
    final Color statusColor = report['status'] == 'pending'
        ? Colors.orange
        : report['status'] == 'assigned'
            ? Colors.green
            : Colors.red;

    final String statusText = report['status'] == 'pending'
        ? 'PENDING'
        : report['status'] == 'assigned'
            ? 'ASSIGNED'
            : 'REJECTED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (report['image_url'] != null)
                  Hero(
                    tag: 'report-image-${report['id']}',
                    child: Image.network(
                      report['image_url'],
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 300,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.black26,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${report['type']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${report['condition']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reported ${_getTimeAgo(createdAt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        icon: Icons.location_on,
                        title: 'Location',
                        content: '${report['lat']}, ${report['lng']}',
                        action: () => _openMaps(report['lat'], report['lng']),
                      ),
                      if (report['address'] != null)
                        _buildDetailSection(
                          icon: Icons.place,
                          title: 'Address',
                          content: report['address'],
                        ),
                      if (report['reporter_name'] != null)
                        _buildDetailSection(
                          icon: Icons.person,
                          title: 'Reporter',
                          content: report['reporter_name'],
                        ),
                      if (report['reporter_contact'] != null)
                        _buildDetailSection(
                          icon: Icons.phone,
                          title: 'Contact',
                          content: report['reporter_contact'],
                          action: () =>
                              _makePhoneCall(report['reporter_contact']),
                        ),
                      if (report['notes'] != null &&
                          report['notes'].toString().isNotEmpty)
                        _buildDetailSection(
                          icon: Icons.notes,
                          title: 'Notes',
                          content: report['notes'],
                        ),
                      if (report['volunteer_name'] != null)
                        _buildDetailSection(
                          icon: Icons.volunteer_activism,
                          title: 'Assigned Volunteer',
                          content: report['volunteer_name'],
                        ),
                      const SizedBox(height: 80), // Space for the bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (report['status'] == 'pending')
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () => _handleRescueAndNavigate(context),
                icon: const Icon(Icons.directions),
                label: const Text(
                  'RESCUE AND NAVIGATE',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleRescueAndNavigate(BuildContext context) async {
    try {
      // First accept the rescue request
      await _supabaseService.updateReportStatus(
        reportId: report['id'].toString(), // Ensure ID is string
        status: 'assigned',
      );

      // Assign the current user as the volunteer
      final userId = _supabaseService.getCurrentUserId();
      if (userId != null) {
        await _supabaseService.assignVolunteer(
          reportId: report['id'].toString(), // Ensure ID is string
          volunteerId: userId.toString(), // Ensure user ID is string
        );
      }

      // Then open navigation
      await _openMaps(
        double.parse(report['lat'].toString()), // Ensure lat is double
        double.parse(report['lng'].toString()), // Ensure lng is double
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rescue accepted! Opening navigation...'),
          backgroundColor: Colors.green,
        ),
      );

      // Close the screen after successful operation
      Navigator.pop(context, true); // Pass true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept rescue: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              Icon(icon, size: 20, color: Colors.orange),
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
          const SizedBox(height: 4),
          GestureDetector(
            onTap: action,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String createdAt) {
    try {
      final DateTime dateTime = DateTime.parse(createdAt);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    String appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lng';
    String googleMapsAppUrl = 'comgooglemaps://?q=$lat,$lng';

    // Check if Google Maps app is installed (only for Android)
    // if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
    //   await launchUrl(Uri.parse(googleMapsAppUrl));
    //   return;
    // }

    // // Open Apple Maps (for iOS)
    // if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
    //   await launchUrl(Uri.parse(appleMapsUrl));
    //   return;
    // }

    // Open Google Maps in Browser
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication);
      return;
    }

    // Show message if nothing works
    throw 'No maps application found. Please install Google Maps.';
  }

  Future<void> _openPlayStoreForMaps() async {
    const playStoreUrl = 'https://play.google.com/store/search?q=maps&c=apps';
    if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
      await launchUrl(Uri.parse(playStoreUrl));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _shareReport(BuildContext context) {
    final String message = 'Rescue Alert: ${report['type']}\n'
        'Condition: ${report['condition']}\n'
        'Location: ${report['lat']}, ${report['lng']}\n'
        'Reported: ${_getTimeAgo(report['created_at'])}';

    // Show share dialog
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy to clipboard'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report details copied to clipboard'),
                    ),
                  );
                  Clipboard.setData(ClipboardData(text: message));
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Share via message'),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaSMS(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Share via email'),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaEmail(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareViaSMS(String message) async {
    final url = 'sms:?body=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _shareViaEmail(String message) async {
    final url =
        'mailto:?subject=Rescue Alert&body=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
