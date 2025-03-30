import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFBEB),
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: SupabaseService().getAllNGOs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final ngos = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Hub',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: ngos.length,
                    itemBuilder: (context, index) {
                      final ngo = ngos[index];
                      return Card(
                        child: ListTile(
                          leading: ngo['logo_url'] != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(ngo['logo_url']),
                                )
                              : const CircleAvatar(child: Icon(Icons.people)),
                          title: Text(ngo['name'] ?? 'NGO'),
                          subtitle: Text(ngo['location'] ?? ''),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to NGO details
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
