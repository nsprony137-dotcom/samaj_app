import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs;

              if (_searchQuery.isNotEmpty) {
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('No users found', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          (user['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (user['isBlueTickVerified'] == true)
                            Icon(Icons.verified, color: Colors.blue, size: 16),
                          if (user['isRedFlagged'] == true)
                            Icon(Icons.warning, color: Colors.red, size: 16),
                        ],
                      ),
                      subtitle: Text(
                        '${user['role'] ?? 'Public'} • ${user['village'] ?? 'N/A'}',
                      ),
                      trailing: PopupMenuButton(
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text('View Profile'),
                              ],
                            ),
                            value: 'view',
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(
                                  user['isBlueTickVerified'] == true
                                      ? Icons.verified
                                      : Icons.verified_outlined,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(user['isBlueTickVerified'] == true
                                    ? 'Remove Blue Tick'
                                    : 'Award Blue Tick'),
                              ],
                            ),
                            value: 'blue_tick',
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(
                                  user['isRedFlagged'] == true
                                      ? Icons.warning
                                      : Icons.warning_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(user['isRedFlagged'] == true
                                    ? 'Remove Red Flag'
                                    : 'Issue Red Flag'),
                              ],
                            ),
                            value: 'red_flag',
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete User'),
                              ],
                            ),
                            value: 'delete',
                          ),
                        ],
                        onSelected: (value) {
                          _handleAction(value, userId, user);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, String userId, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        _showUserDetail(user);
        break;
      case 'blue_tick':
        _toggleBlueTick(userId, user);
        break;
      case 'red_flag':
        _toggleRedFlag(userId, user);
        break;
      case 'delete':
        _deleteUser(userId, user);
        break;
    }
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user['name'] ?? 'Unknown'),
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Role', user['role'] ?? 'Public'),
              _buildDetailRow('Village', user['village'] ?? 'N/A'),
              _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
              _buildDetailRow('Blue Tick', user['isBlueTickVerified'] == true ? '✅ Yes' : '❌ No'),
              _buildDetailRow('Red Flag', user['isRedFlagged'] == true ? '⛔ Yes' : '✅ No'),
              _buildDetailRow('Suspended', user['isAccountSuspended'] == true ? '🔒 Yes' : '✅ No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlueTick(String userId, Map<String, dynamic> user) async {
    try {
      final currentStatus = user['isBlueTickVerified'] ?? false;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlueTickVerified': !currentStatus,
        'blueTickAwardedDate': FieldValue.serverTimestamp(),
      });
      _showSnackBar(
        currentStatus ? '✅ Blue Tick removed' : '✅ Blue Tick awarded',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _toggleRedFlag(String userId, Map<String, dynamic> user) async {
    try {
      final currentStatus = user['isRedFlagged'] ?? false;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isRedFlagged': !currentStatus,
        'redFlagDate': FieldValue.serverTimestamp(),
      });
      _showSnackBar(
        currentStatus ? '✅ Red Flag removed' : '⛔ Red Flag issued',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['name'] ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        _showSnackBar('✅ User deleted successfully', Colors.green);
      } catch (e) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
