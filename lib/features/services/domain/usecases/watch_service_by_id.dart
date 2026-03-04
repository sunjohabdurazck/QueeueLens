// lib/features/services/domain/usecases/watch_service_by_id.dart
import '../entities/service_point.dart';
import '../repositories/services_repository.dart';

class WatchServiceById {
  final ServicesRepository _repository;

  const WatchServiceById(this._repository);

  Stream<ServicePoint?> call(String id) => _repository.watchServiceById(id);
}
