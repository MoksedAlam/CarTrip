import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../cars/models/car.dart';

class OtherCarDetailSheet extends StatelessWidget {
  final Car car;

  const OtherCarDetailSheet({super.key, required this.car});

  static Future<void> show(BuildContext context, Car car) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OtherCarDetailSheet(car: car),
    );
  }

  Future<void> _handleCallOwner(BuildContext context) async {
    if (car.ownerPhone == null || car.ownerPhone!.isEmpty) return;
    final uri = Uri.parse('tel:${car.ownerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = car.derivedStatus;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.carName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      car.carNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: status, fontSize: 13),
            ],
          ),

          const SizedBox(height: 12),
          Text(car.statusSubtitle, style: theme.textTheme.bodyMedium),

          if (car.boardNote != null && car.boardNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.near_me_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Destination: ${car.boardNote}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24),

          // Owner info
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(
                car.ownerName.isNotEmpty ? car.ownerName[0].toUpperCase() : 'O',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(car.ownerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Owner • ${car.seats} Seats • ${car.hasAC ? "AC" : "Non-AC"} • ${CarTypes.label(car.carType)}'),
          ),

          const SizedBox(height: 16),

          if (car.ownerPhone != null && car.ownerPhone!.isNotEmpty) ...[
            AppButton(
              label: 'Call Owner (${car.ownerPhone})',
              icon: Icons.phone_rounded,
              onPressed: () => _handleCallOwner(context),
            ),
            const SizedBox(height: 8),
          ],

          AppButton.text(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
