import 'package:flutter/material.dart';

class SocialLinkData {
  const SocialLinkData({required this.label, required this.url, this.icon});

  final String label;
  final String url;
  final IconData? icon;
}

class HeroSectionData {
  const HeroSectionData({
    required this.avatarUrl,
    required this.name,
    required this.title,
    required this.bio,
    required this.socialLinks,
    this.heroTag,
  });

  final String avatarUrl;
  final String name;
  final String title;
  final String bio;
  final List<SocialLinkData> socialLinks;
  final String? heroTag;
}

class HeroSectionWidget extends StatefulWidget {
  const HeroSectionWidget({
    super.key,
    required this.data,
    this.isEditable = false,
    this.onBioChanged,
    this.onLinkTap,
    this.onAddLink,
  });

  final HeroSectionData data;
  final bool isEditable;
  final ValueChanged<String>? onBioChanged;
  final ValueChanged<SocialLinkData>? onLinkTap;
  final VoidCallback? onAddLink;

  @override
  State<HeroSectionWidget> createState() => _HeroSectionWidgetState();
}

class _HeroSectionWidgetState extends State<HeroSectionWidget> {
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.data.bio);
    _bioController.addListener(_handleBioChanged);
  }

  @override
  void didUpdateWidget(covariant HeroSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.bio != widget.data.bio) {
      _bioController
        ..removeListener(_handleBioChanged)
        ..text = widget.data.bio
        ..addListener(_handleBioChanged);
    }
  }

  @override
  void dispose() {
    _bioController.removeListener(_handleBioChanged);
    _bioController.dispose();
    super.dispose();
  }

  void _handleBioChanged() {
    if (widget.isEditable) {
      widget.onBioChanged?.call(_bioController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.data.heroTag ?? 'hero-section-${widget.data.name}';
    return SizedBox(
      height: 420,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.data.name),
              background: Hero(
                tag: heroTag,
                child: Container(
                  padding: const EdgeInsets.only(top: 48),
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.data.avatarUrl),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.data.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  widget.isEditable
                      ? TextField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          widget.data.bio,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Social links',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (widget.isEditable)
                          IconButton(
                            icon: const Icon(Icons.add_link),
                            tooltip: 'Add social link',
                            onPressed: widget.onAddLink,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SocialGrid(
                    links: widget.data.socialLinks,
                    onTap: widget.onLinkTap,
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

class _SocialGrid extends StatelessWidget {
  const _SocialGrid({required this.links, this.onTap});

  final List<SocialLinkData> links;
  final ValueChanged<SocialLinkData>? onTap;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return Text(
        'No social links configured yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final link in links)
          GestureDetector(
            onTap: () => onTap?.call(link),
            child: Chip(
              avatar: Icon(link.icon ?? Icons.link, size: 18),
              label: Text(link.label),
            ),
          ),
      ],
    );
  }
}
