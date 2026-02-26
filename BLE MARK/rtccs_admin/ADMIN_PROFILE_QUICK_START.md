# Admin Profile Feature - Quick Start Guide

## 🚀 Getting Started

The Admin Profile feature is now fully integrated into your BLE Mark Admin app. Here's how to use it:

---

## 📱 Access Admin Profile

### Method 1: From Dashboard
1. Open the app and login as admin
2. Look at the top-right corner of the dashboard
3. Click the **circular admin avatar icon**
4. Profile screen opens

### Method 2: Direct Navigation (if implementing menu)
```dart
Navigator.pushNamed(context, '/admin_profile');
```

---

## 👤 Profile Features

### 1. View Your Profile
When you open the profile screen, you'll see:
- **Profile Photo** (or initials if no photo uploaded)
- **Full Name**
- **Role** (Super Admin / Admin)
- **Email ID**
- **Mobile Number** (or "Not provided")
- **Institute/College Name** (or "Not provided")
- **Last Login Time** (e.g., "2 hours ago")

### 2. Edit Your Profile
1. Click the **Edit icon** (✏️) in the top-right
2. Update:
   - Full Name (required, min 3 characters)
   - Mobile Number (optional, 10-15 digits)
   - Profile Photo (tap camera icon, max 5 MB)
3. Click **Save Changes**
4. Success message appears: "Profile updated successfully"

### 3. Change Password
1. Scroll to "Security & Activity" section
2. Click **Change Password**
3. Enter:
   - Current Password
   - New Password (min 8 chars, 1 letter, 1 number)
   - Confirm New Password
4. Click **Update Password**
5. Success message: "Password changed successfully"

### 4. View Login Activity
1. Scroll to "Security & Activity" section
2. Click **View Login Activity**
3. See your recent login history:
   - When you logged in
   - Device used
   - IP address (if available)

---

## 🔧 For Developers

### Initialize Profile on First Login
The profile is automatically created when an admin logs in for the first time. The system:
1. Checks if admin profile exists in Firebase
2. If not, creates a basic profile from Firebase Auth data
3. Saves to `admins/{userId}` in Realtime Database

### Firebase Structure Created
```
admins/
  {userId}/
    id: "user123"
    email: "admin@example.com"
    fullName: "John Doe"
    role: "Admin"
    lastLoginTime: 1701234567890
    createdAt: 1701234567890

admin_login_logs/
  {userId}/
    {logId}/
      timestamp: 1701234567890
      deviceInfo: "Unknown Device"
      ipAddress: "Unknown"
```

### Manual Profile Creation (Optional)
If you want to pre-create admin profiles:

```json
{
  "admins": {
    "YOUR_FIREBASE_USER_UID": {
      "id": "YOUR_FIREBASE_USER_UID",
      "email": "admin@example.com",
      "fullName": "Admin Name",
      "mobileNumber": "1234567890",
      "role": "Super Admin",
      "instituteName": "Your College Name",
      "profilePhotoUrl": null,
      "lastLoginTime": null,
      "createdAt": 1701234567890,
      "updatedAt": 1701234567890
    }
  }
}
```

---

## 🎯 Testing Steps

### Step 1: Test Profile View
```bash
flutter run
```
1. Login as admin
2. Click admin avatar on dashboard
3. Verify all fields display correctly

### Step 2: Test Edit Profile
1. Click edit icon
2. Change name to "Test Admin"
3. Add mobile: "9876543210"
4. Click Save Changes
5. Verify success message
6. Reload app and check changes persist

### Step 3: Test Profile Photo
1. Click edit icon
2. Click camera icon on avatar
3. Select an image from gallery
4. Verify preview shows
5. Click Save Changes
6. Verify photo appears on profile

### Step 4: Test Password Change
1. Click "Change Password"
2. Enter current password
3. Enter new password: "NewPass123"
4. Confirm new password: "NewPass123"
5. Click Update Password
6. Verify success message
7. Logout and login with new password

### Step 5: Test Login Activity
1. Click "View Login Activity"
2. Verify login logs appear
3. Check timestamp formatting
4. Verify back button works

---

## ⚠️ Important Notes

### Email & Role Are Read-Only
- Email ID cannot be changed from the profile screen
- Role (Super Admin/Admin) cannot be changed from the profile screen
- To change these, update Firebase directly or create admin management feature

### Profile Photo Storage
- Photos stored in: `admin_profiles/{userId}/profile.jpg`
- Max size: 5 MB
- Formats: JPG, PNG
- Automatically compressed to 800x800px

### Password Requirements
- Minimum 8 characters
- At least 1 letter (A-Z, a-z)
- At least 1 number (0-9)
- Special characters optional but recommended

### Validation Messages
| Error | Message |
|-------|---------|
| Name too short | "Name must be at least 3 characters" |
| Invalid mobile | "Invalid mobile number format" |
| Large photo | "Image size must be less than 5 MB" |
| Wrong password | "Current password is incorrect" |
| Weak password | "Password must be at least 8 characters with at least one letter and one number" |
| Password mismatch | "Passwords do not match" |

---

## 🛠️ Troubleshooting

### Issue: Profile not loading
**Solution:**
1. Check internet connection
2. Verify Firebase is initialized
3. Check Firebase Auth user is logged in
4. Check Firebase Realtime Database rules allow read access

### Issue: Photo upload fails
**Solution:**
1. Verify photo is < 5 MB
2. Check Firebase Storage rules allow write access
3. Ensure stable internet connection

### Issue: Password change fails
**Solution:**
1. Verify current password is correct
2. Check new password meets requirements
3. Ensure Firebase Auth is configured properly

### Issue: Login activity empty
**Solution:**
- Login logs are created automatically on each login
- If empty, it means no logs exist yet
- They will appear after next login

---

## 📊 Firebase Security Rules

### Realtime Database Rules
```json
{
  "rules": {
    "admins": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "admin_login_logs": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### Storage Rules
```
service firebase.storage {
  match /b/{bucket}/o {
    match /admin_profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ✅ Feature Checklist

- [x] Profile data loading from Firebase
- [x] Edit full name
- [x] Edit mobile number (optional)
- [x] Upload/change profile photo
- [x] Change password with validation
- [x] View login activity history
- [x] Initials avatar fallback
- [x] "Not provided" for missing fields
- [x] Success/error messages
- [x] Form validation
- [x] Navigation from dashboard
- [x] Responsive design
- [x] Dark theme support

---

## 🎨 UI Customization

### Colors Used
- Header Gradient: `kGradientTop` → `kGradientBottom`
- Card Background: `kCardBackground` (#242B3A)
- Primary Blue: `kPrimaryBlue` (#0A3D91)
- Text: White with opacity variations

### Fonts
- Profile Name: 24sp, Bold
- Section Titles: 18sp, Bold
- Card Labels: 12sp, Regular
- Card Values: 16sp, Medium

### Spacing
- All spacing follows 8dp grid system
- Card padding: 16dp
- Section spacing: 16dp
- Button padding: 14dp vertical

---

## 🚀 Next Steps

1. **Run the app**: `flutter run`
2. **Login as admin**
3. **Click admin avatar** on dashboard
4. **Explore all profile features**
5. **Test editing and password change**

---

## 📞 Support

If you encounter any issues:
1. Check error console for detailed messages
2. Verify Firebase configuration
3. Review documentation at `ADMIN_PROFILE_DOCUMENTATION.md`
4. Check that all dependencies are installed

---

**Status: Ready to Use** ✅

All features are fully functional and tested. No existing attendance features were modified or broken.
