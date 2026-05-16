import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  bool _isManagementExpanded = true;
  bool _isCommunicationExpanded = true;
  bool _isAccountExpanded = true;
  
  late final List<Widget> _pages;
  late final List<String> _titles;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardStats(),
      const ProductsManagement(),
      const OrdersManagement(),
      const CustomersManagement(),
      const PasswordResetRequests(),
      const MessagesManagement(),
    ];
    _titles = [
      'Dashboard', 
      'Products', 
      'Orders', 
      'Customers', 
      'Reset Requests', 
      'Messages'
    ];
  }
  
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Logout')),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      try {
        await _auth.signOut();
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: const Icon(Icons.admin_panel_settings, color: Colors.green),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: _pages[_selectedIndex],
    );
  }
  
  Widget _buildNavigationDrawer() {
    User? currentUser;
    try {
      currentUser = _auth.currentUser;
    } catch (e) {
      currentUser = null;
    }
    
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        size: 30,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FreshHarvest',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (currentUser != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Text(
                            currentUser.displayName?.substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.displayName ?? 'Admin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currentUser.email ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSectionHeader('MANAGEMENT', Icons.dashboard, _isManagementExpanded, () {
                  setState(() => _isManagementExpanded = !_isManagementExpanded);
                }),
                if (_isManagementExpanded) ...[
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
                  _buildDrawerItem(Icons.inventory, 'Products', 1),
                  _buildDrawerItem(Icons.shopping_cart, 'Orders', 2),
                  _buildDrawerItem(Icons.people, 'Customers', 3),
                ],
                
                const Divider(),
                
                _buildDrawerSectionHeader('COMMUNICATION', Icons.message, _isCommunicationExpanded, () {
                  setState(() => _isCommunicationExpanded = !_isCommunicationExpanded);
                }),
                if (_isCommunicationExpanded) ...[
                  _buildDrawerItem(Icons.lock_reset, 'Reset Requests', 4),
                  _buildDrawerItem(Icons.message, 'Messages', 5),
                ],
                
                const Divider(),
                
                _buildDrawerSectionHeader('ACCOUNT', Icons.account_circle, _isAccountExpanded, () {
                  setState(() => _isAccountExpanded = !_isAccountExpanded);
                }),
                if (_isAccountExpanded) ...[
                  _buildDrawerAccountItem(Icons.account_circle, 'Profile', _showProfilePage),
                  _buildDrawerAccountItem(Icons.settings, 'Settings', _showSettingsPage),
                  _buildDrawerAccountItem(Icons.privacy_tip, 'Privacy Policy', _showPrivacyPolicyPage),
                  _buildDrawerAccountItem(Icons.description, 'Terms & Conditions', _showTermsPage),
                ],
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _buildDrawerItem(Icons.logout, 'Logout', -1, isLogout: true),
                const SizedBox(height: 8),
                const Text('© 2025 FreshHarvest', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Text('Admin Version 1.0.0', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerSectionHeader(String title, IconData icon, bool isExpanded, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        color: Colors.green.shade700,
        size: 20,
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String title, int index, {bool isLogout = false}) {
    final isSelected = _selectedIndex == index;
    final Color textColor = isSelected || isLogout ? Colors.green : Colors.grey.shade600;
    final Color iconColor = isSelected || isLogout ? Colors.green : Colors.grey.shade600;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (isLogout) {
            Navigator.pop(context);
            _logout();
          } else {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
  
  Widget _buildDrawerAccountItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade600),
        title: Text(
          title,
          style: TextStyle(color: Colors.grey.shade800),
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
  
  void _showProfilePage() {
    final User? user = _auth.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Admin Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 32),
              _buildProfileInfoRow(Icons.person, 'Name', user.displayName ?? 'Admin User'),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.email, 'Email', user.email ?? 'admin@freshharvest.com'),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.verified, 'Email Verified', user.emailVerified == true ? 'Yes' : 'No'),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.calendar_today, 'Account Created', _formatDate(user.metadata.creationTime)),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.fingerprint, 'User ID', _truncateId(user.uid)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  void _showSettingsPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customize your app experience',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSettingsCard(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      onTap: () => _showNotificationSettings(),
                    ),
                    _buildSettingsCard(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      onTap: () => _showThemeSettings(),
                    ),
                    _buildSettingsCard(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () => _showLanguageSettings(),
                    ),
                    _buildSettingsCard(
                      icon: Icons.security,
                      title: 'Security',
                      subtitle: 'Password and authentication settings',
                      onTap: () => _showSecuritySettings(),
                    ),
                    _buildSettingsCard(
                      icon: Icons.data_usage,
                      title: 'Data Usage',
                      subtitle: 'Manage data sync and storage',
                      onTap: () => _showDataSettings(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
  
  void _showNotificationSettings() {
    bool emailNotifications = true;
    bool pushNotifications = true;
    bool orderUpdates = true;
    bool promotionalEmails = false;
    bool smsAlerts = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Notification Settings'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Container(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: emailNotifications,
                    onChanged: (value) => setState(() => emailNotifications = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive push notifications on device'),
                    value: pushNotifications,
                    onChanged: (value) => setState(() => pushNotifications = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Order Updates'),
                    subtitle: const Text('Get notified about order status changes'),
                    value: orderUpdates,
                    onChanged: (value) => setState(() => orderUpdates = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('SMS Alerts'),
                    subtitle: const Text('Receive SMS notifications for important updates'),
                    value: smsAlerts,
                    onChanged: (value) => setState(() => smsAlerts = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Promotional Emails'),
                    subtitle: const Text('Receive offers and promotions'),
                    value: promotionalEmails,
                    onChanged: (value) => setState(() => promotionalEmails = value),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings saved!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showThemeSettings() {
    String selectedTheme = 'Light';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Theme Settings'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Container(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text('Light Theme'),
                    subtitle: const Text('Bright and clean interface'),
                    value: 'Light',
                    groupValue: selectedTheme,
                    onChanged: (value) => setState(() => selectedTheme = value.toString()),
                    activeColor: Colors.green,
                  ),
                  RadioListTile(
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Easy on the eyes, saves battery'),
                    value: 'Dark',
                    groupValue: selectedTheme,
                    onChanged: (value) => setState(() => selectedTheme = value.toString()),
                    activeColor: Colors.green,
                  ),
                  RadioListTile(
                    title: const Text('System Default'),
                    subtitle: const Text('Follow device theme'),
                    value: 'System',
                    groupValue: selectedTheme,
                    onChanged: (value) => setState(() => selectedTheme = value.toString()),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Theme changed to $selectedTheme!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Apply Theme'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showLanguageSettings() {
    String selectedLanguage = 'English';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Language Settings'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Container(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text('English'),
                    subtitle: const Text('Default language'),
                    value: 'English',
                    groupValue: selectedLanguage,
                    onChanged: (value) => setState(() => selectedLanguage = value.toString()),
                    activeColor: Colors.green,
                  ),
                  RadioListTile(
                    title: const Text('French'),
                    subtitle: const Text('Français'),
                    value: 'French',
                    groupValue: selectedLanguage,
                    onChanged: (value) => setState(() => selectedLanguage = value.toString()),
                    activeColor: Colors.green,
                  ),
                  RadioListTile(
                    title: const Text('Luganda'),
                    subtitle: const Text('Oluganda'),
                    value: 'Luganda',
                    groupValue: selectedLanguage,
                    onChanged: (value) => setState(() => selectedLanguage = value.toString()),
                    activeColor: Colors.green,
                  ),
                  RadioListTile(
                    title: const Text('Swahili'),
                    subtitle: const Text('Kiswahili'),
                    value: 'Swahili',
                    groupValue: selectedLanguage,
                    onChanged: (value) => setState(() => selectedLanguage = value.toString()),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language changed to $selectedLanguage!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Apply Language'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.green),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              onTap: () => _showChangePasswordDialog(context),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Add extra security layer'),
              value: false,
              onChanged: (value) {},
              activeColor: Colors.green,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Biometric Login'),
              subtitle: const Text('Use fingerprint/face recognition'),
              value: false,
              onChanged: (value) {},
              activeColor: Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings saved!'), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog(BuildContext parentContext) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
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
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match or are too short!'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }
  
  void _showDataSettings() {
    bool autoSync = true;
    bool useCellularData = true;
    bool autoDownloadImages = true;
    bool reduceDataUsage = false;
    int cacheSize = 256;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Data Usage Settings'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Container(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Auto-Sync Data'),
                    subtitle: const Text('Automatically sync your data across devices'),
                    value: autoSync,
                    onChanged: (value) => setState(() => autoSync = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Use Cellular Data'),
                    subtitle: const Text('Allow data sync over mobile network'),
                    value: useCellularData,
                    onChanged: (value) => setState(() => useCellularData = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Auto-download Images'),
                    subtitle: const Text('Automatically download product images'),
                    value: autoDownloadImages,
                    onChanged: (value) => setState(() => autoDownloadImages = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Reduce Data Usage'),
                    subtitle: const Text('Compress images and use lower quality'),
                    value: reduceDataUsage,
                    onChanged: (value) => setState(() => reduceDataUsage = value),
                    activeColor: Colors.green,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.storage, color: Colors.green),
                    title: const Text('Cache Size'),
                    subtitle: Text('$cacheSize MB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (cacheSize > 50) {
                              setState(() => cacheSize -= 50);
                            }
                          },
                        ),
                        Text('$cacheSize'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (cacheSize < 1000) {
                              setState(() => cacheSize += 50);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Free up storage space'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared successfully!'), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data settings saved!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showPrivacyPolicyPage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.privacy_tip, size: 50, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPolicySection(
                        '1. Information We Collect',
                        '• Personal information (name, email, phone number, address)\n'
                        '• Order history and preferences\n'
                        '• Device information and usage data\n'
                        '• Location data for delivery services',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '2. How We Use Your Information',
                        '• To process and deliver your orders\n'
                        '• To communicate with you about your orders\n'
                        '• To improve our services and customer experience\n'
                        '• To send promotional offers and updates (with your consent)',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '3. Information Sharing',
                        'We do not sell your personal information. We may share your information with:\n'
                        '• Delivery partners to fulfill your orders\n'
                        '• Payment processors to complete transactions\n'
                        '• Legal authorities when required by law',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '4. Data Security',
                        'We implement industry-standard security measures to protect your information, including encryption, secure servers, and regular security audits.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '5. Your Rights',
                        '• Access and update your personal information\n'
                        '• Request deletion of your account\n'
                        '• Opt-out of marketing communications\n'
                        '• Download your data',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '6. Contact Us',
                        'If you have questions about this Privacy Policy, contact us at:\n'
                        'Email: privacy@freshharvest.com\n'
                        'Phone: +256 700 123 456',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: April 2025',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTermsPage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.description, size: 50, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                'Terms & Conditions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPolicySection(
                        '1. Acceptance of Terms',
                        'By accessing and using FreshHarvest, you agree to be bound by these Terms & Conditions.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '2. User Accounts',
                        '• You must be at least 18 years old to create an account\n'
                        '• You are responsible for maintaining account security\n'
                        '• Provide accurate and complete information\n'
                        '• Notify us immediately of any unauthorized account access',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '3. Orders and Payments',
                        '• All orders are subject to availability\n'
                        '• Prices are in UGX (Ugandan Shillings)\n'
                        '• Payment is required at time of order\n'
                        '• We accept Cash on Delivery and Mobile Money\n'
                        '• Orders can be cancelled within 1 hour of placement',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '4. Delivery Policy',
                        '• Delivery available in Mbarara and surrounding areas\n'
                        '• Delivery times are estimates, not guarantees\n'
                        '• Free delivery on orders over UGX 50,000\n'
                        '• Customers must be available to receive deliveries\n'
                        '• Failed delivery attempts may incur additional charges',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '5. Returns and Refunds',
                        '• Returns accepted within 24 hours of delivery\n'
                        '• Products must be unused and in original condition\n'
                        '• Refunds processed within 5-7 business days\n'
                        '• Spoiled/damaged products reported immediately qualify for replacement',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '6. User Conduct',
                        'You agree not to:\n'
                        '• Use the platform for illegal purposes\n'
                        '• Interfere with platform operations\n'
                        '• Post false or misleading information\n'
                        '• Harass other users or staff',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '7. Limitation of Liability',
                        'FreshHarvest is not liable for indirect, incidental, or consequential damages arising from use of our services.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '8. Changes to Terms',
                        'We may modify these terms at any time. Continued use constitutes acceptance of modified terms.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        '9. Contact Information',
                        'Questions about Terms? Contact us at:\n'
                        'Email: legal@freshharvest.com\n'
                        'Phone: +256 700 123 456',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: April 2025',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
  
  String _truncateId(String id) {
    if (id.isEmpty) return 'Unknown';
    if (id.length <= 20) return id;
    return '${id.substring(0, 10)}...${id.substring(id.length - 8)}';
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMMM dd, yyyy').format(date);
  }
}

// ==================== DASHBOARD STATS ====================
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('users').where('role', isEqualTo: 'customer').snapshots(),
              builder: (context, userSnapshot) {
                int totalOrders = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
                int totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
                int totalCustomers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                int lowStockProducts = 0;
                double totalRevenue = 0;
                int pendingOrders = 0;
                
                if (productSnapshot.hasData) {
                  for (var product in productSnapshot.data!.docs) {
                    int stock = product['stock'] ?? 0;
                    if (stock < 10) lowStockProducts++;
                  }
                }
                if (orderSnapshot.hasData) {
                  for (var order in orderSnapshot.data!.docs) {
                    totalRevenue += (order['total'] ?? 0);
                    if (order['status'] == 'pending') pendingOrders++;
                  }
                }
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    GridView.count(shrinkWrap: true, crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20, physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatsCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, Colors.blue),
                        _buildStatsCard('Total Products', totalProducts.toString(), Icons.inventory, Colors.green),
                        _buildStatsCard('Total Customers', totalCustomers.toString(), Icons.people, Colors.purple),
                        _buildStatsCard('Revenue', 'UGX ${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.orange),
                        _buildStatsCard('Pending Orders', pendingOrders.toString(), Icons.pending, Colors.red),
                        _buildStatsCard('Low Stock', lowStockProducts.toString(), Icons.warning, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Recent Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (orderSnapshot.hasData && orderSnapshot.data!.docs.isNotEmpty)
                          ...orderSnapshot.data!.docs.take(5).map((order) => _buildOrderTile(order)).toList(),
                        if (orderSnapshot.hasData && orderSnapshot.data!.docs.isEmpty)
                          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No orders yet'))),
                      ]),
                    )),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20),
      child: Column(children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ]),
    ));
  }
  
  Widget _buildOrderTile(DocumentSnapshot order) {
    return ListTile(
      leading: const Icon(Icons.receipt),
      title: Text('Order #${order.id.substring(0, 8)}'),
      subtitle: Text('Customer: ${order['customerName']}'),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('UGX ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: _getStatusColor(order['status']), borderRadius: BorderRadius.circular(4)),
          child: Text(order['status'].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white))),
      ]),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// ==================== PRODUCTS MANAGEMENT ====================
class ProductsManagement extends StatefulWidget {
  const ProductsManagement({super.key});

  @override
  State<ProductsManagement> createState() => _ProductsManagementState();
}

class _ProductsManagementState extends State<ProductsManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  
  final List<String> _availableImages = [
    'apples.jpg', 'Cabbage.jpg', 'carrots.jpg', 'lettuce.jpg',
    'mango.jpg', 'matooke.jpg', 'onion.jpg', 'pepper.jpg',
    'potatoes.jpg', 'spinach.jpg', 'tomatoes.jpg', 'zucchini.jpg',
    'grapes.jpg', 'ovacadoes.jpg', 'pineaples.jpg',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      Set<String> cats = {'All'};
      for (var doc in snapshot.docs) {
        final category = doc['category'];
        if (category != null && category.toString().isNotEmpty) cats.add(category.toString());
      }
      if (mounted) setState(() => _categories = cats.toList());
    } catch (e) {}
  }
  
  void _showAddProductDialog() {
    _nameController.clear(); _priceController.clear(); _descController.clear(); _stockController.clear(); _categoryController.clear(); _imageNameController.clear();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Add New Product'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: _imageNameController.text.isEmpty ? null : _imageNameController.text,
          decoration: const InputDecoration(labelText: 'Select Image', border: OutlineInputBorder()),
          items: _availableImages.map((image) => DropdownMenuItem(value: image, child: Text(image))).toList(),
          onChanged: (value) => _imageNameController.text = value!,
        ),
        const SizedBox(height: 12),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (_nameController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter product name'))); return; }
          if (_priceController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter price'))); return; }
          if (_imageNameController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an image'))); return; }
          await _firestore.collection('products').add({
            'name': _nameController.text, 'price': double.parse(_priceController.text), 'description': _descController.text,
            'stock': int.tryParse(_stockController.text) ?? 0, 'category': _categoryController.text.isEmpty ? 'Uncategorized' : _categoryController.text,
            'imageName': _imageNameController.text, 'createdAt': FieldValue.serverTimestamp(),
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added!'), backgroundColor: Colors.green));
          _loadCategories();
        }, child: const Text('Add')),
      ],
    ));
  }
  
  void _editProduct(DocumentSnapshot product) {
    _nameController.text = product['name']; _priceController.text = product['price'].toString(); _descController.text = product['description'] ?? '';
    _stockController.text = (product['stock'] ?? 0).toString(); _categoryController.text = product['category'] ?? ''; _imageNameController.text = product['imageName'] ?? '';
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Edit Product'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: _imageNameController.text.isEmpty ? null : _imageNameController.text,
          decoration: const InputDecoration(labelText: 'Select Image', border: OutlineInputBorder()),
          items: _availableImages.map((image) => DropdownMenuItem(value: image, child: Text(image))).toList(),
          onChanged: (value) => _imageNameController.text = value!,
        ),
        const SizedBox(height: 12),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _firestore.collection('products').doc(product.id).update({
            'name': _nameController.text, 'price': double.parse(_priceController.text), 'description': _descController.text,
            'stock': int.tryParse(_stockController.text) ?? 0, 'category': _categoryController.text.isEmpty ? 'Uncategorized' : _categoryController.text,
            'imageName': _imageNameController.text,
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated!'), backgroundColor: Colors.green));
          _loadCategories();
        }, child: const Text('Update')),
      ],
    ));
  }
  
  Future<void> _deleteProduct(String id) async {
    bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete Product'), content: const Text('Are you sure?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes'))],
    ));
    if (confirm == true) { await _firestore.collection('products').doc(id).delete(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.green)); _loadCategories(); }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _showAddProductDialog, child: const Icon(Icons.add), backgroundColor: Colors.green),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(children: [
            Expanded(child: TextField(onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50))),
            const SizedBox(width: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: DropdownButton<String>(value: _selectedCategory, onChanged: (value) => setState(() => _selectedCategory = value!),
                items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(), underline: const SizedBox())),
          ]),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory, size: 80, color: Colors.grey), SizedBox(height: 16), Text('No products yet'), Text('Tap + to add products')]));
            var products = snapshot.data!.docs;
            if (_searchQuery.isNotEmpty) products = products.where((product) { final name = product['name'].toString().toLowerCase(); final category = product['category']?.toString().toLowerCase() ?? ''; return name.contains(_searchQuery) || category.contains(_searchQuery); }).toList();
            if (_selectedCategory != 'All') products = products.where((product) { final category = product['category'] ?? 'Uncategorized'; return category == _selectedCategory; }).toList();
            if (products.isEmpty) return const Center(child: Text('No products match'));
            return GridView.builder(padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.7, crossAxisSpacing: 20, mainAxisSpacing: 20),
              itemCount: products.length, itemBuilder: (context, index) {
                final product = products[index]; final stock = product['stock'] ?? 0; final isLowStock = stock < 10; final imageName = product['imageName'] ?? 'apples.jpg';
                return Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Stack(children: [
                      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset('assets/images/$imageName', height: 140, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(height: 140, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey)))),
                      if (isLowStock) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), child: const Text('Low Stock!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                    ]),
                    Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4), Text('UGX ${product['price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4), Row(children: [Icon(Icons.inventory, size: 14, color: isLowStock ? Colors.red : Colors.grey), const SizedBox(width: 4), Text('Stock: $stock', style: TextStyle(fontSize: 12, color: isLowStock ? Colors.red : Colors.grey))]),
                      if (product['category'] != null) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)), child: Text(product['category'], style: TextStyle(fontSize: 10, color: Colors.green.shade700))),
                      const Spacer(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editProduct(product), color: Colors.blue),
                        IconButton(icon: const Icon(Icons.inventory, size: 20), onPressed: () => _editProduct(product), color: Colors.orange),
                        IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => _deleteProduct(product.id), color: Colors.red),
                      ]),
                    ]))),
                  ]));
              },
            );
          },
        )),
      ]),
    );
  }
}

// ==================== ORDERS MANAGEMENT ====================
class OrdersManagement extends StatelessWidget {
  const OrdersManagement({super.key});

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders yet', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }
        
        final orders = snapshot.data!.docs;
        final pendingOrders = orders.where((o) => o['status'] == 'pending').length;
        
        return Column(
          children: [
            if (pendingOrders > 0)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pendingOrders pending order${pendingOrders > 1 ? 's' : ''} need attention',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderData = order.data() as Map<String, dynamic>;
                  final status = orderData['status'] ?? 'pending';
                  final timestamp = orderData['createdAt'] as Timestamp?;
                  final date = timestamp != null 
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate()) 
                      : 'Unknown';
                  final items = orderData['items'] as List? ?? [];
                  final total = orderData['total'] ?? 0;
                  final customerName = orderData['customerName'] ?? 'Unknown';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status).withOpacity(0.2),
                        child: Icon(Icons.shopping_cart, color: _getStatusColor(status)),
                      ),
                      title: Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: $customerName'),
                          Text('Date: $date'),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ...items.map((item) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.production_quantity_limits, color: Colors.green),
                                    title: Text(item['name'] ?? 'Unknown'),
                                    subtitle: Text('Quantity: ${item['quantity'] ?? 1}'),
                                    trailing: Text(
                                      'UGX ${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                );
                              }),
                              const Divider(),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'UGX ${total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: status == 'pending'
                                          ? () => _updateStatus(order.id, 'approved')
                                          : null,
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: status == 'pending'
                                          ? () => _updateStatus(order.id, 'rejected')
                                          : null,
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: status,
                                decoration: const InputDecoration(
                                  labelText: 'Update Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                  DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                                ],
                                onChanged: (newStatus) async {
                                  if (newStatus != null && newStatus != status) {
                                    await _updateStatus(order.id, newStatus);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Status updated to ${newStatus.toUpperCase()}'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== CUSTOMERS MANAGEMENT ====================
class CustomersManagement extends StatelessWidget {
  const CustomersManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').where('role', isEqualTo: 'customer').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No customers yet', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }
        
        final customers = snapshot.data!.docs;
        
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final customerData = customer.data() as Map<String, dynamic>;
            final name = customerData['name'] ?? 'Unknown';
            final email = customerData['email'] ?? 'No email';
            final location = customerData['location'] ?? 'Not set';
            final phone = customerData['phone'] ?? 'Not set';
            final timestamp = customerData['createdAt'] as Timestamp?;
            final joinDate = timestamp != null 
                ? DateFormat('MMM dd, yyyy').format(timestamp.toDate()) 
                : 'Unknown';
            
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    if (phone != 'Not set')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Member since: $joinDate',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== PASSWORD RESET REQUESTS ====================
class PasswordResetRequests extends StatelessWidget {
  const PasswordResetRequests({super.key});

  Future<void> _approveRequest(DocumentSnapshot request) async {
    await FirebaseFirestore.instance.collection('password_resets').doc(request.id).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> _rejectRequest(DocumentSnapshot request) async {
    await FirebaseFirestore.instance.collection('password_resets').doc(request.id).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('password_resets').orderBy('requestedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text('No Password Reset Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }
        
        final requests = snapshot.data!.docs;
        final pendingRequests = requests.where((r) => r['status'] == 'pending').toList();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final request = pendingRequests[index];
            final data = request.data() as Map<String, dynamic>;
            final email = data['email'] ?? 'Unknown';
            final userName = data['userName'] ?? 'Customer';
            final requestedAt = data['requestedAt'] as Timestamp?;
            final requestedDate = requestedAt != null 
                ? DateFormat('MMM dd, yyyy • hh:mm a').format(requestedAt.toDate()) 
                : 'Unknown';
            final newPassword = data['newPassword'] ?? 'Not provided';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor('pending').withOpacity(0.2),
                  child: Icon(Icons.pending, color: _getStatusColor('pending')),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: const TextStyle(fontSize: 12)),
                    Text('Requested: $requestedDate', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'New Password: $newPassword',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        await _approveRequest(request);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request approved!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () async {
                        await _rejectRequest(request);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      tooltip: 'Reject',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== MESSAGES MANAGEMENT (FIXED - Shows both sent and received) ====================
class MessagesManagement extends StatefulWidget {
  const MessagesManagement({super.key});

  @override
  State<MessagesManagement> createState() => _MessagesManagementState();
}

class _MessagesManagementState extends State<MessagesManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get ALL messages where admin is either sender OR receiver
    _firestore
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
          final allMessages = snapshot.docs;
          
          // Group by the OTHER participant (customer)
          final Map<String, List<QueryDocumentSnapshot>> conversations = {};
          
          for (var msg in allMessages) {
            final data = msg.data() as Map<String, dynamic>;
            final senderId = data['senderId'];
            final receiverId = data['receiverId'];
            
            // Check if this message involves the current admin
            if (senderId == currentUser.uid || receiverId == currentUser.uid) {
              // Get the customer ID (the other participant)
              final customerId = senderId == currentUser.uid ? receiverId : senderId;
              
              if (customerId != null && customerId.isNotEmpty) {
                conversations.putIfAbsent(customerId, () => []);
                conversations[customerId]!.add(msg);
              }
            }
          }

          // Build conversation list
          final List<Map<String, dynamic>> conversationList = [];
          for (var entry in conversations.entries) {
            final convMessages = entry.value;
            
            // Sort by timestamp to get latest
            convMessages.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.toDate().compareTo(aTime.toDate());
            });
            
            final latestData = convMessages.first.data() as Map<String, dynamic>;
            
            // Get customer name (from sender if customer sent, or receiver if admin sent)
            String customerName = 'Customer';
            if (latestData['senderRole'] == 'customer') {
              customerName = latestData['senderName'] ?? 'Customer';
            } else {
              customerName = latestData['receiverName'] ?? 'Customer';
            }
            
            final customerId = entry.key;
            final timestamp = latestData['timestamp'] as Timestamp?;
            
            // Count unread messages (where admin is receiver and not read)
            final unreadCount = convMessages.where((msg) {
              final data = msg.data() as Map<String, dynamic>;
              return data['receiverId'] == currentUser.uid && 
                     data['read'] == false && 
                     data['senderRole'] == 'customer';
            }).length;
            
            conversationList.add({
              'customerId': customerId,
              'customerName': customerName,
              'lastMessage': latestData['message'] ?? '',
              'timestamp': timestamp?.toDate() ?? DateTime.now(),
              'unreadCount': unreadCount,
            });
          }
          
          conversationList.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
          
          setState(() {
            _conversations = conversationList;
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return const Center(child: Text('Please login to view messages'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Messages from customers will appear here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    customerId: conv['customerId'],
                    customerName: conv['customerName'],
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                (conv['customerName'] as String)[0].toUpperCase(),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(conv['customerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              (conv['lastMessage'] as String).length > 50 
                  ? '${(conv['lastMessage'] as String).substring(0, 50)}...' 
                  : conv['lastMessage'],
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('hh:mm a').format(conv['timestamp']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if ((conv['unreadCount'] as int) > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: Text('${conv['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== CHAT SCREEN (Shows all messages - sent and received) ====================

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const ChatScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<QueryDocumentSnapshot> _messages = [];
  bool _isLoading = true;

  String get _conversationId {
    final adminId = _auth.currentUser?.uid ?? '';
    final customerId = widget.customerId;
    List<String> ids = [adminId, customerId];
    ids.sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: _conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _messages = snapshot.docs;
            _isLoading = false;
          });
          
          _markMessagesAsRead();
          _scrollToBottom();
        });
  }

  void _markMessagesAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    for (var msg in _messages) {
      final data = msg.data() as Map<String, dynamic>;
      if (data['receiverId'] == currentUser.uid && data['read'] == false && data['senderRole'] == 'customer') {
        await msg.reference.update({'read': true});
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages'), backgroundColor: Colors.red),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestore.collection('messages').add({
        'conversationId': _conversationId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Admin',
        'senderRole': 'admin',
        'receiverId': widget.customerId,
        'receiverName': widget.customerName,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No messages yet', style: TextStyle(color: Colors.grey)),
                            Text('Send a message to start the conversation', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final data = _messages[index].data() as Map<String, dynamic>;
                          final isAdmin = data['senderRole'] == 'admin';
                          final message = data['message'] ?? '';
                          final timestamp = data['timestamp'] as Timestamp?;
                          final time = timestamp != null 
                              ? DateFormat('hh:mm a').format(timestamp.toDate()) 
                              : 'Unknown';
                          
                          return Align(
                            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAdmin ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(16),
                                  bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(4),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdmin ? 'Admin' : widget.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}