import 'dart:async';
import 'dart:convert';
import 'dart:io' hide BytesBuilder;
import 'dart:typed_data';

import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_suppliers_screen.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_user_create_screen.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/widgets/admin_supplier_list_module.dart';
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
    AdminSuppliersScreen.invalidateCache();
  });

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
    AdminSuppliersScreen.invalidateCache();
  });

  testWidgets('admin users list refreshes after custom role user create',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final client = _AdminUsersHttpClient();

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(useMaterial3: true),
          locale: const Locale('uz'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AppRoutes.adminSuppliers: (_) => const AdminSuppliersScreen(),
            AppRoutes.adminUserCreate: (_) => const AdminUserCreateScreen(),
          },
          home: const AdminSuppliersScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Userlar topilmadi'), findsOneWidget);

      navigatorKey.currentState!.pushNamed(AppRoutes.adminUserCreate);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Omborchi').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item yaratuvchi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'chichqoq');
      await tester.enterText(find.byType(TextField).at(1), '998901234567');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Foydalanuvchi saqlash'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'chichqoq',
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AdminSupplierListModule),
          matching: find.text('chichqoq'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Item yaratuvchi'), findsOneWidget);
      expect(find.textContaining('Customer'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }, createHttpClient: (_) => client);
  });
}

class _AdminUsersHttpClient implements HttpClient {
  bool createdCustomer = false;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final key =
        '$method ${url.path}${url.query.isEmpty ? '' : '?${url.query}'}';

    Object body;
    var statusCode = HttpStatus.ok;
    switch (key) {
      case 'GET /v1/mobile/admin/settings':
        body = const {
          'werka_name': '',
          'werka_phone': '',
          'werka_code': 'WERKA-1',
        };
      case 'GET /v1/mobile/admin/suppliers/list?limit=50':
        body = const [];
      case 'GET /v1/mobile/admin/customers/list?limit=50':
        body = createdCustomer
            ? const [
                {
                  'ref': 'CUS-1',
                  'name': 'chichqoq',
                  'phone': '998901234567',
                },
              ]
            : const [];
      case 'GET /v1/mobile/admin/roles':
        body = const [
          {
            'id': 'item_creator',
            'label': 'Item yaratuvchi',
            'capability_codes': ['catalog.item.read', 'catalog.item.create'],
            'system': false,
          },
        ];
      case 'GET /v1/mobile/admin/role-assignments':
        body = createdCustomer
            ? const [
                {
                  'principal_role': 'customer',
                  'principal_ref': 'CUS-1',
                  'role_id': 'item_creator',
                },
              ]
            : const [];
      case 'POST /v1/mobile/admin/customers':
        createdCustomer = true;
        body = const {
          'ref': 'CUS-1',
          'name': 'chichqoq',
          'phone': '998901234567',
        };
      case 'PUT /v1/mobile/admin/role-assignments':
        body = const {
          'principal_role': 'customer',
          'principal_ref': 'CUS-1',
          'role_id': 'item_creator',
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
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({required this.response});

  final _FakeHttpClientResponse response;
  final BytesBuilder _body = BytesBuilder();

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
  void writeln([Object? object = '']) {
    write(object);
    write('\n');
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    add([charCode]);
  }

  @override
  Future<HttpClientResponse> get done => close();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({
    required String body,
    required this.statusCode,
  }) : _bytes = utf8.encode(body);

  final List<int> _bytes;

  @override
  final int statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  String get reasonPhrase => '';

  @override
  bool get persistentConnection => false;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      throw UnsupportedError('redirect');

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
  String? value(String name) => _values[name]?.join(',');

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
