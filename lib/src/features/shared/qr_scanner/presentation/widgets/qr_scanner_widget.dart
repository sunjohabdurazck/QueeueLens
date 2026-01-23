import 'package:flutter/material.dart';

class QRScannerControls extends StatelessWidget {
  final bool isFlashOn;
  final bool isFrontCamera;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraSwitch;
  final VoidCallback onClose;

  const QRScannerControls({
    super.key,
    required this.isFlashOn,
    required this.isFrontCamera,
    required this.onFlashToggle,
    required this.onCameraSwitch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with close button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash toggle
                _ControlButton(
                  icon: isFlashOn ? Icons.flash_off : Icons.flash_on,
                  label: isFlashOn ? 'Flash Off' : 'Flash On',
                  onPressed: onFlashToggle,
                ),
                // Camera switch
                _ControlButton(
                  icon: Icons.cameraswitch,
                  label: isFrontCamera ? 'Back Camera' : 'Front Camera',
                  onPressed: onCameraSwitch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}