import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/services_repository_impl.dart';
import '../../domain/repositories/services_repository.dart';
import '../../domain/entities/service_point.dart';

// --------------------
// MOCK MODE TOGGLE
// --------------------
const bool kUseMockServices =
    false; // set to false when Firestore/Auth is ready

List<ServicePoint> _mockServices() {
  return <ServicePoint>[
    ServicePoint(
      id: 'svc_registrar',
      name: 'Registrar Office',
      description: 'Transcripts, registration, academic documents',
      status: ServiceStatus.open,
      activeCount: 12,
      pendingCount: 5,
      avgMinsPerPerson: 4,
      lastUpdatedAt: Timestamp.now(),
    ),
    ServicePoint(
      id: 'svc_library_print',
      name: 'ICT Printing',
      description: 'Printing, scanning, photocopy services',
      status: ServiceStatus.open,
      activeCount: 6,
      pendingCount: 3,
      avgMinsPerPerson: 3,
      lastUpdatedAt: Timestamp.now(),
    ),
    ServicePoint(
      id: 'svc_medical',
      name: 'Medical Center',
      description: 'Consultation, first aid, basic checkups',
      status: ServiceStatus.closed,
      activeCount: 0,
      pendingCount: 0,
      avgMinsPerPerson: 10,
      lastUpdatedAt: Timestamp.now(),
    ),
    ServicePoint(
      id: 'svc_accounts',
      name: 'Accounts Office',
      description: 'Payments, clearance, fee-related support',
      status: ServiceStatus.open,
      activeCount: 8,
      pendingCount: 6,
      avgMinsPerPerson: 5,
      lastUpdatedAt: Timestamp.now(),
    ),
    ServicePoint(
      id: 'svc_cafeteria',
      name: 'Cafeteria',
      description: 'Meals and snacks during break',
      status: ServiceStatus.open,
      activeCount: 20,
      pendingCount: 10,
      avgMinsPerPerson: 1,
      lastUpdatedAt: Timestamp.now(),
    ),
    ServicePoint(
      id: 'svc_library',
      name: 'Library',
      description: 'Books, study spaces, research materials',
      status: ServiceStatus.open,
      activeCount: 8,
      pendingCount: 6,
      avgMinsPerPerson: 5,
      lastUpdatedAt: Timestamp.now(),
    ),
  ];
}

// Repository provider
final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(FirebaseFirestore.instance);
});

// Watch all services
final servicesStreamProvider = StreamProvider<List<ServicePoint>>((ref) {
  if (kUseMockServices) {
    return Stream.value(_mockServices());
  }

  final repository = ref.watch(servicesRepositoryProvider);
  return repository.watchServices();
});

// Watch specific service by ID
final serviceByIdProvider = StreamProvider.family<ServicePoint?, String>((
  ref,
  id,
) {
  if (kUseMockServices) {
    final services = _mockServices();
    final match = services.where((s) => s.id == id).toList();
    return Stream.value(match.isEmpty ? null : match.first);
  }

  final repository = ref.watch(servicesRepositoryProvider);
  return repository.watchServiceById(id);
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filter state (show open only)
final showOpenOnlyProvider = StateProvider<bool>((ref) => false);

// Filtered services provider
final filteredServicesProvider = Provider<AsyncValue<List<ServicePoint>>>((
  ref,
) {
  final servicesAsync = ref.watch(servicesStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final showOpenOnly = ref.watch(showOpenOnlyProvider);

  return servicesAsync.whenData((services) {
    // Always work on a mutable copy (prevents Unsupported operation: sort)
    var filtered = services.toList();

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(searchQuery) ||
                s.description.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    // Filter by status
    if (showOpenOnly) {
      filtered = filtered.where((s) => s.isOpen).toList();
    }

    // Sort: OPEN services first, then by name
    filtered.sort((a, b) {
      if (a.isOpen && !b.isOpen) return -1;
      if (!a.isOpen && b.isOpen) return 1;
      return a.name.compareTo(b.name);
    });

    return filtered;
  });
});
