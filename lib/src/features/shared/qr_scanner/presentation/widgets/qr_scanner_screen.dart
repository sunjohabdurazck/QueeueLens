import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../../domain/usecases/parse_qr_data.dart';
import '../../domain/entities/qr_data.dart';
import 'qr_scanner_overlay.dart';
import 'qr_scanner_controls.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(QRData) onQRScanned;
  final VoidCallback? onCancel;
  final Duration timeout;

  const QRScannerScreen({
    super.key,
    required this.onQRScanned,
    this.onCancel,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final ParseQRData _parseQRData = ParseQRData();
  Timer? _timeoutTimer;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted && !_isProcessing) {
        _showError('Scanner timeout. Please try again.');
        _close();
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _processQRCode(code);
  }

  void _processQRCode(String qrCode) {
    setState(() => _isProcessing = true);

    final result = _parseQRData(qrCode);

    result.fold(
      (error) {
        _showError(error.message);
        setState(() => _isProcessing = false);
      },
      (qrData) {
        _timeoutTimer?.cancel();
        HapticFeedback.mediumImpact();
        widget.onQRScanned(qrData);
      },
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleFlash() async {
    await _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  void _switchCamera() async {
    await _controller.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  void _close() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          const QRScannerOverlay(),
          // Controls
          QRScannerControls(
            isFlashOn: _isFlashOn,
            isFrontCamera: _isFrontCamera,
            onFlashToggle: _toggleFlash,
            onCameraSwitch: _switchCamera,
            onClose: _close,
          ),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
