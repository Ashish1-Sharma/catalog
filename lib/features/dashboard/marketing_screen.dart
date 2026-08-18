import 'package:flutter/material.dart';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Tools'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.campaign, size: 80),
            SizedBox(height: 16),
            Text(
              'Marketing Tools & Banners',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'This placeholder screen will feature promotional poster generators, discount banner creation, and automated WhatsApp broadcast templates in upcoming releases.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
