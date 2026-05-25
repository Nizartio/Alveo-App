import 'package:flutter/material.dart';

enum DayStatus { none, completed, missed }

class WeeklyAdherenceCalendar extends StatefulWidget {
  /// Map of day number → DayStatus for the current month (static for now)
  final Map<int, DayStatus> dayStatuses;

  const WeeklyAdherenceCalendar({
    super.key,
    this.dayStatuses = const {},
  });

  @override
  State<WeeklyAdherenceCalendar> createState() =>
      _WeeklyAdherenceCalendarState();
}

class _WeeklyAdherenceCalendarState extends State<WeeklyAdherenceCalendar> {
  late DateTime _today;
  late DateTime _firstDayOfMonth;
  late int _daysInMonth;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _firstDayOfMonth = DateTime(_today.year, _today.month, 1);
    _daysInMonth = DateTime(_today.year, _today.month + 1, 0).day;
  }

  int get _startWeekday => (_firstDayOfMonth.weekday - 1) % 7;

  int get _completedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.completed).length;

  int get _missedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.missed).length;

  static const List<String> _weekLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  int get _prevMonthDays =>
      DateTime(_today.year, _today.month, 0).day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
    final monthName = _monthName(_today.month);
    return Text(
      '$monthName ${_today.year}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9AB8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekLabels.map((label) {
        final bool isFriday = label == 'Fri';
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isFriday
                    ? const Color(0xFF6B5CE7)
                    : const Color(0xFFB0ABCC),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final int totalCells =
        ((_startWeekday + _daysInMonth) / 7).ceil() * 7;

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
        final DayStatus status =
            widget.dayStatuses[day] ?? DayStatus.none;
        final bool isToday = day == _today.day;
        cells.add(_DayCell(
          day: day,
          status: status,
          isToday: isToday,
          isCurrentMonth: true,
        ));
      }
    }

  final List<Widget> rows = [];
    for (int r = 0; r < cells.length / 7; r++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
          color: const Color(0xFF6B5CE7),
          label: 'Completed ($_completedCount)',
        ),
        const SizedBox(width: 24),
        _LegendDot(
          color: const Color(0xFFFF6B6B),
          label: 'Missed ($_missedCount)',
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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

    Widget child = Container(
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