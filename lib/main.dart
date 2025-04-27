import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/notification_controller.dart';
import 'package:flutter_application_1/service/volunteer_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/users/LoginPage.dart';
import 'package:flutter_application_1/screens/users/HomePage.dart';
import 'package:flutter_application_1/screens/volunteer/VolunteerDashboard.dart';
import 'package:flutter_application_1/service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zuicmikqkapgodejaxob.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1aWNtaWtxa2FwZ29kZWpheG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3MDU1NzUsImV4cCI6MjA1ODI4MTU3NX0.cboQllH0cO6llyjbLHIRCgaGvKHfjGIOmrj7bMpzWt0',
    // Removed invalid authOptions parameter
  );
  await NotificationService.initialize();
  await VolunteerNotifier.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NGO Animal Rescue',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final supabase = Supabase.instance.client;
  late StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
  }

  Future<void> _initializeAuth() async {
    try {
      // Set up the auth state change listener first
      _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _redirectBasedOnRole();
        } else if (data.event == AuthChangeEvent.signedOut) {
          _redirectToLogin();
        }
      });

      // Check if a session exists and is still valid
      final session = supabase.auth.currentSession;

      if (session != null && !session.isExpired) {
        // User is already logged in, redirect based on role
        await _redirectBasedOnRole();
      } else {
        // No valid session, show login page
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Auth initialization error: $e');
    }
  }

  Future<void> _redirectBasedOnRole() async {
    try {
      final userRole = await _getUserRole();

      if (mounted) {
        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => userRole == 'volunteer'
                ? const VolunteerDashboard()
                : const HomePage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      print('Role redirect error: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<String> _getUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final response = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      return response['role'] ?? 'user';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user'; // Default to user role if there's an error
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('An error occurred'),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _initializeAuth();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const LoginPage();
  }
}
