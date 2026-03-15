import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_customer_detail_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin customer detail renders loaded content',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCustomerDetailScreen(
          customerRef: 'comfi',
          detailLoader: (_) async => const AdminCustomerDetail(
            ref: 'comfi',
            name: 'comfi',
            phone: '+998901000333',
            code: '30SFT8WLPTR9',
            codeLocked: false,
            codeRetryAfterSec: 0,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('comfi'), findsWidgets);
    expect(find.text('+998901000333'), findsOneWidget);
    expect(find.text('30SFT8WLPTR9'), findsOneWidget);
  });
}
