const admin = require('firebase-admin');
const serviceAccount = require('./rtccsattendancesystem-firebase-adminsdk-fbsvc-af29a472c4.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://rtccsattendancesystem-default-rtdb.firebaseio.com'
});

const db = admin.database();

async function setupExamTimetable() {
  const schoolId = 'SCHOOL001';
  const studentUUID = 'STU-2024-001'; // Replace with actual student UUID

  console.log('📅 Setting up Exam Timetable data...\n');

  // Calculate dates relative to today
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const nextWeek = new Date(today);
  nextWeek.setDate(nextWeek.getDate() + 7);
  
  const twoWeeks = new Date(today);
  twoWeeks.setDate(twoWeeks.getDate() + 14);
  
  const threeWeeks = new Date(today);
  threeWeeks.setDate(threeWeeks.getDate() + 21);
  
  const pastExam = new Date(today);
  pastExam.setDate(pastExam.getDate() - 7);

  // Helper to format date as YYYY-MM-DD
  const formatDate = (date) => {
    return date.toISOString().split('T')[0];
  };

  // ========================================
  // EXAM TIMETABLE DATA
  // ========================================
  console.log('Adding Exam Timetable data...');
  const examTimetableRef = db.ref(`schools/${schoolId}/students/${studentUUID}/examTimetable`);
  
  await examTimetableRef.set({
    // Theory Exams - Upcoming
    EXAM001: {
      examName: 'TY BSc IT Sem 5 Regular Exam',
      subjectName: 'Advanced Java Programming',
      subjectCode: 'USIT501',
      examDate: formatDate(nextWeek),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 301, Main Building',
      seatNumber: 'IT-125'
    },
    EXAM002: {
      examName: 'TY BSc IT Sem 5 Regular Exam',
      subjectName: 'Internet of Things',
      subjectCode: 'USIT502',
      examDate: formatDate(nextWeek.setDate(nextWeek.getDate() + 2)),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 301, Main Building',
      seatNumber: 'IT-125'
    },
    EXAM003: {
      examName: 'TY BSc IT Sem 5 Regular Exam',
      subjectName: 'Network Security',
      subjectCode: 'USIT503',
      examDate: formatDate(nextWeek.setDate(nextWeek.getDate() + 3)),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 302, Main Building',
      seatNumber: 'IT-125'
    },
    EXAM004: {
      examName: 'TY BSc IT Sem 5 Regular Exam',
      subjectName: 'Software Project Management',
      subjectCode: 'USIT504',
      examDate: formatDate(twoWeeks),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 303, Main Building',
      seatNumber: 'IT-125'
    },
    EXAM005: {
      examName: 'TY BSc IT Sem 5 Regular Exam',
      subjectName: 'Next Generation Technologies',
      subjectCode: 'USIT505',
      examDate: formatDate(twoWeeks.setDate(twoWeeks.getDate() + 2)),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 304, Main Building',
      seatNumber: 'IT-125'
    },

    // Practical Exams
    EXAM006: {
      examName: 'TY BSc IT Sem 5 Practical Exam',
      subjectName: 'Advanced Java Programming Lab',
      subjectCode: 'USITP501',
      examDate: formatDate(twoWeeks.setDate(twoWeeks.getDate() + 5)),
      startTime: '14:00',
      endTime: '17:00',
      examType: 'Practical',
      roomOrCenter: 'Computer Lab 1',
      seatNumber: 'PC-25'
    },
    EXAM007: {
      examName: 'TY BSc IT Sem 5 Practical Exam',
      subjectName: 'IoT Lab',
      subjectCode: 'USITP502',
      examDate: formatDate(twoWeeks.setDate(twoWeeks.getDate() + 2)),
      startTime: '14:00',
      endTime: '17:00',
      examType: 'Practical',
      roomOrCenter: 'IoT Lab, 4th Floor',
      seatNumber: 'WS-12'
    },
    EXAM008: {
      examName: 'TY BSc IT Sem 5 Practical Exam',
      subjectName: 'Network Security Lab',
      subjectCode: 'USITP503',
      examDate: formatDate(threeWeeks),
      startTime: '14:00',
      endTime: '17:00',
      examType: 'Practical',
      roomOrCenter: 'Network Lab',
      seatNumber: 'WS-08'
    },

    // Viva Exams
    EXAM009: {
      examName: 'TY BSc IT Sem 5 Viva',
      subjectName: 'Project Viva Voce',
      subjectCode: 'USIT5P1',
      examDate: formatDate(threeWeeks.setDate(threeWeeks.getDate() + 3)),
      startTime: '09:00',
      endTime: '12:00',
      examType: 'Viva',
      roomOrCenter: 'Conference Room',
      seatNumber: null
    },
    EXAM010: {
      examName: 'TY BSc IT Sem 5 Viva',
      subjectName: 'Internship Viva',
      subjectCode: 'USIT5P2',
      examDate: formatDate(threeWeeks.setDate(threeWeeks.getDate() + 2)),
      startTime: '14:00',
      endTime: '17:00',
      examType: 'Viva',
      roomOrCenter: 'Staff Room 2',
      seatNumber: null
    },

    // Past Exam (for testing past exam display)
    EXAM011: {
      examName: 'TY BSc IT Sem 4 Final Exam',
      subjectName: 'Database Management Systems',
      subjectCode: 'USIT401',
      examDate: formatDate(pastExam),
      startTime: '10:00',
      endTime: '13:00',
      examType: 'Theory',
      roomOrCenter: 'Room 201, Main Building',
      seatNumber: 'IT-125'
    },

    // Today's exam (for testing)
    EXAM012: {
      examName: 'TY BSc IT Mock Exam',
      subjectName: 'Mock Test - Java',
      subjectCode: 'MOCK001',
      examDate: formatDate(today),
      startTime: '15:00',
      endTime: '16:30',
      examType: 'Theory',
      roomOrCenter: 'Room 305',
      seatNumber: 'IT-125'
    },

    // Tomorrow's exam (for testing)
    EXAM013: {
      examName: 'TY BSc IT Mock Exam',
      subjectName: 'Mock Test - IoT',
      subjectCode: 'MOCK002',
      examDate: formatDate(tomorrow),
      startTime: '11:00',
      endTime: '12:30',
      examType: 'Practical',
      roomOrCenter: 'IoT Lab',
      seatNumber: 'WS-12'
    }
  });

  console.log('✅ Exam Timetable added!\n');

  // ========================================
  // ENABLE FEATURE FLAG
  // ========================================
  console.log('Enabling feature flag...');
  
  const featureFlagsRef = db.ref(`featureFlags/modules/${schoolId}`);
  await featureFlagsRef.update({
    examTimetable: true
  });

  console.log('✅ Feature flag enabled!\n');

  // ========================================
  // SUMMARY
  // ========================================
  console.log('========================================');
  console.log('✨ Setup Complete! ✨');
  console.log('========================================');
  console.log(`School ID: ${schoolId}`);
  console.log(`Student UUID: ${studentUUID}`);
  console.log('\n📊 Data Added:');
  console.log('  - 13 Exam entries total');
  console.log('  - 5 Theory exams (upcoming)');
  console.log('  - 3 Practical exams (upcoming)');
  console.log('  - 2 Viva exams (upcoming)');
  console.log('  - 1 Past exam (for testing)');
  console.log('  - 1 Today\'s exam (for testing)');
  console.log('  - 1 Tomorrow\'s exam (for testing)');
  console.log('\n📅 Exam Schedule:');
  console.log(`  - Today: ${formatDate(today)}`);
  console.log(`  - Tomorrow: ${formatDate(tomorrow)}`);
  console.log(`  - Next Week: ${formatDate(nextWeek)}`);
  console.log(`  - Two Weeks: ${formatDate(twoWeeks)}`);
  console.log(`  - Three Weeks: ${formatDate(threeWeeks)}`);
  console.log('\n🚀 Feature Flag Enabled:');
  console.log('  - Exam Timetable: ✅');
  console.log('\n📱 Test in App:');
  console.log('  1. Login to student app');
  console.log('  2. Go to More → Exam Time Table');
  console.log('  3. See "Next Exam" card at top');
  console.log('  4. Test filters (All, Upcoming, Theory, Practical, Viva)');
  console.log('  5. Check date grouping (Today, Tomorrow, etc.)');
  console.log('========================================\n');

  process.exit(0);
}

setupExamTimetable().catch(error => {
  console.error('❌ Error during setup:', error);
  process.exit(1);
});
