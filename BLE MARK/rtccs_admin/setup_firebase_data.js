// Firebase Setup Script for RTCCS Smart Attendance System
// Run this script to populate your Firebase Realtime Database with test data

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download your service account key from Firebase Console
// Go to Project Settings > Service Accounts > Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://rtccs-smart-attendance-default-rtdb.firebaseio.com' // Replace with your database URL
});

const db = admin.database();

async function setupFirebaseData() {
  try {
    console.log('Setting up Firebase data...');

    // 1. Schools
    await db.ref('schools').set({
      school_001: {
        id: 'school_001',
        name: 'RTCCS Main Campus'
      },
      school_002: {
        id: 'school_002',
        name: 'RTCCS North Campus'
      }
    });

    // 2. Classes
    await db.ref('classes').set({
      school_001: {
        class_001: {
          id: 'class_001',
          name: 'Class 10A',
          schoolId: 'school_001'
        },
        class_002: {
          id: 'class_002',
          name: 'Class 10B',
          schoolId: 'school_001'
        },
        class_003: {
          id: 'class_003',
          name: 'Class 11A',
          schoolId: 'school_001'
        }
      },
      school_002: {
        class_004: {
          id: 'class_004',
          name: 'Class 9A',
          schoolId: 'school_002'
        }
      }
    });

    // 3. Subjects
    await db.ref('subjects').set({
      school_001: {
        class_001: {
          subject_001: {
            id: 'subject_001',
            name: 'Mathematics',
            classId: 'class_001'
          },
          subject_002: {
            id: 'subject_002',
            name: 'Physics',
            classId: 'class_001'
          },
          subject_003: {
            id: 'subject_003',
            name: 'Chemistry',
            classId: 'class_001'
          }
        },
        class_002: {
          subject_004: {
            id: 'subject_004',
            name: 'English',
            classId: 'class_002'
          },
          subject_005: {
            id: 'subject_005',
            name: 'History',
            classId: 'class_002'
          }
        }
      },
      school_002: {
        class_004: {
          subject_006: {
            id: 'subject_006',
            name: 'Science',
            classId: 'class_004'
          }
        }
      }
    });

    // 4. Sample Students (for recovery testing)
    await db.ref('students').set({
      uuid_001: {
        uuid: 'uuid_001',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        schoolId: 'school_001',
        classId: 'class_001',
        subjectId: 'subject_001',
        registrationDate: '2024-01-15T10:30:00.000Z',
        profilePhotoUrl: null
      },
      uuid_002: {
        uuid: 'uuid_002',
        name: 'Jane Smith',
        phoneNumber: '+1234567891',
        schoolId: 'school_001',
        classId: 'class_001',
        subjectId: 'subject_002',
        registrationDate: '2024-01-15T11:00:00.000Z',
        profilePhotoUrl: null
      },
      uuid_003: {
        uuid: 'uuid_003',
        name: 'Mike Johnson',
        phoneNumber: '+1234567892',
        schoolId: 'school_001',
        classId: 'class_002',
        subjectId: 'subject_004',
        registrationDate: '2024-01-15T11:30:00.000Z',
        profilePhotoUrl: null
      }
    });

    // 5. Sample Attendance Records
    await db.ref('attendance').set({
      school_001: {
        class_001: {
          subject_001: {
            '2024-01-15': {
              uuid_001: {
                studentUUID: 'uuid_001',
                schoolID: 'school_001',
                classID: 'class_001',
                subjectID: 'subject_001',
                date: '2024-01-15',
                method: 'BLE',
                facePhotoUrl: null,
                timestamp: 1705312200000
              }
            }
          }
        }
      }
    });

    // 6. Sample Attendance Logs
    await db.ref('attendance_logs').set({
      uuid_001: {
        log_001: {
          studentUUID: 'uuid_001',
          schoolID: 'school_001',
          classID: 'class_001',
          subjectID: 'subject_001',
          date: '2024-01-15',
          method: 'BLE',
          facePhotoUrl: null,
          timestamp: 1705312200000
        }
      },
      uuid_002: {
        log_002: {
          studentUUID: 'uuid_002',
          schoolID: 'school_001',
          classID: 'class_001',
          subjectID: 'subject_002',
          date: '2024-01-15',
          method: 'QR',
          facePhotoUrl: 'https://example.com/photo1.jpg',
          timestamp: 1705315800000
        }
      }
    });

    // 7. Pending Approvals
    await db.ref('pending_approvals').set({
      uuid_004: {
        uuid: 'uuid_004',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        phoneNumber: '+1234567893',
        schoolId: 'school_001',
        classId: 'class_003',
        subjectId: 'subject_003',
        registrationDate: '2024-01-15T12:00:00.000Z',
        status: 'pending'
      }
    });

    console.log('✅ Firebase data setup completed successfully!');
    console.log('\n📋 Test Data Summary:');
    console.log('Schools: 2');
    console.log('Classes: 4');
    console.log('Subjects: 6');
    console.log('Students: 3 (for recovery testing)');
    console.log('Attendance Records: 2');
    console.log('Pending Approvals: 1');
    
    console.log('\n🧪 Test Recovery Data:');
    console.log('Name: Jane Smith, Phone: +1234567891, UUID: uuid_002');
    console.log('Name: Mike Johnson, Phone: +1234567892, UUID: uuid_003');

  } catch (error) {
    console.error('❌ Error setting up Firebase data:', error);
  } finally {
    process.exit(0);
  }
}

// Run the setup
setupFirebaseData(); 