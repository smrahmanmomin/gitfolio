import 'package:flutter/material.dart';

class ContactSectionData {
  const ContactSectionData({
    required this.socialLinks,
    required this.locationImageUrl,
    this.heroTag,
  });

  final List<SocialLinkData> socialLinks;
  final String locationImageUrl;
  final String? heroTag;
}

class SocialLinkData {
  const SocialLinkData({required this.label, required this.url, this.icon});

  final String label;
  final String url;
  final IconData? icon;
}

class ContactSectionWidget extends StatefulWidget {
  const ContactSectionWidget({
    super.key,
    required this.data,
    this.isEditable = false,
    this.onSubmit,
  });

  final ContactSectionData data;
  final bool isEditable;
  final ValueChanged<Map<String, String>>? onSubmit;

  @override
  State<ContactSectionWidget> createState() => _ContactSectionWidgetState();
}

class _ContactSectionWidgetState extends State<ContactSectionWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.data.heroTag ?? 'contact-section';
    return SizedBox(
      height: 520,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Get in touch'),
              background: Hero(
                tag: heroTag,
                child: Image.network(
                  widget.data.locationImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.isEditable) _buildContactForm(context),
                  if (!widget.isEditable) _buildReadOnlySummary(context),
                  const SizedBox(height: 24),
                  _SocialLinks(links: widget.data.socialLinks),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.data.locationImageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
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

  Widget _buildContactForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onSubmit?.call({
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'message': _messageController.text,
                  });
                }
              },
              child: const Text('Send message'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Let\'s work together',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Drop a note with project ideas, speaking invitations, or collaborations.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.links});

  final List<SocialLinkData> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return Text(
        'Add social accounts to make it easier to connect.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final link in links)
          Chip(
            avatar: Icon(link.icon ?? Icons.link),
            label: Text(link.label),
          ),
      ],
    );
  }
}
