import 'package:flutter/material.dart';

class MedicationPlanPage extends StatefulWidget {
  const MedicationPlanPage({super.key});

  @override
  State<MedicationPlanPage> createState() => _MedicationPlanPageState();
}

class _MedicationPlanPageState extends State<MedicationPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _q1 = TextEditingController();
  final _q2 = TextEditingController();
  final _q3 = TextEditingController();
  final _frequencyCountController = TextEditingController();
  final _frequencyDaysController = TextEditingController();

  DateTime? _diseaseStartDate;

  @override
  void dispose() {
    _q1.dispose();
    _q2.dispose();
    _q3.dispose();
    _frequencyCountController.dispose();
    _frequencyDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickDiseaseStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _diseaseStartDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _diseaseStartDate = picked;
      _q1.text = MaterialLocalizations.of(context).formatMediumDate(picked);
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Data berhasil tersimpan'),
            content: const Text(
              'Medication plan Anda sudah disimpan. Silakan login untuk melanjutkan.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF2EEFF), Color(0xFFF8FAFF)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Ayo kita cek!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ceritakan kepada kami masalah yang Anda alami agar kami dapat membantu Anda mendapatkan bantuan yang paling tepat.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _QuestionCard(
                        icon: Icons.air_rounded,
                        title: 'Sudah berapa lama Anda menderita penyakit ini?',
                        controller: _q1,
                        readOnly: true,
                        onTap: _pickDiseaseStartDate,
                        hintText: _diseaseStartDate == null
                            ? 'Pilih tanggal mulai penyakit'
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_diseaseStartDate!),
                      ),
                      const SizedBox(height: 14),
                      _QuestionCard(
                        icon: Icons.medical_services_outlined,
                        title:
                            'Tolong sebutkan obat-obatan yang sedang Anda konsumsi.',
                        controller: _q2,
                        items: const [
                          'Isoniazid',
                          'Rifampicin',
                          'Pyrazinamide',
                          'Ethambutol',
                          'Streptomycin',
                        ],
                      ),
                      const SizedBox(height: 14),
                      _QuestionCard(
                        icon: Icons.schedule_rounded,
                        title: 'Seberapa sering Anda minum obat ini?',
                        controller: _q3,
                        customChild: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _frequencyCountController,
                                keyboardType: TextInputType.number,
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'Wajib diisi'
                                    : int.tryParse(v!.trim()) == null
                                    ? 'Angka tidak valid'
                                    : int.parse(v.trim()) <= 0
                                    ? 'Harus lebih dari 0'
                                    : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF1F4FB),
                                  hintText: '2',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'x per',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _frequencyDaysController,
                                keyboardType: TextInputType.number,
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'Wajib diisi'
                                    : int.tryParse(v!.trim()) == null
                                    ? 'Angka tidak valid'
                                    : int.parse(v.trim()) <= 0
                                    ? 'Harus lebih dari 0'
                                    : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF1F4FB),
                                  hintText: '1 day',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A57E6), Color(0xFF8A75F0)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x336A57E6),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: _submit,
                              child: const Center(
                                child: Text(
                                  'Periksa Resiko Saya →',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.icon,
    required this.title,
    required this.controller,
    this.items,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.customChild,
  });

  final IconData icon;
  final String title;
  final TextEditingController controller;
  final List<String>? items;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6A57E6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (customChild != null)
            customChild!
          else if (items == null)
            TextFormField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F4FB),
                hintText: hintText ?? 'Tulis di sini',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: controller.text.isNotEmpty ? controller.text : null,
              items: items!
                  .map(
                    (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                  )
                  .toList(),
              onChanged: (v) {
                controller.text = v ?? '';
              },
              validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F4FB),
                hintText: 'Pilih obat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
