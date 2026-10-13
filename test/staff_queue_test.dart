import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/views/staff/components/confirm_status_dialog.dart';
import 'package:uniprint_mobile/views/staff/components/staff_order_card.dart';

void main() {
  group('Task 12 - Staff Queue Components & State Machine Tests', () {
    final samplePendingOrder = PrintOrderModel(
      id: 'order-001',
      orderCode: 'ORD-20261013-001',
      studentName: 'Nguyễn Văn A',
      documentName: 'BaoCaoTieuLuan.pdf',
      numberOfCopies: 2,
      isColor: false,
      isDoubleSided: true,
      totalPrice: 15000,
      status: OrderStatus.pending,
      paymentStatus: 1,
      createdAt: DateTime.now(),
    );

    final samplePrintingOrder = PrintOrderModel(
      id: 'order-002',
      orderCode: 'ORD-20261013-002',
      studentName: 'Trần Thị B',
      documentName: 'SlideThuyetTrinh.pdf',
      numberOfCopies: 1,
      isColor: true,
      isDoubleSided: false,
      totalPrice: 25000,
      status: OrderStatus.printing,
      paymentStatus: 1,
      createdAt: DateTime.now(),
    );

    testWidgets('StaffOrderCard renders FIFO index, code, and Pending buttons',
        (tester) async {
      int? clickedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffOrderCard(
              order: samplePendingOrder,
              queueIndex: 1,
              onStatusChange: (order, status, title, desc) {
                clickedStatus = status;
              },
            ),
          ),
        ),
      );

      // Verify FIFO badge #1 and Order Code
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('ORD-20261013-001'), findsOneWidget);
      expect(find.text('Sinh viên: Nguyễn Văn A'), findsOneWidget);

      // Verify Pending action buttons: 'Tiếp nhận đơn' and 'Bắt đầu in'
      expect(find.text('Tiếp nhận đơn'), findsOneWidget);
      expect(find.text('Bắt đầu in'), findsOneWidget);

      // Tap 'Bắt đầu in' button
      await tester.tap(find.text('Bắt đầu in'));
      await tester.pump();
      expect(clickedStatus, OrderStatus.printing.value);
    });

    testWidgets('StaffOrderCard renders Printing state with completion button',
        (tester) async {
      int? clickedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffOrderCard(
              order: samplePrintingOrder,
              queueIndex: 2,
              onStatusChange: (order, status, title, desc) {
                clickedStatus = status;
              },
            ),
          ),
        ),
      );

      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Đang chạy máy in...'), findsOneWidget);
      expect(find.text('Đã in xong'), findsOneWidget);

      await tester.tap(find.text('Đã in xong'));
      await tester.pump();
      expect(clickedStatus, OrderStatus.readyForPickup.value);
    });

    testWidgets('ConfirmStatusDialog displays BR02 warning when transitioning to Printing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmStatusDialog(
              order: samplePendingOrder,
              targetStatus: OrderStatus.printing.value,
              actionTitle: 'Bắt đầu in',
              actionDescription: 'Xác nhận chuyển đơn sang trạng thái in?',
              onConfirm: () async {},
            ),
          ),
        ),
      );

      // Expect BR02 warning message
      expect(
        find.textContaining('Ràng buộc BR02: Khi bắt đầu in, hệ thống sẽ khóa quyền hủy đơn của sinh viên.'),
        findsOneWidget,
      );
      expect(find.text('Xác nhận'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    test('BR02 Rule: Student canCancel is false when printing or completed', () {
      expect(samplePendingOrder.canCancel, true);
      expect(samplePrintingOrder.canCancel, false);

      final readyOrder = PrintOrderModel(
        id: 'order-003',
        orderCode: 'ORD-20261013-003',
        studentName: 'Lê Văn C',
        documentName: 'DeThi.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 5000,
        status: OrderStatus.readyForPickup,
        paymentStatus: 1,
        createdAt: DateTime.now(),
      );
      expect(readyOrder.canCancel, false);
    });
  });
}
