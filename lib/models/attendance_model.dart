import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String? userPhone;
  final String date; // YYYY-MM-DD
  final DateTime? checkInTime;
  final String? checkInPhotoUrl;
  final DateTime? checkOutTime;
  final String? checkOutPhotoUrl;
  final String status; // 'checked_in', 'checked_out', 'present'
  final String? recordedByUserId;
  final DateTime? createdAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userRole = 'WORKER',
    this.userPhone,
    required this.date,
    this.checkInTime,
    this.checkInPhotoUrl,
    this.checkOutTime,
    this.checkOutPhotoUrl,
    this.status = 'checked_in',
    this.recordedByUserId,
    this.createdAt,
  });

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? checkIn;
    final inTs = data['checkInTime'];
    if (inTs is Timestamp) checkIn = inTs.toDate();

    DateTime? checkOut;
    final outTs = data['checkOutTime'];
    if (outTs is Timestamp) checkOut = outTs.toDate();

    DateTime? created;
    final cTs = data['createdAt'];
    if (cTs is Timestamp) created = cTs.toDate();

    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Worker',
      userRole: data['userRole'] as String? ?? 'WORKER',
      userPhone: data['userPhone'] as String?,
      date: data['date'] as String? ?? '',
      checkInTime: checkIn,
      checkInPhotoUrl: data['checkInPhotoUrl'] as String?,
      checkOutTime: checkOut,
      checkOutPhotoUrl: data['checkOutPhotoUrl'] as String?,
      status: data['status'] as String? ?? 'checked_in',
      recordedByUserId: data['recordedByUserId'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userPhone': userPhone,
      'date': date,
      'checkInTime':
          checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'status': status,
      'recordedByUserId': recordedByUserId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? userPhone,
    String? date,
    DateTime? checkInTime,
    String? checkInPhotoUrl,
    DateTime? checkOutTime,
    String? checkOutPhotoUrl,
    String? status,
    String? recordedByUserId,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      userPhone: userPhone ?? this.userPhone,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInPhotoUrl: checkInPhotoUrl ?? this.checkInPhotoUrl,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      status: status ?? this.status,
      recordedByUserId: recordedByUserId ?? this.recordedByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
