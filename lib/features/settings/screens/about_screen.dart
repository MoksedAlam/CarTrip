import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About FleetBoard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      size: 36,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Version $_version', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What is FleetBoard?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'FleetBoard is a modern record-keeping and fleet visibility tool designed for local car owners and operators. It lets you organize your vehicles, track reservations, manage trip fares and expenses, generate UPI payment QR codes, and see real-time availability across local vehicles on a shared board.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Terms & Legal Disclaimer',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  AppConstants.disclaimerText,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Handling',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  AppConstants.upiDisclaimerText,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Privacy Policy',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  AppConstants.privacyPolicySummary,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Support & Inquiries',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Contact: support@fleetboard.local',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
