import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RedFlagManagementPage extends StatefulWidget {
  @override
  _RedFlagManagementPageState createState() => _RedFlagManagementPageState();
}

class _RedFlagManagementPageState extends State<RedFlagManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.red[50],
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Red Flag Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('isRedFlagged', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Text(
                          'Total Red Flag Users: $count',
                          style: TextStyle(color: Colors.grey[600]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isRedFlagged', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_outlined, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('No Red Flag users yet', style: TextStyle(color: Colors.grey[600])),
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
                        backgroundColor: Colors.red[100],
                        child: Text(
                          (user['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(user['name'] ?? 'Unknown')),
                          Icon(Icons.warning, color: Colors.red, size: 20),
                        ],
                      ),
                      subtitle: Text(
                        '${user['role'] ?? 'Public'} • ${user['village'] ?? 'N/A'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⚠️ ${user['redFlagCount'] ?? 0}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.green),
                            onPressed: () => _removeRedFlag(userId, user),
                            tooltip: 'Remove Red Flag',
                          ),
                        ],
                      ),
                      onTap: () => _showUserDetail(user),
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

  Future<void> _removeRedFlag(String userId, Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove Red Flag'),
        content: Text('Are you sure you want to remove Red Flag from ${user['name'] ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isRedFlagged': false,
          'redFlagCount': 0,
          'isAccountSuspended': false,
          'suspensionEndDate': null,
        });
        _showSnackBar('✅ Red Flag removed from ${user['name'] ?? 'user'}', Colors.green);
      } catch (e) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Text(user['name'] ?? 'User'),
            SizedBox(width: 8),
            Icon(Icons.warning, color: Colors.red),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Role', user['role'] ?? 'Public'),
            _buildDetailRow('Village', user['village'] ?? 'N/A'),
            _buildDetailRow('Red Flag Count', '${user['redFlagCount'] ?? 0}'),
            _buildDetailRow('Suspended', user['isAccountSuspended'] == true ? '🔒 Yes' : '✅ No'),
            _buildDetailRow('Flag Date', user['redFlagDate'] != null
                ? (user['redFlagDate'] as Timestamp).toDate().toString()
                : 'N/A'),
          ],
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
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
