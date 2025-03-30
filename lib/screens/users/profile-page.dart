import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';

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
    _loadThemePreference();
    _loadUserData();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      isDarkMode = value;
    });
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
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => isLoading = true);
      final imageUrl = await supabaseService.uploadProfilePicture(image);

      await supabaseService.updateUserProfile(
        name: userData?['name']?.toString() ?? '',
        phoneNumber: userData?['phone_number']?.toString() ?? '',
        profilePictureUrl: imageUrl,
      );

      await _loadUserData();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await supabaseService.logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Future<void> _showEditDialog(String field, String title) async {
    final currentValue = userData?[field]?.toString() ?? '';
    final controller = TextEditingController(text: currentValue);
    final accentColor = const Color(0xFF6C63FF);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProfileField(field, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
        name: field == 'name' ? value : userData?['name']?.toString() ?? '',
        phoneNumber: field == 'phone_number'
            ? value
            : userData?['phone_number']?.toString() ?? '',
      );
      await _loadUserData();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating $field: ${e.toString()}')),
      );
    }
  }

  Future<void> _showPasswordChangeDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final accentColor = const Color(0xFF6C63FF);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    setState(() => isLoading = true);
    try {
      await supabaseService.loginUser(
        context: context,
        email: userData?['email']?.toString() ?? '',
        password: oldPassword,
      );

      final response = await supabaseService.updatePassword(newPassword);
      if (response['error'] != null) {
        throw response['error'].toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor =
        isDarkMode ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF2D2D3D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final dividerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final accentColor = const Color(0xFF6C63FF);

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile data',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: accentColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.8),
                      accentColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: userData?['profile_picture'] != null
                                ? Image.network(
                                    userData!['profile_picture'].toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 60,
                                            color: subtitleColor),
                                  )
                                : Icon(Icons.person,
                                    size: 60, color: subtitleColor),
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData?['name']?.toString() ?? 'No name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userData?['role']?.toString() ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ModernInfoField(
                                icon: Icons.person_outline,
                                label: 'Name',
                                value:
                                    userData?['name']?.toString() ?? 'Not set',
                                isEditable: true,
                                onEdit: () =>
                                    _showEditDialog('name', 'Update Name'),
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                              Divider(height: 1, color: dividerColor),
                              ModernInfoField(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value:
                                    userData?['email']?.toString() ?? 'Not set',
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                              Divider(height: 1, color: dividerColor),
                              ModernInfoField(
                                icon: Icons.phone_outlined,
                                label: 'Phone Number',
                                value: userData?['phone_number']?.toString() ??
                                    'Not set',
                                isEditable: true,
                                onEdit: () => _showEditDialog(
                                    'phone_number', 'Update Phone Number'),
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'General Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ModernSettingsItem(
                                icon: Icons.brightness_6_rounded,
                                title: 'Dark Mode',
                                subtitle: isDarkMode ? 'On' : 'Off',
                                showToggle: true,
                                isToggled: isDarkMode,
                                onToggle: _toggleDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                              Divider(height: 1, color: dividerColor),
                              ModernSettingsItem(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                showArrow: true,
                                onTap: _showPasswordChangeDialog,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                              Divider(height: 1, color: dividerColor),
                              ModernSettingsItem(
                                icon: Icons.language,
                                title: 'Language',
                                subtitle: 'English',
                                showArrow: true,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                              Divider(height: 1, color: dividerColor),
                              ModernSettingsItem(
                                icon: Icons.share,
                                title: 'Share This App',
                                showArrow: true,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernInfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditable;
  final VoidCallback? onEdit;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;

  const ModernInfoField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isEditable = false,
    this.onEdit,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: accentColor),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

class ModernSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final bool showToggle;
  final bool isToggled;
  final Function(bool)? onToggle;
  final VoidCallback? onTap;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;

  const ModernSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showArrow = false,
    this.showToggle = false,
    this.isToggled = false,
    this.onToggle,
    this.onTap,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showToggle)
              Switch(
                value: isToggled,
                onChanged: onToggle,
                activeColor: accentColor,
                activeTrackColor: accentColor.withOpacity(0.3),
              ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: subtitleColor,
              ),
          ],
        ),
      ),
    );
  }
}
