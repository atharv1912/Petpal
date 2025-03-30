import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'AlertScreen.dart';
import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  final SupabaseService _supabaseService = SupabaseService();

  CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFFFBEB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Volunteer Community',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connect. Collaborate. Rescue.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 30),
                // Community stats cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Rescues Today', '12', Icons.pets),
                    _buildStatCard('Active Volunteers', '24', Icons.people),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Pending Alerts', '5', Icons.notifications),
                    _buildStatCard('Completed', '42', Icons.check_circle),
                  ],
                ),
                const SizedBox(height: 30),
                // Quick actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      context,
                      'View Alerts',
                      Icons.notifications_active,
                      Colors.pink,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AlertScreen()),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      'My Assignments',
                      Icons.assignment,
                      Colors.blue,
                      () {
                        // Navigate to assignments
                      },
                    ),
                    _buildActionButton(
                      context,
                      'Resources',
                      Icons.library_books,
                      Colors.green,
                      () {
                        // Navigate to resources
                      },
                    ),
                    _buildActionButton(
                      context,
                      'Team Chat',
                      Icons.chat,
                      Colors.purple,
                      () {
                        // Navigate to chat
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon,
      Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
