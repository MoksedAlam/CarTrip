import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../cars/models/car.dart';
import '../../cars/widgets/live_car_map_sheet.dart';
import '../../trips/screens/reservation_form_screen.dart';

class OtherCarDetailSheet extends StatelessWidget {
  final Car car;

  const OtherCarDetailSheet({super.key, required this.car});

  static Future<void> show(BuildContext context, Car car) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => OtherCarDetailSheet(car: car),
    );
  }

  Future<void> _handleCallOwner(BuildContext context) async {
    if (car.ownerPhone == null || car.ownerPhone!.isEmpty) return;
    final cleanPhone = car.ownerPhone!.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  Future<void> _handleWhatsAppOwner(BuildContext context) async {
    if (car.ownerPhone == null || car.ownerPhone!.isEmpty) return;
    String cleanPhone = car.ownerPhone!.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hi ${car.ownerName}, I am inquiring about your car ${car.carName} (${car.carNumber}) on CarTrip.')}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  Future<void> _handleOpenMap(BuildContext context) async {
    LiveCarMapSheet.show(context, car: car);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = car.derivedStatus;
    final isMoving = car.isMoving;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.brand} ${car.carName}',
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

          const SizedBox(height: 16),

          // Specs Badges Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecItem(context, Icons.event_seat_outlined, '${car.seats} Seats'),
                  _buildSpecItem(context, Icons.local_gas_station_outlined, car.fuelType),
                  _buildSpecItem(context, Icons.ac_unit_outlined, car.hasAC ? 'AC' : 'Non-AC'),
                  _buildSpecItem(
                    context,
                    isMoving ? Icons.navigation_rounded : Icons.local_parking_rounded,
                    car.movementStatus,
                    color: isMoving ? Colors.green : Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Live Location & Map section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isMoving ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMoving ? Icons.directions_car_filled_rounded : Icons.location_on_rounded,
                  color: isMoving ? Colors.green : theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                isMoving ? 'Car is Moving (${car.speedKmH?.toInt() ?? 35} km/h)' : 'Car is Parked / Stay',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                car.lastLocationAddress ??
                    'Coordinates: ${car.latitude?.toStringAsFixed(4) ?? "28.6139"}, ${car.longitude?.toStringAsFixed(4) ?? "77.2090"}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton.filledTonal(
                icon: const Icon(Icons.map_rounded, size: 18),
                tooltip: 'Open in Google Maps',
                onPressed: () => _handleOpenMap(context),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Owner Profile Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: car.ownerPhotoUrl != null && car.ownerPhotoUrl!.isNotEmpty
                  ? NetworkImage(car.ownerPhotoUrl!)
                  : null,
              child: car.ownerPhotoUrl == null || car.ownerPhotoUrl!.isEmpty
                  ? Text(
                      car.ownerName.isNotEmpty ? car.ownerName[0].toUpperCase() : 'O',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                    )
                  : null,
            ),
            title: Text(car.ownerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(car.ownerPhone != null && car.ownerPhone!.isNotEmpty
                ? 'Owner • ${car.ownerPhone}'
                : 'Owner (Verified)'),
          ),

          const SizedBox(height: 16),

          // Primary action: Refer a booking to this car
          AppButton(
            label: 'Refer Booking to This Car',
            icon: Icons.add_circle_outline_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReservationFormScreen(
                    initialCarId: car.id,
                    initialCar: car,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call, WhatsApp, Map
          Row(
            children: [
              if (car.ownerPhone != null && car.ownerPhone!.isNotEmpty) ...[
                Expanded(
                  child: AppButton(
                    label: 'Call',
                    icon: Icons.call_rounded,
                    onPressed: () => _handleCallOwner(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () => _handleWhatsAppOwner(context),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton.outlined(
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Google Maps',
                onPressed: () => _handleOpenMap(context),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(BuildContext context, IconData icon, String text, {Color? color}) {
    final theme = Theme.of(context);
    final finalColor = color ?? theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: finalColor),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: finalColor),
        ),
      ],
    );
  }
}
