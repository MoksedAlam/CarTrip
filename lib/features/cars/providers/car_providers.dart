import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/car_repository.dart';
import '../models/car.dart';
import '../models/car_private.dart';

final carRepositoryProvider = Provider<CarRepository>((ref) {
  return CarRepository();
});

final myCarsProvider = StreamProvider<List<Car>>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return Stream.value([]);
  final carRepo = ref.watch(carRepositoryProvider);
  return carRepo.watchMyCars(user.uid);
});

final carDetailStreamProvider = StreamProvider.family<Car?, String>((ref, carId) {
  final carRepo = ref.watch(carRepositoryProvider);
  return carRepo.watchCar(carId);
});

final carPrivateStreamProvider = StreamProvider.family<CarPrivate?, String>((ref, carId) {
  final carRepo = ref.watch(carRepositoryProvider);
  return carRepo.watchCarPrivate(carId);
});
