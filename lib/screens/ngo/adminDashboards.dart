// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/auth/SupabaseServices.dart';

// import 'package:provider/provider.dart';

// class AdminPanel extends StatelessWidget {
//   const AdminPanel({super.key});

//   @override

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Panel'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               final supabaseService =
//                   Provider.of<SupabaseService>(context, listen: false);
//               await supabaseService.logout();
//               Navigator.pushNamedAndRemoveUntil(
//                   context, '/login', (route) => false);
//             },
//           ),
//         ],
//       ),
//       body: const VolunteersList(),
//     );
//   }
// }

// class VolunteersList extends StatelessWidget {
//   const VolunteersList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final supabaseService = Provider.of<SupabaseService>(context);

//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: supabaseService.getUsersByRole('volunteer'),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final volunteers = snapshot.data!;

//         if (volunteers.isEmpty) {
//           return const Center(child: Text('No volunteers found'));
//         }

//         return ListView.builder(
//           itemCount: volunteers.length,
//           itemBuilder: (context, index) {
//             final volunteer = volunteers[index];
//             return VolunteerCard(volunteer: volunteer);
//           },
//         );
//       },
//     );
//   }
// }

// class VolunteerCard extends StatelessWidget {
//   final Map<String, dynamic> volunteer;

//   const VolunteerCard({
//     super.key,
//     required this.volunteer,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundImage: volunteer['profile_picture'] != null
//               ? NetworkImage(volunteer['profile_picture'])
//               : null,
//           child: volunteer['profile_picture'] == null
//               ? const Icon(Icons.person)
//               : null,
//         ),
//         title: Text(volunteer['name']),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(volunteer['email']),
//             Text(volunteer['phone_number']),
//           ],
//         ),
//         trailing: const Icon(Icons.arrow_forward),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VolunteerDetailsPage(volunteer: volunteer),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class VolunteerDetailsPage extends StatelessWidget {
//   final Map<String, dynamic> volunteer;

//   const VolunteerDetailsPage({
//     super.key,
//     required this.volunteer,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final supabaseService = Provider.of<SupabaseService>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(volunteer['name']),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: volunteer['profile_picture'] != null
//                     ? NetworkImage(volunteer['profile_picture'])
//                     : null,
//                 child: volunteer['profile_picture'] == null
//                     ? const Icon(Icons.person, size: 50)
//                     : null,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Contact Information',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 8),
//             Text('Email: ${volunteer['email']}'),
//             Text('Phone: ${volunteer['phone_number']}'),
//             const Divider(),
//             Text(
//               'Volunteer Report',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 8),
//             FutureBuilder<Map<String, dynamic>>(
//               future: _getVolunteerReport(supabaseService, volunteer['id']),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 }

//                 if (!snapshot.hasData) {
//                   return const CircularProgressIndicator();
//                 }

//                 final report = snapshot.data!;

//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Total Assigned Reports: ${report['totalAssigned']}'),
//                     Text('Total Rescued Animals: ${report['totalRescued']}'),
//                     Text(
//                         'Total Completed Reports: ${report['totalCompleted']}'),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Assigned Reports',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     if (report['assignments'].isEmpty)
//                       const Text('No assigned reports')
//                     else
//                       Column(
//                         children: report['assignments'].map((assignment) {
//                           final reportDetails =
//                               assignment['reports'] as Map<String, dynamic>;
//                           return ListTile(
//                             title: Text('Report ID: ${reportDetails['id']}'),
//                             subtitle: Text('Status: ${assignment['status']}'),
//                             trailing: Text(reportDetails['type']),
//                           );
//                         }).toList(),
//                       ),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> _getVolunteerReport(
//       SupabaseService supabaseService, String volunteerId) async {
//     final assignments = await supabaseService.getVolunteerAssignments();
//     final volunteerAssignments =
//         assignments.where((a) => a['volunteer_id'] == volunteerId).toList();

//     int totalAssigned = volunteerAssignments.length;
//     int totalRescued =
//         volunteerAssignments.where((a) => a['status'] == 'completed').length;
//     int totalCompleted =
//         totalRescued; // Assuming completed reports are the same as rescued animals

//     return {
//       'totalAssigned': totalAssigned,
//       'totalRescued': totalRescued,
//       'totalCompleted': totalCompleted,
//       'assignments': volunteerAssignments,
//     };
//   }
// }
