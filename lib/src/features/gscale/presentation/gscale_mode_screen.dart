import '../gscale_mobile_app.dart';
import '../../../core/widgets/feedback/logout_prompt.dart';
import 'package:flutter/material.dart';

class GScaleModeScreen extends StatelessWidget {
  const GScaleModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GScaleMobileApp(
      onExitMode: () async {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        await showLogoutPrompt(context);
      },
    );
  }
}
