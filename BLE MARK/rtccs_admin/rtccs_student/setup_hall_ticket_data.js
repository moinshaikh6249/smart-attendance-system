const admin = require('firebase-admin');
const serviceAccount = require('./rtccsattendancesystem-firebase-adminsdk-fbsvc-af29a472c4.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://rtccsattendancesystem-default-rtdb.firebaseio.com'
});

const db = admin.database();

async function setupHallTicket() {
  const schoolId = 'SCHOOL001';
  const studentUUID = 'STU-2024-001'; // Replace with actual student UUID

  console.log('🎫 Setting up Hall Ticket data...\n');

  // Calculate exam dates
  const today = new Date();
  const examStartDate = new Date(today);
  examStartDate.setDate(examStartDate.getDate() + 10);
  
  const examEndDate = new Date(examStartDate);
  examEndDate.setDate(examEndDate.getDate() + 15);

  // Helper to format date as YYYY-MM-DD
  const formatDate = (date) => {
    return date.toISOString().split('T')[0];
  };

  // ========================================
  // HALL TICKET DATA
  // ========================================
  console.log('Adding Hall Ticket data...');
  const hallTicketRef = db.ref(`schools/${schoolId}/students/${studentUUID}/hallTicket`);
  
  await hallTicketRef.set({
    studentName: 'John Doe',
    enrollmentNo: '2024IT001',
    prn: 'PRN2024001',
    seatNumber: 'IT-125',
    examName: 'TY BSc IT Semester 5 Final Examination - November 2024',
    program: 'BSc Information Technology',
    semester: 'Semester 5',
    examCenterName: 'Main Examination Center, College Building',
    centerCode: 'CENTER-001',
    examDates: [
      formatDate(examStartDate),
      formatDate(new Date(examStartDate.getTime() + 2 * 24 * 60 * 60 * 1000)),
      formatDate(new Date(examStartDate.getTime() + 5 * 24 * 60 * 60 * 1000)),
      formatDate(new Date(examStartDate.getTime() + 7 * 24 * 60 * 60 * 1000)),
      formatDate(new Date(examStartDate.getTime() + 10 * 24 * 60 * 60 * 1000)),
      formatDate(examEndDate)
    ],
    // PDF URL - Replace with actual URL to PDF file
    pdfUrl: 'https://example.com/hall-tickets/STU-2024-001.pdf',
    // Alternative: Image URL if hall ticket is an image
    imageUrl: null,
    isReleased: true,
    releaseDate: new Date().toISOString(),
    additionalInfo: {
      reportingTime: '09:30 AM',
      examStartTime: '10:00 AM',
      examDuration: '3 hours',
      instructions: [
        'Bring College ID Card',
        'Bring Hall Ticket printout',
        'No mobile phones allowed',
        'Report 30 minutes early'
      ]
    }
  });

  console.log('✅ Hall Ticket added!\n');

  // ========================================
  // ENABLE FEATURE FLAG
  // ========================================
  console.log('Enabling feature flag...');
  
  const featureFlagsRef = db.ref(`featureFlags/modules/${schoolId}`);
  await featureFlagsRef.update({
    hallTicket: true
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
  console.log('  - Student Name: John Doe');
  console.log('  - Enrollment No: 2024IT001');
  console.log('  - PRN: PRN2024001');
  console.log('  - Seat Number: IT-125');
  console.log('  - Program: BSc IT Semester 5');
  console.log('  - Exam Center: Main Examination Center');
  console.log(`  - Exam Start Date: ${formatDate(examStartDate)}`);
  console.log(`  - Exam End Date: ${formatDate(examEndDate)}`);
  console.log('  - Total Exam Days: 6');
  console.log('  - Status: Released ✅');
  console.log('\n📄 Hall Ticket:');
  console.log('  - PDF URL: https://example.com/hall-tickets/STU-2024-001.pdf');
  console.log('  - Note: Replace with actual PDF URL in Firebase');
  console.log('\n🚀 Feature Flag Enabled:');
  console.log('  - Hall Ticket: ✅');
  console.log('\n📱 Test in App:');
  console.log('  1. Login to student app');
  console.log('  2. Go to More → Hall Ticket');
  console.log('  3. See hall ticket details');
  console.log('  4. Tap "View / Download Hall Ticket" button');
  console.log('\n⚠️  Important:');
  console.log('  - Update pdfUrl with actual PDF file URL');
  console.log('  - Or set isReleased: false to test "not yet released" state');
  console.log('  - Update student details to match actual student');
  console.log('========================================\n');

  // ========================================
  // EXAMPLE: NOT RELEASED STATE
  // ========================================
  console.log('\n📝 To test "Not Yet Released" state:');
  console.log('Set isReleased: false in Firebase:\n');
  console.log('hallTicket/isReleased: false\n');

  process.exit(0);
}

setupHallTicket().catch(error => {
  console.error('❌ Error during setup:', error);
  process.exit(1);
});
