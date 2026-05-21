import 'dart:convert';

import '../runtime/app_runtime_reset.dart';
import '../../../features/shared/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();
  static const String _tokenKey = 'app_session_token';
  static const String _profileKey = 'app_session_profile';

  String? token;
  SessionProfile? profile;
  WerkaHomeData? werkaHomeBootstrap;

  bool get isLoggedIn => token != null && profile != null;
  String get homeRoute {
    if (!isLoggedIn) {
      return '/';
    }
    final profile = this.profile!;
    if (profile.hasCapability('admin.access')) {
      return '/admin-home';
    }
    if (profile.hasCapability('werka.access')) {
      return '/werka-home';
    }
    if (profile.hasCapability('supplier.access')) {
      return '/supplier-home';
    }
    if (profile.hasCapability('customer.access')) {
      return '/customer-home';
    }
    if (profile.hasAnyCapability(const [
      'gscale.print',
      'gscale.catalog.read',
      'rps.batch.manage',
    ])) {
      return '/gscale-mode';
    }
    if (profile.hasAnyCapability(const [
      'admin.access',
      'role.capability.read',
      'role.capability.manage',
      'admin.settings.read',
      'admin.settings.manage',
      'catalog.item.read',
      'catalog.item.create',
      'catalog.item_group.read',
      'catalog.item_group.manage',
      'catalog.item.bulk_move',
      'party.supplier.read',
      'party.supplier.manage',
      'party.supplier.item.assign',
      'party.supplier.code.manage',
      'party.customer.read',
      'party.customer.manage',
      'party.customer.item.assign',
      'party.customer.code.manage',
      'admin.activity.read',
      'werka.code.manage',
    ])) {
      return '/admin-home';
    }
    switch (profile.role) {
      case UserRole.supplier:
        return '/supplier-home';
      case UserRole.werka:
        return '/werka-home';
      case UserRole.customer:
        return '/customer-home';
      case UserRole.admin:
        return '/admin-home';
    }
  }

  bool can(String capability) {
    return profile?.hasCapability(capability) ?? false;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedProfile = prefs.getString(_profileKey);
    if (storedToken == null ||
        storedToken.isEmpty ||
        storedProfile == null ||
        storedProfile.isEmpty) {
      return;
    }
    token = storedToken;
    profile = SessionProfile.fromJson(
      jsonDecode(storedProfile) as Map<String, dynamic>,
    );
  }

  Future<void> setSession({
    required String token,
    required SessionProfile profile,
    WerkaHomeData? werkaHomeBootstrap,
  }) async {
    final previousProfile = this.profile;
    final previousKey = previousProfile == null
        ? ''
        : '${previousProfile.role.name}:${previousProfile.ref}';
    final nextKey = '${profile.role.name}:${profile.ref}';
    if (previousKey.isNotEmpty && previousKey != nextKey) {
      await AppRuntimeReset.instance.resetSessionScopedState(
        previousProfile: previousProfile,
      );
    }
    this.token = token;
    this.profile = profile;
    this.werkaHomeBootstrap = werkaHomeBootstrap;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final previousProfile = profile;
    token = null;
    profile = null;
    werkaHomeBootstrap = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_profileKey);
    await AppRuntimeReset.instance.resetSessionScopedState(
      previousProfile: previousProfile,
    );
  }

  Future<void> updateProfile(SessionProfile nextProfile) async {
    profile = nextProfile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(nextProfile.toJson()));
  }

  WerkaHomeData? consumeWerkaHomeBootstrap() {
    final value = werkaHomeBootstrap;
    werkaHomeBootstrap = null;
    return value;
  }
}
