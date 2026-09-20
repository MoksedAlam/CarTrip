import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../core/widgets/status_chip.dart';
import '../../cars/models/car.dart';
import 'other_car_detail_sheet.dart';

class BoardCarCard extends StatelessWidget {
  final Car car;
  final bool isMyCar;

  const BoardCarCard({
    super.key,
    required this.car,
    required this.isMyCar,
  });

  Future<void> _call(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not provided.')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    }
  }

  Future<void> _whatsapp(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not provided.')),
      );
      return;
    }
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hi ${car.ownerName}, I am inquiring about your vehicle ${car.carName} (${car.carNumber}) on CarTrip.')}');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = car.derivedStatus;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isMyCar) {
            context.push('/cars/${car.id}');
          } else {
            OtherCarDetailSheet.show(context, car);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Car Model, Number, Status & MyCar badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Car Icon / Photo thumbnail
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: car.carPhotoUrl != null && car.carPhotoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    car.carPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) => Icon(
                                      Icons.directions_car_filled_rounded,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.directions_car_filled_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      car.carName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isMyCar) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'My Car',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                car.carNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: status),
                ],
              ),

              const SizedBox(height: 10),

              // Badges: Seats, Fuel, AC, Running/Stay
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(context, '${car.seats} Seater', Icons.event_seat_outlined),
                  _buildTag(context, car.fuelType, Icons.local_gas_station_outlined),
                  if (car.hasAC) _buildTag(context, 'AC', Icons.ac_unit_outlined),
                  _buildMovementBadge(context, car.movementStatus, car.isMoving),
                ],
              ),

              const Divider(height: 20),

              // Owner row + 1-Tap Call & WhatsApp buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          backgroundImage: car.ownerPhotoUrl != null && car.ownerPhotoUrl!.isNotEmpty
                              ? NetworkImage(car.ownerPhotoUrl!)
                              : null,
                          child: car.ownerPhotoUrl == null || car.ownerPhotoUrl!.isEmpty
                              ? Text(
                                  car.ownerName.isNotEmpty ? car.ownerName[0].toUpperCase() : 'O',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSecondaryContainer),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.ownerName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (car.ownerPhone != null && car.ownerPhone!.isNotEmpty)
                                Text(
                                  car.ownerPhone!,
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map, Call & WhatsApp icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.location_on_rounded, size: 18),
                        tooltip: 'View Location on Map',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => MapLauncher.openCarLocation(
                          context: context,
                          latitude: car.latitude,
                          longitude: car.longitude,
                          address: car.lastLocationAddress,
                          label: '${car.carName} (${car.carNumber})',
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.call_rounded, size: 18),
                        tooltip: 'Call Owner',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _call(context, car.ownerPhone),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        tooltip: 'WhatsApp Message',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _whatsapp(context, car.ownerPhone),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMovementBadge(BuildContext context, String status, bool isMoving) {
    final color = isMoving ? Colors.green : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
