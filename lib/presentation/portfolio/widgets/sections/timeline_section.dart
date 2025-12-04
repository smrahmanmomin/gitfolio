import 'package:flutter/material.dart';

class ContributionDay {
  const ContributionDay({required this.date, required this.count});

  final DateTime date;
  final int count;
}

class TimelineEventData {
  const TimelineEventData({
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final String title;
  final String subtitle;
  final DateTime date;
}

class TimelineSectionData {
  const TimelineSectionData({
    required this.contributions,
    required this.events,
    required this.availableYears,
    this.initialYear,
    this.heroTag,
  });

  final List<ContributionDay> contributions;
  final List<TimelineEventData> events;
  final List<int> availableYears;
  final int? initialYear;
  final String? heroTag;
}

class TimelineSectionWidget extends StatefulWidget {
  const TimelineSectionWidget({
    super.key,
    required this.data,
    this.isEditable = false,
    this.onAddEvent,
  });

  final TimelineSectionData data;
  final bool isEditable;
  final ValueChanged<int>? onAddEvent;

  @override
  State<TimelineSectionWidget> createState() => _TimelineSectionWidgetState();
}

class _TimelineSectionWidgetState extends State<TimelineSectionWidget> {
  late int _activeYear;

  @override
  void initState() {
    super.initState();
    _activeYear = widget.data.initialYear ?? widget.data.availableYears.first;
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.data.heroTag ?? 'timeline-section';
    final yearContributions = widget.data.contributions
        .where((c) => c.date.year == _activeYear)
        .toList();
    final events = widget.data.events
        .where((event) => event.date.year == _activeYear)
        .toList();

    return SizedBox(
      height: 520,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('GitHub activity $_activeYear'),
              background: Hero(
                tag: heroTag,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceTint,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _YearSwitcher(
                    years: widget.data.availableYears,
                    currentYear: _activeYear,
                    onChanged: (year) => setState(() => _activeYear = year),
                  ),
                  const SizedBox(height: 16),
                  _ContributionHeatmap(days: yearContributions),
                  const SizedBox(height: 16),
                  _TimelineEvents(
                      events: events, isEditable: widget.isEditable),
                  if (widget.isEditable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.onAddEvent?.call(_activeYear),
                        icon: const Icon(Icons.add),
                        label: const Text('Add event'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({
    required this.years,
    required this.currentYear,
    required this.onChanged,
  });

  final List<int> years;
  final int currentYear;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _hasPrev
              ? () {
                  final index = years.indexOf(currentYear);
                  onChanged(years[index - 1]);
                }
              : null,
        ),
        Text(
          '$currentYear',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: _hasNext
              ? () {
                  final index = years.indexOf(currentYear);
                  onChanged(years[index + 1]);
                }
              : null,
        ),
      ],
    );
  }

  bool get _hasPrev => years.indexOf(currentYear) > 0;
  bool get _hasNext => years.indexOf(currentYear) < years.length - 1;
}

class _ContributionHeatmap extends StatelessWidget {
  const _ContributionHeatmap({required this.days});

  final List<ContributionDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Text(
        'No contributions recorded for this year.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final maxCount =
        days.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 53,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final intensity = maxCount == 0 ? 0.0 : day.count / maxCount;
          return Tooltip(
            message: '${day.count} contributions on ${day.date.toLocal()}'
                .split(' ')[0],
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.primary,
                  intensity,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineEvents extends StatelessWidget {
  const _TimelineEvents({required this.events, required this.isEditable});

  final List<TimelineEventData> events;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No milestones recorded for this year.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: [
        for (final event in events)
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Text(event.title),
            subtitle: Text(
                '${event.subtitle} — ${event.date.toIso8601String().split('T').first}'),
            trailing: isEditable ? const Icon(Icons.drag_handle) : null,
          ),
      ],
    );
  }
}
