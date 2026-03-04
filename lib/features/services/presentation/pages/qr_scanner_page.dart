// lib/features/queue/presentation/pages/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/models/qr_payload.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../../../core/constants/app_strings.dart';
import 'join_queue_result_page.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  MobileScannerController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final qrData = QRPayload.parse(barcode!.rawValue!);

      if (qrData == null) {
        _showError(AppStrings.invalidQR);
        return;
      }

      if (qrData.isExpired) {
        _showError(AppStrings.qrExpired);
        return;
      }

      // Verify service exists
      final servicesAsync = ref.read(servicesStreamProvider);
      final services = servicesAsync.valueOrNull;
      final service = services?.firstWhere(
        (s) => s.id == qrData.serviceId,
        orElse: () => throw Exception('Service not found'),
      );

      if (service == null) {
        _showError('Service not found');
        return;
      }

      if (!service.isOpen) {
        _showError(AppStrings.serviceClosed);
        return;
      }

      // Navigate to join result page
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => JoinQueueResultPage(
              serviceId: qrData.serviceId,
              serviceName: service.name,
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scanQR), elevation: 0),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Overlay
          Container(
            decoration: const BoxDecoration(
              color: Color(0x80000000), // 50% opacity black
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xB3000000), // 70% opacity black
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Text(
                      AppStrings.scanToJoin,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: const Color(0xB3000000), // 70% opacity black
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
