import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart'; // Assuming your service file is named this

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = true;
  bool isLoading = true;
  Map<String, dynamic>? userData;
  final SupabaseService supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final data = await supabaseService.fetchUserDetails();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => isLoading = true);
      final imageUrl = await supabaseService.uploadProfilePicture(image);

      await supabaseService.updateUserProfile(
        name: userData?['name'] ?? '',
        phoneNumber: userData?['phone_number'] ?? '',
        profilePictureUrl: imageUrl,
      );

      await _loadUserData(); // Refresh user data
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await supabaseService.logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile data'),
              TextButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture and Name Section
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: userData?['profile_picture'] != null
                              ? Image.network(
                                  userData!['profile_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 60),
                                )
                              : const Icon(Icons.person, size: 60),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _updateProfilePicture,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData?['name'] ?? 'No name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData?['role'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Personal Information Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFFE8EAF6),
              child: const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // User Info Fields
            InfoField(
              label: 'Name',
              value: userData?['name'] ?? 'Not set',
              isEditable: true,
              onEdit: () => _showEditDialog('name', 'Update Name'),
            ),
            const Divider(height: 1),
            InfoField(
              label: 'Email',
              value: userData?['email'] ?? 'Not set',
            ),
            const Divider(height: 1),
            InfoField(
              label: 'Phone Number',
              value: userData?['phone_number'] ?? 'Not set',
              isEditable: true,
              onEdit: () =>
                  _showEditDialog('phone_number', 'Update Phone Number'),
            ),
            const Divider(height: 1),

            const SizedBox(height: 20),

            // General Settings Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFFE8EAF6),
              child: const Text(
                'General Settings',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Settings Items
            SettingsItem(
              icon: Icons.brightness_6_rounded,
              title: 'Mode',
              subtitle: 'Dark & Light',
              showToggle: true,
              isToggled: isDarkMode,
              onToggle: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            const Divider(height: 1),
            SettingsItem(
              icon: Icons.vpn_key,
              title: 'Change Password',
              showArrow: true,
              onTap: () => _showPasswordChangeDialog(),
            ),
            const Divider(height: 1),
            const SettingsItem(
              icon: Icons.language,
              title: 'Language',
              showArrow: true,
            ),
            const Divider(height: 1),
            const SettingsItem(
              icon: Icons.share,
              title: 'Share This App',
              showArrow: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(String field, String title) async {
    final currentValue = userData?[field] ?? '';
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProfileField(field, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileField(String field, String value) async {
    if (value.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await supabaseService.updateUserProfile(
        name: field == 'name' ? value : userData?['name'] ?? '',
        phoneNumber:
            field == 'phone_number' ? value : userData?['phone_number'] ?? '',
      );
      await _loadUserData();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating $field: $e')),
      );
    }
  }

  Future<void> _showPasswordChangeDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              Navigator.pop(context);
              await _updatePassword(
                oldPasswordController.text,
                newPasswordController.text,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    setState(() => isLoading = true);
    try {
      // First reauthenticate with old password
      await supabaseService.loginUser(
        context: context,
        email: userData?['email'] ?? '',
        password: oldPassword,
      );

      // Then update password
      await supabaseService.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}

class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditable;
  final VoidCallback? onEdit;

  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.isEditable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final bool showToggle;
  final bool isToggled;
  final Function(bool)? onToggle;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showArrow = false,
    this.showToggle = false,
    this.isToggled = false,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        color: const Color(0xFFFFF8E1),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (showToggle)
              Switch(
                value: isToggled,
                onChanged: onToggle,
                activeColor: Colors.blue,
              ),
            if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
