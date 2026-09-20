import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_launcher.dart';
import '../models/car.dart';
import '../providers/car_providers.dart';

class LiveCarMapSheet extends ConsumerStatefulWidget {
  final Car car;

  const LiveCarMapSheet({
    super.key,
    required this.car,
  });

  static Future<void> show(BuildContext context, {required Car car}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiveCarMapSheet(car: car),
    );
  }

  @override
  ConsumerState<LiveCarMapSheet> createState() => _LiveCarMapSheetState();
}

class _LiveCarMapSheetState extends ConsumerState<LiveCarMapSheet> {
  late MapController _mapController;
  bool _isUpdatingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _refreshGps(Car currentCar) async {
    setState(() => _isUpdatingGps = true);
    try {
      final locService = ref.read(locationServiceProvider);
      final loc = await locService.getCurrentLocation();
      if (!mounted) return;

      if (loc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not obtain device GPS. Please check location permissions and ensure GPS is on.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await ref.read(carRepositoryProvider).updateCarLocation(
        carId: currentCar.id,
        latitude: loc.latitude,
        longitude: loc.longitude,
        speedKmH: loc.speedKmH,
        isMoving: (loc.speedKmH ?? 0) > 3,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS updated: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
        ),
      );

      _mapController.move(LatLng(loc.latitude, loc.longitude), 16.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update GPS: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingGps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time car document so location changes reflect instantly
    final liveCarAsync = ref.watch(carDetailStreamProvider(widget.car.id));
    final car = liveCarAsync.value ?? widget.car;

    final theme = Theme.of(context);
    final hasLoc = car.hasLocation;
    final lat = car.latitude ?? 20.5937;
    final lng = car.longitude ?? 78.9629;
    final carLatLng = LatLng(lat, lng);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.brand} ${car.carName}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        car.carNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Interactive Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: carLatLng,
                    initialZoom: hasLoc ? 15.5 : 4.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fleetboard.fleetboard',
                    ),
                    if (hasLoc)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: carLatLng,
                            width: 140,
                            height: 80,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                  child: Text(
                                    car.carNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Map controls overlay (zoom in/out, recenter)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                        child: const Icon(Icons.remove),
                      ),
                      if (hasLoc) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter',
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          onPressed: () => _mapController.move(carLatLng, 15.5),
                          child: const Icon(Icons.my_location),
                        ),
                      ],
                    ],
                  ),
                ),

                // Info banner if no GPS yet
                if (!hasLoc)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'GPS has not been recorded yet. Tap "Update GPS Location Now" below to record current device position.',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Details & Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location Status text
                  Row(
                    children: [
                      Icon(
                        hasLoc ? Icons.check_circle : Icons.location_off,
                        color: hasLoc ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasLoc
                              ? 'Last GPS: ${car.lastLocationTime != null ? Formatters.dateTime(car.lastLocationTime) : "Recorded"} (${car.latitude!.toStringAsFixed(4)}, ${car.longitude!.toStringAsFixed(4)})'
                              : 'No GPS data recorded yet',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Actions
                  Row(
                    children: [
                      // Refresh / Update GPS button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isUpdatingGps ? null : () => _refreshGps(car),
                          icon: _isUpdatingGps
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.gps_fixed, size: 18),
                          label: Text(_isUpdatingGps ? 'Querying GPS...' : 'Update GPS Now'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Google Maps Launch button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: hasLoc
                              ? () => MapLauncher.openCarLocation(
                                    context: context,
                                    latitude: car.latitude,
                                    longitude: car.longitude,
                                    label: '${car.brand} ${car.carName} (${car.carNumber})',
                                  )
                              : null,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Google Maps'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
