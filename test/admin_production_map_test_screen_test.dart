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

    await tester.tap(find.text('Location'));
    await tester.pumpAndSettle();
    expect(find.text('Yangi location'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yangi location'));
    await tester.pumpAndSettle();
    expect(find.text('Node sozlash'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Rezka location');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Rezka location'), findsOneWidget);
  });

  testWidgets('production map page edits product and reorders nodes',
      (tester) async {
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

    await tester.tap(find.text('HOTLUNCH'));
    await tester.pumpAndSettle();
    expect(find.text('Map sozlash'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'OPP');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(find.text('OPP'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    final dragStart = tester.getCenter(find.text('Rezkaga yuborish'));
    final gesture = await tester.startGesture(dragStart);
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    final rezkaTop = tester.getTopLeft(find.text('Rezkaga yuborish')).dy;
    final cppTop = tester.getTopLeft(find.text('CPP hisob')).dy;
    expect(rezkaTop, lessThan(cppTop));
  });
}
