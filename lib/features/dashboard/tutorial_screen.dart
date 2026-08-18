import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://ashish-dev.xyz');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial & Help Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.play_circle_fill, size: 36),
            title: Text('1. How to Setup Business Profile'),
            subtitle: Text('Enter address, logo, currency, and GST details'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.play_circle_fill, size: 36),
            title: Text('2. Adding Categories & Products'),
            subtitle: Text('Organize items with MRP, sale price & discount'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.play_circle_fill, size: 36),
            title: Text('3. Generating PDF & Image Catalogs'),
            subtitle: Text('Export grid/list catalogs and share to WhatsApp'),
          ),
          const Divider(),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Visit Help Website'),
              onPressed: _launchUrl,
            ),
          ),
        ],
      ),
    );
  }
}
