import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for a fee component (e.g., tuition, hostel, library)
class FeeComponent {
  final String id;
  final String name;
  final double amount;
  final String? academicYear;
  final String? semester;
  final bool isPaid;

  FeeComponent({
    required this.id,
    required this.name,
    required this.amount,
    this.academicYear,
    this.semester,
    this.isPaid = false,
  });

  factory FeeComponent.fromMap(Map<dynamic, dynamic> map, String id) {
    return FeeComponent(
      id: id,
      name: map['name']?.toString() ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      academicYear: map['academicYear']?.toString(),
      semester: map['semester']?.toString(),
      isPaid: map['isPaid'] == true,
    );
  }

  factory FeeComponent.fromJson(Map<String, dynamic> json) {
    return FeeComponent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      academicYear: json['academicYear'],
      semester: json['semester'],
      isPaid: json['isPaid'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'academicYear': academicYear,
      'semester': semester,
      'isPaid': isPaid,
    };
  }
}

/// Model for fee information
class FeeInfo {
  final String studentUUID;
  final double totalFee;
  final double paidAmount;
  final double pendingAmount;
  final List<PaymentRecord> payments;
  final List<FeeComponent> feeComponents;
  final DateTime? nextDueDate;
  final String? academicYear;
  final String? semester;

  FeeInfo({
    required this.studentUUID,
    required this.totalFee,
    required this.paidAmount,
    required this.pendingAmount,
    required this.payments,
    this.feeComponents = const [],
    this.nextDueDate,
    this.academicYear,
    this.semester,
  });

  factory FeeInfo.fromMap(Map<dynamic, dynamic> map, String studentUUID) {
    final payments = <PaymentRecord>[];
    if (map['payments'] != null) {
      final paymentsList = map['payments'] as List;
      for (var i = 0; i < paymentsList.length; i++) {
        if (paymentsList[i] != null) {
          payments.add(PaymentRecord.fromMap(paymentsList[i], i.toString()));
        }
      }
    }

    final components = <FeeComponent>[];
    if (map['feeComponents'] != null) {
      if (map['feeComponents'] is List) {
        final componentsList = map['feeComponents'] as List;
        for (var i = 0; i < componentsList.length; i++) {
          if (componentsList[i] != null) {
            components.add(FeeComponent.fromMap(componentsList[i], i.toString()));
          }
        }
      } else if (map['feeComponents'] is Map) {
        final componentsMap = map['feeComponents'] as Map;
        componentsMap.forEach((key, value) {
          if (value != null) {
            components.add(FeeComponent.fromMap(value, key.toString()));
          }
        });
      }
    }

    return FeeInfo(
      studentUUID: studentUUID,
      totalFee: (map['totalFee'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      pendingAmount: (map['pendingAmount'] ?? 0).toDouble(),
      payments: payments,
      feeComponents: components,
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.tryParse(map['nextDueDate'].toString())
          : null,
      academicYear: map['academicYear']?.toString(),
      semester: map['semester']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentUUID': studentUUID,
      'totalFee': totalFee,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'payments': payments.map((p) => {
        'date': p.date.toIso8601String(),
        'amount': p.amount,
        'mode': p.mode,
        'transactionId': p.transactionId,
        'receiptUrl': p.receiptUrl,
      }).toList(),
      'feeComponents': feeComponents.map((c) => c.toJson()).toList(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'academicYear': academicYear,
      'semester': semester,
    };
  }

  factory FeeInfo.fromJson(Map<String, dynamic> json) {
    return FeeInfo(
      studentUUID: json['studentUUID'] ?? '',
      totalFee: (json['totalFee'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      payments: (json['payments'] as List? ?? [])
          .map((p) => PaymentRecord(
                id: '',
                date: DateTime.parse(p['date']),
                amount: (p['amount'] ?? 0).toDouble(),
                mode: p['mode'] ?? 'cash',
                transactionId: p['transactionId'],
                receiptUrl: p['receiptUrl'],
              ))
          .toList(),
      feeComponents: (json['feeComponents'] as List? ?? [])
          .map((c) => FeeComponent.fromJson(c))
          .toList(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'])
          : null,
      academicYear: json['academicYear'],
      semester: json['semester'],
    );
  }

  double get paidPercentage => totalFee > 0 ? (paidAmount / totalFee) * 100 : 0;
}

/// Model for payment record
class PaymentRecord {
  final String id;
  final DateTime date;
  final double amount;
  final String mode; // online, cash, cheque, etc.
  final String? transactionId;
  final String? receiptUrl;

  PaymentRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.mode,
    this.transactionId,
    this.receiptUrl,
  });

  factory PaymentRecord.fromMap(Map<dynamic, dynamic> map, String id) {
    return PaymentRecord(
      id: id,
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
      amount: (map['amount'] ?? 0).toDouble(),
      mode: map['mode']?.toString() ?? 'cash',
      transactionId: map['transactionId']?.toString(),
      receiptUrl: map['receiptUrl']?.toString(),
    );
  }
}

/// Provider for fees information
class FeesProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  FeeInfo? _feeInfo;
  bool _isLoading = false;
  String? _error;
  String? _selectedAcademicYear;
  String? _selectedSemester;
  DateTime? _lastUpdated;
  bool _isFromCache = false;

  FeeInfo? get feeInfo => _feeInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedAcademicYear => _selectedAcademicYear;
  String? get selectedSemester => _selectedSemester;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isFromCache => _isFromCache;

  static const String _cacheKey = 'fees_cache';
  static const String _cacheTimestampKey = 'fees_cache_timestamp';

  /// Load cached fee info
  Future<void> loadCachedFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        _feeInfo = FeeInfo.fromJson(json);
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        _isFromCache = true;
        notifyListeners();
        print('[FeesProvider] Loaded from cache');
      }
    } catch (e) {
      print('[FeesProvider] Cache load error: $e');
    }
  }

  /// Save fee info to cache
  Future<void> _saveToCache(FeeInfo feeInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(feeInfo.toJson()));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('[FeesProvider] Saved to cache');
    } catch (e) {
      print('[FeesProvider] Cache save error: $e');
    }
  }

  /// Fetch fee information from Firebase
  Future<void> fetchFees({
    required String schoolId,
    required String studentUUID,
    bool showLoading = true,
    String? academicYear,
    String? semester,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    // Load from cache first if available
    if (_feeInfo == null) {
      await loadCachedFees();
    }

    _selectedAcademicYear = academicYear;
    _selectedSemester = semester;

    try {
      // Build path with optional filters
      String path = 'fees/$schoolId/students/$studentUUID';
      if (academicYear != null) {
        path += '/$academicYear';
        if (semester != null) {
          path += '/$semester';
        }
      }

      final snapshot = await _db
          .ref(path)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout: Unable to load fee information. Please check your network connection.');
            },
          );

      if (snapshot.exists) {
        _feeInfo = FeeInfo.fromMap(snapshot.value as Map, studentUUID);
        _lastUpdated = DateTime.now();
        _isFromCache = false;
        _error = null;

        // Save to cache
        await _saveToCache(_feeInfo!);
      } else {
        // No data on server
        if (_feeInfo == null) {
          _feeInfo = null;
          _error = null; // Not an error, just no data
        }
        // Keep cached data if server has no data
      }
    } catch (e) {
      // If we have cached data, keep showing it
      if (_feeInfo == null) {
        _error = e.toString();
      } else {
        // Show cached data but set error for "couldn't refresh" message
        _error = 'Showing last updated fee information. Couldn\'t refresh right now.';
      }
      print('[FeesProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get fee components filtered by academic year/semester
  List<FeeComponent> getFilteredComponents() {
    if (_feeInfo == null) return [];
    
    var components = _feeInfo!.feeComponents;
    
    if (_selectedAcademicYear != null) {
      components = components.where((c) => c.academicYear == _selectedAcademicYear).toList();
    }
    
    if (_selectedSemester != null) {
      components = components.where((c) => c.semester == _selectedSemester).toList();
    }
    
    return components;
  }

  /// Set filter for academic year/semester
  void setFilter({String? academicYear, String? semester}) {
    _selectedAcademicYear = academicYear;
    _selectedSemester = semester;
    notifyListeners();
  }

  void clear() {
    _feeInfo = null;
    _error = null;
    notifyListeners();
  }
}
