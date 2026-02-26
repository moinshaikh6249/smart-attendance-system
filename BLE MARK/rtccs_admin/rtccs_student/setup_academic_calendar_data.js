/**
 * Academic Calendar Module - Sample Data Setup Script
 * 
 * This script sets up sample calendar events for the RTCCS Student app.
 * It creates holidays, exams, college events, and lectures with realistic dates.
 * 
 * Prerequisites:
 * - Node.js installed
 * - firebase-admin package: npm install firebase-admin
 * - Firebase Admin SDK service account JSON file
 * 
 * Usage:
 * 1. Update SCHOOL_ID below
 * 2. Update SERVICE_ACCOUNT_PATH to your Firebase service account JSON
 * 3. Run: node setup_academic_calendar_data.js
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================
// CONFIGURATION - UPDATE THESE VALUES
// ============================================
const SCHOOL_ID = 'SCHOOL001';  // Change to your school ID
const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', 'rtccsattendancesystem-firebase-adminsdk-fbsvc-af29a472c4.json');

// ============================================
// Initialize Firebase Admin
// ============================================
try {
  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://rtccsattendancesystem-default-rtdb.firebaseio.com'
  });
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:', error.message);
  process.exit(1);
}

const db = admin.database();

// ============================================
// Helper: Generate Date String (YYYY-MM-DD)
// ============================================
function getDateString(year, month, day) {
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

// ============================================
// SAMPLE CALENDAR EVENTS DATA
// ============================================
const calendarEvents = [
  // ========== DECEMBER 2025 ==========
  {
    id: 'event_dec_college_reopen',
    date: getDateString(2025, 12, 1),
    title: 'College Reopens',
    description: 'College reopens after semester break. All students must report by 10:00 AM.',
    eventType: 'Other',
    isHoliday: false
  },
  {
    id: 'event_dec_workshop_python',
    date: getDateString(2025, 12, 5),
    title: 'Workshop - Python for Data Science',
    description: 'Two-day workshop on Python programming and data analysis libraries',
    eventType: 'Lecture',
    isHoliday: false
  },
  {
    id: 'event_dec_workshop_python_day2',
    date: getDateString(2025, 12, 6),
    title: 'Workshop - Python for Data Science (Day 2)',
    description: 'Hands-on session with Pandas, NumPy, and Matplotlib',
    eventType: 'Lecture',
    isHoliday: false
  },
  {
    id: 'event_dec_internal_exam_start',
    date: getDateString(2025, 12, 10),
    title: 'Internal Assessment - 2 Begins',
    description: 'Second internal assessment exams start for all programs',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_dec_internal_exam_cs',
    date: getDateString(2025, 12, 11),
    title: 'Internal Exam - Computer Science',
    description: 'Data Structures, DBMS, and Operating Systems',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_dec_internal_exam_ec',
    date: getDateString(2025, 12, 12),
    title: 'Internal Exam - Electronics',
    description: 'Digital Electronics, Microprocessors, and Communication Systems',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_dec_sports_day',
    date: getDateString(2025, 12, 18),
    title: 'Annual Sports Day',
    description: 'Inter-department sports competition. All students encouraged to participate.',
    eventType: 'College Event',
    isHoliday: false
  },
  {
    id: 'event_dec_annual_day',
    date: getDateString(2025, 12, 20),
    title: 'Annual Day Celebration',
    description: 'Cultural events, prize distribution, and chief guest address',
    eventType: 'College Event',
    isHoliday: false
  },
  {
    id: 'event_dec_christmas',
    date: getDateString(2025, 12, 25),
    title: 'Christmas Holiday',
    description: 'College will remain closed for Christmas celebration',
    eventType: 'Holiday',
    isHoliday: true
  },
  {
    id: 'event_dec_semester_end',
    date: getDateString(2025, 12, 31),
    title: 'Semester Classes End',
    description: 'Last day of regular classes. Study leave begins from Jan 1',
    eventType: 'Other',
    isHoliday: false
  },

  // ========== JANUARY 2026 ==========
  {
    id: 'event_jan_new_year',
    date: getDateString(2026, 1, 1),
    title: 'New Year Holiday',
    description: 'College closed for New Year celebration',
    eventType: 'Holiday',
    isHoliday: true
  },
  {
    id: 'event_jan_study_leave_start',
    date: getDateString(2026, 1, 2),
    title: 'Study Leave Begins',
    description: 'Study leave for semester end examinations',
    eventType: 'Other',
    isHoliday: false
  },
  {
    id: 'event_jan_guest_lecture_ai',
    date: getDateString(2026, 1, 15),
    title: 'Guest Lecture - AI & Machine Learning',
    description: 'Special guest lecture by industry expert from Google on latest AI trends',
    eventType: 'Lecture',
    isHoliday: false
  },
  {
    id: 'event_jan_republic_day',
    date: getDateString(2026, 1, 26),
    title: 'Republic Day',
    description: 'National holiday - College closed',
    eventType: 'Holiday',
    isHoliday: true
  },
  {
    id: 'event_jan_sem_exam_start',
    date: getDateString(2026, 1, 20),
    title: 'Semester End Examinations Begin',
    description: 'Final semester examinations start for all programs',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_jan_sem_exam_theory_1',
    date: getDateString(2026, 1, 21),
    title: 'Theory Exam - Mathematics & Programming',
    description: 'Semester exam for Mathematics and C Programming',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_jan_sem_exam_theory_2',
    date: getDateString(2026, 1, 23),
    title: 'Theory Exam - Database & Operating Systems',
    description: 'Semester exam for DBMS and OS',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_jan_practical_exam',
    date: getDateString(2026, 1, 28),
    title: 'Practical Examinations',
    description: 'Lab practical exams for all subjects',
    eventType: 'Exam',
    isHoliday: false
  },

  // ========== FEBRUARY 2026 ==========
  {
    id: 'event_feb_sem_exam_end',
    date: getDateString(2026, 2, 5),
    title: 'Semester Examinations End',
    description: 'Last day of semester end examinations',
    eventType: 'Exam',
    isHoliday: false
  },
  {
    id: 'event_feb_semester_break_start',
    date: getDateString(2026, 2, 6),
    title: 'Semester Break Begins',
    description: 'College closes for semester break. Reopens on March 1',
    eventType: 'Other',
    isHoliday: false
  },
  {
    id: 'event_feb_valentines',
    date: getDateString(2026, 2, 14),
    title: 'Rose Day Event',
    description: 'Student council organized event (during semester break)',
    eventType: 'College Event',
    isHoliday: false
  },
  {
    id: 'event_feb_maha_shivaratri',
    date: getDateString(2026, 2, 17),
    title: 'Maha Shivaratri Holiday',
    description: 'College closed for Maha Shivaratri',
    eventType: 'Holiday',
    isHoliday: true
  },
  {
    id: 'event_feb_result_declaration',
    date: getDateString(2026, 2, 25),
    title: 'Semester Results Declaration',
    description: 'Results will be published on student portal',
    eventType: 'Other',
    isHoliday: false
  }
];

// ============================================
// MAIN SETUP FUNCTION
// ============================================
async function setupAcademicCalendar() {
  console.log('\n📅 Starting Academic Calendar Setup...\n');

  try {
    // 1. Set up calendar events
    console.log('📝 Adding calendar events...');
    const calendarRef = db.ref(`schools/${SCHOOL_ID}/academicCalendar`);
    
    for (const event of calendarEvents) {
      const eventId = event.id;
      delete event.id; // Remove id from event object before saving
      
      await calendarRef.child(eventId).set(event);
      
      const typeIcon = event.isHoliday ? '🎉' : 
                       event.eventType === 'Exam' ? '📝' : 
                       event.eventType === 'College Event' ? '🎊' :
                       event.eventType === 'Lecture' ? '👨‍🏫' : '📌';
      
      console.log(`  ${typeIcon} ${event.date} - ${event.title}`);
    }
    
    console.log(`\n✅ Successfully added ${calendarEvents.length} calendar events`);

    // 2. Enable the feature flag
    console.log('\n🚩 Enabling Academic Calendar feature flag...');
    await db.ref(`schools/${SCHOOL_ID}/featureFlags/modules/calendar`).set(true);
    console.log('✅ Feature flag enabled');

    // 3. Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 SETUP SUMMARY');
    console.log('='.repeat(60));
    
    const holidays = calendarEvents.filter(e => e.isHoliday).length;
    const exams = calendarEvents.filter(e => e.eventType === 'Exam').length;
    const collegeEvents = calendarEvents.filter(e => e.eventType === 'College Event').length;
    const lectures = calendarEvents.filter(e => e.eventType === 'Lecture').length;
    const others = calendarEvents.filter(e => 
      e.eventType === 'Other' || 
      (!e.isHoliday && !['Exam', 'College Event', 'Lecture'].includes(e.eventType))
    ).length;
    
    console.log(`School ID:         ${SCHOOL_ID}`);
    console.log(`Total Events:      ${calendarEvents.length}`);
    console.log(`  🎉 Holidays:     ${holidays}`);
    console.log(`  📝 Exams:        ${exams}`);
    console.log(`  🎊 Events:       ${collegeEvents}`);
    console.log(`  👨‍🏫 Lectures:    ${lectures}`);
    console.log(`  📌 Others:       ${others}`);
    console.log(`Feature Flag:      ✅ Enabled`);
    console.log(`Date Range:        Dec 2025 - Feb 2026`);
    console.log('='.repeat(60));

    console.log('\n✨ Academic Calendar setup completed successfully!\n');
    console.log('📱 You can now:');
    console.log('   1. Open the student app');
    console.log('   2. Navigate to More → Academic Calendar');
    console.log('   3. View events in monthly calendar view');
    console.log('   4. Tap dates to see event details');
    console.log('   5. Use filters to view specific event types\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Error during setup:', error);
    process.exit(1);
  }
}

// ============================================
// RUN SETUP
// ============================================
setupAcademicCalendar();
