# BLE Platform Exception - Troubleshooting Guide

## ✅ Fixes Applied

### 1. AndroidManifest.xml Updates

#### Admin App (`android/app/src/main/AndroidManifest.xml`)
- ✅ Added `BLUETOOTH_ADVERTISE` permission
- ✅ Added `usesPermissionFlags="neverForLocation"` for Android 12+
- ✅ All BLE permissions properly declared

#### Student App (`rtccs_student/android/app/src/main/AndroidManifest.xml`)
- ✅ Added all BLE permissions (was missing!)
- ✅ Added `BLUETOOTH_ADVERTISE` permission
- ✅ Added `usesPermissionFlags="neverForLocation"` for Android 12+
- ✅ Added hardware feature declarations

### 2. BLE Service Improvements

#### Admin App (`lib/services/ble_service.dart`)
- ✅ Enhanced error handling with detailed messages
- ✅ Automatic Bluetooth turn-on with timeout
- ✅ Better permission checking
- ✅ Specific error messages for different failure types

#### Student App (`rtccs_student/lib/services/ble_service.dart`)
- ✅ Enhanced error handling
- ✅ Automatic Bluetooth turn-on
- ✅ Better permission checking
- ✅ Improved logging for debugging

## 🔧 Additional Steps Required

### Step 1: Check Minimum SDK Version

Ensure your `android/app/build.gradle.kts` has:
```kotlin
minSdk = 21  // Minimum for BLE advertising
targetSdk = 34  // Latest recommended
```

BLE advertising requires **Android 5.0 (API 21)** minimum.

### Step 2: Request Permissions at Runtime

The apps now automatically request permissions, but if you still get errors:

1. **Go to Android Settings** → **Apps** → **RTCCS Admin** → **Permissions**
2. **Grant all Bluetooth permissions**:
   - Bluetooth
   - Bluetooth Advertise
   - Bluetooth Connect
   - Location (required for BLE on Android)

### Step 3: Enable Bluetooth Manually (if auto-enable fails)

If the app can't automatically turn on Bluetooth:
1. Go to **Android Settings** → **Bluetooth**
2. **Turn ON Bluetooth**
3. Try again in the app

### Step 4: Check Device Compatibility

Some devices have limitations:
- **Xiaomi/Redmi**: May need additional permissions in MIUI settings
- **Samsung**: May need to allow app in battery optimization
- **Huawei**: May need special permissions in EMUI settings

## 🐛 Common Platform Exceptions & Solutions

### Exception: "ADVERTISE_FAILED_TOO_MANY_ADVERTISERS"
**Solution**: Only one app can advertise at a time. Close other BLE apps.

### Exception: "ADVERTISE_FAILED_ALREADY_STARTED"
**Solution**: The app is already advertising. Stop it first, then restart.

### Exception: "Permission denied"
**Solution**: 
1. Go to Settings → Apps → Your App → Permissions
2. Grant all Bluetooth permissions
3. Restart the app

### Exception: "Bluetooth adapter is null"
**Solution**: 
1. Restart your device
2. Ensure Bluetooth hardware is working
3. Check if Bluetooth is enabled in system settings

### Exception: "BLE advertising not supported"
**Solution**: 
- Your device may not support BLE advertising
- Try on a different device
- Use QR code method as fallback

## 📱 Testing Checklist

- [ ] All permissions granted in Android Settings
- [ ] Bluetooth is ON
- [ ] No other BLE apps running
- [ ] Device supports BLE advertising (Android 5.0+)
- [ ] App has been restarted after permission changes
- [ ] Check logcat for detailed error messages

## 🔍 Debug Commands

### Check Logs
```bash
# Admin app
flutter run -d <device_id> --verbose

# Student app  
cd rtccs_student
flutter run -d <device_id> --verbose
```

### Check Permissions
```bash
adb shell dumpsys package com.rtccs.admin.rtccs_admin | grep permission
```

## 💡 Best Practices

1. **Always request permissions before BLE operations**
2. **Check Bluetooth state before starting**
3. **Handle errors gracefully with user-friendly messages**
4. **Provide fallback methods (QR code)**
5. **Test on multiple devices**

## ✅ All Fixes Applied!

The code now:
- ✅ Forces Bluetooth ON automatically
- ✅ Requests all required permissions
- ✅ Provides detailed error messages
- ✅ Handles platform exceptions gracefully

If you still get errors, check the logcat output for specific error codes!

