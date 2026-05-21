import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_roles_screen.dart';
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

  testWidgets('admin role screen loads roles and saves a custom role',
      (tester) async {
    final seenRequests = <String>[];
    final seenBodies = <String>[];
    final client = _AdminRolesHttpClient(seenRequests, seenBodies);

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
          home: const AdminRolesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(seenRequests, contains('GET /v1/mobile/admin/capabilities'));
      expect(seenRequests, contains('GET /v1/mobile/admin/roles'));
      expect(seenRequests, contains('GET /v1/mobile/admin/role-assignments'));
      expect(seenRequests, contains('GET /v1/mobile/admin/settings'));
      expect(seenRequests,
          contains('GET /v1/mobile/admin/suppliers/list?limit=100'));
      expect(seenRequests,
          contains('GET /v1/mobile/admin/customers/list?limit=100'));
      expect(find.text('Rollar'), findsWidgets);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.textContaining('Role huquqlarini ko‘rish'), findsNothing);
      expect(find.textContaining('Role capability catalog read'), findsNothing);
      expect(find.text('Scale operator'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('admin-role-card-admin')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Role huquqlarini ko‘rish'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('admin-role-details-scale_operator')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Role huquqlarini ko‘rish'), findsNothing);
      expect(find.text('GScale chop etish'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Yangi role'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Catalog reader');
      await tester.pump();
      await tester.tap(find.text('Katalog mahsulotlarini ko‘rish'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
      await tester.pumpAndSettle();

      expect(seenRequests, contains('PUT /v1/mobile/admin/roles'));
      expect(seenBodies.last, contains('"id":"catalog_reader"'));
      expect(seenBodies.last, contains('"base_role":"werka"'));
      expect(seenBodies.last, contains('"catalog.item.read"'));
      expect(find.text('Role saqlandi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(tester.takeException(), isNull);
    }, createHttpClient: (_) => client);
  });

  testWidgets('admin role assignments save selected user role', (tester) async {
    final seenRequests = <String>[];
    final seenBodies = <String>[];
    final client = _AdminRolesHttpClient(seenRequests, seenBodies);

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
          home: const AdminRolesScreen(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Biriktirish'));
      await tester.pumpAndSettle();

      expect(find.text('Werka'), findsOneWidget);
      expect(find.text('Scale operator'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Tanlash').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scale operator').last);
      await tester.pumpAndSettle();

      expect(seenRequests, contains('PUT /v1/mobile/admin/role-assignments'));
      expect(seenBodies.last, contains('"principal_role":"werka"'));
      expect(seenBodies.last, contains('"principal_ref":"werka"'));
      expect(seenBodies.last, contains('"role_id":"scale_operator"'));
      expect(find.text('Role biriktirildi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(tester.takeException(), isNull);
    }, createHttpClient: (_) => client);
  });
}

class _AdminRolesHttpClient implements HttpClient {
  _AdminRolesHttpClient(this.seenRequests, this.seenBodies);

  final List<String> seenRequests;
  final List<String> seenBodies;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final key =
        '$method ${url.path}${url.query.isEmpty ? '' : '?${url.query}'}';
    seenRequests.add(key);

    Object body;
    var statusCode = HttpStatus.ok;
    switch (key) {
      case 'GET /v1/mobile/admin/capabilities':
        body = const [
          {
            'code': 'admin.access',
            'label': 'Admin panel',
            'default_roles': ['admin'],
          },
          {
            'code': 'role.capability.read',
            'label': 'Role capability catalog read',
            'default_roles': ['admin'],
          },
          {
            'code': 'gscale.print',
            'label': 'GScale chop etish',
            'default_roles': ['admin', 'werka'],
          },
          {
            'code': 'catalog.item.read',
            'label': 'Catalog item read',
            'default_roles': ['admin'],
          },
        ];
      case 'GET /v1/mobile/admin/roles':
        body = const [
          {
            'id': 'admin',
            'label': 'Admin',
            'base_role': 'admin',
            'capability_codes': ['admin.access', 'role.capability.read'],
            'system': true,
          },
          {
            'id': 'werka',
            'label': 'Werka',
            'base_role': 'werka',
            'capability_codes': ['gscale.print'],
            'system': true,
          },
          {
            'id': 'scale_operator',
            'label': 'Scale operator',
            'base_role': 'werka',
            'capability_codes': ['gscale.print'],
            'system': false,
          },
        ];
      case 'GET /v1/mobile/admin/role-assignments':
        body = const [
          {
            'principal_role': 'werka',
            'principal_ref': 'werka',
            'role_id': 'scale_operator',
          },
        ];
      case 'GET /v1/mobile/admin/settings':
        body = const {
          'werka_name': 'Werka',
          'werka_phone': '+998',
        };
      case 'GET /v1/mobile/admin/suppliers/list?limit=100':
      case 'GET /v1/mobile/admin/suppliers/list?limit=100&offset=0':
        body = const [
          {
            'ref': 'SUP-1',
            'name': 'Supplier',
            'phone': '+9981',
            'code': 'S1',
            'blocked': false,
            'removed': false,
            'assigned_item_codes': [],
            'assigned_item_count': 0,
          },
        ];
      case 'GET /v1/mobile/admin/customers/list?limit=100':
      case 'GET /v1/mobile/admin/customers/list?limit=100&offset=0':
        body = const [
          {
            'ref': 'CUS-1',
            'name': 'Customer',
            'phone': '+9982',
          },
        ];
      case 'PUT /v1/mobile/admin/roles':
        body = const {
          'id': 'catalog_reader',
          'label': 'Catalog reader',
          'base_role': 'werka',
          'capability_codes': ['catalog.item.read'],
          'system': false,
        };
      case 'PUT /v1/mobile/admin/role-assignments':
        body = const {
          'principal_role': 'werka',
          'principal_ref': 'werka',
          'role_id': 'scale_operator',
        };
      default:
        statusCode = HttpStatus.notFound;
        body = {'error': 'Unhandled request: $key'};
    }

    return _FakeHttpClientRequest(
      onClose: (requestBody) {
        if (requestBody.trim().isNotEmpty) {
          seenBodies.add(requestBody);
        }
      },
      response: _FakeHttpClientResponse(
        body: jsonEncode(body),
        statusCode: statusCode,
      ),
    );
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({
    required this.response,
    required this.onClose,
  });

  final _FakeHttpClientResponse response;
  final ValueChanged<String> onClose;
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();
  final Completer<HttpClientResponse> _done = Completer<HttpClientResponse>();
  final StringBuffer _body = StringBuffer();

  @override
  HttpHeaders get headers => _headers;

  @override
  bool persistentConnection = true;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool bufferOutput = true;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<HttpClientResponse> get done => _done.future;

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  void write(Object? object) {
    _body.write(object);
  }

  @override
  void add(List<int> data) {
    _body.write(utf8.decode(data));
  }

  @override
  void writeln([Object? object = '']) {
    _body.writeln(object);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() {
    onClose(_body.toString());
    if (!_done.isCompleted) {
      _done.complete(response);
    }
    return Future<HttpClientResponse>.value(response);
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    if (!_done.isCompleted) {
      _done.completeError(exception ?? Exception('aborted'), stackTrace);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({
    required String body,
    required this.statusCode,
  })  : _headers = _FakeHttpHeaders(),
        super(Stream<List<int>>.fromIterable([utf8.encode(body)]));

  final _FakeHttpHeaders _headers;

  @override
  final int statusCode;

  @override
  int get contentLength => -1;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => '';

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<Socket> detachSocket() {
    return Future<Socket>.error(
      UnsupportedError('detachSocket is not supported in tests'),
    );
  }

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      Future<HttpClientResponse>.value(this);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name, () => <String>[]).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = <String>[value.toString()];
  }

  @override
  List<String>? operator [](String name) => _values[name];

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
