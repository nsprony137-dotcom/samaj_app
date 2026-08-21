import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintManagementPage extends StatefulWidget {
  @override
  _ComplaintManagementPageState createState() => _ComplaintManagementPageState();
}

class _ComplaintManagementPageState extends State<ComplaintManagementPage> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Pending', 'pending', Colors.orange),
              _buildFilterChip('Resolved', 'resolved', Colors.green),
              _buildFilterChip('Rejected', 'rejected', Colors.red),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var complaints = snapshot.data!.docs;

              if (_filterStatus != 'all') {
                complaints = complaints.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == _filterStatus;
                }).toList();
              }

              if (complaints.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_off, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('No complaints found', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index].data() as Map<String, dynamic>;
                  final complaintId = complaints[index].id;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: _getComplaintIcon(complaint['type']),
                      title: Text(
                        complaint['type'] ?? 'General',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'By: ${complaint['userName'] ?? 'Anonymous'}\n${complaint['description'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _getStatusChip(complaint['status']),
                          if (complaint['status'] == 'pending')
                            IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _resolveComplaint(complaintId),
                              tooltip: 'Resolve',
                            ),
                        ],
                      ),
                      onTap: () => _showComplaintDetail(complaint),
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

  Widget _buildFilterChip(String label, String value, [Color? color]) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) => setState(() => _filterStatus = value),
      selectedColor: color?.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _getComplaintIcon(String? type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'Daru (Alcohol)':
        icon = Icons.local_drink;
        color = Colors.red;
        break;
      case 'Road':
        icon = Icons.road;
        color = Colors.orange;
        break;
      case 'Water':
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'Electricity':
        icon = Icons.electric_bolt;
        color = Colors.yellow;
        break;
      default:
        icon = Icons.report_problem;
        color = Colors.grey;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _getStatusChip(String? status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status ?? 'Unknown',
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }

  Future<void> _resolveComplaint(String complaintId) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('✅ Complaint resolved', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  void _showComplaintDetail(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(complaint['type'] ?? 'Complaint'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', complaint['userName'] ?? 'Anonymous'),
              _buildDetailRow('Status', complaint['status'] ?? 'Unknown'),
              _buildDetailRow('Date', complaint['timestamp'] != null
                  ? (complaint['timestamp'] as Timestamp).toDate().toString()
                  : 'N/A'),
              SizedBox(height: 8),
              Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint['description'] ?? 'No description'),
              if (complaint['imageUrl'] != null) ...[
                SizedBox(height: 8),
                Image.network(complaint['imageUrl'], height: 150),
              ],
              if (complaint['latitude'] != null)
                Text('📍 Location: ${complaint['latitude']}, ${complaint['longitude']}'),
            ],
          ),
        ),
        actions: [
          if (complaint['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resolveComplaint(complaint['id']);
              },
              child: Text('Resolve'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
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
        children: [
          SizedBox(
            width: 60,
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
