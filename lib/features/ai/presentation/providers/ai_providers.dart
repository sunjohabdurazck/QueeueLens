// lib/features/ai/presentation/providers/ai_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import '../../data/datasources/ai_local_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/predict_wait_time.dart';
import '../../domain/usecases/recommend_best_service.dart';
import '../../domain/entities/wait_prediction.dart';
import '../../domain/entities/recommendation.dart';
import '../../core/geo.dart';
import '../../../services/presentation/providers/services_providers.dart';

// Repository provider
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(AiLocalDataSource());
});

// Wait time prediction provider
final waitPredictionProvider =
    FutureProvider.family<WaitPrediction, WaitPredictionParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(aiRepositoryProvider);
      final usecase = PredictWaitTime(repo);

      return usecase(
        serviceId: params.serviceId,
        positionInQueue: params.position,
        now: DateTime.now(),
        fallbackServeSeconds: params.fallbackSeconds ?? 120,
      );
    });

class WaitPredictionParams {
  final String serviceId;
  final int position;
  final int? fallbackSeconds;

  WaitPredictionParams({
    required this.serviceId,
    required this.position,
    this.fallbackSeconds,
  });
}

// User location provider
final userLocationProvider = FutureProvider<LocationData?>((ref) async {
  final location = Location();

  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) return null;
  }

  PermissionStatus permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return null;
  }

  try {
    return await location.getLocation();
  } catch (e) {
    return null;
  }
});

// IUT coords - aligned with MapDataService.getDefaultPlaces()
final _serviceCoordinates = <String, Map<String, double>>{
  'svc_registrar': {
    'lat': 23.94806072165071,
    'lng': 90.37928129865955,
  }, // Admin Building
  'svc_accounts': {
    'lat': 23.94864834931579,
    'lng': 90.37898213461050,
  }, // Administrative Building
  'svc_medical': {
    'lat': 23.948847342350103,
    'lng': 90.37738137384427,
  }, // Medical Center
  'svc_cafeteria': {
    'lat': 23.948039068381526,
    'lng': 90.37968418660170,
  }, // Cafeteria
  'svc_library': {
    'lat': 23.94814651513253,
    'lng': 90.37968899664604,
  }, // Library
  'svc_library_print': {
    'lat': 23.94814651513253,
    'lng': 90.37968899664604,
  }, // Library
};

// Best service recommendation provider
final bestServiceRecommendationProvider =
    FutureProvider<ServiceRecommendation?>((ref) async {
      final servicesAsync = await ref.watch(servicesStreamProvider.future);
      final locationData = await ref.watch(userLocationProvider.future);

      if (servicesAsync.isEmpty || locationData == null) return null;

      final serviceDataList = <ServiceData>[];

      for (final service in servicesAsync) {
        // Get coordinates from mock map or use default
        final coords =
            _serviceCoordinates[service.id] ?? {'lat': 0.0, 'lng': 0.0};
        final serviceLat = coords['lat']!;
        final serviceLng = coords['lng']!;

        final distance = GeoUtils.haversineDistance(
          locationData.latitude!,
          locationData.longitude!,
          serviceLat,
          serviceLng,
        );

        // Get queue count for wait estimate
        final queueCount = service.pendingCount + service.activeCount;
        // Convert avgMinsPerPerson to seconds
        final estimatedTimeSeconds = (service.avgMinsPerPerson * 60).toInt();
        final waitMin = queueCount > 0
            ? (queueCount * service.avgMinsPerPerson).clamp(0, 120)
            : 5;

        serviceDataList.add(
          ServiceData(
            serviceId: service.id,
            serviceName: service.name,
            waitMin: waitMin,
            distanceMeters: distance,
            isOpen: service.isOpen,
          ),
        );
      }

      final usecase = RecommendBestService();
      return usecase(
        services: serviceDataList,
        userLat: locationData.latitude!,
        userLon: locationData.longitude!,
      );
    });
