import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SupabaseService {
  // Add this getter to access the Supabase client
  SupabaseClient get supabase => Supabase.instance.client;

  // Initialize Supabase (call this once in main.dart)
  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://zuicmikqkapgodejaxob.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1aWNtaWtxa2FwZ29kZWpheG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3MDU1NzUsImV4cCI6MjA1ODI4MTU3NX0.cboQllH0cO6llyjbLHIRCgaGvKHfjGIOmrj7bMpzWt0',
    );
  }

  Stream<List<Map<String, dynamic>>> getPendingReportsStream() {
    return supabase
        .from('reports')
        .stream(primaryKey: ['id']) // Ensure 'id' is the primary key
        .eq('status', 'pending') // Fetch only pending reports
        .order('created_at', ascending: false)
        .map((data) =>
            List<Map<String, dynamic>>.from(data)) // Ensure correct type
        .handleError((error) {
          print('Error in pending reports stream: $error');
        });
  }

  // Get current user ID
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  // Register a new user
  Future<bool> registerUser({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String profilePictureUrl,
  }) async {
    if (email.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty ||
        phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    try {
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        await supabase.from('users').insert({
          'id': authResponse.user!.id,
          'name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'role': role,
          'profile_picture': profilePictureUrl,
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registration successful! Please check your email to confirm your account.'),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Error: $e');
      return false;
    }
  }

  // Login user
  Future<bool> loginUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (response.user?.emailConfirmedAt == null) {
          // Email not confirmed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Please confirm your email before logging in. Check your inbox.')),
          );
          return false;
        }
        // Login successful
        return true;
      } else {
        // Invalid credentials
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Login error: $e');
      return false;
    }
  }

  // Check if email is confirmed
  Future<bool> isEmailConfirmed() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      return user.emailConfirmedAt != null;
    } catch (e) {
      print('Error checking email confirmation: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // Get current user ID

  // Fetch user details
  Future<Map<String, dynamic>?> fetchUserDetails() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response =
          await supabase.from('users').select().eq('id', user.id).single();

      return {
        "id": user.id,
        "email": user.email,
        "name": response['name'],
        "phone_number": response['phone_number'],
        "role": response['role'],
        "profile_picture": response['profile_picture'],
        "created_at": response['created_at'],
        "last_sign_in_at": user.lastSignInAt != null
            ? DateTime.parse(user.lastSignInAt!).toIso8601String()
            : null,
      };
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phoneNumber,
    String? profilePictureUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final updates = {
        'name': name,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (profilePictureUrl != null) {
        updates['profile_picture'] = profilePictureUrl;
      }

      await supabase.from('users').update(updates).eq('id', user.id);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Upload image (generic method for both gallery and camera)
  Future<String> uploadReportImage(File imageFile) async {
    try {
      final fileExt = path.extension(imageFile.path).replaceAll('.', '');
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = 'reports/$fileName';

      await supabase.storage.from('images').upload(
            filePath,
            imageFile,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: false,
            ),
          );

      return supabase.storage.from('images').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(XFile imageFile) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final file = File(imageFile.path);
      final fileExt = path.extension(imageFile.path).replaceAll('.', '');
      final filePath = 'profile_pictures/${user.id}.$fileExt';

      await supabase.storage.from('images').upload(
            filePath,
            file,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final imageUrl = supabase.storage.from('images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw Exception("Profile picture upload failed: $e");
    }
  }

  // Insert a new report
  Future<String> insertReport({
    required String imageUrl,
    required String condition,
    required String type,
    required String notes,
    required double lat,
    required double lng,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final response = await supabase.from('reports').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'condition': condition,
        'type': type,
        'notes': notes,
        'lat': lat,
        'lng': lng,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select('id');

      // Handle the response properly
      if (response.isEmpty) {
        throw Exception('No data returned from insert operation');
      }

      // Convert the ID to string regardless of its original type
      return response[0]['id'].toString();
    } catch (e) {
      throw Exception('Failed to insert report: $e');
    }
  }

  // Fetch user reports
  Future<List<Map<String, dynamic>>> getUserReports() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user reports: $e');
      return [];
    }
  }

  // Fetch report details
  Future<Map<String, dynamic>?> getReportDetails(String reportId) async {
    try {
      final response =
          await supabase.from('reports').select().eq('id', reportId).single();

      return response;
    } catch (e) {
      print('Error fetching report details: $e');
      return null;
    }
  }

  // Fetch all reports
  Stream<List<Map<String, dynamic>>> getAllReportsStream() {
    return supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map<List<Map<String, dynamic>>>(
            (data) => List<Map<String, dynamic>>.from(data));
  }

  // Update report status
  // In SupabaseService
  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    try {
      await supabase.from('reports').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  Future<bool> assignVolunteer({
    required String reportId,
    required String volunteerId,
  }) async {
    try {
      await supabase.from('assignments').insert({
        'report_id': reportId,
        'volunteer_id': volunteerId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
      });

      // Update report status
      await supabase.from('reports').update({
        'status': 'assigned',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      return true;
    } catch (e) {
      print('Error assigning volunteer: $e');
      return false;
    }
  }

  Future<bool> addRescueUpdate({
    required String reportId,
    required String status,
    required String updateNotes,
  }) async {
    try {
      await supabase.from('rescue_updates').insert({
        'report_id': reportId,
        'status': status,
        'notes': updateNotes,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error adding rescue update: $e');
      return false;
    }
  }

  // Assign a volunteer to a report

  // Get volunteer assignments
  Future<List<Map<String, dynamic>>> getVolunteerAssignments() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('assignments')
          .select('*, reports(*)')
          .eq('volunteer_id', user.id)
          .order('assigned_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching volunteer assignments: $e');
      return [];
    }
  }

  // Update assignment status
  Future<bool> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    String? notes,
  }) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await supabase.from('assignments').update(updates).eq('id', assignmentId);
      return true;
    } catch (e) {
      print('Error updating assignment status: $e');
      return false;
    }
  }

  // Create a new NGO
  Future<bool> createNGO({
    required String name,
    required String contactPerson,
    required String phoneNumber,
    required String email,
    required String location,
    String? description,
    String? logoUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase.from('ngos').insert({
        'name': name,
        'contact_person': contactPerson,
        'phone_number': phoneNumber,
        'email': email,
        'location': location,
        'description': description,
        'logo_url': logoUrl,
        'admin_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error creating NGO: $e');
      return false;
    }
  }

  // Get all NGOs
  Future<List<Map<String, dynamic>>> getAllNGOs() async {
    try {
      final response =
          await supabase.from('ngos').select().order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching NGOs: $e');
      return [];
    }
  }

  // Get NGO details
  Future<Map<String, dynamic>?> getNGODetails(String ngoId) async {
    try {
      final response =
          await supabase.from('ngos').select().eq('id', ngoId).single();

      return response;
    } catch (e) {
      print('Error fetching NGO details: $e');
      return null;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // Update password
  Future<dynamic> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      print('Error updating password: $e');
      return {'error': e};
    }
  }

  // Future<Map<String, dynamic>?> _getUserRole() async {
  //   try {
  //     final userId = supabase.auth.currentUser?.id;
  //     if (userId == null) return 'user'; // Default role if no user

  //     // Fetch user data from your 'profiles' or 'users' table
  //     final response = await supabase
  //         .from('profiles') // Replace with your table name
  //         .select('role')
  //         .eq('id', userId)
  //         .single();

  //     return response['role'] ?? 'user'; // Default to 'user' if role is null
  //   } catch (e) {
  //     print('Error fetching user role: $e');
  //     return 'user'; // Default role on error
  //   }
  // }

  // Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('role', role)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  Future<void> sendAppreciationMessage({
    required String reportId,
    required String volunteerId,
    required String reporterId,
  }) async {
    try {
      print('Attempting to send appreciation message...');

      // Get volunteer details
      final volunteerResponse = await supabase
          .from('users')
          .select('name, email')
          .eq('id', volunteerId)
          .maybeSingle();

      // Get reporter details
      final reporterResponse = await supabase
          .from('users')
          .select('name, email')
          .eq('id', reporterId)
          .maybeSingle();

      print('Volunteer data: $volunteerResponse');
      print('Reporter data: $reporterResponse');

      final volunteerName = volunteerResponse?['name'] ?? 'a volunteer';
      final reporterName = reporterResponse?['name'] ?? 'a community member';

      // Create appreciation message
      final message =
          '🌟 Great news! $volunteerName successfully rescued an animal reported by $reporterName. '
          'Thank you for your compassion and service to our furry friends! 🐾';

      print('Prepared message: $message');

      // Send to community chat
      final response = await supabase.from('community_messages').insert({
        'user_id': volunteerId,
        'message': message,
        'user_name': 'PetPal Team',
        'is_system': true,
        'report_id': reportId, // Add report reference
      }).select();

      print('Message sent successfully: $response');
    } catch (e) {
      print('Error sending appreciation message: $e');
      rethrow; // Re-throw to handle in the calling function
    }
  }

  // Add this to your SupabaseService class
  Future<List<Map<String, dynamic>>> getAssignedReports() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('assignments')
          .select('*, reports(*)')
          .eq('volunteer_id', user.id)
          .order('assigned_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned reports: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReportById(String reportId) async {
    try {
      final response =
          await supabase.from('reports').select().eq('id', reportId).single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting report by ID: $e');
      return null;
    }
  }
}
