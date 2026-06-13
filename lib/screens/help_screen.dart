import 'package:flutter/material.dart';
import 'scan_screen.dart';

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
      body: CarbonBackground(child: const Center(
        child: Text('Help coming soon', style: TextStyle(color: Colors.grey)),
      )),
    );
  }
}
