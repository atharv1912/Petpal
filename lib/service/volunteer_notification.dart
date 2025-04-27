import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerNotifier {
  static final _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    // Setup notification channels
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'animal_reports',
          channelName: 'Animal Reports',
          channelDescription: 'Notifications for new animal reports',
          importance: NotificationImportance.High,
          defaultColor: Colors.green,
          ledColor: Colors.green,
        ),
      ],
    );

    // Listen for new reports
    _supabase
        .from('reports')
        .stream(primaryKey: ['id']).listen(_handleNewReport);
  }

  static void _handleNewReport(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return;

    final latestReport = reports.last;
    final isVolunteer =
        _supabase.auth.currentUser?.userMetadata?['is_volunteer'] ?? false;

    if (isVolunteer) {
      _showNotification(latestReport);
    }
  }

  static Future<void> _showNotification(Map<String, dynamic> report) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'animal_reports',
        title: 'New Animal Report!',
        body: '${report['type']} needs help (${report['condition']})',
        payload: {'report_id': report['id'].toString()},
      ),
    );
  }
}
