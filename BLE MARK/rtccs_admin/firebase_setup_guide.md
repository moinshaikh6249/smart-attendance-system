# Firebase Setup Guide for RTCCS Smart Attendance System

## 1. Firebase Project Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Name: `rtccs-smart-attendance`
4. Enable Google Analytics (optional)
5. Create project

### Add Apps to Firebase Project

#### Admin App
1. Click "Add app" → Android
2. Package name: `com.rtccs.admin.rtccs_admin`
3. App nickname: `RTCCS Admin`
4. Download `google-services.json` and place in `android/app/`

#### Student App
1. Click "Add app" → Android
2. Package name: `com.rtccs.admin.rtccs_student`
3. App nickname: `RTCCS Student`
4. Download `google-services.json` and place in `rtccs_student/android/app/`

## 2. Firebase Realtime Database Structure

```json
{
  "schools": {
    "school_001": {
      "id": "school_001",
      "name": "RTCCS Main Campus"
    },
    "school_002": {
      "id": "school_002", 
      "name": "RTCCS North Campus"
    }
  },
  
  "classes": {
    "school_001": {
      "class_001": {
        "id": "class_001",
        "name": "Class 10A",
        "schoolId": "school_001"
      },
      "class_002": {
        "id": "class_002", 
        "name": "Class 10B",
        "schoolId": "school_001"
      },
      "class_003": {
        "id": "class_003",
        "name": "Class 11A", 
        "schoolId": "school_001"
      }
    },
    "school_002": {
      "class_004": {
        "id": "class_004",
        "name": "Class 9A",
        "schoolId": "school_002"
      }
    }
  },
  
  "subjects": {
    "school_001": {
      "class_001": {
        "subject_001": {
          "id": "subject_001",
          "name": "Mathematics",
          "classId": "class_001"
        },
        "subject_002": {
          "id": "subject_002", 
          "name": "Physics",
          "classId": "class_001"
        },
        "subject_003": {
          "id": "subject_003",
          "name": "Chemistry", 
          "classId": "class_001"
        }
      },
      "class_002": {
        "subject_004": {
          "id": "subject_004",
          "name": "English",
          "classId": "class_002"
        },
        "subject_005": {
          "id": "subject_005",
          "name": "History",
          "classId": "class_002"
        }
      }
    },
    "school_002": {
      "class_004": {
        "subject_006": {
          "id": "subject_006",
          "name": "Science",
          "classId": "class_004"
        }
      }
    }
  },
  
  "students": {
    "uuid_001": {
      "uuid": "uuid_001",
      "name": "John Doe",
      "phoneNumber": "+1234567890",
      "schoolId": "school_001",
      "classId": "class_001", 
      "subjectId": "subject_001",
      "registrationDate": "2024-01-15T10:30:00.000Z",
      "profilePhotoUrl": null
    },
    "uuid_002": {
      "uuid": "uuid_002",
      "name": "Jane Smith",
      "phoneNumber": "+1234567891", 
      "schoolId": "school_001",
      "classId": "class_001",
      "subjectId": "subject_002",
      "registrationDate": "2024-01-15T11:00:00.000Z",
      "profilePhotoUrl": null
    },
    "uuid_003": {
      "uuid": "uuid_003",
      "name": "Mike Johnson",
      "phoneNumber": "+1234567892",
      "schoolId": "school_001", 
      "classId": "class_002",
      "subjectId": "subject_004",
      "registrationDate": "2024-01-15T11:30:00.000Z",
      "profilePhotoUrl": null
    },
    "school_001": {
      "class_001": {
        "subject_001": {
          "uuid_001": {
            "uuid": "uuid_001",
            "name": "John Doe",
            "phoneNumber": "+1234567890",
            "schoolId": "school_001",
            "classId": "class_001",
            "subjectId": "subject_001",
            "registrationDate": "2024-01-15T10:30:00.000Z"
          }
        },
        "subject_002": {
          "uuid_002": {
            "uuid": "uuid_002", 
            "name": "Jane Smith",
            "phoneNumber": "+1234567891",
            "schoolId": "school_001",
            "classId": "class_001",
            "subjectId": "subject_002", 
            "registrationDate": "2024-01-15T11:00:00.000Z"
          }
        }
      },
      "class_002": {
        "subject_004": {
          "uuid_003": {
            "uuid": "uuid_003",
            "name": "Mike Johnson", 
            "phoneNumber": "+1234567892",
            "schoolId": "school_001",
            "classId": "class_002",
            "subjectId": "subject_004",
            "registrationDate": "2024-01-15T11:30:00.000Z"
          }
        }
      }
    }
  },
  
  "attendance": {
    "school_001": {
      "class_001": {
        "subject_001": {
          "2024-01-15": {
            "uuid_001": {
              "studentUUID": "uuid_001",
              "schoolID": "school_001",
              "classID": "class_001", 
              "subjectID": "subject_001",
              "date": "2024-01-15",
              "method": "BLE",
              "facePhotoUrl": null,
              "timestamp": 1705312200000
            }
          }
        },
        "subject_002": {
          "2024-01-15": {
            "uuid_002": {
              "studentUUID": "uuid_002",
              "schoolID": "school_001",
              "classID": "class_001",
              "subjectID": "subject_002", 
              "date": "2024-01-15",
              "method": "QR",
              "facePhotoUrl": "https://example.com/photo1.jpg",
              "timestamp": 1705315800000
            }
          }
        }
      }
    }
  },
  
  "attendance_logs": {
    "uuid_001": {
      "log_001": {
        "studentUUID": "uuid_001",
        "schoolID": "school_001",
        "classID": "class_001",
        "subjectID": "subject_001",
        "date": "2024-01-15",
        "method": "BLE",
        "facePhotoUrl": null,
        "timestamp": 1705312200000
      },
      "log_002": {
        "studentUUID": "uuid_001",
        "schoolID": "school_001", 
        "classID": "class_001",
        "subjectID": "subject_002",
        "date": "2024-01-16",
        "method": "QR",
        "facePhotoUrl": "https://example.com/photo2.jpg",
        "timestamp": 1705398600000
      }
    },
    "uuid_002": {
      "log_003": {
        "studentUUID": "uuid_002",
        "schoolID": "school_001",
        "classID": "class_001", 
        "subjectID": "subject_002",
        "date": "2024-01-15",
        "method": "QR",
        "facePhotoUrl": "https://example.com/photo3.jpg",
        "timestamp": 1705315800000
      }
    }
  },
  
  "pending_approvals": {
    "uuid_004": {
      "uuid": "uuid_004",
      "name": "Sarah Wilson",
      "email": "sarah.wilson@example.com",
      "phoneNumber": "+1234567893",
      "schoolId": "school_001",
      "classId": "class_003",
      "subjectId": "subject_003",
      "registrationDate": "2024-01-15T12:00:00.000Z",
      "status": "pending"
    }
  }
}
```

## 3. Firebase Security Rules

```json
{
  "rules": {
    "schools": {
      ".read": true,
      ".write": "auth != null"
    },
    "classes": {
      ".read": true,
      ".write": "auth != null"
    },
    "subjects": {
      ".read": true,
      ".write": "auth != null"
    },
    "students": {
      "$uuid": {
        ".read": "auth != null || data.child('uuid').val() == $uuid",
        ".write": "auth != null"
      }
    },
    "attendance": {
      "$schoolId": {
        "$classId": {
          "$subjectId": {
            "$date": {
              ".read": "auth != null",
              ".write": "auth != null"
            }
          }
        }
      }
    },
    "attendance_logs": {
      "$uuid": {
        ".read": "auth != null || $uuid == auth.uid",
        ".write": "auth != null"
      }
    },
    "pending_approvals": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

## 4. Test Data for Registration/Recovery

### Test Student 1 (for Registration)
- **Name**: John Doe
- **Phone**: +1234567890
- **School**: RTCCS Main Campus
- **Class**: Class 10A
- **Subject**: Mathematics

### Test Student 2 (for Recovery)
- **Name**: Jane Smith  
- **Phone**: +1234567891
- **School**: RTCCS Main Campus
- **Class**: Class 10A
- **Subject**: Physics
- **UUID**: uuid_002

### Test Student 3 (for Recovery)
- **Name**: Mike Johnson
- **Phone**: +1234567892
- **School**: RTCCS Main Campus
- **Class**: Class 10B
- **Subject**: English
- **UUID**: uuid_003

## 5. Firebase Authentication Setup

### Enable Email/Password Authentication
1. Go to Authentication → Sign-in method
2. Enable Email/Password
3. Add test users:

#### Admin Users
- **Email**: admin@rtccs.com
- **Password**: admin123

- **Email**: teacher@rtccs.com  
- **Password**: teacher123

#### Student Users (optional for testing)
- **Email**: john.doe@student.com
- **Password**: student123

## 6. Firebase Storage Setup

### Create Storage Bucket
1. Go to Storage → Get started
2. Choose production mode
3. Select location (us-central1 recommended)
4. Create bucket

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{uuid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 5 * 1024 * 1024;
    }
    match /face_photos/{uuid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

## 7. Testing Checklist

### Admin App Testing
- [ ] Login with admin credentials
- [ ] View dashboard with attendance statistics
- [ ] Select school, class, subject dropdowns
- [ ] Test BLE scanning (simulated)
- [ ] Test QR scanning
- [ ] View attendance records
- [ ] Export attendance data
- [ ] Approve pending students

### Student App Testing
- [ ] Welcome screen navigation
- [ ] New student registration
  - [ ] Fill all dropdowns and fields
  - [ ] Verify UUID generation
  - [ ] Check Firebase storage
  - [ ] Verify local storage
- [ ] Returning student recovery
  - [ ] Use test data (Jane Smith)
  - [ ] Verify UUID recovery
  - [ ] Check local storage update
- [ ] Dashboard functionality
  - [ ] Display student info
  - [ ] Mark attendance (BLE/QR)
  - [ ] View attendance history
  - [ ] Logout functionality

## 8. Common Issues & Solutions

### Issue: "No matching client found for package name"
**Solution**: Ensure `google-services.json` is in correct location and contains the right package name

### Issue: "Permission denied" in Firebase
**Solution**: Check security rules and authentication status

### Issue: "Network error" when accessing Firebase
**Solution**: Verify internet connection and Firebase project configuration

### Issue: "Invalid UUID" during registration
**Solution**: Check UUID generation and Firebase write permissions

## 9. Firebase Console URLs

- **Project Overview**: https://console.firebase.google.com/project/rtccs-smart-attendance
- **Realtime Database**: https://console.firebase.google.com/project/rtccs-smart-attendance/database
- **Authentication**: https://console.firebase.google.com/project/rtccs-smart-attendance/authentication
- **Storage**: https://console.firebase.google.com/project/rtccs-smart-attendance/storage

## 10. Sample Test Commands

```bash
# Test Admin App
cd rtccs_admin
flutter run

# Test Student App  
cd rtccs_student
flutter run

# Check Firebase connection
flutter doctor
flutter pub get
flutter analyze
```

This setup provides a complete testing environment for both apps with realistic data and proper Firebase configuration! 