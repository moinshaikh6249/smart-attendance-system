# Firebase Realtime Database Setup Instructions

## 📋 Files Provided

1. **`firebase_rtdb_structure.json`** - Complete database structure with sample data
2. **`firebase_security_rules.json`** - Security rules for all nodes

## 🚀 Setup Steps

### Step 1: Import Database Structure

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `rtccsattendancesystem`
3. Navigate to **Realtime Database** → **Data** tab
4. Click the **⋮** (three dots) menu → **Import JSON**
5. Select `firebase_rtdb_structure.json`
6. Click **Import**

⚠️ **Warning**: This will overwrite existing data. If you have production data, export it first!

### Step 2: Update Security Rules

1. In Firebase Console, go to **Realtime Database** → **Rules** tab
2. Click **Edit Rules**
3. Copy the entire content from `firebase_security_rules.json`
4. Paste it into the rules editor
5. Click **Publish**

### Step 3: Verify Structure

After importing, verify these nodes exist:

- ✅ `schools/`
- ✅ `classes/`
- ✅ `subjects/`
- ✅ `teachers/` (NEW)
- ✅ `students/`
- ✅ `attendance/`
- ✅ `attendance_logs/`
- ✅ `pending_attendance_requests/` (NEW)
- ✅ `student_attendance_requests/` (NEW)
- ✅ `pending_approvals/`
- ✅ `qr_sessions/`

## 🔐 Security Rules Explanation

### Teachers Node
- **Read**: Any authenticated user
- **Write**: Only the teacher themselves (by auth.uid)
- **Validation**: Ensures required fields and ID match

### Pending Attendance Requests
- **Read**: Only the teacher who owns the requests
- **Write**: Any authenticated user (students can create, teachers can approve/reject)
- **Validation**: Ensures required fields and teacherId matches path

### Student Attendance Requests
- **Read**: Any authenticated user (for history)
- **Write**: Any authenticated user
- **Validation**: Ensures studentUUID matches path

### Other Nodes
- **Schools/Classes/Subjects**: Public read, authenticated write
- **Students**: Readable by owner or authenticated users
- **Attendance**: Authenticated read/write
- **Attendance Logs**: Readable by student owner or authenticated users

## 📝 Important Notes

### Teacher UUIDs
- Teacher UUIDs in the sample data are **examples only**
- Real UUIDs will be auto-generated when teachers log in
- Format: UUID v4 (e.g., `550e8400-e29b-41d4-a716-446655440000`)

### Sample Teacher Accounts
The JSON includes sample teachers:
- `teacher_001`: teacher@rtccs.com
- `teacher_002`: teacher2@rtccs.com

**You need to:**
1. Create these users in Firebase Authentication
2. Update the `teachers` node with the actual Firebase Auth UIDs
3. Or let the app auto-create teacher records on first login

### Testing
1. Create a teacher account in Firebase Authentication
2. Log in to the admin app
3. The app will auto-create a teacher record with a BLE UUID
4. Use that UUID for testing BLE scanning

## 🔄 Migration from Old Structure

If you have existing data:

1. **Export current data**: Realtime Database → Data → ⋮ → Export JSON
2. **Backup the export**
3. **Import new structure**: Use `firebase_rtdb_structure.json`
4. **Manually migrate**:
   - Copy existing schools/classes/subjects/students
   - Create teacher records for existing admin users
   - Keep existing attendance records

## ✅ Verification Checklist

- [ ] Database structure imported successfully
- [ ] Security rules published
- [ ] All nodes visible in Firebase Console
- [ ] Teacher accounts created in Authentication
- [ ] Test teacher login creates teacher record
- [ ] Test BLE UUID generation
- [ ] Test pending request creation
- [ ] Test request approval flow

## 🆘 Troubleshooting

### "Permission denied" errors
- Check security rules are published
- Verify user is authenticated
- Check auth.uid matches teacherId in rules

### Teacher UUID not found
- Ensure teacher logged in at least once (creates record)
- Check `teachers/{auth.uid}` exists in database
- Verify `bleUuid` field is present

### Pending requests not showing
- Check `pending_attendance_requests/{teacherId}` path
- Verify teacherId matches auth.uid
- Check request status is "pending"

## 📞 Support

If you encounter issues:
1. Check Firebase Console → Realtime Database → Rules for syntax errors
2. Check Firebase Console → Authentication for user accounts
3. Review app logs for specific error messages
4. Verify all required fields are present in data structure

