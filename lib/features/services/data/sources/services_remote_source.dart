import '../models/service_point_model.dart';

abstract class ServicesRemoteSource {
  Stream<List<ServicePointModel>> watchServices();
  Stream<ServicePointModel?> watchServiceById(String id);
}
