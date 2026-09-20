import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  /// Open car location in Google Maps (or external map app)
  static Future<void> openCarLocation({
    required BuildContext context,
    double? latitude,
    double? longitude,
    String? address,
    String? label,
  }) async {
    Uri uri;
    if (latitude != null && longitude != null) {
      final queryParam = label != null && label.isNotEmpty
          ? '$latitude,$longitude(${Uri.encodeComponent(label)})'
          : '$latitude,$longitude';
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$queryParam');
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.trim())}');
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No GPS location recorded for this car yet.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Maps: $e')),
        );
      }
    }
  }

  /// Open navigation route in Google Maps from pickup to destination
  static Future<void> openRoute({
    required BuildContext context,
    required String pickup,
    required String destination,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(pickup)}&destination=${Uri.encodeComponent(destination)}',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open route in Google Maps.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open route in Maps: $e')),
        );
      }
    }
  }
}
