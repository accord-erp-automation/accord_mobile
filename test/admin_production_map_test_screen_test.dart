import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_test_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.admin,
      displayName: 'Admin',
      legalName: 'Admin',
      ref: 'ADMIN-001',
      phone: '',
      avatarUrl: '',
    );
  });

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  testWidgets('production map page can add and edit a location node',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Location');
    await tester.pumpAndSettle();
    expect(find.text('Yangi location'), findsOneWidget);

    await tester.ensureVisible(find.text('Yangi location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yangi location'));
    await tester.pumpAndSettle();
    expect(find.text('Node sozlash'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Rezka location');
    await tester.tap(find.text('Saqlash').last);
    await tester.pumpAndSettle();

    expect(find.text('Rezka location'), findsOneWidget);
  });

  testWidgets('production map sheet closes when tapping the dimmed barrier',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katta partiyami?'));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsOneWidget);

    await tester.tapAt(const Offset(200, 90));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsNothing);
  });

  testWidgets('production map page shows default condition flow',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Katta partiyami?'), findsOneWidget);
    expect(find.text('Katta partiya'), findsNothing);
    expect(find.text('Rezkaga yuborish'), findsNothing);
    expect(
      find.byKey(const ValueKey('production-map-branch-add-true')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('production-map-branch-add-false')),
      findsWidgets,
    );
  });

  testWidgets('production map formula field shows human variable editor',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CPP hisob'));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsOneWidget);
    expect(find.text('Buyurtma miqdori * 1.08'), findsOneWidget);
    expect(find.text('order_qty * 1.08'), findsNothing);

    await tester.tap(find.text('Buyurtma miqdori * 1.08'));
    await tester.pumpAndSettle();

    expect(find.text('Formula yozish'), findsOneWidget);
    expect(find.text('Buyurtma miqdori'), findsWidgets);

    await tester.enterText(find.byType(TextField).last, 'buyu');
    await tester.pump();
    final formulaField = tester.widget<TextField>(find.byType(TextField).last);
    final formulaSpan = formulaField.controller!.buildTextSpan(
      context: tester.element(find.byType(TextField).last),
      style: const TextStyle(),
      withComposing: false,
    );
    expect(formulaSpan.toPlainText(), 'buyurtma miqdori');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Formula yozish'), findsOneWidget);
    expect(formulaField.focusNode?.hasFocus, isTrue);
    expect(formulaField.controller!.text, 'Buyurtma miqdori ');

    await tester.tap(find.text('Saqlash').last);
    await tester.pumpAndSettle();

    expect(find.text('Buyurtma miqdori'), findsWidgets);
  });

  testWidgets('production map edge delete button removes an outgoing edge',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Location');
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(
      const ValueKey('production-map-edge-delete-task_1-end-'),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(deleteButton, findsNothing);
  });

  testWidgets('production map branch adds condition with open branch handles',
      (tester) async {
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Condition');
    await tester.pumpAndSettle();

    expect(find.text('Shart'), findsOneWidget);
    expect(find.text('Shunda yo‘liga qo‘shish'), findsNothing);
    expect(find.text('Bajariladigan ish'), findsNothing);
    expect(find.text('Boshqa holatdagi ish'), findsNothing);
    expect(
      find.byKey(const ValueKey('production-map-branch-add-true')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('production-map-branch-add-false')),
      findsWidgets,
    );
  });
}

Future<void> _usePhoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapMapTool(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.tune_rounded), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
}
