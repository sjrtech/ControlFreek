import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scan_screen.dart';

const _wikiUrl = 'https://github.com/sjrtech/ControlFreek/wiki';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBarTitle('Help', icon: Icons.help_outline),
        backgroundColor: const Color(0xFF1A3A7A),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CarbonBackground(child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'ControlFreek Documentation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Full documentation is available on the GitHub wiki.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Wiki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A7A),
                foregroundColor: const Color(0xFFBCC8DC),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => launchUrl(
                Uri.parse(_wikiUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      )),
    );
  }
}
