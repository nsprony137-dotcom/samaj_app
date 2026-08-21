import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';

class AdminSetupPage extends StatefulWidget {
  @override
  _AdminSetupPageState createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCode = true;
  final String _secretCode = "SAMAJ2026@ADMIN";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔐 Admin Setup'),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[700]!, Colors.blue[400]!],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Admin Banayein',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Secret Code daalein admin banne ke liye',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Secret Admin Code',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCode
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCode = !_obscureCode;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter code here...',
                      ),
                      obscureText: _obscureCode,
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ Sirf authorised person hi code daalein',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _becomeAdmin,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings),
                                  SizedBox(width: 10),
                                  Text(
                                    '🚀 Admin Banayein',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '📋 Demo Code:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          SelectableText(
                            'SAMAJ2026@ADMIN',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to copy',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _becomeAdmin() async {
    if (_codeController.text.isEmpty) {
      _showSnackBar('❌ Code daalein', Colors.red);
      return;
    }

    if (_codeController.text.trim() != _secretCode) {
      _showSnackBar('❌ Galat Code!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot existing = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();

      if (existing.exists) {
        _showSnackBar('ℹ️ Aap already admin hain', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .set({
        'userId': userId,
        'name': FirebaseAuth.instance.currentUser!.displayName ?? 'Admin',
        'email': FirebaseAuth.instance.currentUser!.email,
        'role': 'super_admin',
        'isActive': true,
        'assignedDate': FieldValue.serverTimestamp(),
        'permissions': [
          'manage_users',
          'manage_complaints',
          'manage_projects',
          'manage_blue_tick',
          'manage_red_flag',
          'view_reports',
          'send_notifications',
          'view_analytics',
        ],
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isAdmin': true,
        'adminRole': 'super_admin',
      });

      _showSnackBar('✅ Aap Admin ban gaye!', Colors.green);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(admin: userData),
        ),
      );
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
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
