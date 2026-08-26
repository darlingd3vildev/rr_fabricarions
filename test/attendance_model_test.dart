import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/attendance_model.dart';
import 'package:rr_fabrication/models/user_role.dart';

void main() {
  group('AttendanceModel & UserRole Tests', () {
    test('AttendanceModel instantiates and computes check-in/out status', () {
      final inTime = DateTime(2026, 8, 25, 9, 15);
      final outTime = DateTime(2026, 8, 25, 18, 30);

      final attendance = AttendanceModel(
        id: 'att-101',
        userId: 'worker-1',
        userName: 'Ramesh Welder',
        userRole: 'WORKER',
        userPhone: '9876543210',
        date: '2026-08-25',
        checkInTime: inTime,
        checkInPhotoUrl: 'https://example.com/checkin.jpg',
        checkOutTime: outTime,
        checkOutPhotoUrl: 'https://example.com/checkout.jpg',
        status: 'checked_out',
      );

      expect(attendance.isCheckedIn, isTrue);
      expect(attendance.isCheckedOut, isTrue);
      expect(attendance.userName, equals('Ramesh Welder'));
      expect(attendance.date, equals('2026-08-25'));
    });

    test('AttendanceModel toMap contains proper fields', () {
      final inTime = DateTime(2026, 8, 25, 9, 0);
      final attendance = AttendanceModel(
        id: 'att-102',
        userId: 'worker-2',
        userName: 'Kiran Painter',
        date: '2026-08-25',
        checkInTime: inTime,
        status: 'checked_in',
      );

      final map = attendance.toMap();
      expect(map['userId'], equals('worker-2'));
      expect(map['userName'], equals('Kiran Painter'));
      expect(map['date'], equals('2026-08-25'));
      expect(map['status'], equals('checked_in'));
      expect(map['checkOutTime'], isNull);
    });

    test('UserRole enum contains MARKETING and ATTENDANCE', () {
      expect(UserRole.values, contains(UserRole.MARKETING));
      expect(UserRole.values, contains(UserRole.ATTENDANCE));
      expect(UserRole.MARKETING.displayName, equals('Marketing'));
      expect(UserRole.ATTENDANCE.displayName, equals('Attendance'));

      expect(UserRole.fromString('MARKETING'), equals(UserRole.MARKETING));
      expect(UserRole.fromString('ATTENDANCE'), equals(UserRole.ATTENDANCE));
      expect(UserRole.fromString('nonexistent'), equals(UserRole.CUSTOMER));
    });
  });
}
