import 'dart:convert';

import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_batch_qr.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_batch_qr_lookup_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parses legacy archive batch QR payload', () {
    final raw = _archiveUrl([
      'ARCHIVE',
      'sess-1',
      'Akis mega 2-3 kg paket',
      '3.6',
      '01 May 2026 15:23',
    ]);

    final parsed = WerkaArchiveBatchQrPayload.tryParse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.sessionID, 'sess-1');
    expect(parsed.itemName, 'Akis mega 2-3 kg paket');
    expect(parsed.qty, 3.6);
    expect(parsed.nettoQty, 3.6);
    expect(parsed.bruttoQty, 3.6);
    expect(parsed.batchTime, '01 May 2026 15:23');
  });

  test('parses separated brutto and netto archive batch QR payload', () {
    final raw = _archiveUrl([
      'ARCHIVE',
      'sess-2',
      'Akis mega 2-3 kg paket',
      '4.1',
      '3.6',
      '01 May 2026 15:23',
    ]);

    final parsed = WerkaArchiveBatchQrPayload.tryParse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.sessionID, 'sess-2');
    expect(parsed.qty, 3.6);
    expect(parsed.nettoQty, 3.6);
    expect(parsed.bruttoQty, 4.1);
    expect(parsed.batchTime, '01 May 2026 15:23');
  });

  test('batch QR item resolution requires exact item match', () {
    final options = [
      const CustomerItemOption(
        customerRef: 'CUST-1',
        customerName: 'Customer',
        customerPhone: '',
        itemCode: 'Adras aboy 4kg paket',
        itemName: 'Adras aboy 4kg paket',
        uom: 'Kg',
        warehouse: 'Stores - A',
      ),
      const CustomerItemOption(
        customerRef: 'CUST-2',
        customerName: 'Customer 2',
        customerPhone: '',
        itemCode: 'Adras aboy 3kg paekt',
        itemName: 'Adras aboy 3kg paekt',
        uom: 'Kg',
        warehouse: 'Stores - A',
      ),
    ];

    final exact = resolveExactArchiveBatchItemOption(
      'Adras aboy 3kg paekt',
      options,
    );
    final missing = resolveExactArchiveBatchItemOption(
      'Adras aboy 2kg paekt',
      options,
    );

    expect(exact?.itemCode, 'Adras aboy 3kg paekt');
    expect(missing, isNull);
  });

  test('batch QR default customer prefers primary customer', () {
    const option = CustomerItemOption(
      customerRef: 'saidamin',
      customerName: 'saidamin',
      customerPhone: '',
      itemCode: 'Adras aboy 3kg paekt',
      itemName: 'Adras aboy 3kg paekt',
      uom: 'Kg',
      warehouse: 'Stores - A',
    );
    const customers = [
      CustomerDirectoryEntry(ref: 'saidamin', name: 'saidamin', phone: ''),
      CustomerDirectoryEntry(ref: 'umar-oboy', name: 'Umar Oboy', phone: ''),
    ];

    final resolved = resolveArchiveBatchDefaultCustomer(option, customers);

    expect(resolved.ref, 'umar-oboy');
  });

  test('batch QR default customer falls back to item option', () {
    const option = CustomerItemOption(
      customerRef: 'fallback-customer',
      customerName: 'Fallback Customer',
      customerPhone: '+998',
      itemCode: 'Adras aboy 3kg paekt',
      itemName: 'Adras aboy 3kg paekt',
      uom: 'Kg',
      warehouse: 'Stores - A',
    );

    final resolved = resolveArchiveBatchDefaultCustomer(
      option,
      const <CustomerDirectoryEntry>[],
    );

    expect(resolved.ref, 'fallback-customer');
    expect(resolved.name, 'Fallback Customer');
  });

  testWidgets('batch QR result submits exact item to preferred customer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = WerkaArchiveBatchQrPayload.tryParse(
      _archiveUrl([
        'ARCHIVE',
        'batch-session-1',
        'Adras aboy 3kg paekt',
        '8',
        '6',
        '07 May 2026 11:04',
      ]),
    )!;
    final api = _FakeArchiveBatchQrLookupApi(
      options: const [
        CustomerItemOption(
          customerRef: 'wrong-customer',
          customerName: 'Wrong Customer',
          customerPhone: '',
          itemCode: 'Adras aboy 4kg paket',
          itemName: 'Adras aboy 4kg paket',
          uom: 'Kg',
          warehouse: 'Stores - A',
        ),
        CustomerItemOption(
          customerRef: 'fallback-customer',
          customerName: 'Fallback Customer',
          customerPhone: '',
          itemCode: 'Adras aboy 3kg paekt',
          itemName: 'Adras aboy 3kg paekt',
          uom: 'Kg',
          warehouse: 'Stores - A',
        ),
      ],
      customers: const [
        CustomerDirectoryEntry(
          ref: 'saidamin',
          name: 'saidamin',
          phone: '',
        ),
        CustomerDirectoryEntry(
          ref: 'umar-oboy',
          name: 'Umar Oboy',
          phone: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        WerkaArchiveBatchQrLookupScreen(
          args: WerkaArchiveBatchQrLookupArgs(payload: payload),
          api: api,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Adras aboy 3kg paekt'), findsWidgets);
    expect(find.text('Umar Oboy'), findsWidgets);
    expect(find.text('Customerga jo‘natish'), findsOneWidget);

    await tester.tap(find.text('Customerga jo‘natish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.createCalls, 1);
    expect(api.lastCustomerRef, 'umar-oboy');
    expect(api.lastItemCode, 'Adras aboy 3kg paekt');
    expect(api.lastQty, 6);
  });
}

String _archiveUrl(List<String> lines) {
  final encoded = base64Url.encode(utf8.encode(lines.join('\n'))).replaceAll(
        '=',
        '',
      );
  return 'https://scan.wspace.sbs/A/$encoded';
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: child,
  );
}

class _FakeArchiveBatchQrLookupApi implements WerkaArchiveBatchQrLookupApi {
  _FakeArchiveBatchQrLookupApi({
    required this.options,
    required this.customers,
  });

  final List<CustomerItemOption> options;
  final List<CustomerDirectoryEntry> customers;
  int createCalls = 0;
  String lastCustomerRef = '';
  String lastItemCode = '';
  double lastQty = 0;

  @override
  Future<List<CustomerItemOption>> customerItemOptions({
    required String query,
    required int limit,
  }) async {
    return options;
  }

  @override
  Future<List<CustomerDirectoryEntry>> customersForItem({
    required String itemCode,
    required String itemName,
    String query = '',
    required int limit,
    int offset = 0,
  }) async {
    return customers;
  }

  @override
  Future<WerkaCustomerIssueRecord> createCustomerIssue({
    required String customerRef,
    required String itemCode,
    required double qty,
  }) async {
    createCalls += 1;
    lastCustomerRef = customerRef;
    lastItemCode = itemCode;
    lastQty = qty;
    return WerkaCustomerIssueRecord(
      entryID: 'DN-TEST-1',
      customerRef: customerRef,
      customerName: customerRef,
      itemCode: itemCode,
      itemName: itemCode,
      uom: 'Kg',
      qty: qty,
      createdLabel: 'now',
    );
  }
}
