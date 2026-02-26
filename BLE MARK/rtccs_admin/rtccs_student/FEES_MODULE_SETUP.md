# Fees Paid Module - Firebase Data Structure

## Database Path
```
fees/
  {schoolId}/
    students/
      {studentUUID}/
        totalFee: 50000
        paidAmount: 30000
        pendingAmount: 20000
        nextDueDate: "2025-12-15"
        academicYear: "2025-26"
        semester: "Semester 1"
        feeComponents/
          - 0:
              feeType: "Tuition Fee"
              amountPayable: 25000
              amountPaid: 15000
              dueAmount: 10000
              status: "Partially Paid"
              lastPaymentDate: "2025-10-15"
              dueDate: "2025-12-15"
              academicYear: "2025-26"
              semester: "Semester 1"
          - 1:
              feeType: "Exam Fee"
              amountPayable: 5000
              amountPaid: 5000
              dueAmount: 0
              status: "Paid"
              lastPaymentDate: "2025-09-20"
              academicYear: "2025-26"
              semester: "Semester 1"
          - 2:
              feeType: "Library Fee"
              amountPayable: 3000
              amountPaid: 1000
              dueAmount: 2000
              status: "Partially Paid"
              lastPaymentDate: "2025-10-01"
              dueDate: "2025-12-01"
        payments/
          - 0:
              date: "2025-10-15"
              amount: 15000
              mode: "online"
              transactionId: "TXN123456789"
          - 1:
              date: "2025-09-20"
              amount: 5000
              mode: "cash"
```

## Sample Data (JSON Format)

```json
{
  "fees": {
    "school_001": {
      "students": {
        "uuid-student-123": {
          "totalFee": 50000,
          "paidAmount": 30000,
          "pendingAmount": 20000,
          "nextDueDate": "2025-12-15",
          "academicYear": "2025-26",
          "semester": "Semester 1",
          "feeComponents": [
            {
              "feeType": "Tuition Fee",
              "amountPayable": 25000,
              "amountPaid": 15000,
              "dueAmount": 10000,
              "status": "Partially Paid",
              "lastPaymentDate": "2025-10-15",
              "dueDate": "2025-12-15",
              "academicYear": "2025-26",
              "semester": "Semester 1"
            },
            {
              "feeType": "Exam Fee",
              "amountPayable": 5000,
              "amountPaid": 5000,
              "dueAmount": 0,
              "status": "Paid",
              "lastPaymentDate": "2025-09-20",
              "academicYear": "2025-26",
              "semester": "Semester 1"
            },
            {
              "feeType": "Library Fee",
              "amountPayable": 3000,
              "amountPaid": 1000,
              "dueAmount": 2000,
              "status": "Partially Paid",
              "lastPaymentDate": "2025-10-01",
              "dueDate": "2025-12-01",
              "academicYear": "2025-26",
              "semester": "Semester 1"
            },
            {
              "feeType": "Hostel Fee",
              "amountPayable": 12000,
              "amountPaid": 9000,
              "dueAmount": 3000,
              "status": "Partially Paid",
              "lastPaymentDate": "2025-11-01",
              "dueDate": "2025-12-15",
              "academicYear": "2025-26",
              "semester": "Semester 1"
            },
            {
              "feeType": "Transportation",
              "amountPayable": 5000,
              "amountPaid": 0,
              "dueAmount": 5000,
              "status": "Pending",
              "dueDate": "2025-12-01",
              "academicYear": "2025-26",
              "semester": "Semester 1"
            }
          ],
          "payments": [
            {
              "date": "2025-10-15",
              "amount": 15000,
              "mode": "online",
              "transactionId": "TXN123456789",
              "receiptUrl": "https://example.com/receipt1.pdf"
            },
            {
              "date": "2025-09-20",
              "amount": 5000,
              "mode": "cash",
              "transactionId": null,
              "receiptUrl": null
            },
            {
              "date": "2025-11-01",
              "amount": 9000,
              "mode": "cheque",
              "transactionId": "CHQ987654",
              "receiptUrl": "https://example.com/receipt2.pdf"
            },
            {
              "date": "2025-10-01",
              "amount": 1000,
              "mode": "online",
              "transactionId": "TXN456789123",
              "receiptUrl": null
            }
          ]
        }
      }
    }
  }
}
```

## Data Fields Reference

### Overall Fee Summary
- **totalFee** (number): Total fee amount payable
- **paidAmount** (number): Total amount paid so far
- **pendingAmount** (number): Remaining amount to be paid
- **nextDueDate** (string): Next payment due date (YYYY-MM-DD format)
- **academicYear** (string): Academic year (e.g., "2025-26")
- **semester** (string): Semester name (e.g., "Semester 1", "Semester 2")

### Fee Components (Required Fields)
- **feeType** (string): Type of fee
  - Examples: "Tuition Fee", "Exam Fee", "Library Fee", "Hostel Fee", "Transportation", "Sports Fee", "Lab Fee", "Computer Lab Fee", "Development Fee"
- **amountPayable** (number): Total amount for this fee type
- **amountPaid** (number): Amount already paid
- **dueAmount** (number): Remaining amount for this fee type
- **status** (string): Payment status
  - Values: "Paid", "Partially Paid", "Pending", "Overdue"

### Fee Components (Optional Fields)
- **lastPaymentDate** (string): Date of last payment (YYYY-MM-DD)
- **dueDate** (string): Due date for this fee component (YYYY-MM-DD)
- **academicYear** (string): Academic year for filtering
- **semester** (string): Semester for filtering

### Payment Records
- **date** (string): Payment date (YYYY-MM-DD)
- **amount** (number): Payment amount
- **mode** (string): Payment mode
  - Values: "online", "cash", "cheque", "card", "bank_transfer"
- **transactionId** (string, optional): Transaction/reference ID
- **receiptUrl** (string, optional): URL to payment receipt

## Fee Status Auto-Calculation

If status is not provided, the app auto-calculates:
```
amountPaid >= amountPayable → "Paid"
amountPaid > 0 && amountPaid < amountPayable → "Partially Paid"
amountPaid == 0 → "Pending"
dueDate < currentDate && dueAmount > 0 → "Overdue"
```

## Feature Flag Configuration

Enable the Fees Paid module in Firebase:

```json
{
  "app_config": {
    "student_features": {
      "global": {
        "feesPaid": true,
        "classSchedule": false,
        "hostelAttendance": false,
        "itle": false,
        "certificates": false,
        "hallTicket": false,
        "examTimeTable": false,
        "registerSubject": false,
        "internalMark": false,
        "result": false,
        "calendar": false,
        "feedback": false
      },
      "school_001": {
        "feesPaid": true,
        "classSchedule": true
      }
    }
  }
}
```

## Alternative Data Structure (Year/Semester Filtering)

For academic year/semester based filtering:

```json
{
  "fees": {
    "school_001": {
      "students": {
        "uuid-student-123": {
          "2025-26": {
            "Semester 1": {
              "totalFee": 50000,
              "paidAmount": 30000,
              "pendingAmount": 20000,
              "nextDueDate": "2025-12-15",
              "feeComponents": [...],
              "payments": [...]
            },
            "Semester 2": {
              "totalFee": 50000,
              "paidAmount": 0,
              "pendingAmount": 50000,
              "feeComponents": [...],
              "payments": []
            }
          }
        }
      }
    }
  }
}
```

## Security Rules

Ensure students can only read their own fee data:

```json
{
  "rules": {
    "fees": {
      "$schoolId": {
        "students": {
          "$studentUUID": {
            ".read": "auth != null && auth.uid == $studentUUID",
            ".write": false
          }
        }
      }
    }
  }
}
```

## How It Works

1. **Student logs in** → App fetches student's UUID and schoolId

2. **Feature flag check** → App checks if `feesPaid` is enabled

3. **Data fetch** → App loads fee data from:
   ```
   fees/{schoolId}/students/{studentUUID}
   ```

4. **Caching** → Data is cached locally using SharedPreferences

5. **Offline mode** → If no internet, app shows cached fee data

6. **Refresh** → Pull-to-refresh updates from Firebase and updates cache

7. **Read-only** → Students can only view, cannot edit any data

## Features Implemented

### ✅ Summary Card
- Total Fee amount
- Total Paid amount
- Total Pending amount
- Payment percentage (circular progress)
- Next due date (if applicable)

### ✅ Fee Components Breakdown
- Individual fee types (Tuition, Exam, Library, etc.)
- Status badges (Paid, Partially Paid, Pending, Overdue)
- Amount breakdown per component:
  - Payable amount
  - Paid amount
  - Due amount
- Last payment date
- Due date

### ✅ Payment History
- Chronological payment records
- Payment amount
- Payment mode (with color coding)
- Transaction ID
- Payment date & time
- Receipt download option (placeholder)

### ✅ Offline Support
- Caches fee data locally
- Shows cached data when offline
- Offline indicator with last updated time
- Pull-to-refresh to update data

### ✅ Error Handling
- Timeout protection (15 seconds)
- Friendly error messages
- Retry functionality
- No app crashes

### ✅ Security
- Student can only view their own data
- Read-only access (no edit/delete)
- Firebase security rules enforced
- Authentication required

## UI Features

### Color Coding
- **Paid**: Green badge with checkmark icon
- **Partially Paid**: Orange badge with pending icon
- **Pending**: Grey badge with schedule icon
- **Overdue**: Red badge with warning icon

### Payment Modes
- **Online**: Blue color
- **Cash**: Green color
- **Cheque**: Orange color
- **Card/Others**: Grey color

### Responsive Design
- Scrollable content
- Pull-to-refresh gesture
- Card-based layout
- Dark theme (matching app style)

## Testing Steps

1. Add sample fee data to Firebase at `fees/school_001/students/{uuid}/`
2. Enable feature flag: `app_config/student_features/global/feesPaid: true`
3. Ensure student profile has correct UUID
4. Open app → Dashboard → Tap "Fees Payment"
5. Verify summary shows correct totals
6. Verify fee components display correctly
7. Verify payment history shows all transactions
8. Test pull-to-refresh
9. Test offline mode (disable internet, reopen app)
10. Verify status badges show correct colors

## Troubleshooting

**Issue**: "No Fee Information"
- Check if fee data exists at correct path
- Verify student UUID matches Firebase data
- Check Firebase security rules

**Issue**: "Unable to load fee details right now"
- Check internet connection
- Verify Firebase is accessible
- Check if data structure matches expected format

**Issue**: Module not showing on dashboard
- Check feature flag: `app_config/student_features/global/feesPaid`
- Should be `true`

**Issue**: "Fees information is currently not available"
- Feature flag is disabled
- Enable in Firebase: `feesPaid: true`

**Issue**: Fee components not showing
- Ensure `feeComponents` array exists in Firebase
- Verify data structure matches expected format
- Check for any data type mismatches

## Important Notes

- ✅ All amounts are in numbers (not strings)
- ✅ Dates must be in YYYY-MM-DD format
- ✅ Status values are case-insensitive
- ✅ Student cannot edit or modify any fee data
- ✅ Student cannot access other students' fee data
- ✅ Payment history is sorted by date (newest first)
- ✅ Fee components can be filtered by academic year/semester
- ✅ Module is completely independent of attendance system
- ✅ No changes to BLE, QR, or core attendance logic
