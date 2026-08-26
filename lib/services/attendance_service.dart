import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rr_fabrication/models/attendance_model.dart';
import 'package:rr_fabrication/models/user_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/services/storage_service.dart';

class AttendanceService {
  final CollectionReference _attendanceCollection =
      FirebaseFirestore.instance.collection('attendance');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final StorageService _storageService = StorageService();

  static String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Stream<List<AttendanceModel>> getTodayAttendanceStream() {
    final today = getTodayDateString();
    return _attendanceCollection
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }

  Future<AttendanceModel?> getEmployeeAttendanceToday(String userId) async {
    try {
      final today = getTodayDateString();
      final docId = '${userId}_$today';
      final doc = await _attendanceCollection.doc(docId).get();
      if (!doc.exists) return null;
      return AttendanceModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting employee attendance: $e');
      return null;
    }
  }

  Future<List<UserModel>> searchEmployees(String query) async {
    try {
      final snapshot = await _usersCollection.get();
      final allUsers =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      if (query.trim().isEmpty) {
        // Return workers and staff
        return allUsers
            .where((u) => u.role == UserRole.WORKER || u.role == UserRole.ADMIN)
            .toList();
      }

      final q = query.trim().toLowerCase();
      return allUsers.where((u) {
        final matchName = u.name.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchPhone = u.phoneNumber?.contains(q) ?? false;
        final matchId = u.id.toLowerCase().contains(q);
        return matchName || matchEmail || matchPhone || matchId;
      }).toList();
    } catch (e) {
      debugPrint('Error searching employees: $e');
      return [];
    }
  }

  Future<void> recordCheckIn({
    required UserModel employee,
    XFile? photoFile,
    required String recordedByUserId,
  }) async {
    try {
      final today = getTodayDateString();
      final docId = '${employee.id}_$today';

      String? photoUrl;
      if (photoFile != null) {
        try {
          photoUrl = await _storageService.uploadProductImage(photoFile);
        } catch (e) {
          debugPrint('Photo upload fallback for attendance: $e');
        }
      }

      await _attendanceCollection.doc(docId).set({
        'userId': employee.id,
        'userName': employee.name,
        'userRole': employee.role.name,
        'userPhone': employee.phoneNumber,
        'date': today,
        'checkInTime': FieldValue.serverTimestamp(),
        'checkInPhotoUrl': photoUrl,
        'status': 'checked_in',
        'recordedByUserId': recordedByUserId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording check-in: $e');
      rethrow;
    }
  }

  Future<void> recordCheckOut({
    required UserModel employee,
    XFile? photoFile,
    required String recordedByUserId,
  }) async {
    try {
      final today = getTodayDateString();
      final docId = '${employee.id}_$today';

      String? photoUrl;
      if (photoFile != null) {
        try {
          photoUrl = await _storageService.uploadProductImage(photoFile);
        } catch (e) {
          debugPrint('Photo upload fallback for check-out: $e');
        }
      }

      final Map<String, dynamic> updateData = {
        'checkOutTime': FieldValue.serverTimestamp(),
        'status': 'checked_out',
        'recordedByUserId': recordedByUserId,
      };

      if (photoUrl != null) {
        updateData['checkOutPhotoUrl'] = photoUrl;
      }

      await _attendanceCollection.doc(docId).set(
            updateData,
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error recording check-out: $e');
      rethrow;
    }
  }
}
