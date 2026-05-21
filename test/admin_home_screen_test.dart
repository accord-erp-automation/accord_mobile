import 'dart:io';

import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/core/theme/app_theme.dart';
import 'package:erpnext_stock_mobile/src/core/theme/theme_controller.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_home_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  testWidgets('custom catalog role opens admin home without summary request',
      (tester) async {
    final seenRequests = <String>[];
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.customer,
      displayName: 'Custom operator',
      legalName: '',
      ref: 'custom',
      phone: '',
      avatarUrl: '',
      capabilities: [
        'catalog.item.read',
        'catalog.item.create',
        'gscale.print',
        'rps.batch.manage',
      ],
    );

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppThemeVariant.earthy),
          locale: const Locale('uz'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item qo‘shish'), findsOneWidget);
      expect(find.text('GScale'), findsOneWidget);
      expect(find.text('Jami users'), findsNothing);
      expect(seenRequests, isEmpty);
    }, createHttpClient: (_) => _RecordingHttpClient(seenRequests));
  });
}

class _RecordingHttpClient extends Fake implements HttpClient {
  _RecordingHttpClient(this.seenRequests);

  final List<String> seenRequests;

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    seenRequests.add('GET ${url.path}');
    throw UnsupportedError('unexpected HTTP request: $url');
  }
}
