import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shows a reusable, themed confirmation bottom sheet when a medication plan
/// is successfully saved. The sheet handles its own entrance and calls
/// [onContinue] after the user taps the primary CTA.
Future<void> showMedPlanSavedBottomSheet(
  BuildContext context, {
  required int xpAmount,
  required VoidCallback onContinue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.black54,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: _MedPlanSavedSheetContent(
          xpAmount: xpAmount,
          onContinue: () {
            // Close the sheet first, then invoke the caller callback which
            // is expected to navigate (using the outer context).
            Navigator.of(sheetContext).pop();
            onContinue();
          },
        ),
      );
    },
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
  );
}

class _MedPlanSavedSheetContent extends StatefulWidget {
  const _MedPlanSavedSheetContent({
    required this.xpAmount,
    required this.onContinue,
  });

  final int xpAmount;
  final VoidCallback onContinue;

  @override
  State<_MedPlanSavedSheetContent> createState() =>
      _MedPlanSavedSheetContentState();
}

class _MedPlanSavedSheetContentState extends State<_MedPlanSavedSheetContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final accent = AppColors.primaryLight;

    final gradient = LinearGradient(
      colors: [primary, accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    );
                  },
                  child: _buildMascot(context, gradient),
                ),
                const SizedBox(height: 18),
                Text(
                  'Progress kamu telah disimpan!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Perjalanan penyembuhanmu akan dimulai. Tetap konsisten dan jaga terus streak-mu!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _buildXpChip(context, widget.xpAmount, gradient),
                const SizedBox(height: 18),
                const SizedBox(height: 8),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.loginShadow,
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: widget.onContinue,
                        child: Center(
                          child: Text(
                            'Lanjut ke Dashboard',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascot(BuildContext context, Gradient gradient) {
    return Semantics(
      label: 'Mascot illustration',
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'lib/assets/maskot-rmv.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.emoji_emotions_outlined,
                  size: 56,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXpChip(BuildContext context, int xp, Gradient gradient) {
    return Semantics(
      label: 'Earned $xp XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              '+$xp XP Earned 🎉',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
