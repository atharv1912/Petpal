import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:flutter_application_1/screens/volunteer/CommunityPage.dart';
import 'package:flutter_application_1/screens/volunteer/AlertScreen.dart';
import 'package:flutter_application_1/screens/volunteer/profilePage.dart';
import 'package:flutter_application_1/screens/users/LoginPage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  final SupabaseService _supabaseService = SupabaseService();
  int _selectedIndex = 0;
  late final RealtimeChannel _reportChannel;

  static final List<Widget> _pages = [
    const CommunityPage(),
    const AlertScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupReportListener();
  }

  Future<void> _initializeNotifications() async {
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

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction action) {
        if (_selectedIndex != 1) {
          setState(() {
            _selectedIndex = 1; // Switch to Alerts tab
          });
        }
        return Future.value(true);
      },
    );
  }

  void _setupReportListener() {
    final supabase = Supabase.instance.client;
    _reportChannel = supabase.channel('reports_channel');

    _reportChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'reports',
      ),
      (payload, [ref]) {
        if (payload != null) {
          _showNewReportNotification(payload['new']);
        }
      },
    ).subscribe();
  }

  Future<void> _showNewReportNotification(Map<String, dynamic> report) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'animal_reports',
        title: 'New Animal Report!',
        body: '${report['type']} needs help (${report['condition']})',
      ),
    );
  }

  @override
  void dispose() {
    _reportChannel.unsubscribe();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFFFF4E0),
        onTap: _onItemTapped,
      ),
    );
  }
}
