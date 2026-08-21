import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsWidget extends StatefulWidget {
  @override
  _AnalyticsWidgetState createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
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
      final complaints = await FirebaseFirestore.instance.collection('complaints').get();
      final pending = await FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: 'pending')
          .get();
      final resolved = await FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: 'resolved')
          .get();
      final projects = await FirebaseFirestore.instance.collection('projects').get();
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
          'totalUsers': users.docs.length,
          'totalComplaints': complaints.docs.length,
          'pendingComplaints': pending.docs.length,
          'resolvedComplaints': resolved.docs.length,
          'totalProjects': projects.docs.length,
          'blueTickUsers': blueTick.docs.length,
          'redFlagUsers': redFlag.docs.length,
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
        title: Text('📊 Analytics'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Overview Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildAnalyticsCard(
                        '👥 Users',
                        stats['totalUsers'].toString(),
                        'Total users',
                        Colors.blue,
                        Icons.people,
                      ),
                      _buildAnalyticsCard(
                        '📋 Complaints',
                        stats['totalComplaints'].toString(),
                        'Total complaints',
                        Colors.red,
                        Icons.report_problem,
                      ),
                      _buildAnalyticsCard(
                        '⏳ Pending',
                        stats['pendingComplaints'].toString(),
                        'Pending complaints',
                        Colors.orange,
                        Icons.pending_actions,
                      ),
                      _buildAnalyticsCard(
                        '✅ Resolved',
                        stats['resolvedComplaints'].toString(),
                        'Resolved complaints',
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildAnalyticsCard(
                        '🏗️ Projects',
                        stats['totalProjects'].toString(),
                        'Total projects',
                        Colors.green,
                        Icons.build,
                      ),
                      _buildAnalyticsCard(
                        '✅ Blue Tick',
                        stats['blueTickUsers'].toString(),
                        'Blue tick users',
                        Colors.blue,
                        Icons.verified,
                      ),
                      _buildAnalyticsCard(
                        '⛔ Red Flag',
                        stats['redFlagUsers'].toString(),
                        'Red flag users',
                        Colors.red,
                        Icons.warning,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Complaint Status Chart
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Complaint Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildProgressBar(
                            'Pending',
                            stats['pendingComplaints'],
                            stats['totalComplaints'],
                            Colors.orange,
                          ),
                          _buildProgressBar(
                            'Resolved',
                            stats['resolvedComplaints'],
                            stats['totalComplaints'],
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // User Roles Distribution
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👥 User Roles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildRoleDistribution(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _exportReport,
                      icon: Icon(Icons.download),
                      label: Text('📥 Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
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
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) * 100 : 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
              Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final users = snapshot.data!.docs;
        final total = users.length;

        int sarpanch = 0;
        int member = 0;
        int public = 0;

        for (var doc in users) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'public';
          if (role == 'sarpanch') sarpanch++;
          else if (role == 'member') member++;
          else public++;
        }

        return Column(
          children: [
            _buildRoleRow('Sarpanch', sarpanch, total, Colors.blue),
            _buildRoleRow('Member', member, total, Colors.green),
            _buildRoleRow('Public', public, total, Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildRoleRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📥 Report Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Report generating...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This feature will export analytics data as PDF/Excel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
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
}
