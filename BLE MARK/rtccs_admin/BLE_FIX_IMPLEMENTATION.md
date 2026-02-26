# BLE Broadcasting & Scanning Fix - Implementation Guide

## Changes Made

### 1. Admin App (BLE Broadcasting)
**File: `lib/services/ble_service.dart`**

#### Key Improvements:
- ✅ **Added Service UUID Broadcasting**: Now broadcasts a proper BLE service UUID that nRF Connect can detect
- ✅ **Dual-Method Broadcasting**: Uses both Service UUID AND Manufacturer Data for maximum compatibility
- ✅ **Enhanced Permissions**: Added BLUETOOTH_SCAN to permission requests
- ✅ **Better Error Handling**: More detailed logging and error messages
- ✅ **Standard Manufacturer ID**: Changed from 1234 to 0xFFFF (65535) - industry standard for testing

#### Broadcasting Method:
```dart
AdvertiseData(
  serviceUuid: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  // Your UUID
  manufacturerId: 0xFFFF,                                 // Standard test ID
  manufacturerData: <16-byte UUID>,                       // Fallback method
  includeDeviceName: false                                // Keep packet small
)
```

### 2. Student App (BLE Scanning)
**File: `rtccs_student/lib/services/ble_service.dart`**

#### Key Improvements:
- ✅ **Multi-Method Detection**: Scans for BOTH Service UUID and Manufacturer Data
- ✅ **Backward Compatibility**: Supports both old (ID: 1234) and new (ID: 0xFFFF) manufacturer data
- ✅ **Enhanced Logging**: Detailed console output showing what's being detected
- ✅ **Better Filtering**: Properly normalizes and compares UUIDs

#### Scanning Process:
1. Check for Service UUID match (primary method)
2. Check Manufacturer Data with ID 0xFFFF (new format)
3. Check Manufacturer Data with ID 1234 (old format - backward compatible)

### 3. Android Manifest Updates
**Files: `android/app/src/main/AndroidManifest.xml` (both apps)**

#### Changes:
- ✅ Removed `android:usesPermissionFlags="neverForLocation"` from BLUETOOTH_SCAN
- ✅ Added `android:maxSdkVersion="30"` to legacy permissions (BLUETOOTH, BLUETOOTH_ADMIN)
- ✅ This fixes permission issues on Android 12+ devices

### 4. Package Updates
**Files: `pubspec.yaml` (both apps)**

#### Updated Packages:
- `flutter_blue_plus`: ^1.31.15 → ^1.32.12 (latest stable)
- `flutter_ble_peripheral`: ^1.2.6 → ^2.0.2 (major update with bug fixes)

## Testing Instructions

### Step 1: Clean and Rebuild Both Apps

```bash
# Admin App
cd c:\Users\ADMIN\StudioProjects\rtccs_admin
flutter clean
flutter pub get
flutter build apk --debug

# Student App
cd c:\Users\ADMIN\StudioProjects\rtccs_admin\rtccs_student
flutter clean
flutter pub get
flutter build apk --debug
```

### Step 2: Install and Grant Permissions

1. **Uninstall old versions** of both apps from your test devices
2. **Install the new builds**
3. **Grant ALL permissions** when prompted:
   - Bluetooth
   - Bluetooth Scan
   - Bluetooth Advertise
   - Bluetooth Connect
   - Location (Fine & Coarse)

### Step 3: Test Admin App Broadcasting

1. Open the **Admin App**
2. Navigate to the attendance session screen
3. Start broadcasting
4. **Check the console logs** (Run from VS Code or Android Studio to see logs)
5. You should see:
   ```
   [BLEService] Starting BLE advertising...
   [BLEService] UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   [BLEService] Service UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   [BLEService] Manufacturer ID: 0xFFFF (65535)
   [BLEService] ✓ Successfully started broadcasting!
   ```

### Step 4: Verify with nRF Connect App

1. **Install nRF Connect** on a separate device
2. **Open Scanner** tab
3. **Look for your broadcast**:
   - You should see a device with **Complete List of 128-bit Service UUIDs**
   - The UUID should match your admin's UUID
   - You may also see **Manufacturer Data** with Company ID `0xFFFF`
   - RSSI signal strength should be visible

**Screenshot Example in nRF Connect:**
```
Device Name: (Unknown)
├─ Complete List of 128-bit Service UUIDs
│  └─ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
├─ Manufacturer Specific Data
│  └─ Company: 0xFFFF (Unknown)
│  └─ Data: [16 bytes]
└─ RSSI: -45 dBm
```

### Step 5: Test Student App Scanning

1. **Keep admin app broadcasting**
2. Open **Student App** on another device
3. Navigate to attendance marking screen
4. Start scanning
5. **Check the console logs**:
   ```
   [BLEService] Starting continuous scan for 1 teacher UUID(s)...
   [BLEService] Teacher UUIDs to scan for:
   [BLEService]   - xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   [BLEService] ✓ BLE scan started successfully
   [BLEService] ✓ Found teacher via Service UUID: xxxxxxxx-xxxx-...
   [BLEService] ✓ Teacher detected! UUID: xxxxxxxx-xxxx-..., RSSI: -45 dBm
   ```

## Troubleshooting

### Problem: Admin app not broadcasting

**Check:**
1. All permissions granted? Go to Settings → Apps → RTCCS Admin → Permissions
2. Bluetooth enabled?
3. Check logs for errors
4. Try restarting Bluetooth on the device
5. Some devices don't support BLE advertising - use QR code fallback

**Error Messages:**
- `"Error code: 18"` → Device doesn't support BLE advertising
- `"PERMISSION denied"` → Grant all permissions in Settings
- `"Bluetooth is not enabled"` → Turn on Bluetooth

### Problem: Student app not detecting admin

**Check:**
1. Is admin actually broadcasting? Check with nRF Connect first
2. Are the UUIDs matching? Check Firebase database
3. Student app has all permissions?
4. Both devices have Bluetooth enabled?
5. Devices are within range (usually 10-30 meters for BLE)

**Debug Steps:**
1. Open both app consoles side by side
2. Admin should log: `✓ Successfully started broadcasting!`
3. Student should log: `✓ BLE scan started successfully`
4. Student should then detect and log: `✓ Teacher detected!`

### Problem: nRF Connect can't find the broadcast

**Possible Causes:**
1. **Device limitation**: Some devices (especially older ones) can't do BLE advertising
2. **Background restrictions**: Make sure the admin app is in foreground
3. **Battery saver**: Disable battery optimization for the admin app
4. **Bluetooth interference**: Try in a different location

**Solutions:**
1. Use a different device for admin app
2. Keep admin app in foreground while broadcasting
3. Settings → Apps → RTCCS Admin → Battery → Unrestricted
4. Move away from WiFi routers and other BLE devices

### Problem: Works with nRF Connect but student app can't detect

**Check:**
1. Student app has teacher UUID in Firebase? (`/sessions/{sessionId}/teacherUUID`)
2. UUID format matches exactly (including dashes)
3. Student app called `setTeacherUuids()` before scanning
4. Check student app logs for "Teacher UUIDs to scan for"

**Debug:**
```dart
// In student app, verify UUIDs are loaded:
print('Known UUIDs: $_knownTeacherUuids');
```

## Key Technical Details

### BLE Advertisement Packet Structure

**Service UUID Method (Primary):**
- Type: Complete List of 128-bit Service UUIDs
- Length: 16 bytes
- Format: Standard UUID format
- Advantage: Scannable by standard BLE scanners

**Manufacturer Data Method (Fallback):**
- Company ID: 0xFFFF (65535)
- Data: 16 bytes (raw UUID)
- Format: Big-endian byte array
- Advantage: Backward compatible

### UUID Format
- Standard: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- Total length: 36 characters (32 hex + 4 dashes)
- Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`

### Scanning Strategy
Student app uses **continuous scanning** (no timeout) and checks each advertisement for:
1. Matching Service UUID
2. Matching Manufacturer Data (0xFFFF)
3. Matching Manufacturer Data (1234) - legacy support

### Permission Requirements (Android 12+)

| Permission | Purpose | Required |
|------------|---------|----------|
| BLUETOOTH | Legacy BLE access | Yes (≤ API 30) |
| BLUETOOTH_ADMIN | Legacy admin | Yes (≤ API 30) |
| BLUETOOTH_SCAN | Scan for devices | Yes |
| BLUETOOTH_ADVERTISE | Broadcast BLE | Yes (Admin) |
| BLUETOOTH_CONNECT | Connect to devices | Yes |
| ACCESS_FINE_LOCATION | BLE scanning | Yes |
| ACCESS_COARSE_LOCATION | BLE scanning | Yes |

## Expected Behavior

### Admin App:
1. Starts broadcasting immediately when session begins
2. Broadcast continues in foreground (background has limitations)
3. UUID is visible in nRF Connect and student apps
4. Can be detected from 10-30 meters away (varies by device)

### Student App:
1. Starts scanning when attendance screen opens
2. Detects admin within 1-5 seconds (usually)
3. Shows RSSI signal strength
4. Auto-marks attendance when in range
5. Stops scanning when screen is closed

## Performance Notes

- **Broadcasting interval**: ~100ms (10 times per second)
- **Scanning interval**: Continuous (updates in real-time)
- **Detection time**: 1-5 seconds typical
- **Range**: 10-30 meters (varies by device and environment)
- **Battery impact**: Moderate (BLE is low energy but continuous use drains battery)

## Testing Checklist

- [ ] Admin app broadcasts successfully
- [ ] nRF Connect detects the broadcast
- [ ] nRF Connect shows correct UUID
- [ ] Student app starts scanning
- [ ] Student app detects admin
- [ ] Student app shows correct RSSI
- [ ] Attendance is marked automatically
- [ ] Works at various distances (5m, 10m, 15m)
- [ ] Works with multiple students simultaneously
- [ ] Graceful error handling when Bluetooth is off

## Next Steps

1. **Test on multiple devices** - BLE behavior varies by manufacturer
2. **Test in real classroom** - Check range and reliability
3. **Monitor battery usage** - Adjust scanning intervals if needed
4. **Implement fallback to QR codes** - For devices that don't support BLE advertising

## Support

If you still encounter issues:
1. Check the console logs for both apps
2. Test with nRF Connect to isolate the problem
3. Verify all permissions are granted
4. Try different test devices
5. Check Firebase UUID configuration

The implementation now uses **industry-standard BLE advertising** that should work with nRF Connect and properly detect between admin and student apps.
