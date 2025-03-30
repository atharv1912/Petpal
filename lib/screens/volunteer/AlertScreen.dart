import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Stream<List<Map<String, dynamic>>> _reportsStream;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _showOnlyPending = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _reportsStream = _supabaseService.getPendingReportsStream();
    _setupRealTimeListener();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  void _setupRealTimeListener() {
    _supabaseService.supabase
        .channel('reports_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reports',
          callback: (payload) {
            if (payload.newRecord['status'] == 'pending') {
              _showNewReportNotification(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  void _showNewReportNotification(Map<String, dynamic> report) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rescue_alerts_channel',
      'Rescue Alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _notificationsPlugin.show(
      0,
      'New Rescue Alert: ${report['type']}',
      'Location: ${report['lat']}, ${report['lng']}',
      platformChannelSpecifics,
      payload: report['id'].toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Alerts'),
        actions: [
          Switch(
            value: _showOnlyPending,
            onChanged: (value) => setState(() => _showOnlyPending = value),
            activeColor: Colors.orange,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFFFFBEB),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _reportsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = _showOnlyPending
                ? snapshot.data!
                : snapshot.data!
                    .where((r) => r['status'] != 'pending')
                    .toList();

            if (reports.isEmpty) {
              return const Center(child: Text('No alerts available'));
            }

            return ListView.builder(
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

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report['image_url'] != null)
              Image.network(
                report['image_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 12),
            Text(
              '${report['type']} - ${report['condition']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Location: ${report['lat']}, ${report['lng']}'),
            const SizedBox(height: 8),
            Text(report['notes'] ?? 'No additional notes'),
            const SizedBox(height: 12),
            if (report['status'] == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleReportAction(report['id'], 'assigned'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green)),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleReportAction(report['id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                      child: const Text('REJECT'),
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

  Future<void> _handleReportAction(String reportId, String status) async {
    try {
      await _supabaseService.updateReportStatus(
          reportId: reportId, status: status);
      if (status == 'assigned') {
        final userId = _supabaseService.getCurrentUserId();
        if (userId != null) {
          await _supabaseService.assignVolunteer(
              reportId: reportId, volunteerId: userId);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update report: $e')),
      );
    }
  }
}
