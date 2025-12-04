import 'package:flutter/material.dart';

class ProjectCardData {
  const ProjectCardData({
    required this.name,
    required this.description,
    required this.language,
    required this.stars,
    required this.updatedAt,
  });

  final String name;
  final String description;
  final String language;
  final int stars;
  final DateTime updatedAt;
}

class ProjectsSectionData {
  const ProjectsSectionData({
    required this.projects,
    required this.languages,
    this.heroTag,
  });

  final List<ProjectCardData> projects;
  final List<String> languages;
  final String? heroTag;
}

enum ProjectSortOption { stars, updated, alphabetical }

class ProjectsSectionWidget extends StatefulWidget {
  const ProjectsSectionWidget({
    super.key,
    required this.data,
    this.isEditable = false,
    this.onDescriptionChanged,
  });

  final ProjectsSectionData data;
  final bool isEditable;
  final ValueChanged<ProjectCardData>? onDescriptionChanged;

  @override
  State<ProjectsSectionWidget> createState() => _ProjectsSectionWidgetState();
}

class _ProjectsSectionWidgetState extends State<ProjectsSectionWidget> {
  String _languageFilter = 'All';
  ProjectSortOption _sortOption = ProjectSortOption.stars;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.data.heroTag ?? 'projects-section';
    final filtered = widget.data.projects
        .where(
          (project) =>
              _languageFilter == 'All' || project.language == _languageFilter,
        )
        .toList()
      ..sort(_sortComparator);

    return SizedBox(
      height: 520,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Projects'),
              background: Hero(
                tag: heroTag,
                child: Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilters(context),
                  const SizedBox(height: 16),
                  _ProjectsGrid(
                    projects: filtered,
                    isEditable: widget.isEditable,
                    getController: _getController,
                    onDescriptionChanged: widget.onDescriptionChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final languages = ['All', ...widget.data.languages];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropdownButton<String>(
          value: _languageFilter,
          items: [
            for (final language in languages)
              DropdownMenuItem(value: language, child: Text(language)),
          ],
          onChanged: (value) =>
              setState(() => _languageFilter = value ?? 'All'),
        ),
        DropdownButton<ProjectSortOption>(
          value: _sortOption,
          items: const [
            DropdownMenuItem(
              value: ProjectSortOption.stars,
              child: Text('Most stars'),
            ),
            DropdownMenuItem(
              value: ProjectSortOption.updated,
              child: Text('Recently updated'),
            ),
            DropdownMenuItem(
              value: ProjectSortOption.alphabetical,
              child: Text('Alphabetical'),
            ),
          ],
          onChanged: (value) => setState(() => _sortOption = value!),
        ),
      ],
    );
  }

  TextEditingController _getController(ProjectCardData data) {
    return _controllers.putIfAbsent(
      data.name,
      () => TextEditingController(text: data.description),
    );
  }

  int _sortComparator(ProjectCardData a, ProjectCardData b) {
    switch (_sortOption) {
      case ProjectSortOption.stars:
        return b.stars.compareTo(a.stars);
      case ProjectSortOption.updated:
        return b.updatedAt.compareTo(a.updatedAt);
      case ProjectSortOption.alphabetical:
        return a.name.compareTo(b.name);
    }
  }
}

class _ProjectsGrid extends StatelessWidget {
  const _ProjectsGrid({
    required this.projects,
    required this.isEditable,
    required this.getController,
    this.onDescriptionChanged,
  });

  final List<ProjectCardData> projects;
  final bool isEditable;
  final TextEditingController Function(ProjectCardData data) getController;
  final ValueChanged<ProjectCardData>? onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Text(
        'No repositories match the current filters.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000
        ? 3
        : width > 600
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (isEditable)
                  Expanded(
                    child: TextField(
                      controller: getController(project),
                      maxLines: null,
                      decoration: const InputDecoration(
                          labelText: 'Custom description'),
                      onChanged: (_) => onDescriptionChanged?.call(project),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      project.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(project.language)),
                    Chip(
                        avatar: const Icon(Icons.star, size: 16),
                        label: Text('${project.stars}')),
                    Text(
                        'Updated ${project.updatedAt.year}-${project.updatedAt.month}-${project.updatedAt.day}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
