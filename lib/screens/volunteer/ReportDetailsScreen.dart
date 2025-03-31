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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.orange),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                if (report['image_url'] != null)
                  Stack(
                    children: [
                      Hero(
                        tag: 'report-image-${report['id']}',
                        child: Container(
                          height: 280,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: Image.network(
                              report['image_url'],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.black26,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    top: report['image_url'] != null ? 0 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report['image_url'] == null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        '${report['type']}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reported ${_getTimeAgo(createdAt)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildDetailSection(
                        context: context,
                        icon: Icons.location_on,
                        title: 'Location',
                        content: '${report['lat']}, ${report['lng']}',
                        action: () => _openMaps(report['lat'], report['lng']),
                      ),
                      if (report['address'] != null)
                        _buildDetailSection(
                          context: context,
                          icon: Icons.place,
                          title: 'Address',
                          content: report['address'],
                        ),
                      if (report['reporter_name'] != null)
                        _buildDetailSection(
                          context: context,
                          icon: Icons.person,
                          title: 'Reporter',
                          content: report['reporter_name'],
                        ),
                      if (report['reporter_contact'] != null)
                        _buildDetailSection(
                          context: context,
                          icon: Icons.phone,
                          title: 'Contact',
                          content: report['reporter_contact'],
                          action: () =>
                              _makePhoneCall(report['reporter_contact']),
                        ),
                      if (report['notes'] != null &&
                          report['notes'].toString().isNotEmpty)
                        _buildDetailSection(
                          context: context,
                          icon: Icons.notes,
                          title: 'Notes',
                          content: report['notes'],
                        ),
                      if (report['volunteer_name'] != null)
                        _buildDetailSection(
                          context: context,
                          icon: Icons.volunteer_activism,
                          title: 'Assigned Volunteer',
                          content: report['volunteer_name'],
                        ),
                      const SizedBox(
                          height: 100), // Space for the bottom button
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
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _handleRescueAndNavigate(context),
                  icon: const Icon(Icons.directions),
                  label: const Text(
                    'RESCUE AND NAVIGATE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                SizedBox(height: 20),
                Text(
                  'Accepting rescue...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );

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

      // Close the loading dialog
      Navigator.pop(context);

      // Then open navigation
      await _openMaps(
        double.parse(report['lat'].toString()), // Ensure lat is double
        double.parse(report['lng'].toString()), // Ensure lng is double
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Text('Rescue accepted! Opening navigation...'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      // Close the screen after successful operation
      Navigator.pop(context, true); // Pass true to indicate success
    } catch (e) {
      // Close the loading dialog if it's still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Failed to accept rescue: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  Widget _buildDetailSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: action,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: action != null
                    ? Colors.orange.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: action != null
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 15,
                        color: action != null
                            ? Colors.orange.shade800
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (action != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.orange,
                    ),
                ],
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to share this rescue report',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              _buildShareOption(
                context: context,
                icon: Icons.copy,
                title: 'Copy to clipboard',
                subtitle: 'Copy report details to paste elsewhere',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 16),
                          Text('Report details copied to clipboard'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  );
                  Clipboard.setData(ClipboardData(text: message));
                },
              ),
              _buildShareOption(
                context: context,
                icon: Icons.message,
                title: 'Share via message',
                subtitle: 'Send the report through SMS',
                onTap: () {
                  Navigator.pop(context);
                  _shareViaSMS(message);
                },
              ),
              _buildShareOption(
                context: context,
                icon: Icons.email,
                title: 'Share via email',
                subtitle: 'Send the report through email',
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

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
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
