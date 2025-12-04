import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model representing the contributions for a single calendar day.
class ContributionDayData {
  const ContributionDayData({required this.date, required this.count});

  final DateTime date;
  final int count;
}

/// GitHub-inspired contribution heatmap with month/year navigation controls.
class ContributionHeatmap extends StatefulWidget {
  const ContributionHeatmap({
    super.key,
    required this.days,
    required this.availableYears,
    this.initialYear,
  });

  final List<ContributionDayData> days;
  final List<int> availableYears;
  final int? initialYear;

  @override
  State<ContributionHeatmap> createState() => _ContributionHeatmapState();
}

class _ContributionHeatmapState extends State<ContributionHeatmap> {
  late int _activeYear;
  int? _activeMonth;
  late final Map<DateTime, ContributionDayData> _dayLookup;
  final List<Color> _intensityPalette = const [
    Color(0xffebedf0),
    Color(0xffc6e48b),
    Color(0xff7bc96f),
    Color(0xff239a3b),
    Color(0xff216e39),
  ];

  @override
  void initState() {
    super.initState();
    _activeYear = widget.initialYear ?? _defaultYear;
    _dayLookup = {
      for (final day in widget.days)
        DateTime(day.date.year, day.date.month, day.date.day): day,
    };
  }

  int get _defaultYear => widget.availableYears.isNotEmpty
      ? widget.availableYears.last
      : DateTime.now().year;

  List<int> get _yearOptions => widget.availableYears.isNotEmpty
      ? widget.availableYears
      : <int>[_defaultYear];

  List<int> get _monthOptions {
    final months = widget.days
        .where((day) => day.date.year == _activeYear)
        .map((day) => day.date.month)
        .toSet()
        .toList()
      ..sort();
    return months.isEmpty
        ? List<int>.generate(12, (index) => index + 1)
        : months;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) {
      return Text(
        'No contributions available yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final weeks = _buildWeeks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavigationRow(context),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final week in weeks)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      children: week
                          .map(
                            (cell) => _ContributionCell(
                              data: cell,
                              background: _cellColor(cell.count),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
    final monthNames = _monthOptions
        .map((month) => DateFormat.MMM().format(DateTime(0, month)))
        .toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous year',
              onPressed: _canStepYear(-1) ? () => _stepYear(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            DropdownButton<int>(
              value: _activeYear,
              items: [
                for (final year in _yearOptions)
                  DropdownMenuItem<int>(value: year, child: Text('$year')),
              ],
              onChanged: (value) =>
                  setState(() => _activeYear = value ?? _activeYear),
            ),
            IconButton(
              tooltip: 'Next year',
              onPressed: _canStepYear(1) ? () => _stepYear(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        DropdownButton<int?>(
          value: _activeMonth,
          hint: const Text('All months'),
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('All months')),
            for (var i = 0; i < _monthOptions.length; i++)
              DropdownMenuItem<int?>(
                value: _monthOptions[i],
                child: Text(monthNames[i]),
              ),
          ],
          onChanged: (value) => setState(() => _activeMonth = value),
        ),
      ],
    );
  }

  bool _canStepYear(int delta) {
    final index = _yearOptions.indexOf(_activeYear);
    if (index == -1) return false;
    final nextIndex = index + delta;
    return nextIndex >= 0 && nextIndex < _yearOptions.length;
  }

  void _stepYear(int delta) {
    final index = _yearOptions.indexOf(_activeYear);
    if (index == -1) return;
    final nextIndex = (index + delta).clamp(0, _yearOptions.length - 1);
    setState(() {
      _activeYear = _yearOptions[nextIndex];
      _activeMonth = null;
    });
  }

  List<List<_HeatmapCell>> _buildWeeks() {
    final startMonth = _activeMonth ?? 1;
    final rangeStart = DateTime(_activeYear, startMonth, 1);
    final rangeEnd = _activeMonth == null
        ? DateTime(_activeYear, 12, 31)
        : DateTime(_activeYear, startMonth + 1, 0);

    final normalizedStart =
        DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final totalDays = rangeEnd.difference(rangeStart).inDays + 1;
    final cells = <_HeatmapCell>[];
    for (var i = 0; i < totalDays; i++) {
      final date = normalizedStart.add(Duration(days: i));
      final data = _dayLookup[date];
      cells.add(
        _HeatmapCell(date: date, count: data?.count ?? 0),
      );
    }

    final leading = normalizedStart.weekday % 7;
    final paddedCells = <_HeatmapCell>[];
    for (var i = 0; i < leading; i++) {
      paddedCells.add(
        _HeatmapCell(
          date: normalizedStart.subtract(Duration(days: leading - i)),
          count: 0,
          isPadding: true,
        ),
      );
    }
    paddedCells.addAll(cells);
    while (paddedCells.length % 7 != 0) {
      final lastDate = paddedCells.isEmpty
          ? normalizedStart
          : paddedCells.last.date.add(const Duration(days: 1));
      paddedCells.add(
        _HeatmapCell(date: lastDate, count: 0, isPadding: true),
      );
    }

    final weeks = <List<_HeatmapCell>>[];
    for (var i = 0; i < paddedCells.length; i += 7) {
      weeks.add(paddedCells.sublist(i, i + 7));
    }
    return weeks;
  }

  Color _cellColor(int value) {
    if (value <= 0) return _intensityPalette.first;
    final bucket = value >= 8
        ? _intensityPalette.length - 1
        : (value / 2).ceil().clamp(1, _intensityPalette.length - 1);
    return _intensityPalette[bucket];
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        for (final color in _intensityPalette)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 8),
        Text('More', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HeatmapCell {
  const _HeatmapCell({
    required this.date,
    required this.count,
    this.isPadding = false,
  });

  final DateTime date;
  final int count;
  final bool isPadding;
}

class _ContributionCell extends StatelessWidget {
  const _ContributionCell({required this.data, required this.background});

  final _HeatmapCell data;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final tooltipText =
        '${DateFormat.yMMMd().format(data.date)}\n${data.count} contributions';
    return Tooltip(
      message: tooltipText,
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color:
              data.isPadding ? background.withValues(alpha: 0.4) : background,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
