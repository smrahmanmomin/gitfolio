import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SkillEntry {
  const SkillEntry({required this.label, required this.level});

  final String label;
  final double level; // 0-1
}

class SkillsSectionData {
  const SkillsSectionData({
    required this.languages,
    required this.skills,
    this.heroTag,
  });

  final Map<String, double> languages;
  final List<SkillEntry> skills;
  final String? heroTag;
}

class SkillsSectionWidget extends StatefulWidget {
  const SkillsSectionWidget({
    super.key,
    required this.data,
    this.isEditable = false,
    this.onAddSkill,
    this.onRemoveSkill,
  });

  final SkillsSectionData data;
  final bool isEditable;
  final ValueChanged<SkillEntry>? onAddSkill;
  final ValueChanged<SkillEntry>? onRemoveSkill;

  @override
  State<SkillsSectionWidget> createState() => _SkillsSectionWidgetState();
}

class _SkillsSectionWidgetState extends State<SkillsSectionWidget> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.data.heroTag ?? 'skills-section';
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetHeight = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0
            ? constraints.maxHeight
            : 480.0;
        return SizedBox(
          height: targetHeight,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Skill radar'),
                  background: Hero(
                    tag: heroTag,
                    child: Container(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: _buildRadarChart(context),
                      ),
                      const SizedBox(height: 16),
                      _SkillsList(
                        isEditable: widget.isEditable,
                        skills: widget.data.skills,
                        onRemove: widget.onRemoveSkill,
                      ),
                      if (widget.isEditable) _buildAddSkillForm(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    final entries = widget.data.languages.entries.toList();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No language data yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final maxValue =
        entries.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: entries
                .map(
                  (e) =>
                      RadarEntry(value: maxValue == 0 ? 0 : e.value / maxValue),
                )
                .toList(),
            borderWidth: 2,
            borderColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ],
        getTitle: (index, angle) => RadarChartTitle(
          text: entries[index].key,
        ),
        radarTouchData: RadarTouchData(enabled: false),
      ),
    );
  }

  Widget _buildAddSkillForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Add skill', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Skill name'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _levelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Level (0-1)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final label = _labelController.text.trim();
              final level = double.tryParse(_levelController.text.trim()) ?? 0;
              if (label.isEmpty) return;
              final entry = SkillEntry(label: label, level: level.clamp(0, 1));
              widget.onAddSkill?.call(entry);
              _labelController.clear();
              _levelController.clear();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add skill'),
          ),
        ),
      ],
    );
  }
}

class _SkillsList extends StatelessWidget {
  const _SkillsList({
    required this.skills,
    required this.isEditable,
    this.onRemove,
  });

  final List<SkillEntry> skills;
  final bool isEditable;
  final ValueChanged<SkillEntry>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No skills added yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: [
        for (final entry in skills)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: entry.level.clamp(0, 1),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEditable)
                  IconButton(
                    onPressed: () => onRemove?.call(entry),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
