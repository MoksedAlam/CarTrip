import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/month_key.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/trip_repository.dart';
import '../models/trip.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

class TripStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setStatus(String status) => state = status;
}

final tripStatusFilterProvider =
    NotifierProvider<TripStatusFilterNotifier, String>(TripStatusFilterNotifier.new);

class TripCarFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCarId(String? carId) => state = carId;
}

final tripCarFilterProvider =
    NotifierProvider<TripCarFilterNotifier, String?>(TripCarFilterNotifier.new);

class TripMonthFilterNotifier extends Notifier<String> {
  @override
  String build() => MonthKey.fromDateTime(DateTime.now());

  void setMonth(String monthKey) => state = monthKey;

  void previous() => state = MonthKey.previousMonth(state);

  void next() => state = MonthKey.nextMonth(state);
}

final tripMonthFilterProvider =
    NotifierProvider<TripMonthFilterNotifier, String>(TripMonthFilterNotifier.new);

final tripsListProvider = StreamProvider<List<Trip>>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return Stream.value([]);

  final repo = ref.watch(tripRepositoryProvider);
  final status = ref.watch(tripStatusFilterProvider);
  final carId = ref.watch(tripCarFilterProvider);
  final monthKey = ref.watch(tripMonthFilterProvider);

  return repo.watchTrips(
    ownerId: user.uid,
    status: status,
    monthKey: status == 'completed' ? monthKey : null,
    carId: carId,
  );
});

final tripDetailProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchTrip(tripId);
});

final upcomingReservationsProvider = StreamProvider<List<Trip>>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchUpcomingReservations(user.uid);
});

final pendingPaymentsBalanceProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return Stream.value(0);
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchPendingPaymentsBalance(user.uid);
});
