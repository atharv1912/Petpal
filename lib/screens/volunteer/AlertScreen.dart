import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_application_1/screens/volunteer/ReportDetailsScreen.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Stream<List<Map<String, dynamic>>> _reportsStream;
  bool _showOnlyPending = true;
  late RealtimeChannel _reportsChannel;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
    _setupReportsStream();
  }

  @override
  void dispose() {
    _reportsChannel.unsubscribe();
    super.dispose();
  }

  void _setupReportsStream() {
    setState(() {
      _isInitialLoad = true;
    });

    _reportsStream = (_showOnlyPending
            ? _supabaseService.getPendingReportsStream()
            : _supabaseService.getAllReportsStream())
        .map<List<Map<String, dynamic>>>((reports) {
      return (reports as List).cast<Map<String, dynamic>>();
    }).handleError((error) {
      debugPrint('Error in reports stream: $error');
      return <Map<String, dynamic>>[];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  void _setupRealTimeListener() {
    final supabase = _supabaseService.supabase;
    _reportsChannel = supabase.channel('reports_changes');

    _reportsChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*', // Listen to all events: INSERT, UPDATE, DELETE
        schema: 'public',
        table: 'reports',
      ),
      (payload, [ref]) {
        if (!mounted) return;

        if (_showOnlyPending &&
            payload.eventType == 'UPDATE' &&
            payload.newRecord['status'] != 'pending') {
          return;
        }

        // Refresh the stream
        _setupReportsStream();
      },
    ).subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Rescue Alerts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Row(
            children: [
              const Text(
                'Pending Only',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Switch(
                value: _showOnlyPending,
                onChanged: (value) {
                  setState(() {
                    _showOnlyPending = value;
                    _setupReportsStream();
                  });
                },
                activeColor: Colors.orange,
                activeTrackColor: Colors.orange.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFFFFBEB),
            ],
          ),
        ),
        child: _isInitialLoad
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              )
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _reportsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final reports = _showOnlyPending
                      ? snapshot.data
                              ?.where((r) => r['status'] == 'pending')
                              .toList() ??
                          []
                      : snapshot.data ?? [];

                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showOnlyPending
                                ? 'No pending alerts'
                                : 'No alerts available',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'All clear for now!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportCard(report);
                    },
                  );
                },
              ),
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

  Widget _buildReportCard(Map<String, dynamic> report) {
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
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(report: report),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report['image_url'] != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Image.network(
                        report['image_url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 200,
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
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
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
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report['image_url'] == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
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
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${report['type']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${report['condition']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _getTimeAgo(createdAt),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location: ${report['lat']}, ${report['lng']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (report['notes'] != null &&
                        report['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['notes'] ?? 'No additional notes',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    if (report['status'] == 'pending') ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _handleReportAction(report['id'], 'assigned'),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('ACCEPT'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _handleReportAction(report['id'], 'rejected'),
                              icon: const Icon(Icons.cancel),
                              label: const Text('REJECT'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> _handleReportAction(dynamic reportId, String status) async {
    try {
      // Convert reportId to string if it's not already
      final String reportIdStr = reportId.toString();

      await _supabaseService.updateReportStatus(
        reportId: reportIdStr,
        status: status,
      );

      if (status == 'assigned') {
        final userId = _supabaseService.getCurrentUserId();
        if (userId != null) {
          await _supabaseService.assignVolunteer(
            reportId: reportIdStr,
            volunteerId: userId,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status == 'assigned' ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  status == 'assigned'
                      ? 'Alert accepted successfully!'
                      : 'Alert rejected successfully!',
                ),
              ],
            ),
            backgroundColor: status == 'assigned' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update alert: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      debugPrint('Error in _handleReportAction: $e');
    }
  }
}
