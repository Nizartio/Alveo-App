import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/medication_service.dart';
import '../../stats/services/stats_service.dart';
import '../widgets/history/stats_card.dart';
import '../widgets/history/empty_state.dart';
import '../widgets/history/history_date_section.dart';

class MedsHistoryPage extends StatefulWidget {
  const MedsHistoryPage({super.key});

  @override
  State<MedsHistoryPage> createState() => _MedsHistoryPageState();
}

class _MedsHistoryPageState extends State<MedsHistoryPage> {
  final _medicationService = MedicationService();
  final _statsService = StatsService();
  List<Map<String, dynamic>> _historyEntries = [];
  List<Map<String, dynamic>> _medicationOptions = [];
  bool _isLoading = true;
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

    setState(() {});
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
        setState(() {});
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

    setState(() {});
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
        setState(() {});
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
                    HistoryStatsCard(
                      adherencePercentage: _adherencePercentage,
                      dayStreak: _dayStreak,
                    ),
                    const SizedBox(height: 16),
                    if (_historyEntries.isEmpty)
                      const HistoryEmptyState()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sortedDates.map((date) {
                          final entries = groupedHistory[date]!;
                          final allTaken = entries.every(
                            (e) => e['status'] == 'taken',
                          );
                          final dateFormatted = _formatDate(date);

                          return HistoryDateSection(
                            dateFormatted: dateFormatted,
                            entries: entries,
                            allTaken: allTaken,
                            getMedicationName: _getMedicationName,
                            getMedicationSubtitle: _getMedicationSubtitle,
                            formatTime: _formatTime,
                            statusLabel: _statusLabel,
                            statusColor: _statusColor,
                            statusIcon: _statusIcon,
                            onEdit: (entry) => _saveHistoryEntry(entry: entry),
                            onDelete: _deleteHistoryEntry,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      // No FAB: adding history is not allowed from this page
    );
  }
}
