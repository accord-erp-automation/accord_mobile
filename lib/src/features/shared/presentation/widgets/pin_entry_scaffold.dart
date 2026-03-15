import '../../../../core/widgets/pin_pad.dart';
import '../../../../core/widgets/app_shell.dart';
import 'package:flutter/material.dart';

class PinEntryScaffold extends StatelessWidget {
  const PinEntryScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.actionLabel,
    required this.onAction,
    this.errorText,
    this.autofocus = true,
    this.busy = false,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String actionLabel;
  final VoidCallback onAction;
  final String? errorText;
  final bool autofocus;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: title,
      subtitle: subtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card.filled(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4 xonali PIN kiriting',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  PinCodeEditor(
                    controller: controller,
                    onAction: onAction,
                    actionLabel: busy ? 'Tekshirilmoqda...' : actionLabel,
                    actionIcon: actionLabel == 'Saqlash'
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    errorText: errorText,
                    busy: busy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
