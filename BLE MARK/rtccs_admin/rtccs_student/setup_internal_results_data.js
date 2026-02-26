const admin = require('firebase-admin');
const serviceAccount = require('./rtccsattendancesystem-firebase-adminsdk-fbsvc-af29a472c4.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://rtccsattendancesystem-default-rtdb.firebaseio.com'
});

const db = admin.database();

async function setupInternalMarksAndResults() {
  const schoolId = 'SCHOOL001';
  const studentUUID = 'STU-2024-001'; // Replace with actual student UUID

  console.log('📚 Setting up Internal Marks and Results data...\n');

  // ========================================
  // INTERNAL MARKS DATA
  // ========================================
  console.log('Adding Internal Marks data...');
  const internalMarksRef = db.ref(`schools/${schoolId}/students/${studentUUID}/internalMarks`);
  
  await internalMarksRef.set({
    // Mathematics - Multiple components
    MARK001: {
      subjectName: 'Mathematics',
      subjectCode: 'MATH101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 22,
      weightage: 20,
      examDate: '2024-01-15'
    },
    MARK002: {
      subjectName: 'Mathematics',
      subjectCode: 'MATH101',
      examComponent: 'IA2',
      maxMarks: 25,
      marksObtained: 23,
      weightage: 20,
      examDate: '2024-02-20'
    },
    MARK003: {
      subjectName: 'Mathematics',
      subjectCode: 'MATH101',
      examComponent: 'Assignment',
      maxMarks: 10,
      marksObtained: 9,
      weightage: 10,
      examDate: '2024-03-05'
    },

    // Physics - Multiple components
    MARK004: {
      subjectName: 'Physics',
      subjectCode: 'PHY101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 20,
      weightage: 20,
      examDate: '2024-01-18'
    },
    MARK005: {
      subjectName: 'Physics',
      subjectCode: 'PHY101',
      examComponent: 'IA2',
      maxMarks: 25,
      marksObtained: 22,
      weightage: 20,
      examDate: '2024-02-22'
    },
    MARK006: {
      subjectName: 'Physics',
      subjectCode: 'PHY101',
      examComponent: 'Practical',
      maxMarks: 50,
      marksObtained: 45,
      weightage: 30,
      examDate: '2024-03-10'
    },

    // Chemistry
    MARK007: {
      subjectName: 'Chemistry',
      subjectCode: 'CHEM101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 19,
      weightage: 20,
      examDate: '2024-01-20'
    },
    MARK008: {
      subjectName: 'Chemistry',
      subjectCode: 'CHEM101',
      examComponent: 'IA2',
      maxMarks: 25,
      marksObtained: 21,
      weightage: 20,
      examDate: '2024-02-25'
    },
    MARK009: {
      subjectName: 'Chemistry',
      subjectCode: 'CHEM101',
      examComponent: 'Practical',
      maxMarks: 50,
      marksObtained: 42,
      weightage: 30,
      examDate: '2024-03-12'
    },

    // Computer Science
    MARK010: {
      subjectName: 'Computer Science',
      subjectCode: 'CS101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 24,
      weightage: 20,
      examDate: '2024-01-22'
    },
    MARK011: {
      subjectName: 'Computer Science',
      subjectCode: 'CS101',
      examComponent: 'IA2',
      maxMarks: 25,
      marksObtained: 25,
      weightage: 20,
      examDate: '2024-02-28'
    },
    MARK012: {
      subjectName: 'Computer Science',
      subjectCode: 'CS101',
      examComponent: 'Assignment',
      maxMarks: 20,
      marksObtained: 19,
      weightage: 15,
      examDate: '2024-03-08'
    },
    MARK013: {
      subjectName: 'Computer Science',
      subjectCode: 'CS101',
      examComponent: 'Practical',
      maxMarks: 50,
      marksObtained: 48,
      weightage: 25,
      examDate: '2024-03-15'
    }
  });

  console.log('✅ Internal Marks added!\n');

  // ========================================
  // RESULTS DATA
  // ========================================
  console.log('Adding Results data...');
  const resultsRef = db.ref(`schools/${schoolId}/students/${studentUUID}/results`);
  
  await resultsRef.set({
    // Semester 1 Results
    RESULT001: {
      examName: '1st Semester Final Exam',
      semesterCode: 'SEM1',
      academicYear: '2023-24',
      sgpa: 8.5,
      cgpa: 8.5,
      totalCreditsEarned: 24,
      isPublished: true,
      subjects: [
        {
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          grade: 'A+',
          gradePoints: 9.0,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Physics',
          subjectCode: 'PHY101',
          grade: 'A',
          gradePoints: 8.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Chemistry',
          subjectCode: 'CHEM101',
          grade: 'B+',
          gradePoints: 7.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Computer Science',
          subjectCode: 'CS101',
          grade: 'A+',
          gradePoints: 9.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'English',
          subjectCode: 'ENG101',
          grade: 'A',
          gradePoints: 8.0,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Engineering Graphics',
          subjectCode: 'EG101',
          grade: 'B',
          gradePoints: 7.0,
          credits: 4,
          resultStatus: 'Pass'
        }
      ]
    },

    // Semester 2 Results
    RESULT002: {
      examName: '2nd Semester Final Exam',
      semesterCode: 'SEM2',
      academicYear: '2023-24',
      sgpa: 8.2,
      cgpa: 8.35,
      totalCreditsEarned: 48,
      isPublished: true,
      subjects: [
        {
          subjectName: 'Advanced Mathematics',
          subjectCode: 'MATH201',
          grade: 'A',
          gradePoints: 8.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Electronics',
          subjectCode: 'ELEC201',
          grade: 'A-',
          gradePoints: 8.0,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Data Structures',
          subjectCode: 'CS201',
          grade: 'A+',
          gradePoints: 9.0,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Digital Logic',
          subjectCode: 'DL201',
          grade: 'B+',
          gradePoints: 7.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Environmental Science',
          subjectCode: 'ENV201',
          grade: 'A',
          gradePoints: 8.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Workshop Practice',
          subjectCode: 'WP201',
          grade: 'B',
          gradePoints: 7.0,
          credits: 4,
          resultStatus: 'Pass'
        }
      ]
    },

    // Semester 3 Results (Not Published)
    RESULT003: {
      examName: '3rd Semester Final Exam',
      semesterCode: 'SEM3',
      academicYear: '2024-25',
      sgpa: null,
      cgpa: null,
      totalCreditsEarned: null,
      isPublished: false, // Not yet published
      subjects: []
    }
  });

  console.log('✅ Results added!\n');

  // ========================================
  // ENABLE FEATURE FLAGS
  // ========================================
  console.log('Enabling feature flags...');
  
  const featureFlagsRef = db.ref(`featureFlags/modules/${schoolId}`);
  await featureFlagsRef.update({
    internalMark: true,
    result: true
  });

  console.log('✅ Feature flags enabled!\n');

  // ========================================
  // SUMMARY
  // ========================================
  console.log('========================================');
  console.log('✨ Setup Complete! ✨');
  console.log('========================================');
  console.log(`School ID: ${schoolId}`);
  console.log(`Student UUID: ${studentUUID}`);
  console.log('\n📊 Data Added:');
  console.log('  - 13 Internal Mark entries (4 subjects)');
  console.log('  - 2 Published semester results');
  console.log('  - 1 Unpublished result (for testing)');
  console.log('\n🚀 Feature Flags Enabled:');
  console.log('  - Internal Mark: ✅');
  console.log('  - Result: ✅');
  console.log('\n📱 Test in App:');
  console.log('  1. Login to student app');
  console.log('  2. Go to More → Internal Marks');
  console.log('  3. Go to More → Results');
  console.log('========================================\n');

  process.exit(0);
}

setupInternalMarksAndResults().catch(error => {
  console.error('❌ Error during setup:', error);
  process.exit(1);
});
