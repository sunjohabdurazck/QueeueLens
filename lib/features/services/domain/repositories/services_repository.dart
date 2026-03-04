import '../entities/service_point.dart';

abstract class ServicesRepository {
  Stream<List<ServicePoint>> watchServices();
  Stream<ServicePoint?> watchServiceById(String id);
}
