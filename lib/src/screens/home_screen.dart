// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '/map/map_screen.dart';
import 'login_screen.dart';
import 'student_profile_screen.dart';
import '../../features/services/presentation/pages/services_list_page.dart';
import '../../features/services/presentation/pages/my_queue_page.dart';
import '../../features/services/presentation/providers/services_providers.dart';
import '../../features/services/presentation/providers/queue_providers.dart';
import '../../features/services/domain/entities/service_point.dart';
import '../../features/services/domain/entities/queue_entry.dart';

// AI Features Imports
import '../../features/ai/presentation/widgets/best_service_card.dart';
import '../../features/ai/presentation/widgets/wait_time_badge.dart';
import '../../features/ai/presentation/pages/virtual_campus_view_page.dart';
import '../../features/ai/presentation/pages/anomalies_page.dart';
import '../../features/ai/presentation/providers/ai_providers.dart';
import '../../features/ai/domain/entities/anomaly.dart';
// Remove unused import
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/queue/application/queue_intelligence_listener.dart';
// Fix imports - use correct paths
import '../../core/notifications/inbox/notification_inbox_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  QueueIntelligenceListener? _listener;
  int _selectedIndex = 2;

  // Define the screens list with Map as first tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex;

    _screens = [
      const MapScreen(),
      const ServicesListPage(),
      _buildHomeContent(),
      const MyQueuePage(),
      _buildMoreScreen(),
    ];

    // 🔥 Start AI Listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _listener = QueueIntelligenceListener(
        queueRepo: ref.read(queueRepositoryProvider),
        aiRepo: ref.read(aiRepositoryProvider),
      );

      _listener!.start(user.uid);
    });
  }

  @override
  void dispose() {
    _listener?.stop();
    super.dispose();
  }

  // Build the appropriate screen based on selected index
  Widget _buildSelectedScreen() {
    return _screens[_selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IUTColors.background,
      appBar: _selectedIndex == 0
          ? null // No app bar for map screen (it has its own)
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 2,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QueueLens',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: IUTColors.primary,
                    ),
                  ),
                  Text(
                    'AI-Powered Queue Management',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                // AI Anomalies Badge
                Consumer(
                  builder: (context, ref, child) {
                    // This is a placeholder - you'll need to implement actual anomaly detection
                    final mockAnomalies = [
                      Anomaly(
                        id: 'anomaly_1',
                        type: AnomalyType.suddenJump,
                        serviceId: 'svc_registrar',
                        message: 'Queue jumped by 15 people',
                        severity: AnomalySeverity.high,
                        detectedAt: DateTime.now(),
                      ),
                    ];

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.warning_amber_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnomaliesPage(anomalies: mockAnomalies),
                              ),
                            );
                          },
                        ),
                        if (mockAnomalies.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                // Notification badge using real inbox data
                Consumer(
                  builder: (context, ref, child) {
                    final inbox = ref.watch(notificationInboxProvider);
                    final unreadCount = inbox.where((n) => !n.read).length;

                    return IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(fontSize: 10),
                        ),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      onPressed: _showNotifications,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  onPressed: _scanQRCode,
                ),
                IconButton(
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: IUTColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: _buildSelectedScreen(),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: _scanQRCode,
              backgroundColor: IUTColors.primary,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: IUTColors.primary,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_outlined),
            activeIcon: Icon(Icons.queue),
            label: 'My Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer(
      builder: (context, ref, child) {
        final servicesAsync = ref.watch(servicesStreamProvider);
        final myActiveEntryAsync = ref.watch(myActiveEntryProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: IUTColors.primary.withValues(
                    alpha: 0.2,
                  ), // Fixed: replaced withAlpha with withValues
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: IUTColors.primary.withValues(alpha: 0.15),
                  ), // Fixed: replaced withAlpha with withValues
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: IUTColors.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: IUTColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-powered queue management at your fingertips',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: IUTColors.success,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'AI Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Smart Predictions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Best Service Recommendation Card
              const BestServiceCard(),
              const SizedBox(height: 16),

              // Virtual Campus View Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VirtualCampusViewPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.view_in_ar,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Virtual Campus View',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Explore services in 3D view',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Access to Map
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 0; // Map tab
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore Campus Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Find services and locations',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Active Queues Section with AI Predictions
              myActiveEntryAsync.when(
                data: (entry) {
                  if (entry != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Active Queue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: IUTColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 3; // My Queue tab
                                });
                              },
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: IUTColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEnhancedQueueCard(ref, entry),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const SizedBox.shrink(),
              ),

              // All Services Section
              const Text(
                'Available Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: IUTColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No services available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Take only 4 services for the home grid
                  final homeServices = services.take(4).toList();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: homeServices.length,
                    itemBuilder: (context, index) {
                      final service = homeServices[index];
                      return _buildServiceCard(service);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading services',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // View All Services Button
              servicesAsync.when(
                data: (services) {
                  if (services.length > 4) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1; // Services tab
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IUTColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View All Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Quick Stats with AI Insights
              servicesAsync.when(
                data: (services) {
                  final openServices = services.where((s) => s.isOpen).length;
                  final totalWaitTime = services.fold<int>(
                    0,
                    (sum, service) => sum + service.estimatedWaitMinutes,
                  );
                  final avgWaitTime = services.isNotEmpty
                      ? (totalWaitTime / services.length).round()
                      : 0;

                  // AI Insight based on time of day
                  final hour = DateTime.now().hour;
                  String aiInsight = '';
                  Color insightColor = Colors.green;

                  if (hour >= 11 && hour <= 14) {
                    aiInsight = 'Peak hours • Expect longer waits';
                    insightColor = Colors.orange;
                  } else if (hour >= 8 && hour <= 10) {
                    aiInsight = 'Morning rush • Plan accordingly';
                    insightColor = Colors.blue;
                  } else if (hour >= 15 && hour <= 17) {
                    aiInsight = 'Afternoon busy • Check predictions';
                    insightColor = Colors.purple;
                  } else {
                    aiInsight = 'Optimal time • Minimal waits expected';
                    insightColor = Colors.green;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Stats',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: IUTColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: insightColor.withValues(
                                alpha: 0.2,
                              ), // Fixed: replaced withAlpha with withValues
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              aiInsight,
                              style: TextStyle(
                                fontSize: 11,
                                color: insightColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              icon: Icons.timer_outlined,
                              label: 'Avg. Wait Time',
                              value: '$avgWaitTime min',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatTile(
                              icon: Icons.people_outline,
                              label: 'Active Services',
                              value: '$openServices/${services.length}',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              icon: Icons.analytics_outlined,
                              label: 'AI Accuracy',
                              value: '92%',
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatTile(
                              icon: Icons.bolt_outlined,
                              label: 'Time Saved',
                              value: '~45 min',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedQueueCard(WidgetRef ref, QueueEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: IUTColors.primary.withValues(
                alpha: 0.2,
              ), // Fixed: replaced withAlpha with withValues
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getServiceIcon(entry.serviceId),
              color: IUTColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final serviceAsync = ref.watch(
                      serviceByIdProvider(entry.serviceId),
                    );

                    return serviceAsync.when(
                      data: (service) => Text(
                        service?.name ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: IUTColors.textPrimary,
                        ),
                      ),
                      loading: () => const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: IUTColors.textPrimary,
                        ),
                      ),
                      error: (error, _) => const Text(
                        'Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: IUTColors.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: entry.status == QueueEntryStatus.active
                            ? Colors.green.withValues(
                                alpha: 0.2,
                              ) // Fixed: replaced withAlpha with withValues
                            : Colors.orange.withValues(
                                alpha: 0.2,
                              ), // Fixed: replaced withAlpha with withValues
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: entry.status == QueueEntryStatus.active
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (entry.status == QueueEntryStatus.pending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(
                            alpha: 0.2,
                          ), // Fixed: replaced withAlpha with withValues
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.timeUntilCheckInExpiry.inMinutes}m',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'to check-in',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final entryWithPosAsync = ref.watch(
                entryWithPositionProvider('${entry.serviceId}:${entry.id}'),
              );

              return entryWithPosAsync.when(
                data: (entryWithPos) {
                  final position = entryWithPos?.position ?? 0;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: IUTColors.primary.withValues(
                            alpha: 0.2,
                          ), // Fixed: replaced withAlpha with withValues
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          position > 0 ? 'Position #$position' : 'Waiting',
                          style: const TextStyle(
                            color: IUTColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (position > 0) ...[
                        const SizedBox(height: 8),
                        WaitTimeBadge(
                          serviceId: entry.serviceId,
                          position: position,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => const Text(
                  '~0 min',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServicePoint service) {
    return GestureDetector(
      onTap: () => _joinService(service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getServiceColor(service.id).withValues(
                        alpha: 0.2,
                      ), // Fixed: replaced withAlpha with withValues
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getServiceIcon(service.id),
                      color: _getServiceColor(service.id),
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: service.isOpen
                          ? Colors.green.withValues(
                              alpha: 0.2,
                            ) // Fixed: replaced withAlpha with withValues
                          : Colors.red.withValues(
                              alpha: 0.2,
                            ), // Fixed: replaced withAlpha with withValues
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 10,
                        color: service.isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                service.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: IUTColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service.description,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.activeCount + service.pendingCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: IUTColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final position =
                          service.pendingCount + service.activeCount;
                      if (position > 0) {
                        return WaitTimeBadge(
                          serviceId: service.id,
                          position: position,
                        );
                      }
                      return Text(
                        '${service.estimatedWaitMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: service.estimatedWaitMinutes > 15
                              ? Colors.red
                              : Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.2,
              ), // Fixed: replaced withAlpha with withValues
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: IUTColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMoreScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'More Options',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: IUTColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSettings,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('AI Analytics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VirtualCampusViewPage(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Anomaly Detection'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final mockAnomalies = [
                Anomaly(
                  id: 'anomaly_1',
                  type: AnomalyType.suddenJump,
                  serviceId: 'svc_registrar',
                  message: 'Queue jumped by 15 people',
                  severity: AnomalySeverity.high,
                  detectedAt: DateTime.now(),
                ),
                Anomaly(
                  id: 'anomaly_2',
                  type: AnomalyType.highExpireRate,
                  serviceId: 'svc_library_print',
                  message: 'High expired entries detected',
                  severity: AnomalySeverity.medium,
                  detectedAt: DateTime.now().subtract(
                    const Duration(minutes: 30),
                  ),
                ),
              ];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnomaliesPage(anomalies: mockAnomalies),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.help_outline_outlined),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showHelp,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About QueueLens'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper methods to get service-specific icons and colors
  IconData _getServiceIcon(String serviceId) {
    if (serviceId.contains('registrar')) return Icons.description_outlined;
    if (serviceId.contains('library')) return Icons.print_outlined;
    if (serviceId.contains('medical')) return Icons.local_hospital_outlined;
    if (serviceId.contains('accounts')) return Icons.account_balance_outlined;
    if (serviceId.contains('cafeteria')) return Icons.restaurant_outlined;
    return Icons.help_outline_outlined;
  }

  Color _getServiceColor(String serviceId) {
    if (serviceId.contains('registrar')) return Colors.blue;
    if (serviceId.contains('library')) return Colors.green;
    if (serviceId.contains('medical')) return Colors.red;
    if (serviceId.contains('accounts')) return Colors.orange;
    if (serviceId.contains('cafeteria')) return Colors.purple;
    return Colors.teal;
  }

  void _scanQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: IUTColors.primary),
            SizedBox(height: 16),
            Text(
              'Point your camera at a service point QR code to join the queue',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to QRScannerPage when implemented
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  void _joinService(ServicePoint service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${service.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current queue: ${service.activeCount + service.pendingCount} people',
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final position = service.pendingCount + service.activeCount;
                if (position > 0) {
                  return WaitTimeBadge(
                    serviceId: service.id,
                    position: position,
                  );
                }
                return Text(
                  'Estimated wait: ${service.estimatedWaitMinutes} minutes',
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Status: ${service.isOpen ? 'Open' : 'Closed'}'),
            if (service.isOpen) ...[
              const SizedBox(height: 8),
              Text(
                'AI Prediction: ${service.avgMinsPerPerson * (service.activeCount + service.pendingCount)} min',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: service.isOpen
                ? () {
                    Navigator.pop(context);
                    // Navigate to QRScannerPage or JoinQueueResultPage
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: service.isOpen ? IUTColors.primary : Colors.grey,
            ),
            child: Text(service.isOpen ? 'Join Queue' : 'Closed'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    final inbox = ref.watch(notificationInboxProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: inbox.length,
            itemBuilder: (context, index) {
              final notification = inbox[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.type == 'queue'
                      ? IUTColors.primary.withValues(
                          alpha: 0.2,
                        ) // Fixed: replaced withAlpha with withValues
                      : notification.type == 'alert'
                      ? Colors.red.withValues(
                          alpha: 0.2,
                        ) // Fixed: replaced withAlpha with withValues
                      : Colors.blue.withValues(
                          alpha: 0.2,
                        ), // Fixed: replaced withAlpha with withValues
                  child: Icon(
                    notification.type == 'queue'
                        ? Icons.queue_outlined
                        : notification.type == 'alert'
                        ? Icons.warning_outlined
                        : Icons.info_outlined,
                    color: notification.type == 'queue'
                        ? IUTColors.primary
                        : notification.type == 'alert'
                        ? Colors.red
                        : Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(notification.title),
                subtitle: Text(notification.message),
                trailing: Text(
                  _formatTime(
                    notification.createdAt,
                  ), // Fixed: changed 'timestamp' to 'createdAt'
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                tileColor: notification.read ? null : Colors.blue.shade50,
                onTap: () {
                  ref
                      .read(notificationInboxProvider.notifier)
                      .markRead(notification.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationInboxProvider.notifier).markAllRead();
              Navigator.pop(context);
            },
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Settings'),
            SizedBox(height: 8),
            Text('AI Prediction Settings'),
            SizedBox(height: 8),
            Text('Location Services'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use QueueLens:'),
            SizedBox(height: 8),
            Text('1. Scan QR code at service point'),
            Text('2. View real-time queue status'),
            Text('3. Get AI-powered wait predictions'),
            Text('4. Receive notifications before your turn'),
            SizedBox(height: 16),
            Text('AI Features:'),
            Text('• Smart wait time predictions'),
            Text('• Best service recommendations'),
            Text('• Anomaly detection'),
            Text('• 3D campus visualization'),
            SizedBox(height: 16),
            Text('For support, contact: support@queuelens.edu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About QueueLens'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QueueLens v2.0.0'),
            SizedBox(height: 4),
            Text('AI-Powered Queue Management System'),
            SizedBox(height: 8),
            Text('Islamic University of Technology'),
            Text('Department of Computer Science and Engineering'),
            SizedBox(height: 16),
            Text('Core Features:'),
            Text('• Real-time queue tracking'),
            Text('• AI wait time predictions'),
            Text('• Smart service recommendations'),
            Text('• 3D campus visualization'),
            Text('• Anomaly detection'),
            SizedBox(height: 16),
            Text('Developed by:'),
            Text('• Idris Rayan (220041257)'),
            Text('• Sunjoh Abdurazack (220041258)'),
            Text('• Abdrahman Yousouf (220041260)'),
            Text('• Usman Jabir (220041262)'),
            Text('• Ebrima Demba (220041264)'),
            Text('• Amadu Gbanyawai (220041266)'),
            Text('• Soumaila (220041267)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
