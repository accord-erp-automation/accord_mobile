import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class WerkaSuccessScreen extends StatelessWidget {
  const WerkaSuccessScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qabul qilindi',
      subtitle:
          'Receipt submit bo‘lganidan keyin supplierga ham status qaytadi.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: SoftCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 72, color: Color(0xFFFFFFFF)),
                  const SizedBox(height: 16),
                  Text(record.id, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      '${record.acceptedQty.toStringAsFixed(2)} ${record.uom} qabul qilindi'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.werkaHome,
                (route) => route.isFirst,
              ),
              child: const Text('Pending listga qaytish'),
            ),
          ),
        ],
      ),
    );
  }
}
