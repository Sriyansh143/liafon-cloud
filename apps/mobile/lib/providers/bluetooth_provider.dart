import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider extends ChangeNotifier {
  FlutterBluePlus _flutterBlue = FlutterBluePlus();
  
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _availableDevices = [];
  List<BluetoothService> _services = [];
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get availableDevices => _availableDevices;
  List<BluetoothService> get services => _services;
  
  // Initialize Bluetooth
  Future<void> initialize() async {
    try {
      // Check if Bluetooth is supported
      final isSupported = await _flutterBlue.isSupported;
      if (!isSupported) {
        throw Exception('Bluetooth is not supported on this device');
      }
      
      // Turn on Bluetooth if off
      if (!await _flutterBlue.isOn) {
        await _flutterBlue.turnOn();
      }
      
      // Set up connection state listener
      _setupConnectionListener();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
      rethrow;
    }
  }
  
  // Setup connection state listener
  void _setupConnectionListener() {
    _connectionSubscription?.cancel();
    
    if (_connectedDevice != null) {
      _connectionSubscription = _connectedDevice!.connectionState.listen(
        (state) {
          _isConnected = state == BluetoothConnectionState.connected;
          
          if (!_isConnected) {
            _connectedDevice = null;
            _services.clear();
          }
          
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Connection error: $error');
          _isConnected = false;
          _connectedDevice = null;
          notifyListeners();
        },
      );
    }
  }
  
  // Start scanning for devices
  Future<void> startScan({Duration duration = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    
    try {
      _availableDevices.clear();
      _isScanning = true;
      notifyListeners();
      
      // Start scanning
      await _flutterBlue.startScan(
        timeout: duration,
        removeIfGone: const Duration(seconds: 5),
      );
      
      // Listen for scan results
      _flutterBlue.scanResults.listen(
        (scanResult) {
          final device = scanResult.device;
          
          // Filter for smartwatch devices (you can customize this)
          if (device.name.isNotEmpty && 
              !_availableDevices.any((d) => d.id == device.id)) {
            _availableDevices.add(device);
            notifyListeners();
          }
        },
        onDone: () {
          _isScanning = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Scan error: $error');
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Stop scanning
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    try {
      await _flutterBlue.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
      rethrow;
    }
  }
  
  // Connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      
      // Wait for connection
      await device.discoverServices();
      _services = device.servicesList;
      
      _setupConnectionListener();
      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      rethrow;
    }
  }
  
  // Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _services.clear();
        _isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error disconnecting: $e');
      rethrow;
    }
  }
  
  // Read characteristic
  Future<List<int>> readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      return await characteristic.read();
    } catch (e) {
      debugPrint('Error reading characteristic: $e');
      rethrow;
    }
  }
  
  // Write characteristic
  Future<void> writeCharacteristic(
    BluetoothCharacteristic characteristic,
    List<int> value, {
    bool withoutResponse = false,
  }) async {
    try {
      await characteristic.write(value, withoutResponse: withoutResponse);
    } catch (e) {
      debugPrint('Error writing characteristic: $e');
      rethrow;
    }
  }
  
  // Subscribe to characteristic notifications
  Future<void> subscribeToCharacteristic(
    BluetoothCharacteristic characteristic,
    Function(List<int>) onValueReceived,
  ) async {
    try {
      await characteristic.setNotifyValue(true);
      characteristic.value.listen(onValueReceived);
    } catch (e) {
      debugPrint('Error subscribing to characteristic: $e');
      rethrow;
    }
  }
  
  // Find specific service by UUID
  BluetoothService? findService(String uuid) {
    try {
      return _services.firstWhere(
        (service) => service.uuid.toString().toLowerCase() == uuid.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Find characteristic by UUID within a service
  BluetoothCharacteristic? findCharacteristic(
    BluetoothService service,
    String uuid,
  ) {
    try {
      return service.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == uuid.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _flutterBlue.stopScan();
    disconnect();
    super.dispose();
  }
}
