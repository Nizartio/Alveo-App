import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/medication_service.dart';
import '../../stats/services/stats_service.dart';

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key});

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  final _medicationService = MedicationService();
  final _statsService = StatsService();
  List<Map<String, dynamic>> _historyEntries = [];
  List<Map<String, dynamic>> _medicationOptions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _adherencePercentage = 0;
  int _dayStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final results = await Future.wait<dynamic>([
        _medicationService.fetchMedicationHistory(days: 30),
        _statsService.calculateWeeklyAdherence(),
        _medicationService.fetchActiveMedications(),
        _medicationService.fetchCurrentStreak(),
      ]);

      if (mounted) {
        setState(() {
          _historyEntries = List<Map<String, dynamic>>.from(results[0] as List);
          _adherencePercentage = (results[1] as num).toDouble();
          _medicationOptions = List<Map<String, dynamic>>.from(
            results[2] as List,
          );
          _dayStreak = (results[3] as int?) ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan memuat riwayat: $e')));
      }
    }
  }

  DateTime? _parseDateValue(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay _parseTimeValue(String? timeStr) {
    try {
      final parts = (timeStr ?? '').split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  Map<String, dynamic>? _extractMedicationData(Map<String, dynamic> entry) {
    final relation = entry['user_medications'];
    if (relation is Map<String, dynamic>) {
      return relation;
    }
    if (relation is List && relation.isNotEmpty && relation.first is Map) {
      return Map<String, dynamic>.from(relation.first as Map);
    }
    return null;
  }

  String _getMedicationName(Map<String, dynamic> entry) {
    final medication = _extractMedicationData(entry);
    final medicine = medication?['medicines'];
    if (medicine is Map<String, dynamic>) {
      final name = medicine['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    final fallback = entry['medicine_name']?.toString();
    return (fallback != null && fallback.isNotEmpty) ? fallback : 'Obat';
  }

  String _getMedicationSubtitle(Map<String, dynamic> entry) {
    final medication = _extractMedicationData(entry);
    final dosage =
        medication?['dosage']?.toString() ?? entry['dosage']?.toString() ?? '0';
    final frequency =
        medication?['frequency_per_day']?.toString() ??
        entry['frequency_per_day']?.toString() ??
        '1';
    return '$dosage • ${frequency}x/hari';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'taken':
        return 'Diminum';
      case 'missed':
        return 'Terlewat';
      default:
        return 'Jadwal';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.close_rounded;
      default:
        return Icons.schedule;
    }
  }

  String _medicationOptionLabel(Map<String, dynamic> medication) {
    final medicine = medication['medicines'];
    final medicineName = medicine is Map<String, dynamic>
        ? medicine['name']?.toString() ?? 'Obat'
        : 'Obat';
    final dosage = medication['dosage']?.toString() ?? '0';
    return '$medicineName • $dosage';
  }

  Future<void> _saveHistoryEntry({Map<String, dynamic>? entry}) async {
    if (_medicationOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada obat untuk dipilih')),
      );
      return;
    }

    final initialMedicationId =
        entry?['user_medication_id']?.toString() ??
        _medicationOptions.first['id']?.toString();
    final initialDate =
        _parseDateValue(entry?['date']?.toString()) ?? DateTime.now();
    final initialTime = _parseTimeValue(entry?['scheduled_time']?.toString());
    final initialStatus = entry?['status']?.toString() ?? 'taken';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        String selectedMedicationId = initialMedicationId ?? '';
        DateTime selectedDate = initialDate;
        TimeOfDay selectedTime = initialTime;
        String selectedStatus = initialStatus == 'missed' ? 'missed' : 'taken';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setDialogState(() => selectedDate = date);
              }
            }

            Future<void> pickTime() async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (time != null) {
                setDialogState(() => selectedTime = time);
              }
            }

            return AlertDialog(
              title: Text(entry == null ? 'Tambah Riwayat' : 'Ubah Riwayat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedMedicationId.isEmpty
                          ? null
                          : selectedMedicationId,
                      decoration: const InputDecoration(labelText: 'Obat'),
                      items: _medicationOptions
                          .map(
                            (medication) => DropdownMenuItem<String>(
                              value: medication['id']?.toString(),
                              child: Text(_medicationOptionLabel(medication)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedMedicationId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(selectedDate),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Waktu'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedTime.format(context)),
                            const Icon(Icons.access_time, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'taken',
                          child: Text('Diminum'),
                        ),
                        DropdownMenuItem(
                          value: 'missed',
                          child: Text('Terlewat'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedMedicationId.isEmpty) {
                      return;
                    }

                    Navigator.pop<Map<String, dynamic>>(dialogContext, {
                      'userMedicationId': selectedMedicationId,
                      'date': selectedDate,
                      'time': selectedTime,
                      'status': selectedStatus,
                    });
                  },
                  child: Text(entry == null ? 'Simpan' : 'Ubah'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userMedicationId = result['userMedicationId'] as String;
      final date = result['date'] as DateTime;
      final time = result['time'] as TimeOfDay;
      final status = result['status'] as String;

      if (entry == null) {
        await _medicationService.createMedicationLog(
          userMedicationId: userMedicationId,
          date: date,
          scheduledTime: time,
          status: status,
        );
      } else {
        await _medicationService.updateMedicationLog(
          logId: entry['id']?.toString() ?? '',
          userMedicationId: userMedicationId,
          date: date,
          scheduledTime: time,
          status: status,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              entry == null
                  ? 'Riwayat berhasil ditambahkan'
                  : 'Riwayat berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kesalahan menyimpan riwayat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteHistoryEntry(Map<String, dynamic> entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus catatan riwayat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _medicationService.deleteMedicationLog(
        entry['id']?.toString() ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kesalahan menghapus riwayat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'HARI INI';
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'KEMARIN';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      return timeOfDay.format(context);
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group history by date
    Map<String, List<Map<String, dynamic>>> groupedHistory = {};
    for (var entry in _historyEntries) {
      final date = entry['date'] as String;
      if (!groupedHistory.containsKey(date)) {
        groupedHistory[date] = [];
      }
      groupedHistory[date]!.add(entry);
    }

    // Sort dates in descending order
    final sortedDates = groupedHistory.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.loginShadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
          ),
        ),
        title: const Text(
          'Riwayat Obat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.bottomSheetShadow,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_adherencePercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Kepatuhan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppColors.chipBackground,
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_dayStreak',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Seri Hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_historyEntries.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.history,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Riwayat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tambahkan catatan untuk melihat riwayatmu di sini',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveHistoryEntry(),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Riwayat'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sortedDates.map((date) {
                            final entries = groupedHistory[date]!;
                            final allTaken = entries.every(
                              (e) => e['status'] == 'taken',
                            );
                            final dateFormatted = _formatDate(date);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    bottom: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (allTaken)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.green,
                                            ),
                                          ),
                                          child: const Text(
                                            'Perfect Day! 🌟',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ...entries.map((entry) {
                                  final status = entry['status']?.toString();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _statusColor(
                                          status,
                                        ).withValues(alpha: 0.3),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.bottomSheetShadow,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              status,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _statusIcon(status),
                                              color: _statusColor(status),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getMedicationName(entry),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '${_getMedicationSubtitle(entry)} • ${_formatTime(entry['scheduled_time']?.toString() ?? '')}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: _statusColor(status),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _saveHistoryEntry(entry: entry);
                                            } else if (value == 'delete') {
                                              _deleteHistoryEntry(entry);
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Sunting'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : () => _saveHistoryEntry(),
        backgroundColor: AppColors.primary,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
