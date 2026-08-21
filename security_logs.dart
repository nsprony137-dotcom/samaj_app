import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecurityLogsWidget extends StatefulWidget {
  @override
  _SecurityLogsWidgetState createState() => _SecurityLogsWidgetState();
}

class _SecurityLogsWidgetState extends State<SecurityLogsWidget> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue[800], size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔐 Security Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
        ),

        // Filters
        Container(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Login', 'login'),
              _buildFilterChip('Admin', 'admin'),
              _buildFilterChip('Complaint', 'complaint'),
              _buildFilterChip('User', 'user'),
            ],
          ),
        ),

        // Logs List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_logs')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var logs = snapshot.data!.docs;

              if (_filter != 'all') {
                logs = logs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final action = data['action'] ?? '';
                  return action.contains(_filter);
                }).toList();
              }

              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security_outlined, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('No logs found', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index].data() as Map<String, dynamic>;
                  final logId = logs[index].id;

                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: _getLogIcon(log['action']),
                      title: Text(
                        log['details']?['message'] ?? log['action'] ?? 'Unknown Action',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        log['timestamp'] != null
                            ? _formatTimestamp((log['timestamp'] as Timestamp).toDate())
                            : 'Just now',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: _getLogStatusChip(log['action']),
                      onTap: () => _showLogDetail(log),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) => setState(() => _filter = value),
      selectedColor: Colors.blue[100],
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _getLogIcon(String action) {
    Color color;
    IconData icon;

    if (action.contains('login')) {
      color = Colors.green;
      icon = Icons.login;
    } else if (action.contains('admin')) {
      color = Colors.blue;
      icon = Icons.admin_panel_settings;
    } else if (action.contains('complaint')) {
      color = Colors.orange;
      icon = Icons.report_problem;
    } else if (action.contains('user')) {
      color = Colors.purple;
      icon = Icons.person;
    } else {
      color = Colors.grey;
      icon = Icons.info;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _getLogStatusChip(String action) {
    Color color;
    if (action.contains('login')) {
      color = Colors.green;
    } else if (action.contains('admin') || action.contains('blue_tick')) {
      color = Colors.blue;
    } else if (action.contains('red_flag') || action.contains('suspend')) {
      color = Colors.red;
    } else if (action.contains('complaint')) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action.split('_').join(' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 8),
      ),
    );
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Action', log['action'] ?? 'Unknown'),
            _buildDetailRow('Message', log['details']?['message'] ?? 'N/A'),
            _buildDetailRow('Time', log['timestamp'] != null
                ? (log['timestamp'] as Timestamp).toDate().toString()
                : 'N/A'),
            if (log['details'] != null)
              for (var key in log['details'].keys)
                if (key != 'message')
                  _buildDetailRow(key, log['details'][key].toString()),
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
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
