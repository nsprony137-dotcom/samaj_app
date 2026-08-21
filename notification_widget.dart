import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationWidget extends StatefulWidget {
  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _targetAudience = 'all';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📢 Send Notification',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Audience Selection
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Target Audience',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAudienceChip('All Users', 'all'),
                      _buildAudienceChip('Sarpanch', 'sarpanch'),
                      _buildAudienceChip('Members', 'member'),
                      _buildAudienceChip('Public', 'public'),
                      _buildAudienceChip('Blue Tick', 'blue_tick'),
                      _buildAudienceChip('Red Flag', 'red_flag'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: 'Enter title...',
            ),
          ),

          SizedBox(height: 16),

          // Body
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: 'Message Body',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: 'Enter message...',
            ),
            maxLines: 5,
          ),

          SizedBox(height: 16),

          // Preview
          Card(
            elevation: 2,
            color: Colors.blue[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 Preview',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _titleController.text.isEmpty ? 'Title' : _titleController.text,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _bodyController.text.isEmpty ? 'Message' : _bodyController.text,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Send Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              child: _isSending
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 10),
                        Text(
                          'Send Notification',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String label, String value) {
    final isSelected = _targetAudience == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _targetAudience = value;
        });
      },
      selectedColor: Colors.blue[100],
      backgroundColor: Colors.grey[200],
    );
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('Please fill all fields', Colors.red);
      return;
    }

    setState(() => _isSending = true);

    try {
      // Get target users
      QuerySnapshot usersSnapshot;

      switch (_targetAudience) {
        case 'sarpanch':
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'sarpanch')
              .get();
          break;
        case 'member':
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'member')
              .get();
          break;
        case 'public':
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'public')
              .get();
          break;
        case 'blue_tick':
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('isBlueTickVerified', isEqualTo: true)
              .get();
          break;
        case 'red_flag':
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('isRedFlagged', isEqualTo: true)
              .get();
          break;
        default:
          usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      }

      // Send notification to each user
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in usersSnapshot.docs) {
        final notificationRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'userId': doc.id,
          'title': _titleController.text,
          'body': _bodyController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'admin_notification',
        });
      }

      await batch.commit();

      // Log admin action
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': 'send_notification',
        'adminId': FirebaseAuth.instance.currentUser?.uid,
        'details': {
          'message': 'Sent notification to ${_targetAudience} (${usersSnapshot.docs.length} users)',
          'title': _titleController.text,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
        '✅ Notification sent to ${usersSnapshot.docs.length} users',
        Colors.green,
      );

      // Clear fields
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
