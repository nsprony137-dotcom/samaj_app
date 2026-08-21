import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_management.dart';
import 'complaint_management.dart';
import 'blue_tick_management.dart';
import 'red_flag_management.dart';
import 'notification_widget.dart';
import 'analytics_widget.dart';
import 'security_logs.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> admin;

  const AdminDashboard({Key? key, required this.admin}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => isLoading = true);
    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      final complaints = await FirebaseFirestore.instance
          .collection('complaints')
          .get();
      final pending = await FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: 'pending')
          .get();
      final projects = await FirebaseFirestore.instance
          .collection('projects')
          .get();
      final blueTick = await FirebaseFirestore.instance
          .collection('users')
          .where('isBlueTickVerified', isEqualTo: true)
          .get();
      final redFlag = await FirebaseFirestore.instance
          .collection('users')
          .where('isRedFlagged', isEqualTo: true)
          .get();

      setState(() {
        stats = {
          'users': users.docs.length,
          'complaints': complaints.docs.length,
          'pending': pending.docs.length,
          'projects': projects.docs.length,
          'blueTick': blueTick.docs.length,
          'redFlag': redFlag.docs.length,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛠️ Admin Panel'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue[800],
                    size: 35,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  widget.admin['name'] ?? 'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'SUPER ADMIN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                _buildMenuItem(Icons.people, 'Users', 1),
                _buildMenuItem(Icons.report_problem, 'Complaints', 2),
                _buildMenuItem(Icons.verified, 'Blue Tick', 3),
                _buildMenuItem(Icons.warning, 'Red Flag', 4),
                _buildMenuItem(Icons.notifications, 'Notifications', 5),
                _buildMenuItem(Icons.analytics, 'Analytics', 6),
                _buildMenuItem(Icons.security, 'Security Logs', 7),
                Divider(),
                _buildMenuItem(Icons.logout, 'Logout', -1, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index,
      [Color? color]) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[800] : (color ?? Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue[800] : (color ?? Colors.black87),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue[50] : null,
      onTap: () {
        if (index == -1) {
          _logout();
        } else {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading stats...'),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return UserManagementPage();
      case 2:
        return ComplaintManagementPage();
      case 3:
        return BlueTickManagementPage();
      case 4:
        return RedFlagManagementPage();
      case 5:
        return NotificationWidget();
      case 6:
        return AnalyticsWidget();
      case 7:
        return SecurityLogsWidget();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '📊 Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Welcome back, ${widget.admin['name'] ?? 'Admin'}!',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard('👥 Users', stats['users'].toString(),
                    Icons.people, Colors.blue),
                _buildStatCard('📋 Complaints', stats['complaints'].toString(),
                    Icons.report_problem, Colors.red),
                _buildStatCard('⏳ Pending', stats['pending'].toString(),
                    Icons.pending_actions, Colors.orange),
                _buildStatCard('🏗️ Projects', stats['projects'].toString(),
                    Icons.build, Colors.green),
                _buildStatCard('✅ Blue Tick', stats['blueTick'].toString(),
                    Icons.verified, Colors.blue),
                _buildStatCard('⛔ Red Flag', stats['redFlag'].toString(),
                    Icons.warning, Colors.red),
              ],
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💡 Click on any stat to view details',
                        style: TextStyle(color: Colors.blue[700]),
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
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[800],
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_problem),
          label: 'Complaints',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified),
          label: 'Blue Tick',
        ),
      ],
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Logout'),
        content: Text('Kya aap admin panel se logout karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
