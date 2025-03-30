import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({Key? key}) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final SupabaseService supabaseService = SupabaseService();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _showOnlyPending = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReports();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await supabaseService.getAllReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load reports: $e');
    }
  }

  void _setupRealtimeSubscription() {
    supabaseService.supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() => _reports = data);
          }
        });
  }

  Future<void> _handleReportAction(String reportId, String action) async {
    try {
      await supabaseService.updateReportStatus(
        reportId: reportId,
        status: action,
      );

      // If accepting, create an assignment
      if (action == 'assigned') {
        final currentUserId = supabaseService.getCurrentUserId();
        if (currentUserId != null) {
          await supabaseService.assignVolunteer(
            reportId: reportId,
            volunteerId: currentUserId,
          );
        }
      }

      _showSuccessSnackbar('Report marked as $action');
    } catch (e) {
      _showErrorSnackbar('Failed to update report: $e');
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackbar('Could not launch maps');
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _showOnlyPending
        ? _reports.where((report) => report['status'] == 'pending').toList()
        : _reports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Alerts'),
        actions: [
          IconButton(
            icon: Icon(
                _showOnlyPending ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () =>
                setState(() => _showOnlyPending = !_showOnlyPending),
            tooltip: _showOnlyPending ? 'Show All' : 'Show Pending Only',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: filteredReports.isEmpty
                  ? const Center(child: Text('No alerts available'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status']?.toString().toLowerCase() ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report['image_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 180,
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${report['type'] ?? 'Unknown'} - ${report['condition'] ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isPending)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report['notes'] ?? 'No additional notes',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _openMaps(
                    (report['lat'] as num?)?.toDouble() ?? 0,
                    (report['lng'] as num?)?.toDouble() ?? 0,
                  ),
                  child: Text(
                    'View Location on Map',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported: ${_formatDate(report['created_at'])}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleReportAction(report['id'], 'assigned'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                      ),
                      child: const Text(
                        'ACCEPT',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleReportAction(report['id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'REJECT',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
