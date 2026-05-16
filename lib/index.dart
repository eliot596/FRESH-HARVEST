import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'customer_home.dart';
import 'admin_dashboard.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFirebaseReady = false;
  bool _isLoading = true;

  // Removed 'Organic' from categories
  final List<String> _categories = [
    'All', 'Vegetables', 'Fruits',
  ];

  final List<Map<String, String>> _farmingTips = [
    {'icon': '🌱', 'title': 'Buy Fresh, Eat Fresh', 'description': 'Fresh produce retains more nutrients and tastes better.'},
    {'icon': '📍', 'title': 'Farm to Table', 'description': 'We connect you directly with local farmers.'},
    {'icon': '🥬', 'title': 'Seasonal Produce', 'description': 'Buy fruits and vegetables that are in season.'},
    {'icon': '📦', 'title': 'Proper Storage', 'description': 'Learn how to store different produce items.'},
  ];

  final List<Map<String, String>> _popularCategories = [
    {'name': 'Tomatoes', 'image': '🍅', 'color': '#E53935'},
    {'name': 'Onions', 'image': '🧅', 'color': '#1E88E5'},
    {'name': 'Potatoes', 'image': '🥔', 'color': '#43A047'},
    {'name': 'Cabbages', 'image': '🥬', 'color': '#FB8C00'},
    {'name': 'Carrots', 'image': '🥕', 'color': '#8E24AA'},
    {'name': 'Spinach', 'image': '🌿', 'color': '#00ACC1'},
     
  ];

  final List<Map<String, String>> _locations = [
    {'name': 'Mbarara City Center', 'icon': '🏙️', 'delivery': 'Free Delivery', 'time': '30-45 min'},
    {'name': 'Kakoba', 'icon': '🏘️', 'delivery': 'Free Delivery', 'time': '20-30 min'},
    {'name': 'Nyamitanga', 'icon': '🏡', 'delivery': 'Free Delivery', 'time': '25-35 min'},
    {'name': 'Kamukuzi', 'icon': '🏛️', 'delivery': 'Free Delivery', 'time': '20-30 min'},
    {'name': 'Boma', 'icon': '🏢', 'delivery': 'Free Delivery', 'time': '15-25 min'},
    {'name': 'Ruharo', 'icon': '🏠', 'delivery': 'UGX 2,000', 'time': '35-45 min'},
  ];

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  void _checkFirebase() {
    try {
      FirebaseAuth.instance;
      setState(() {
        _isFirebaseReady = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isFirebaseReady = false;
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToCustomerDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CustomerHome()),
    );
  }

  bool _filterProduct(Map<String, dynamic> product) {
    // Search filter
    if (_searchQuery.isNotEmpty) {
      final name = product['name']?.toLowerCase() ?? '';
      final category = product['category']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      if (!name.contains(query) && !category.contains(query)) return false;
    }
    
    // Category filter - Remove category restriction, show ALL products
    // Only filter if category is not 'All' AND product category matches
    if (_selectedCategory != 'All') {
      final productCategory = product['category'] ?? '';
      if (productCategory.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
    }
    
    return true;
  }

  Widget _buildDrawer() {
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
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
                          'Fresh from Farm to Table',
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
                            currentUser.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.displayName ?? 'Customer',
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
                _buildDrawerItem(Icons.home, 'Home', () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.shopping_bag, 'My Orders', () {
                  Navigator.pop(context);
                  _navigateToCustomerDashboard();
                }),
                _buildDrawerItem(Icons.favorite, 'My Wishlist', () {
                  Navigator.pop(context);
                  _showComingSoon('Wishlist');
                }),
                _buildDrawerItem(Icons.location_on, 'Delivery Areas', () {
                  Navigator.pop(context);
                  _showLocationDialog();
                }),
                _buildDrawerItem(Icons.info, 'About Us', () {
                  Navigator.pop(context);
                  _showAboutDialog();
                }),
                _buildDrawerItem(Icons.help, 'Help Center', () {
                  Navigator.pop(context);
                  _showHelpDialog();
                }),
                _buildDrawerItem(Icons.phone, 'Contact Us', () {
                  Navigator.pop(context);
                  _showContactDialog();
                }),
                const Divider(),
                if (currentUser == null)
                  _buildDrawerItem(Icons.login, 'Login / Register', () {
                    Navigator.pop(context);
                    _navigateToLogin();
                  }),
                if (currentUser != null)
                  _buildDrawerItem(Icons.logout, 'Logout', () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    _navigateToLogin();
                  }),
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
                const Text(
                  '© 2025 FreshHarvest',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '📍 Serving Mbarara & Surrounding Areas',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📍 Delivery Areas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 10),
              ..._locations.map((loc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(loc['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${loc['delivery']} • ${loc['time']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.agriculture, color: Colors.green),
            const SizedBox(width: 8),
            const Text('About FreshHarvest'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FreshHarvest connects farmers directly with customers in Mbarara, Uganda.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('🌱 Mission:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('To provide fresh, quality farm products at fair prices.'),
            const SizedBox(height: 8),
            const Text('📍 Service Area:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Mbarara City and surrounding areas'),
            const SizedBox(height: 8),
            const Text('📞 Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('+256 700 123 456'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Help Center'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('🛒', 'How to order?', 'Select products, add to cart, and checkout'),
            const Divider(),
            _buildHelpItem('💳', 'Payment Methods?', 'Cash on Delivery, Mobile Money'),
            const Divider(),
            _buildHelpItem('🚚', 'Delivery Time?', 'Same day delivery for orders before 2PM'),
            const Divider(),
            _buildHelpItem('🔄', 'Returns Policy?', 'Returns accepted within 24 hours'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Contact Us'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactItem(Icons.phone, 'Call Us', '+256 700 123 456'),
            const Divider(),
            _buildContactItem(Icons.message, 'WhatsApp', '+256 700 123 456'),
            const Divider(),
            _buildContactItem(Icons.email, 'Email', 'support@freshharvest.com'),
            const Divider(),
            _buildContactItem(Icons.access_time, 'Working Hours', 'Mon-Sat: 8AM - 8PM, Sun: 10AM - 6PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade700, Colors.green.shade400, Colors.green.shade300],
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.login, color: Colors.white, size: 28),
                      onPressed: _navigateToLogin,
                      tooltip: 'Login / Register',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'FreshHarvest',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green.shade700, Colors.green.shade500],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.agriculture, size: 50, color: Colors.white),
                            SizedBox(height: 6),
                            Text(
                              'Fresh Farm Products',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome to FreshHarvest!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Get fresh farm products delivered to your doorstep in Mbarara',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _navigateToLogin,
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text('Login / Register', style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📍 We deliver to Mbarara!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Free delivery on orders over UGX 50,000',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showLocationDialog,
                          style: TextButton.styleFrom(minimumSize: const Size(0, 30)),
                          child: const Text('View Areas', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat, style: const TextStyle(fontSize: 12)),
                              selected: _selectedCategory == cat,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? cat : 'All';
                                });
                              },
                              backgroundColor: Colors.grey.shade100,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Fresh Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                
                _isFirebaseReady
                    ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 50, color: Colors.red),
                                    const SizedBox(height: 12),
                                    const Text('Unable to load products'),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const SliverToBoxAdapter(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          var products = snapshot.data!.docs.where((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            data['id'] = doc.id;
                            return _filterProduct(data);
                          }).toList();

                          if (products.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 50, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    const Text('No products found'),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedCategory = 'All';
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                      child: const Text('Clear Filters'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  var data = products[index].data() as Map<String, dynamic>;
                                  String? imageBase64 = data['imageBase64'];
                                  String? imageName = data['imageName'];
                                  double currentPrice = data['price'] ?? 0;
                                  int stock = data['stock'] ?? 0;
                                  String productName = data['name'] ?? 'Product';
                                  String category = data['category'] ?? 'Uncategorized';

                                  return GestureDetector(
                                    onTap: () {
                                      User? user = FirebaseAuth.instance.currentUser;
                                      if (user == null) {
                                        _showLoginPrompt();
                                      } else {
                                        _navigateToCustomerDashboard();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Full Image Cover
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: imageBase64 != null && imageBase64.isNotEmpty
                                                ? Image.memory(
                                                    base64Decode(imageBase64.split(',')[1]),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      if (imageName != null && imageName.isNotEmpty) {
                                                        return Image.asset(
                                                          'assets/images/$imageName',
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          errorBuilder: (context, error, stackTrace) => Container(
                                                            color: Colors.green.shade100,
                                                            child: const Center(
                                                              child: Icon(Icons.image_not_supported, size: 40, color: Colors.green),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return Container(
                                                        color: Colors.green.shade100,
                                                        child: const Center(
                                                          child: Icon(Icons.inventory, size: 40, color: Colors.green),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : imageName != null && imageName.isNotEmpty
                                                    ? Image.asset(
                                                        'assets/images/$imageName',
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          color: Colors.green.shade100,
                                                          child: const Center(
                                                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.green),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: Colors.green.shade100,
                                                        child: const Center(
                                                          child: Icon(Icons.inventory, size: 40, color: Colors.green),
                                                        ),
                                                      ),
                                          ),
                                          // Gradient Overlay for better text visibility
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.3),
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Product Info Overlay
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    category,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.inventory, size: 12, color: Colors.white70),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        stock > 0 ? 'In Stock' : 'Out of Stock',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'UGX ${currentPrice.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        User? user = FirebaseAuth.instance.currentUser;
                                                        if (user == null) {
                                                          _showLoginPrompt();
                                                        } else {
                                                          _navigateToCustomerDashboard();
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: const Text('Buy Now'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                childCount: products.length,
                              ),
                            ),
                          );
                        },
                      )
                    : const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Login Required'),
        content: const Text('Please login or register to continue shopping.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}