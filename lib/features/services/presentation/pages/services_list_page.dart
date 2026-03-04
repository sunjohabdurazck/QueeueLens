// lib/features/services/presentation/pages/services_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/services_providers.dart';
import '../widgets/service_tile.dart';
import 'service_details_page.dart';
import 'scan_queue_qr_page.dart'; // ✅ add this

class ServicesListPage extends ConsumerWidget {
  const ServicesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(filteredServicesProvider);
    final showOpenOnly = ref.watch(showOpenOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        elevation: 0,
        actions: [
          // ✅ Scan QR Button
          IconButton(
            tooltip: "Scan Queue QR",
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanQueueQrPage()),
              );
            },
          ),

          // (kept from your file)
          IconButton(
            tooltip: "Switch theme",
            onPressed: () {
              final themeModeProvider = StateProvider<ThemeMode>(
                (ref) => ThemeMode.light,
              );
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: Consumer(
              builder: (context, ref, child) {
                final themeModeProvider = StateProvider<ThemeMode>(
                  (ref) => ThemeMode.light,
                );
                final themeMode = ref.watch(themeModeProvider);
                return Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.searchServices,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text(AppStrings.showOpenOnly),
                      selected: showOpenOnly,
                      onSelected: (value) {
                        ref.read(showOpenOnlyProvider.notifier).state = value;
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: showOpenOnly ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    servicesAsync.whenData((services) {
                          return Text(
                            '${services.length} service${services.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          );
                        }).value ??
                        const SizedBox(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noServices,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceTile(
                service: service,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailsPage(serviceId: service.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                AppStrings.errorLoading,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(servicesStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
