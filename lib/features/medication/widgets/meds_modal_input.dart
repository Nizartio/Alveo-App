import 'package:flutter/material.dart';
import '../pages/medication_plan_page.dart';

class MedsModalInput extends StatelessWidget {
  const MedsModalInput({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SizedBox(
            height: screenHeight * 0.9,
            child: const MedicationPlanPage(isModal: true),
          ),
        ),
      ),
    );
  }
}
