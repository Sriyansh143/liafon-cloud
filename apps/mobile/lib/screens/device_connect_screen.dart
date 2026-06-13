import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/health_provider.dart';

class DeviceConnectScreen extends StatelessWidget {
  const DeviceConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Watch'),
        actions: [
          IconButton(
            icon: Icon(
              bluetoothProvider.isScanning 
                ? Icons.bluetooth_searching 
                : Icons.bluetooth_disabled,
              color: bluetoothProvider.isConnected 
                ? Colors.green 
                : null,
            ),
            onPressed: () {
              if (bluetoothProvider.isScanning) {
                bluetoothProvider.stopScan();
              } else {
                bluetoothProvider.startScan();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: bluetoothProvider.isConnected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.watch,
                        size: 30,
                        color: bluetoothProvider.isConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bluetoothProvider.isConnected
                                ? 'Watch Connected'
                                : 'No Watch Connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: bluetoothProvider.isConnected
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bluetoothProvider.isConnected
                                ? bluetoothProvider.connectedDevice?.name ?? 'Unknown'
                                : 'Tap scan to find your watch',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bluetoothProvider.isConnected)
                      IconButton(
                        icon: const Icon(Icons.disconnect, color: Colors.red),
                        onPressed: () => _showDisconnectDialog(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Scan Button
          if (!bluetoothProvider.isScanning && !bluetoothProvider.isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan for Devices'),
                  onPressed: () => bluetoothProvider.startScan(),
                ),
              ),
            ),
          
          // Scanning Indicator
          if (bluetoothProvider.isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for devices...'),
                ],
              ),
            ),
          
          // Device List
          Expanded(
            child: bluetoothProvider.availableDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bluetoothProvider.isScanning
                              ? 'Searching for nearby devices...'
                              : 'No devices found. Tap scan to search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bluetoothProvider.availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = bluetoothProvider.availableDevices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.watch, color: Colors.white),
                          ),
                          title: Text(
                            device.name.isNotEmpty ? device.name : 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            device.id.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: ElevatedButton(
                            child: const Text('Connect'),
                            onPressed: () => _connectToDevice(context, device),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _connectToDevice(
    BuildContext context,
    dynamic device,
  ) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    
    try {
      await bluetoothProvider.connectToDevice(device);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Watch'),
        content: const Text('Are you sure you want to disconnect from your watch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<BluetoothProvider>(context, listen: false).disconnect();
              Navigator.pop(context);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
