// lib/features/ai/presentation/pages/anomalies_page.dart
import 'package:flutter/material.dart';
import '../../domain/entities/anomaly.dart';

class AnomaliesPage extends StatelessWidget {
  final List<Anomaly> anomalies;

  const AnomaliesPage({super.key, required this.anomalies});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anomalies')),
      body: ListView.separated(
        itemCount: anomalies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final a = anomalies[i];
          return ListTile(
            leading: Icon(
              a.severity == AnomalySeverity.high
                  ? Icons.warning_amber
                  : a.severity == AnomalySeverity.medium
                  ? Icons.info
                  : Icons.check_circle,
            ),
            title: Text(a.type.toString().split('.').last),
            subtitle: Text(a.message),
          );
        },
      ),
    );
  }
}
