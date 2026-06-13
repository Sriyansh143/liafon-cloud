import 'package:flutter/material.dart';

/// **Privacy Dashboard Screen**
/// 
/// **Features:**
/// 1. Visual graph of data sharing (Who has what?)
/// 2. "Nuclear Button" to wipe all cloud data instantly
/// 3. Granular toggle for each data category
/// 4. Export all data (GDPR compliance)
class PrivacyDashboardScreen extends StatefulWidget {
  @override
  _PrivacyDashboardScreenState createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> {
  // Mock data - replace with actual stats from backend
  final Map<String, bool> _dataToggles = {
    'Health Metrics (HR, SpO2, Sleep)': true,
    'Location History': true,
    'Voice Recordings': false,
    'Chat Conversations': true,
    'Prescription Images': true,
    'Marketplace Activity': true,
  };

  final Map<String, int> _sharedWith = {
    'PocketBase (Cloud)': 6,
    'AI Engine (Ollama)': 2,
    'Emergency Contacts': 1,
    'Marketplace Users': 0,
  };

  bool _isWiping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Dashboard'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            
            SizedBox(height: 24),
            
            // Data Sharing Visualization
            Text('🔗 Data Sharing Overview', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            _buildSharingGraph(),
            
            SizedBox(height: 24),
            
            // Granular Toggles
            Text('🛡️ Data Permissions', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            _buildPermissionToggles(),
            
            SizedBox(height: 24),
            
            // Actions
            Text('⚙️ Data Actions', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            _buildActionButtons(),
            
            SizedBox(height: 32),
            
            // NUCLEAR BUTTON
            _buildNuclearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security, size: 40, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Your Data, Your Control',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Liafon Cloud stores 0% of your sensitive data without consent.\nReview and control everything here.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingGraph() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _sharedWith.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: TextStyle(fontSize: 14)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.value > 0 ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.value} items',
                    style: TextStyle(
                      color: entry.value > 0 ? Colors.orange[900] : Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionToggles() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _dataToggles.entries.map((entry) {
          return ListTile(
            title: Text(entry.key, style: TextStyle(fontSize: 14)),
            trailing: Switch(
              value: entry.value,
              onChanged: (value) {
                setState(() {
                  _dataToggles[entry.key] = value;
                });
                // TODO: Save preference to backend
              },
              activeColor: Colors.green,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Export all data as JSON/ZIP
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Preparing data export...')),
            );
          },
          icon: Icon(Icons.download),
          label: Text('Export My Data (GDPR)'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Show detailed audit log
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening audit log...')),
            );
          },
          icon: Icon(Icons.history),
          label: Text('View Access Log'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildNuclearButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 40),
          SizedBox(height: 12),
          Text(
            'NUCLEAR OPTION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900]),
          ),
          SizedBox(height: 8),
          Text(
            'Permanently delete ALL your data from cloud servers.\nThis action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 12),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isWiping ? null : _confirmNuclearWipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
            child: _isWiping
                ? CircularProgressIndicator(color: Colors.white)
                : Text('DELETE ALL CLOUD DATA'),
          ),
        ],
      ),
    );
  }

  void _confirmNuclearWipe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('⚠️ Final Warning'),
        content: Text(
          'Are you absolutely sure? This will:\n'
          '• Delete all health records\n'
          '• Remove all prescriptions\n'
          '• Erase chat history\n'
          '• Wipe marketplace data\n\n'
          'Local data will remain, but cloud sync will be broken.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeNuclearWipe();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeNuclearWipe() async {
    setState(() => _isWiping = true);
    
    // TODO: Call backend API to wipe all data
    await Future.delayed(Duration(seconds: 2)); // Simulate API call
    
    setState(() => _isWiping = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ All cloud data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
