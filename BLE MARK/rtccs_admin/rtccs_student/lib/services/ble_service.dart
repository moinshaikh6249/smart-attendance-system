import 'dart:io';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  bool _isAdvertising = false;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Set<String> _knownTeacherUuids = {}; // UUIDs to filter for

  bool get isAdvertising => _isAdvertising;
  bool get isScanning => _isScanning;

  Future<bool> requestBluetoothAndLocationPermissions() async {
    try {
      print('[BLE Permissions] Requesting permissions...');
      
      if (Platform.isAndroid) {
        // Request all Android 12+ Bluetooth permissions
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
        final location = await Permission.locationWhenInUse.request();
        
        print('[BLE Permissions] Permission statuses:');
        print('  Bluetooth Scan: $bluetoothScan');
        print('  Bluetooth Connect: $bluetoothConnect');
        print('  Bluetooth Advertise: $bluetoothAdvertise');
        print('  Location: $location');
        
        // All critical permissions must be granted
        final allGranted = bluetoothScan.isGranted && 
                          bluetoothConnect.isGranted && 
                          bluetoothAdvertise.isGranted;
        
        if (allGranted) {
          print('[BLE Permissions] ✓ All required permissions granted');
        } else {
          print('[BLE Permissions] ✗ Some permissions denied');
        }
        
        return allGranted;
      } else if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.request();
        final location = await Permission.locationWhenInUse.request();
        return bluetooth.isGranted && location.isGranted;
      }
      
      return false;
    } catch (e) {
      print('[BLE Permissions] Error requesting permissions: $e');
      return false;
    }
  }

  // Convert UUID string to standard 128-bit UUID format
  String _formatServiceUuid(String uuid) {
    final hex = uuid.replaceAll('-', '').toLowerCase();
    if (hex.length != 32) {
      throw Exception('Invalid UUID format');
    }
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Convert UUID string to bytes
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

  // Convert bytes back to UUID string
  String _bytesToUuidString(Uint8List bytes) {
    if (bytes.length != 16) {
      throw Exception('Invalid UUID bytes length');
    }
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> startBroadcasting(String uuid, String name) async {
    print('[BLE Broadcast] ======== START BROADCASTING ========');
    print('[BLE Broadcast] UUID: $uuid');
    
    final hasPermissions = await requestBluetoothAndLocationPermissions();
    if (!hasPermissions) {
      throw Exception(
        'Bluetooth permissions required. Please enable:\n'
        '1. Bluetooth Scan\n'
        '2. Bluetooth Connect\n'
        '3. Bluetooth Advertise\n\n'
        'Go to: Settings > Apps > BLE MARK STUDENT > Permissions',
      );
    }

    // Prompt user to turn on Bluetooth if needed
    if (Platform.isAndroid) {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        // Wait for the adapter state to become 'on', up to 5 seconds
        bool turnedOn = false;
        try {
          await for (final state in FlutterBluePlus.adapterState.timeout(
            const Duration(seconds: 5),
          )) {
            if (state == BluetoothAdapterState.on) {
              turnedOn = true;
              break;
            }
          }
        } catch (_) {}
        if (!turnedOn) {
          throw Exception('Bluetooth is not enabled');
        }
      }
    } else if (Platform.isIOS) {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        throw Exception('Please enable Bluetooth in Settings.');
      }
    }

    try {
      // Use 16-byte raw UUID in manufacturer data to fit BLE advertisement limits
      final uuidBytes = _uuidStringToBytes(uuid);
      final advertiseData = AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 1234,
        manufacturerData: uuidBytes,
      );
      await _blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
    } catch (e) {
      // Provide more detailed error message for BLE advertising failures
      if (e.toString().contains('18') ||
          e.toString().contains('UNDOCUMENTED')) {
        throw Exception(
          'BLE advertising not supported on this device. Please use QR code method instead.',
        );
      }
      rethrow;
    }
  }

  Future<void> stopBroadcasting() async {
    await _blePeripheral.stop();
    _isAdvertising = false;
  }

  /// Set the list of teacher UUIDs to scan for (from Firebase)
  void setTeacherUuids(Set<String> uuids) {
    _knownTeacherUuids.clear();
    _knownTeacherUuids.addAll(uuids);
    print(
      '[BLEService] Updated teacher UUIDs to scan: ${_knownTeacherUuids.length} UUIDs',
    );
  }

  /// Start continuous scanning for teacher UUIDs
  /// Detects BLE advertisements using BOTH service UUID and manufacturer data
  Future<void> startContinuousScan({
    Function(String uuid, int rssi)? onTeacherDetected,
  }) async {
    try {
      print('[BLE Scan] ======== START CONTINUOUS SCAN ========');
      
      final hasPermissions = await requestBluetoothAndLocationPermissions();
      if (!hasPermissions) {
        throw Exception(
          'Bluetooth permissions required. Please enable:\n'
          '1. Bluetooth Scan\n'
          '2. Bluetooth Connect\n'
          '3. Bluetooth Advertise\n'
          '4. Location (required for BLE)\n\n'
          'Go to: Settings > Apps > BLE MARK STUDENT > Permissions',
        );
      }

      if (_isScanning) {
        print('[BLEService] Already scanning, stopping previous scan...');
        await stopScan();
      }

      // Force Bluetooth to be on
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
              await for (final state in FlutterBluePlus.adapterState.timeout(
                const Duration(seconds: 10),
              )) {
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
              throw Exception(
                'Bluetooth failed to turn on. Please enable Bluetooth manually in Settings.',
              );
            }
            print('[BLEService] Bluetooth turned on successfully');
          } catch (e) {
            print('[BLEService] Error turning on Bluetooth: $e');
            throw Exception(
              'Failed to enable Bluetooth: $e. Please enable Bluetooth manually in Settings.',
            );
          }
        }
      }

      // Verify Bluetooth is now on
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        throw Exception(
          'Bluetooth is not enabled. Please enable Bluetooth in Settings.',
        );
      }

      _isScanning = true;
      final detectedUuids = <String>{}; // Track detected UUIDs to avoid duplicates

      print('[BLEService] Starting continuous scan for ${_knownTeacherUuids.length} teacher UUID(s)...');
      if (_knownTeacherUuids.isEmpty) {
        print('[BLEService] ⚠️ Warning: No teacher UUIDs configured. Scan will run but won\'t detect any teachers.');
      } else {
        print('[BLEService] Teacher UUIDs to scan for:');
        for (var uuid in _knownTeacherUuids) {
          print('[BLEService]   - $uuid');
        }
      }

      // Start scanning with no timeout (continuous)
      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 0), // 0 = no timeout, scan indefinitely
          androidUsesFineLocation: true,
        );
        print('[BLEService] ✓ BLE scan started successfully');
      } catch (e) {
        print('[BLEService] ✗ Error starting BLE scan: $e');
        _isScanning = false;
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION')) {
          throw Exception('Bluetooth permission denied. Please grant all permissions in Settings.');
        } else {
          throw Exception('Failed to start BLE scan: $e');
        }
      }

      // Listen to scan results continuously
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          String? foundUuid;
          
          // Method 1: Check service UUIDs (primary method)
          final serviceUuids = r.advertisementData.serviceUuids;
          if (serviceUuids.isNotEmpty) {
            for (var serviceUuid in serviceUuids) {
              final normalizedUuid = _formatServiceUuid(serviceUuid.toString());
              if (_knownTeacherUuids.contains(normalizedUuid)) {
                foundUuid = normalizedUuid;
                print('[BLEService] ✓ Found teacher via Service UUID: $normalizedUuid');
                break;
              }
            }
          }
          
          // Method 2: Check manufacturer data (fallback method)
          if (foundUuid == null) {
            final manufacturerData = r.advertisementData.manufacturerData;
            
            // Check for manufacturer ID 0xFFFF (65535) - new format
            if (manufacturerData.containsKey(0xFFFF)) {
              final data = manufacturerData[0xFFFF];
              if (data != null && data.length == 16) {
                final uuid = _bytesToUuidString(Uint8List.fromList(data));
                if (_knownTeacherUuids.contains(uuid)) {
                  foundUuid = uuid;
                  print('[BLEService] ✓ Found teacher via Manufacturer Data (0xFFFF): $uuid');
                }
              }
            }
            
            // Check for manufacturer ID 1234 - old format (backward compatibility)
            if (foundUuid == null && manufacturerData.containsKey(1234)) {
              final data = manufacturerData[1234];
              if (data != null && data.length == 16) {
                final uuid = _bytesToUuidString(Uint8List.fromList(data));
                if (_knownTeacherUuids.contains(uuid)) {
                  foundUuid = uuid;
                  print('[BLEService] ✓ Found teacher via Manufacturer Data (1234): $uuid');
                }
              }
            }
          }
          
          // If we found a matching UUID, notify the callback
          if (foundUuid != null && !detectedUuids.contains(foundUuid)) {
            detectedUuids.add(foundUuid);
            print('[BLEService] ✓ Teacher detected! UUID: $foundUuid, RSSI: ${r.rssi} dBm');
            
            // Call the callback
            if (onTeacherDetected != null) {
              onTeacherDetected(foundUuid, r.rssi);
            }
          }
        }
      });

      print('[BLEService] ✓ Continuous scan started successfully');
    } catch (e) {
      print('[BLEService] Fatal error in startContinuousScan: $e');
      _isScanning = false;
      rethrow;
    }
  }

  // Legacy method - scan for admin's BLE broadcast
  Future<Map<String, dynamic>?> scanForAdmin({
    Duration timeout = const Duration(seconds: 30),
    Function(String)? onDeviceFound,
  }) async {
    final hasPermissions = await requestBluetoothAndLocationPermissions();
    if (!hasPermissions)
      throw Exception('Bluetooth and Location permissions are required.');

    // Ensure Bluetooth is on
    if (Platform.isAndroid) {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      throw Exception('Please enable Bluetooth');
    }

    _isScanning = true;
    Map<String, dynamic>? result;
    final completer = Completer<Map<String, dynamic>?>();

    try {
      print('[BLE Scan] Starting scan for admin device...');

      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          final device = r.device;
          final advertisementData = r.advertisementData;
          String? foundUuid;

          // Method 1: Check service UUIDs
          final serviceUuids = advertisementData.serviceUuids;
          if (serviceUuids.isNotEmpty) {
            for (var serviceUuid in serviceUuids) {
              foundUuid = _formatServiceUuid(serviceUuid.toString());
              print('[BLE Scan] Found admin device via Service UUID: $foundUuid');
              break;
            }
          }

          // Method 2: Check manufacturer data with ID 0xFFFF
          if (foundUuid == null && advertisementData.manufacturerData.containsKey(0xFFFF)) {
            final data = advertisementData.manufacturerData[0xFFFF];
            if (data != null && data.length == 16) {
              foundUuid = _bytesToUuidString(Uint8List.fromList(data));
              print('[BLE Scan] Found admin device via Manufacturer Data (0xFFFF): $foundUuid');
            }
          }

          // Method 3: Check manufacturer data with ID 1234 (backward compatibility)
          if (foundUuid == null && advertisementData.manufacturerData.containsKey(1234)) {
            final data = advertisementData.manufacturerData[1234];
            if (data != null && data.length == 16) {
              foundUuid = _bytesToUuidString(Uint8List.fromList(data));
              print('[BLE Scan] Found admin device via Manufacturer Data (1234): $foundUuid');
            }
          }

          if (foundUuid != null) {
            if (onDeviceFound != null) {
              onDeviceFound(foundUuid);
            }

            if (!completer.isCompleted) {
              result = {
                'adminUUID': foundUuid,
                'deviceId': device.remoteId.toString(),
                'deviceName': advertisementData.advName,
                'rssi': r.rssi,
              };
              completer.complete(result);
            }
          }
        }
      });

      // Wait for timeout or device found
      await completer.future.timeout(
        timeout,
        onTimeout: () {
          print('[BLE Scan] Scan timeout - no admin device found');
          return null;
        },
      );
    } catch (e) {
      print('[BLE Scan] Error: $e');
      rethrow;
    } finally {
      await stopScan();
    }

    return result;
  }

  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      _isScanning = false;
      print('[BLEService] Scan stopped');
    } catch (e) {
      print('[BLEService] Error stopping scan: $e');
      _isScanning = false;
    }
  }
}
