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
  final DateTime _actualToday = DateTime.now();

  DateTime get _currentMonth => widget.visibleMonth;
  DateTime get _firstDayOfMonth => DateTime(_currentMonth.year, _currentMonth.month, 1);
  int get _daysInMonth => DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
  int get _prevMonthDays => DateTime(_currentMonth.year, _currentMonth.month, 0).day;

  void _goToPreviousMonth() {
    widget.onPreviousMonth();
  }

  void _goToNextMonth() {
    widget.onNextMonth();
  }

  int get _startWeekday => (_firstDayOfMonth.weekday - 1) % 7;

  int get _completedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.completed).length;

  int get _missedCount =>
      widget.dayStatuses.values.where((s) => s == DayStatus.missed).length;

  static const List<String> _weekLabels = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

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
          const SizedBox(height: 8),
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
    final monthName = _monthName(_currentMonth.month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$monthName ${_currentMonth.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9AB8),
            letterSpacing: 0.5,
          ),
        ),
        Row(
          children: [
            // Tombol Kiri (Bulan Sebelumnya)
            InkWell(
              onTap: _goToPreviousMonth,
              borderRadius: BorderRadius.circular(100), // Agar efek ripple bundar rapi
              child: const Padding(
                padding: EdgeInsets.all(0), // Kontrol manual area sentuh tombol
                child: Icon(
                  Icons.chevron_left_rounded, 
                  color: Color(0xFF9E9AB8),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12), // Jarak horizontal antar panah
            // Tombol Kanan (Bulan Berikutnya)
            InkWell(
              onTap: _goToNextMonth,
              borderRadius: BorderRadius.circular(100),
              child: const Padding(
                padding: EdgeInsets.all(0), // Kontrol manual area sentuh tombol
                child: Icon(
                  Icons.chevron_right_rounded, 
                  color: Color(0xFF9E9AB8),
                  size: 24,
                ),
              ),
            ),
          ],
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
        final DayStatus status =
            widget.dayStatuses[day] ?? DayStatus.none;
            
        // Validasi kecocokan hari ini (Hanya aktif jika kalender sedang membuka bulan & tahun berjalan saat ini)
        final bool isToday = day == _actualToday.day &&
            _currentMonth.month == _actualToday.month &&
            _currentMonth.year == _actualToday.year;

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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            _LegendDot(
              color: const Color(0xFF6B5CE7),
              label: 'Diminum ($_completedCount)',
            ),
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
