import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/session/state/app_session.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  test('route guard stays open before a session is loaded', () {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;

    expect(AppRouter.canOpenRoute(AppRoutes.werkaArchive), isTrue);
  });

  test('route access follows session capabilities', () {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.werka,
      displayName: 'Scale operator',
      legalName: '',
      ref: 'werka',
      phone: '',
      avatarUrl: '',
      capabilities: ['gscale.print', 'rps.batch.manage'],
    );

    expect(AppRouter.canOpenRoute(AppRoutes.gscaleMode), isTrue);
    expect(AppRouter.canOpenRoute(AppRoutes.werkaHome), isFalse);
    expect(AppRouter.canOpenRoute(AppRoutes.adminRoles), isFalse);
  });

  test('admin role route only opens with role capability', () {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.supplier,
      displayName: 'Role manager',
      legalName: '',
      ref: 'SUP-001',
      phone: '',
      avatarUrl: '',
      capabilities: ['role.capability.read'],
    );

    expect(AppRouter.canOpenRoute(AppRoutes.adminRoles), isTrue);
    expect(AppRouter.canOpenRoute(AppRoutes.adminSettings), isFalse);
    expect(AppRouter.canOpenRoute(AppRoutes.supplierHome), isFalse);
  });

  test('production map route opens with production map capability', () {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.werka,
      displayName: 'Production mapper',
      legalName: '',
      ref: 'werka',
      phone: '',
      avatarUrl: '',
      capabilities: ['production.map.manage'],
    );

    expect(AppRouter.canOpenRoute(AppRoutes.adminProductionMapTest), isTrue);
    expect(AppRouter.canOpenRoute(AppRoutes.adminRoles), isFalse);
  });

  test('production map route stays open for admin access', () {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.admin,
      displayName: 'Admin',
      legalName: '',
      ref: 'admin',
      phone: '',
      avatarUrl: '',
      capabilities: ['admin.access'],
    );

    expect(AppRouter.canOpenRoute(AppRoutes.adminProductionMapTest), isTrue);
  });
}
