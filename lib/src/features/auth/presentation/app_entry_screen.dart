import '../../../core/api/mobile_api.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import 'login_screen.dart';
import 'package:flutter/material.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  bool _booting = true;
  bool _showLogin = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!AppSession.instance.isLoggedIn) {
      if (!mounted) {
        return;
      }
      setState(() {
        _booting = false;
        _showLogin = true;
      });
      return;
    }

    try {
      await MobileApi.instance.profile().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Keep existing local session on transient network/backend failures.
    }

    if (!mounted) {
      return;
    }

    if (!AppSession.instance.isLoggedIn) {
      setState(() {
        _booting = false;
        _showLogin = true;
      });
      return;
    }

    _navigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppSession.instance.homeRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return const LoginScreen();
    }

    return AppShell(
      title: 'Accord',
      subtitle: '',
      child: Center(
        child: _navigated
            ? const SizedBox.shrink()
            : _booting
                ? const CircularProgressIndicator.adaptive()
                : const SizedBox.shrink(),
      ),
    );
  }
}
