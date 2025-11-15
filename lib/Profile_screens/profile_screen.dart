import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runpro9ja_agent/Other_screens/support_chat_screen.dart';
import '../Auth/auth_services.dart';
import '../Other_screens/notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _agentProfile = {};
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadUnreadCount();
  }

  // ADD THIS METHOD TO GET TOKEN
  Future<String?> _getToken() async {
    try {
      return await AuthService().getToken();
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> _loadProfileData() async {
    try {
      // Get user data from token
      final userData = await AuthService().getUserData();

      // Get agent profile
      final agentProfile = await _getAgentProfile();

      setState(() {
        _userData = userData;
        _agentProfile = agentProfile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ADD THIS METHOD
  Future<void> _loadUnreadCount() async {
    try {
      final token = await _getToken();
      if (token != null) {
        // For now, we'll set a placeholder count
        // You can implement the actual notification count later
        setState(() {
          _unreadCount = 0; // Placeholder - replace with actual count
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<Map<String, dynamic>> _getAgentProfile() async {
    try {
      final response = await AuthService().post('api/agents/me', {});
      if (response['statusCode'] == 200) {
        return response['body'];
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  String _getProfileImage() {
    if (_agentProfile['profileImage'] != null) {
      return 'https://runpro9ja-pxqoa.ondigitalocean.app${_agentProfile['profileImage']}';
    }
    return 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop';
  }

  String _getUserName() {
    if (_userData != null && _userData!['name'] != null) {
      return _userData!['name'];
    }
    if (_agentProfile['user'] != null && _agentProfile['user']['fullName'] != null) {
      return _agentProfile['user']['fullName'];
    }
    return 'User Name';
  }

  double _getRating() {
    if (_agentProfile['rating'] != null) {
      return _agentProfile['rating'].toDouble();
    }
    return 5.0;
  }

  int _getCompletedJobs() {
    return _agentProfile['completedJobs'] ?? 0;
  }

  bool _getVerificationStatus() {
    return _agentProfile['isVerified'] ?? false;
  }

  // ADD DELETE ACCOUNT METHOD
  Future<void> _deleteAccount() async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'To confirm, please type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'DELETE MY ACCOUNT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Type the confirmation phrase',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // We'll handle validation in the button
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Check if the user typed the correct phrase
                final textField = context.findAncestorStateOfType<_ProfileScreenState>();
                // We'll handle this differently - show password dialog after confirmation
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Show password confirmation dialog
      await _showPasswordConfirmationDialog();
    }
  }

  // ADD PASSWORD CONFIRMATION DIALOG
  Future<void> _showPasswordConfirmationDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to confirm account deletion:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Type "DELETE MY ACCOUNT"',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (confirmationController.text != 'DELETE MY ACCOUNT') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please type "DELETE MY ACCOUNT" to confirm')),
                  );
                  return;
                }

                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your password')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _performAccountDeletion(
                  passwordController.text,
                  confirmationController.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ADD ACTUAL DELETION METHOD
  Future<void> _performAccountDeletion(String password, String confirmation) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await AuthService().delete('api/customers/me', {
        'password': password,
        'confirmation': confirmation,
      });

      Navigator.of(context).pop(); // Close loading dialog

      if (response['statusCode'] == 200) {
        // Account deleted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );

        // Logout and navigate to login
        await AuthService().logout();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        throw Exception(response['body']['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF26857C),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
            ),
            child: const Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Profile Section
          Container(
            color: const Color(0xFF26857C),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_getProfileImage()),
                ),
                const SizedBox(height: 12),
                Text(
                  _getUserName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Rating Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      color: index < _getRating().floor()
                          ? Colors.amber
                          : Colors.grey[300],
                      size: 20,
                    ),
                  ),
                ),
                // Agent Stats
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem('Completed Jobs', _getCompletedJobs().toString()),
                    const SizedBox(width: 20),
                    _buildStatItem('Rating', _getRating().toStringAsFixed(1)),
                    const SizedBox(width: 20),
                    _buildStatItem('Verified', _getVerificationStatus() ? 'Yes' : 'No'),
                  ],
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  transform: Matrix4.translationValues(0, -16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MenuItem(
                        icon: Icons.person_outline,
                        text: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                userData: _userData ?? {},
                                agentProfile: _agentProfile,
                                onProfileUpdated: _loadProfileData,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuItem(
                        icon: Icons.work_outline,
                        text: 'Service Profile',
                        onTap: _showServiceProfile,
                      ),
                      // SIMPLE NOTIFICATION MENU ITEM
                      MenuItem(
                        icon: Icons.notifications_outlined,
                        text: 'Notification',
                        badgeCount: _unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      // ADD DELETE ACCOUNT MENU ITEM
                      MenuItem(
                        icon: Icons.delete_outline,
                        text: 'Delete Account',
                        onTap: _deleteAccount,
                        isLast: false, // Not the last item
                      ),
                      MenuItem(
                        icon: Icons.logout,
                        text: 'Logout',
                        onTap: _logout,
                        isLast: true, // This is now the last item
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showServiceProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_agentProfile['serviceType'] != null)
              Text('Service: ${_agentProfile['serviceType']}'),
            if (_agentProfile['bio'] != null)
              Text('Bio: ${_agentProfile['bio']}'),
            if (_agentProfile['servicesOffered'] != null)
              Text('Services: ${_agentProfile['servicesOffered']}'),
            if (_agentProfile.isEmpty)
              const Text('No service profile created yet.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      await AuthService().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isLast;
  final int? badgeCount;

  const MenuItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isLast = false,
    this.badgeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Wrap icon in Stack to show badge
            Stack(
              children: [
                Icon(
                    icon,
                    color: text == 'Delete Account' ? Colors.red : Colors.grey[700],
                    size: 24
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: text == 'Delete Account' ? Colors.red : Colors.grey[800],
                  fontWeight: text == 'Delete Account' ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
                Icons.chevron_right,
                color: text == 'Delete Account' ? Colors.red : Colors.grey[400]
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> agentProfile;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.userData,
    required this.agentProfile,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController.text = widget.userData['name'] ?? '';
    _bioController.text = widget.agentProfile['bio'] ?? '';
    _cityController.text = widget.agentProfile['location']?['city'] ?? 'Lagos';
    _phoneController.text = widget.userData['phone'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare profile data
      final profileData = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': {
          'city': _cityController.text.trim(),
          'state': 'Lagos',
          'country': 'Nigeria'
        },
      };

      // Update profile using your existing AuthService
      final response = await AuthService().post('api/agents/me', profileData);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        // Upload image if selected
        if (_selectedImage != null) {
          await AuthService().uploadProfileImage(_selectedImage!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        widget.onProfileUpdated();
        Navigator.pop(context);
      } else {
        throw Exception(response['body']['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26857C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Picture with upload option
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : NetworkImage(
                    widget.agentProfile['profileImage'] != null
                        ? 'https://runpro9ja-pxqoa.ondigitalocean.app${widget.agentProfile['profileImage']}'
                        : 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop',
                  ) as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26857C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTextField('Full Name', _nameController),
                  const SizedBox(height: 24),
                  _buildTextField('Bio', _bioController, maxLines: 3),
                  const SizedBox(height: 24),
                  _buildTextField('City', _cityController),
                  const SizedBox(height: 24),
                  _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 24),
                  _buildTextField('Email Address', _emailController,
                      keyboardType: TextInputType.emailAddress, enabled: false),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF26857C)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintText: 'Enter your $label',
          ),
        ),
      ],
    );
  }
}