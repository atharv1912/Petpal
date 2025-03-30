import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/users/LoginPage.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:flutter_application_1/screens/users/camera_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/users/profile-page.dart';

// Import the global supabase client
final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _supabaseService = SupabaseService();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO Animal Rescue"),
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton.icon(
              onPressed: () async {
                // Fixed: Pass context to logout method and handle navigation
                await _supabaseService.logout();
                // Navigate to login page after logout
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
              ? CameraScreen()
              : _selectedIndex == 2
                  ? ProfilePage() // Direct navigation to camera screen
                  : Center(
                      child: Text(
                        "Profile Page",
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFFFFF4E0),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fixed: add a delay to avoid infinite navigation loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Widget _buildHomeContent() {
    return Container(
      color: Color(0xFFFFFBEB), // Light cream background color
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'See an injured animal?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click. Upload. Help.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Together, we rescue.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Animal illustration
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/animals.png', // You'll need to add this asset
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey.withOpacity(0.3),
                            child: const Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CameraScreen()),
                    );

                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Report submitted successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Upload photo of an injured animal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
