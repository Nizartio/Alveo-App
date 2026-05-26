import 'package:flutter/material.dart';
import '../models/medication_form_model.dart';
import '../pages/meds_create_page.dart';

class MedsModalInput extends StatelessWidget {
  const MedsModalInput({
    super.key,
    this.initialMedication,
    this.userMedicationId,
  });

  final MedicationFormModel? initialMedication;
  final String? userMedicationId;

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
            child: MedsCreatePage(
              initialMedication: initialMedication,
              userMedicationId: userMedicationId,
            ),
          ),
        ),
      ),
    );
  }
}
