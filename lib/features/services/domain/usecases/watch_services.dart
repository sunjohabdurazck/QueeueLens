import '../entities/service_point.dart';
import '../repositories/services_repository.dart';

class WatchServices {
  final ServicesRepository _repository;

  const WatchServices(this._repository);

  Stream<List<ServicePoint>> call() => _repository.watchServices();
}
