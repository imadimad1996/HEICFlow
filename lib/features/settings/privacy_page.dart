import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const <Widget>[
          Text(
            'HEICFlow processes photos fully on-device. Files are never uploaded to external servers for conversion.',
          ),
          SizedBox(height: AppSpacing.md),
          Text('What is stored locally:'),
          SizedBox(height: AppSpacing.xs),
          Text('• Temporary thumbnails and conversion artifacts in app cache.'),
          Text(
            '• Last 20 export sessions (timestamp, format, and output file paths).',
          ),
          SizedBox(height: AppSpacing.md),
          Text('No analytics are enabled by default.'),
          SizedBox(height: AppSpacing.md),
          Text(
            'You can clear all cached files at any time from Settings > Storage > Clear cache.',
          ),
        ],
      ),
    );
  }
}
