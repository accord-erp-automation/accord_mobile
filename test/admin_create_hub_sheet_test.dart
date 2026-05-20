import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/widgets/admin_create_hub_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {List<NavigatorObserver> observers = const []}) {
  return MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    navigatorObservers: observers,
    onGenerateRoute: (settings) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text(settings.name ?? 'root')),
      );
    },
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('admin create hub groups user creation into one action',
      (tester) async {
    final observer = _RouteObserver();

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showAdminCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
        observers: [observer],
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Foydalanuvchi qo‘shish'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-hub-user-create')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('admin-hub-supplier-create')), findsNothing);
    expect(
        find.byKey(const ValueKey('admin-hub-customer-create')), findsNothing);
    expect(find.byKey(const ValueKey('admin-hub-werka-create')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-hub-user-create')));
    await tester.pumpAndSettle();

    expect(observer.pushedRouteNames, contains(AppRoutes.adminUserCreate));
  });
}

class _RouteObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
