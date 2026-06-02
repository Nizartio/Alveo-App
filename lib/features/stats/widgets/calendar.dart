import 'package:flutter/material.dart';

enum DayStatus { none, completed, missed }

class WeeklyAdherenceCalendar extends StatefulWidget {
  final Map<int, DayStatus> dayStatuses;
  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPickMonthYear;

  const WeeklyAdherenceCalendar({
    super.key,
    this.dayStatuses = const {},
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonthYear,
  });

  @override
  State<WeeklyAdherenceCalendar> createState() =>
      _WeeklyAdherenceCalendarState();
}

class _WeeklyAdherenceCalendarState extends State<WeeklyAdherenceCalendar> {
  static const List<String> _weekLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  DateTime get _month =>
      DateTime(widget.visibleMonth.year, widget.visibleMonth.month, 1);
  DateTime get _today => DateTime.now();
  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;
  int get _startWeekday => (_month.weekday - 1) % 7;
  int get _prevMonthDays => DateTime(_month.year, _month.month, 0).day;

  int get _completedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.completed).length;

  int get _missedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.missed).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthTitle(),
          const SizedBox(height: 16),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthTitle() {
    final monthName = _monthName(_month.month);
    return Row(
      children: [
        IconButton(
          onPressed: widget.onPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFF6B5CE7),
          tooltip: 'Bulan sebelumnya',
        ),
        Expanded(
          child: InkWell(
            onTap: widget.onPickMonthYear,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  '$monthName ${_month.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9E9AB8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: const Color(0xFF6B5CE7),
          tooltip: 'Bulan berikutnya',
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB0ABCC),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final int totalCells = ((_startWeekday + _daysInMonth) / 7).ceil() * 7;

    final List<Widget> cells = [];

    for (int i = 0; i < totalCells; i++) {
      final int dayOffset = i - _startWeekday;

      if (dayOffset < 0) {
        final int prevDay = _prevMonthDays + dayOffset + 1;
        cells.add(_DayCell(day: prevDay, isCurrentMonth: false));
      } else if (dayOffset >= _daysInMonth) {
        final int nextDay = dayOffset - _daysInMonth + 1;
        cells.add(_DayCell(day: nextDay, isCurrentMonth: false));
      } else {
        final int day = dayOffset + 1;
        final DayStatus status = widget.dayStatuses[day] ?? DayStatus.none;
        final bool isToday =
            day == _today.day &&
            _month.month == _today.month &&
            _month.year == _today.year;
        cells.add(
          _DayCell(
            day: day,
            status: status,
            isToday: isToday,
            isCurrentMonth: true,
          ),
        );
      }
    }

    final List<Widget> rows = [];
    for (int r = 0; r < cells.length / 7; r++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cells.sublist(r * 7, r * 7 + 7),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(
              color: const Color(0xFF6B5CE7),
              label: 'Diminum ($_completedCount)',
            ),
            const SizedBox(width: 24),
            _LegendDot(
              color: const Color(0xFFFF6B6B),
              label: 'Terlewat / reset streak ($_missedCount)',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Hari merah menandakan dosis yang tidak tercatat pada hari itu. Jika itu memutus rangkaian hari berturut-turut, streak akan reset dari hari berikutnya.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: const Color(0xFF8E88AE).withOpacity(0.95),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return names[month];
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DayStatus status;
  final bool isToday;
  final bool isCurrentMonth;

  const _DayCell({
    required this.day,
    this.status = DayStatus.none,
    this.isToday = false,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFFCBCADA);

    if (!isCurrentMonth) {
      textColor = const Color(0xFFDDDBEB);
    } else {
      switch (status) {
        case DayStatus.completed:
          bgColor = const Color(0xFF6B5CE7);
          textColor = Colors.white;
          break;
        case DayStatus.missed:
          bgColor = const Color(0xFFFF6B6B);
          textColor = Colors.white;
          break;
        case DayStatus.none:
          textColor = const Color(0xFFAEAAC8);
          break;
      }
    }

    final child = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && status == DayStatus.none
            ? Border.all(color: const Color(0xFF6B5CE7), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: status != DayStatus.none
                ? FontWeight.w700
                : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );

    return Expanded(child: Center(child: child));
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8A85A8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
