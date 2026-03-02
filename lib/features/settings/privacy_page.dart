import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const <Widget>[
            _PrivacyCard(
              icon: Icons.shield_moon_outlined,
              title: 'Local-first processing',
              body:
                  'HEICFlow processes photos fully on-device. Files are never uploaded to external servers for conversion.',
            ),
            SizedBox(height: AppSpacing.sm),
            _PrivacyCard(
              icon: Icons.storage_outlined,
              title: 'What is stored locally',
              body:
                  'Temporary thumbnails and conversion artifacts in app cache, plus the last 20 export sessions (timestamp, format, and output file paths).',
            ),
            SizedBox(height: AppSpacing.sm),
            _PrivacyCard(
              icon: Icons.insights_outlined,
              title: 'Analytics',
              body: 'No analytics are enabled by default.',
            ),
            SizedBox(height: AppSpacing.sm),
            _PrivacyCard(
              icon: Icons.cleaning_services_outlined,
              title: 'Data control',
              body:
                  'You can clear cached files at any time from Settings > Storage > Clear cache.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
