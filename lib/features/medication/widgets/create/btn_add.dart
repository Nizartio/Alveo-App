import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BtnAdd extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const BtnAdd({super.key, required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Obat Lain'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
