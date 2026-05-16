import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [];
  final List<String> _titles = ['Shop', 'My Orders', 'Messages', 'Profile'];
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const ShopPage(),
      const MyOrdersPage(),
      const MessagesPage(),
      const ProfilePage(),
    ]);
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.green.shade700, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.agriculture, color: Colors.white, size: 28), const SizedBox(width: 12), Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout, tooltip: 'Logout'),
              ],
            ),
          ),
          Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}

// Shop Page
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<Map<String, dynamic>> _cart = [];
  
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex != -1) {
        _cart[existingIndex]['quantity'] = (_cart[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        _cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'imageName': product['imageName'] ?? 'apples.jpg',
          'quantity': 1,
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product['name']} added to cart!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
  }
  
  void _removeFromCart(int index) { setState(() { _cart.removeAt(index); }); }
  
  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = (_cart[index]['quantity'] ?? 1) + delta;
      if (newQuantity <= 0) { _cart.removeAt(index); } else { _cart[index]['quantity'] = newQuantity; }
    });
  }
  
  double _getTotal() {
    double total = 0;
    for (var item in _cart) { total += (item['price'] as num).toDouble() * (item['quantity'] as int); }
    return total;
  }
  
  Future<void> _placeOrder() async {
    if (_cart.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty!'), backgroundColor: Colors.orange)); return; }
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login'), backgroundColor: Colors.red)); return; }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid, 'customerName': userDoc['name'] ?? 'Customer',
        'items': _cart.map((item) => ({'id': item['id'], 'name': item['name'], 'price': item['price'], 'quantity': item['quantity']})).toList(),
        'total': _getTotal(), 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() { _cart.clear(); });
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Order placed!'), backgroundColor: Colors.green));
    } catch (e) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  }
  
  void _showCart() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.8,
          child: Column(children: [
            const Text('Your Cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: _cart.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart, size: 80, color: Colors.grey), Text('Cart empty')])) : ListView.builder(itemCount: _cart.length, itemBuilder: (context, index) {
              final item = _cart[index];
              return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                leading: Image.asset('assets/images/${item['imageName']}', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.green.shade50)),
                title: Text(item['name']), 
                subtitle: Text('UGX ${item['price']} x ${item['quantity']} = UGX ${item['price'] * item['quantity']}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () { _updateQuantity(index, -1); setModalState(() {}); }),
                  Text('${item['quantity']}'),
                  IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () { _updateQuantity(index, 1); setModalState(() {}); }),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { _removeFromCart(index); setModalState(() {}); }),
                ]),
              ));
            })),
            if (_cart.isNotEmpty) ...[
              const Divider(), 
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:'), Text('UGX ${_getTotal().toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _placeOrder, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Place Order'))),
            ],
          ]),
        );
      }),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCart, 
        child: Stack(children: [
          const Icon(Icons.shopping_cart), 
          if (_cart.isNotEmpty) 
            Positioned(
              right: 0, 
              top: 0, 
              child: Container(
                padding: const EdgeInsets.all(2), 
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), 
                child: Text(_cart.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 10))
              )
            )
        ]),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!.docs;
          if (products.isEmpty) return const Center(child: Text('No products'));
          return GridView.builder(
            padding: const EdgeInsets.all(16), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Card(
                child: Column(children: [
                  Expanded(child: Image.asset('assets/images/${p['imageName'] ?? 'apples.jpg'}', fit: BoxFit.cover)),
                  Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)), 
                    Text('UGX ${p['price']}', style: const TextStyle(color: Colors.green)),
                    ElevatedButton(
                      onPressed: () => _addToCart({'id': p.id, 'name': p['name'], 'price': p['price'], 'imageName': p['imageName']}), 
                      child: const Text('Add to Cart')
                    ),
                  ])),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// My Orders Page
class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});
  
  Color getColor(String s) => s == 'pending' ? Colors.orange : s == 'approved' ? Colors.green : s == 'rejected' ? Colors.red : Colors.grey;
  
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Login'));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('customerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) return const Center(child: Text('No orders'));
        return ListView.builder(
          itemCount: orders.length, 
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.all(8), 
              child: ListTile(
                title: Text('Order #${o.id.substring(0, 8)}'), 
                subtitle: Text('Total: UGX ${o['total']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                  decoration: BoxDecoration(color: getColor(o['status']), borderRadius: BorderRadius.circular(12)), 
                  child: Text(o['status'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10))
                ),
              )
            );
          },
        );
      },
    );
  }
}

// Messages Page
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  String? _adminId;
  
  @override
  void initState() {
    super.initState();
    _setupConversation();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _setupConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final adminQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    
    if (adminQuery.docs.isNotEmpty && mounted) {
      setState(() {
        _adminId = adminQuery.docs.first.id;
        _conversationId = user.uid.compareTo(_adminId!) < 0 
            ? '${user.uid}_$_adminId' 
            : '${_adminId}_${user.uid}';
      });
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _adminId == null) return;
    
    setState(() => _isSending = true);
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      await FirebaseFirestore.instance.collection('messages').add({
        'conversationId': _conversationId,
        'senderId': user.uid,
        'senderName': userDoc['name'] ?? 'Customer',
        'senderRole': 'customer',
        'receiverId': _adminId,
        'receiverRole': 'admin',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSending = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login'));
    
    if (_adminId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.support_agent, color: Colors.green)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Customer Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('conversationId', isEqualTo: _conversationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final messages = snapshot.data?.docs ?? [];
              
              final List<QueryDocumentSnapshot> sortedMessages = List.from(messages);
              sortedMessages.sort((a, b) {
                final Timestamp? aTime = a['timestamp'] as Timestamp?;
                final Timestamp? bTime = b['timestamp'] as Timestamp?;
                
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                
                return aTime.toDate().compareTo(bTime.toDate());
              });
              
              if (sortedMessages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No messages yet', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Send a message to support', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              for (var msg in messages) {
                final receiverId = msg['receiverId'];
                final isRead = msg['read'];
                if (receiverId == user.uid && isRead == false) {
                  msg.reference.update({'read': true});
                }
              }
              
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final msg = sortedMessages[index];
                  final isMe = msg['senderId'] == user.uid;
                  final Timestamp? timestamp = msg['timestamp'] as Timestamp?;
                  final time = timestamp?.toDate();
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.green.shade700 : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      msg['senderName'] ?? 'Support',
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Text(msg['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  time != null ? DateFormat('hh:mm a').format(time) : '',
                                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (isMe && msg['read'] == true)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, top: 4),
                              child: Text('✓ Read', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)], 
            border: Border(top: BorderSide(color: Colors.grey.shade200))
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.green.shade700,
                child: IconButton(
                  icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please log in to view profile'));
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        Map<String, dynamic> userData = {};
        bool hasFirestoreData = snapshot.hasData && snapshot.data!.exists;
        
        if (hasFirestoreData) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
        }
        
        String displayName = userData['name'] ?? user.displayName ?? 'Customer';
        String email = userData['email'] ?? user.email ?? 'No email';
        String phone = userData['phone'] ?? user.phoneNumber ?? '';
        String role = userData['role'] ?? 'customer';
        String address = userData['address'] ?? '';
        String location = userData['location'] ?? '';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                displayName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
              if (phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              if (location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        location,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              if (address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        address,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person_outline, 'User ID', _truncateId(user.uid)),
                    const Divider(),
                    _buildInfoRow(Icons.email_outlined, 'Email verified', user.emailVerified ? 'Yes' : 'No'),
                    const Divider(),
                    _buildInfoRow(Icons.calendar_today, 'Member since', _formatDate(user.metadata.creationTime)),
                    if (user.metadata.lastSignInTime != null) ...[
                      const Divider(),
                      _buildInfoRow(Icons.login, 'Last sign in', _formatDate(user.metadata.lastSignInTime)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!hasFirestoreData)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete your profile to save your information.',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'name': user.displayName ?? email.split('@')[0],
                              'email': user.email,
                              'role': 'customer',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile created successfully!')),
                              );
                              setState(() {});
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating profile: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Complete Profile'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
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
      ),
    );
  }
  
  String _truncateId(String id) {
    if (id.isEmpty) return 'Unknown';
    if (id.length <= 25) return id;
    return '${id.substring(0, 12)}...${id.substring(id.length - 8)}';
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}