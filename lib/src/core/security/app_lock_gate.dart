import 'device_permissions_bootstrap.dart';
import '../widgets/pin_pad.dart';
import 'security_controller.dart';
import 'package:flutter/material.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DevicePermissionsBootstrap.instance.runOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SecurityController.instance,
      builder: (context, _) {
        final locked = SecurityController.instance.locked;
        if (!locked) {
          _biometricAttempted = false;
          return widget.child;
        }

        if (!_biometricAttempted &&
            SecurityController.instance.biometricEnabledForCurrentUser) {
          _biometricAttempted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SecurityController.instance.unlockWithBiometric();
          });
        }

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: TickerMode(
                  enabled: !locked,
                  child: widget.child,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            const Positioned.fill(
              child: _PinUnlockOverlay(),
            ),
          ],
        );
      },
    );
  }
}

class _PinUnlockOverlay extends StatefulWidget {
  const _PinUnlockOverlay();

  @override
  State<_PinUnlockOverlay> createState() => _PinUnlockOverlayState();
}

class _PinUnlockOverlayState extends State<_PinUnlockOverlay> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _unlocking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _resetPinField({String? error}) {
    _pinController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    setState(() {
      _error = error;
    });
  }

  Future<void> _unlock() async {
    setState(() {
      _unlocking = true;
      _error = null;
    });
    try {
      final ok = await SecurityController.instance
          .unlockWithPin(_pinController.text.trim());
      if (!ok && mounted) {
        _resetPinField(error: 'PIN noto‘g‘ri');
      }
      if (ok) {
        _pinController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometric() async {
    setState(() {
      _unlocking = true;
      _error = null;
    });
    try {
      final ok = await SecurityController.instance.unlockWithBiometric();
      if (!ok && mounted) {
        setState(() {
          _error = 'Biometrik tasdiq bajarilmadi';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, 0.12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'App qulfi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4 xonali PIN kiriting',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 22),
                    PinCodeEditor(
                      controller: _pinController,
                      onAction: _unlock,
                      actionLabel: _unlocking ? 'Tekshirilmoqda...' : 'Ochish',
                      actionIcon: Icons.arrow_forward_rounded,
                      errorText: _error,
                      busy: _unlocking,
                    ),
                    if (SecurityController
                        .instance.biometricEnabledForCurrentUser) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _unlocking ? null : _unlockWithBiometric,
                          child: const Text('Face ID / Fingerprint'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
