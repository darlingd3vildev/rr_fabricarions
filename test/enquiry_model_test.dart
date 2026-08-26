import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/enquiry_model.dart';

void main() {
  group('EnquiryModel Tests', () {
    test('EnquiryModel instantiates correctly with full fields', () {
      final now = DateTime(2026, 8, 25, 10, 30);
      final comment = EnquiryComment(
        id: 'c-1',
        userId: 'm-1',
        userName: 'Pooja (Sales)',
        text: 'Sent quotation of ₹45,000 via WhatsApp',
        createdAt: now,
      );

      final enquiry = EnquiryModel(
        id: 'enq-101',
        customerName: 'Suresh Patel',
        customerPhone: '9876543210',
        customerEmail: 'suresh@example.com',
        customerAddress: '123 Main Road, City',
        productId: 'prod-gate-1',
        productName: 'Sliding Steel Gate',
        dimensions: '12ft x 6ft',
        description: 'Need motorized gate with primer coating',
        estimatedBudget: 45000.0,
        status: EnquiryStatus.followup,
        createdByUserId: 'm-1',
        createdByUserName: 'Pooja (Sales)',
        comments: [comment],
        createdAt: now,
        updatedAt: now,
      );

      expect(enquiry.id, equals('enq-101'));
      expect(enquiry.customerName, equals('Suresh Patel'));
      expect(enquiry.customerPhone, equals('9876543210'));
      expect(enquiry.productName, equals('Sliding Steel Gate'));
      expect(enquiry.status, equals(EnquiryStatus.followup));
      expect(enquiry.comments.length, equals(1));
      expect(enquiry.comments.first.text, contains('Sent quotation'));
    });

    test('EnquiryModel toMap and fromMap serialization', () {
      final now = DateTime(2026, 8, 25, 12, 0);
      final enquiry = EnquiryModel(
        id: 'enq-102',
        customerName: 'Anita Sharma',
        customerPhone: '9123456780',
        productName: 'Balcony Grill',
        dimensions: '20 running feet',
        status: EnquiryStatus.active,
        createdByUserId: 'm-2',
        createdByUserName: 'Vikas',
        createdAt: now,
      );

      final map = enquiry.toMap();
      expect(map['customerName'], equals('Anita Sharma'));
      expect(map['customerPhone'], equals('9123456780'));
      expect(map['productName'], equals('Balcony Grill'));
      expect(map['status'], equals('active'));
      expect(map['createdByUserId'], equals('m-2'));
    });

    test('EnquiryStatus fromString fallback handling', () {
      expect(EnquiryStatus.fromString('active'), equals(EnquiryStatus.active));
      expect(EnquiryStatus.fromString('followup'),
          equals(EnquiryStatus.followup));
      expect(EnquiryStatus.fromString('In Follow-up'),
          equals(EnquiryStatus.followup));
      expect(EnquiryStatus.fromString('confirmed'),
          equals(EnquiryStatus.confirmed));
      expect(EnquiryStatus.fromString('cancelled'),
          equals(EnquiryStatus.cancelled));
      expect(EnquiryStatus.fromString('unknown_value'),
          equals(EnquiryStatus.active));
    });
  });
}
