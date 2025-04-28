// import 'package:flutter/material.dart';

// class RescueMissionScreen extends StatelessWidget {
//   final Map<String, dynamic> report;
//   final String volunteerId;

//   const RescueMissionScreen({
//     super.key,
//     required this.report,
//     required this.volunteerId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Rescue Mission'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildMissionCard(
//               icon: Icons.assignment,
//               title: 'Mission Details',
//               children: [
//                 _buildDetailRow('Type:', report['type']),
//                 _buildDetailRow('Condition:', report['condition']),
//                 _buildDetailRow('Status:', 'ASSIGNED'),
//                 _buildDetailRow(
//                     'Assigned Volunteer:', 'You (ID: $volunteerId)'),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _buildMissionCard(
//               icon: Icons.location_pin,
//               title: 'Location Information',
//               children: [
//                 _buildDetailRow(
//                     'Coordinates:', '${report['lat']}, ${report['lng']}'),
//                 if (report['address'] != null)
//                   _buildDetailRow('Address:', report['address']),
//                 ElevatedButton(
//                   onPressed: () => _openMaps(report['lat'], report['lng']),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     minimumSize: const Size(double.infinity, 50),
//                   ),
//                   child: const Text('OPEN IN MAPS'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _buildMissionCard(
//               icon: Icons.person,
//               title: 'Reporter Information',
//               children: [
//                 if (report['reporter_name'] != null)
//                   _buildDetailRow('Name:', report['reporter_name']),
//                 if (report['reporter_contact'] != null)
//                   _buildDetailRow('Contact:', report['reporter_contact']),
//                 if (report['reporter_contact'] != null)
//                   ElevatedButton(
//                     onPressed: () => _makePhoneCall(report['reporter_contact']),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text('CALL REPORTER'),
//                   ),
//               ],
//             ),
//             if (report['notes'] != null &&
//                 report['notes'].toString().isNotEmpty)
//               Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   _buildMissionCard(
//                     icon: Icons.notes,
//                     title: 'Additional Notes',
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Text(
//                           report['notes'],
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             const SizedBox(height: 20),
//             _buildActionButtons(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMissionCard({
//     required IconData icon,
//     required String title,
//     required List<Widget> children,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.orange),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons(BuildContext context) {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: () => _openMaps(report['lat'], report['lng']),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.orange,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           child: const Text('NAVIGATE TO LOCATION'),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: () {
//             // Add your complete mission logic here
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           child: const Text('MISSION COMPLETED'),
//         ),
//         const SizedBox(height: 10),
//         OutlinedButton(
//           onPressed: () {
//             // Add your cancel mission logic here
//           },
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.red,
//             side: const BorderSide(color: Colors.red),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           child: const Text('CANCEL MISSION'),
//         ),
//       ],
//     );
//   }

//   Future<void> _openMaps(double lat, double lng) async {
//     String googleMapsUrl =
//         'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
//     if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
//       await launchUrl(Uri.parse(googleMapsUrl),
//           mode: LaunchMode.externalApplication);
//     } else {
//       throw 'Could not launch $googleMapsUrl';
//     }
//   }

//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final url = 'tel:$phoneNumber';
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url));
//     } else {
//       throw 'Could not launch $url';
//     }
//   }
// }
