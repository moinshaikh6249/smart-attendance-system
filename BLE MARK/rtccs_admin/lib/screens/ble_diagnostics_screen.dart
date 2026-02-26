import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class BleDiagnosticsScreen extends StatefulWidget {
  const BleDiagnosticsScreen({super.key});

  @override
  State<BleDiagnosticsScreen> createState() => _BleDiagnosticsScreenState();
}

class _BleDiagnosticsScreenState extends State<BleDiagnosticsScreen> {
  final List<_BlePacket> _packets = [];
  bool _scanning = false;
  BluetoothAdapterState _adapterState = FlutterBluePlus.adapterStateNow;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _adapterState = state);
      }
    });
  }

  @override
  void dispose() {
    _stopScan();
    _adapterSub?.cancel();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final granted = statuses.values.every((status) => status.isGranted);
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth and Location permissions are required'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return granted;
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    final hasPermissions = await _ensurePermissions();
    if (!hasPermissions) return;

    if (_adapterState != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        // Ignore; user might be on iOS.
      }
    }

    setState(() {
      _scanning = true;
      _packets.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 0));
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final result in results) {
            final packet = _BlePacket(
              deviceId: result.device.remoteId.str,
              name: result.advertisementData.advName ?? 'Unknown',
              rssi: result.rssi,
              manufacturerData: Map<int, List<int>>.from(
                result.advertisementData.manufacturerData,
              ),
              timestamp: DateTime.now(),
            );
            _packets.insert(0, packet);
            if (_packets.length > 50) {
              _packets.removeLast();
            }
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start scan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _scanning = false);
    }
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _openNrfConnect() async {
    const playStore = 'market://details?id=no.nordicsemi.android.mcp';
    const webUrl =
        'https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp';
    final Uri primary = Uri.parse(playStore);
    if (!await launchUrl(primary, mode: LaunchMode.externalApplication)) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  String _formatManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) return '—';
    return data.entries
        .map((entry) {
          final manufacturerId = entry.key;
          final payload = entry.value
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          final isAppPayload = manufacturerId == 1234;
          final label = isAppPayload ? ' (RTCCS)' : '';
          return '0x${manufacturerId.toRadixString(16).padLeft(4, '0')}$label: $payload';
        })
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Open nRF Connect',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openNrfConnect,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adapter State: ${_adapterState.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _adapterState == BluetoothAdapterState.on
                          ? 'Bluetooth is ON. You should also see this device from the nRF Connect app.'
                          : 'Please enable Bluetooth from Quick Settings or tap the power button above.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              _scanning ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(_scanning ? 'Stop Scan' : 'Start Scan'),
                            onPressed: _scanning ? _stopScan : _startScan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.power_settings_new),
                          label: const Text('Turn Bluetooth On'),
                          onPressed: () async {
                            try {
                              await FlutterBluePlus.turnOn();
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _scanning
                  ? 'Live packets (highlighted entries contain manufacturer ID 0x04D2 used by the admin app):'
                  : 'Press "Start Scan" to begin capturing advertisements.',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _packets.isEmpty
                  ? const Center(child: Text('No advertisements captured yet.'))
                  : ListView.builder(
                      itemCount: _packets.length,
                      itemBuilder: (context, index) {
                        final packet = _packets[index];
                        final matchesApp = packet.manufacturerData.containsKey(
                          1234,
                        );
                        return Card(
                          color: matchesApp
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.2)
                              : null,
                          child: ListTile(
                            title: Text(
                              '${packet.name} • RSSI ${packet.rssi} dBm',
                            ),
                            subtitle: Text(
                              [
                                'Device: ${packet.deviceId}',
                                'Seen: ${packet.timestamp.toLocal()}',
                                'Manufacturer:\n${_formatManufacturerData(packet.manufacturerData)}',
                              ].join('\n'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlePacket {
  _BlePacket({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.manufacturerData,
    required this.timestamp,
  });

  final String deviceId;
  final String name;
  final int rssi;
  final Map<int, List<int>> manufacturerData;
  final DateTime timestamp;
}
