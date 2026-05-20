import 'dart:async';
import 'dart:convert';
import 'dart:io' hide BytesBuilder;
import 'dart:typed_data';

import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_user_create_screen.dart';
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

  testWidgets('admin user create screen creates customers from one tabbed page',
      (tester) async {
    final seenRequests = <String>[];
    final client = _AdminUserCreateHttpClient(seenRequests);

    await HttpOverrides.runZoned(() async {
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
          home: const AdminUserCreateScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Omborchi'), findsOneWidget);
      expect(find.text('Haridor'), findsOneWidget);
      expect(find.text('Ta’minotchi'), findsOneWidget);
      expect(seenRequests, contains('GET /v1/mobile/admin/settings'));

      await tester.tap(find.text('Haridor'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Ali Market');
      await tester.enterText(find.byType(TextField).at(1), '+998900001111');
      await tester.tap(find.widgetWithText(FilledButton, 'Haridor qo‘shish'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(seenRequests, contains('POST /v1/mobile/admin/customers'));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();
    }, createHttpClient: (_) => client);
  });
}

class _AdminUserCreateHttpClient implements HttpClient {
  _AdminUserCreateHttpClient(this.seenRequests);

  final List<String> seenRequests;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final key =
        '$method ${url.path}${url.query.isEmpty ? '' : '?${url.query}'}';
    seenRequests.add(key);

    Object body;
    var statusCode = HttpStatus.ok;
    switch (key) {
      case 'GET /v1/mobile/admin/settings':
        body = const {
          'werka_name': 'Werka',
          'werka_phone': '+998',
          'werka_code': 'WERKA-1',
        };
      case 'POST /v1/mobile/admin/customers':
        body = const {
          'ref': 'CUS-1',
          'name': 'Ali Market',
          'phone': '+998900001111',
        };
      default:
        statusCode = HttpStatus.notFound;
        body = {'error': 'Unhandled request: $key'};
    }

    return _FakeHttpClientRequest(
      response: _FakeHttpClientResponse(
        body: jsonEncode(body),
        statusCode: statusCode,
      ),
    );
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({
    required this.response,
  });

  final _FakeHttpClientResponse response;
  final BytesBuilder _body = BytesBuilder();

  @override
  void write(Object? object) {
    if (object != null) {
      _body.add(utf8.encode(object.toString()));
    }
  }

  @override
  void add(List<int> data) {
    _body.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      _body.add(data);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    _body.clear();
    return response;
  }

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({
    required this.body,
    required this.statusCode,
  });

  final String body;

  @override
  final int statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([utf8.encode(body)]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get contentLength => utf8.encode(body).length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
