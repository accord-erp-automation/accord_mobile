import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/session/state/app_session.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppSession.instance.clear();
  });

  tearDown(() async {
    await AppSession.instance.clear();
  });

  test('session profile stores capabilities from login response', () {
    final profile = SessionProfile.fromJson(const {
      'role': 'werka',
      'display_name': 'Scale operator',
      'ref': 'werka',
      'capabilities': ['gscale.print', 'rps.batch.manage'],
    });

    expect(profile.hasCapability('gscale.print'), isTrue);
    expect(profile.hasCapability('werka.access'), isFalse);
    expect(profile.toJson()['capabilities'], [
      'gscale.print',
      'rps.batch.manage',
    ]);
  });

  test('home route prefers capabilities over base role', () async {
    await AppSession.instance.setSession(
      token: 'token',
      profile: const SessionProfile(
        role: UserRole.werka,
        displayName: 'Scale operator',
        legalName: '',
        ref: 'werka',
        phone: '',
        avatarUrl: '',
        capabilities: ['gscale.print', 'rps.batch.manage'],
      ),
    );

    expect(AppSession.instance.homeRoute, AppRoutes.gscaleMode);
    expect(AppSession.instance.can('rps.batch.manage'), isTrue);
    expect(AppSession.instance.can('werka.access'), isFalse);
  });

  test('workspace access wins over shared gscale capabilities', () async {
    await AppSession.instance.setSession(
      token: 'token',
      profile: const SessionProfile(
        role: UserRole.admin,
        displayName: 'Admin',
        legalName: '',
        ref: 'admin',
        phone: '',
        avatarUrl: '',
        capabilities: ['admin.access', 'gscale.print'],
      ),
    );

    expect(AppSession.instance.homeRoute, AppRoutes.adminHome);
  });

  test('empty capability profile falls back to default role access', () {
    const profile = SessionProfile(
      role: UserRole.werka,
      displayName: 'Werka',
      legalName: '',
      ref: 'werka',
      phone: '',
      avatarUrl: '',
    );

    expect(profile.hasCapability('werka.access'), isTrue);
    expect(profile.hasCapability('gscale.print'), isTrue);
  });
}
