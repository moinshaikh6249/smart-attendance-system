import 'dart:io';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  bool _isAdvertising = false;
  String? _currentUuid;
  int? _advertiseInterval; // Advertising interval in milliseconds

  bool get isAdvertising => _isAdvertising;
  String? get currentUuid => _currentUuid;

  Future<bool> requestBluetoothAndLocationPermissions() async {
    final bluetooth = await Permission.bluetooth.request();
    final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    final location = await Permission.locationWhenInUse.request();
    return bluetooth.isGranted && 
           bluetoothAdvertise.isGranted && 
           bluetoothConnect.isGranted && 
           bluetoothScan.isGranted &&
           location.isGranted;
  }

  // Convert UUID string to standard 128-bit UUID format for BLE
  String _formatServiceUuid(String uuid) {
    // Remove all dashes and ensure it's 32 hex characters
    final hex = uuid.replaceAll('-', '').toLowerCase();
    if (hex.length != 32) {
      throw Exception('Invalid UUID format: must be 128-bit UUID');
    }
    // Return in standard format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Convert UUID string to bytes for manufacturer data
  Uint8List _uuidStringToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '');
    if (hex.length != 32) {
      throw Exception('Invalid UUID format');
    }
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      final byteHex = hex.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(byteHex, radix: 16);
    }
    return bytes;
  }

  Future<void> startBroadcasting(String uuid) async {
    try {
      print('[BLEService] ======== START BROADCASTING REQUEST ========');
      print('[BLEService] Input UUID: $uuid');
      
      // Request all required permissions
      final hasPermissions = await requestBluetoothAndLocationPermissions();
      if (!hasPermissions) {
        print('[BLEService] ✗ PERMISSIONS DENIED!');
        throw Exception('Bluetooth and Location permissions are required. Please grant all permissions in Settings.');
      }
      print('[BLEService] ✓ All permissions granted');

      if (_isAdvertising && _currentUuid == uuid) {
        print('[BLEService] Already advertising UUID: $uuid');
        return;
      }

      if (_isAdvertising) {
        print('[BLEService] Stopping previous broadcast...');
        await stopBroadcasting();
      }

      // Ensure Bluetooth is enabled
      if (Platform.isAndroid) {
        final currentState = FlutterBluePlus.adapterStateNow;
        print('[BLEService] Current Bluetooth state: $currentState');
        
        if (currentState != BluetoothAdapterState.on) {
          print('[BLEService] Attempting to turn on Bluetooth...');
          try {
            await FlutterBluePlus.turnOn();
            // Wait for the adapter state to become 'on', up to 10 seconds
            bool turnedOn = false;
            try {
              await for (final state in FlutterBluePlus.adapterState.timeout(const Duration(seconds: 10))) {
                print('[BLEService] Bluetooth state changed: $state');
                if (state == BluetoothAdapterState.on) {
                  turnedOn = true;
                  break;
                }
              }
            } catch (e) {
              print('[BLEService] Timeout waiting for Bluetooth: $e');
            }
            if (!turnedOn) {
              throw Exception('Bluetooth failed to turn on. Please enable Bluetooth manually in Settings.');
            }
            print('[BLEService] Bluetooth turned on successfully');
          } catch (e) {
            print('[BLEService] Error turning on Bluetooth: $e');
            throw Exception('Failed to enable Bluetooth: $e. Please enable Bluetooth manually in Settings.');
          }
        }
      } else if (Platform.isIOS) {
        if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
          throw Exception('Please enable Bluetooth in Settings.');
        }
      }

      // Verify Bluetooth is now on
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        print('[BLEService] ✗ Bluetooth is STILL OFF!');
        throw Exception('Bluetooth is not enabled. Please enable Bluetooth in Settings.');
      }
      print('[BLEService] ✓ Bluetooth is ON');

      // Convert UUID to bytes for manufacturer data
      final uuidBytes = _uuidStringToBytes(uuid);
      
      print('[BLEService] ========================================');
      print('[BLEService] BLE ADVERTISING CONFIGURATION:');
      print('[BLEService] - UUID: $uuid');
      print('[BLEService] - Manufacturer ID: 0xFFFF (65535)');
      print('[BLEService] - Manufacturer Data: ${uuidBytes.length} bytes');
      print('[BLEService] - Device Name: RTCCS_ADMIN');
      print('[BLEService] - Include Device Name: true');
      print('[BLEService] ========================================');
      
      // Use manufacturer data with device name for maximum visibility
      // This approach works reliably on all Android devices
      final advertiseData = AdvertiseData(
        includeDeviceName: true,      // Include device name for visibility
        localName: 'RTCCS_ADMIN',     // Custom name visible in scanners
        manufacturerId: 0xFFFF,       // Standard test manufacturer ID (65535)
        manufacturerData: uuidBytes,  // UUID as 16-byte manufacturer data
      );
      
      print('[BLEService] Calling _blePeripheral.start()...');
      
      // Start advertising
      try {
        await _blePeripheral.start(advertiseData: advertiseData);
        _isAdvertising = true;
        _currentUuid = uuid;
        _advertiseInterval = 100; // Default 100ms interval
        print('[BLEService] ========================================');
        print('[BLEService] ✓✓✓ BROADCASTING STARTED SUCCESSFULLY! ✓✓✓');
        print('[BLEService] ========================================');
        print('[BLEService] Device Name: RTCCS_ADMIN');
        print('[BLEService] Manufacturer ID: 0xFFFF');
        print('[BLEService] UUID in Data: $uuid');
        print('[BLEService] ========================================');
        print('[BLEService] NOW VISIBLE TO:');
        print('[BLEService] - nRF Connect app');
        print('[BLEService] - Student app');
        print('[BLEService] - Any BLE scanner');
        print('[BLEService] ========================================');
      } catch (e) {
        print('[BLEService] ✗ Error starting BLE advertising: $e');
        // Check for specific error codes
        if (e.toString().contains('18') || e.toString().contains('ADVERTISE_FAILED')) {
          throw Exception('BLE advertising not supported on this device. Error code: $e');
        } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION')) {
          throw Exception('Bluetooth permission denied. Please grant all permissions in Settings.');
        } else {
          throw Exception('Failed to start BLE advertising: $e');
        }
      }
    } catch (e) {
      print('[BLEService] Fatal error in startBroadcasting: $e');
      _isAdvertising = false;
      _currentUuid = null;
      rethrow;
    }
  }

  Future<void> stopBroadcasting() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      _isAdvertising = false;
      _currentUuid = null;
      _advertiseInterval = null;
      print('[BLEService] Stopped broadcasting');
    }
  }

  /// Get current advertising status info (for UI display)
  Map<String, dynamic> getAdvertisingStatus() {
    return {
      'isAdvertising': _isAdvertising,
      'uuid': _currentUuid,
      'interval': _advertiseInterval,
    };
  }
}
