import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../services/medication_service.dart';
import '../../stats/services/stats_service.dart';
import '../widgets/widgets_history/header.dart';
import '../widgets/widgets_history/history_date_section.dart';
import '../widgets/widgets_history/history_empty_state.dart';
import '../widgets/widgets_history/history_stats_header.dart';

class MedsHistoryPage extends StatefulWidget {
  const MedsHistoryPage({super.key});

  @override
  State<MedsHistoryPage> createState() => _MedsHistoryPageState();
}

class _MedsHistoryPageState extends State<MedsHistoryPage> {
  final _medicationService = MedicationService();
  final _statsService = StatsService();
  List<Map<String, dynamic>> _historyEntries = [];
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
      final history = await _medicationService.fetchMedicationHistory(days: 30);
      final adherence = await _statsService.calculateWeeklyAdherence();

      if (mounted) {
        setState(() {
          _historyEntries = history;
          _adherencePercentage = adherence;
          _dayStreak = 7; // This should come from user_profile
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HistoryHeader(),
                      const SizedBox(height: 24),
                      HistoryStatsHeader(
                        adherencePercentage: _adherencePercentage,
                        dayStreak: _dayStreak,
                      ),
                      const SizedBox(height: 24),

                      // History Timeline
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
                            final dateFormatted = _medicationService
                                .formatHistoryDate(date);

                            return HistoryDateSection(
                              dateFormatted: dateFormatted,
                              allTaken: allTaken,
                              entries: entries,
                              formatTime: _medicationService.formatHistoryTime,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
