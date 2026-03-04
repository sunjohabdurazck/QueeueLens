import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../domain/entities/surveillance_camera.dart';

/// Sample camera data for testing
/// Run this function once to populate Firestore with sample cameras
/// Usage: await seedSampleCameras();
Future<void> seedSampleCameras() async {
  final firestore = FirebaseFirestore.instance;
  final cameras = _getSampleCameras();

  for (final camera in cameras) {
    await firestore.collection('surveillance_cameras').doc(camera.id).set({
      'serviceId': camera.serviceId,
      'name': camera.name,
      'streamUrl': camera.streamUrl,
      'type': camera.type.index,
      'isActive': camera.isActive,
      'position': {
        'x': camera.position.x,
        'y': camera.position.y,
        'z': camera.position.z,
      },
      'description': camera.description,
      'lastActive': camera.lastActive != null
          ? Timestamp.fromDate(camera.lastActive!)
          : null,
    });
  }

  print('✅ Successfully seeded ${cameras.length} sample cameras');
}

List<SurveillanceCamera> _getSampleCameras() {
  // Base IP for all cameras (for testing)
  const String baseIp = 'http://192.168.1.102:8080/video';

  return [
    // Registrar Office cameras
    SurveillanceCamera(
      id: 'cam_registrar_counter',
      serviceId: 'svc_registrar',
      name: 'Registrar Counter View',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: -10, y: 12, z: 0),
      description: 'Service counter and queue area',
      lastActive: DateTime.now(),
    ),

    SurveillanceCamera(
      id: 'cam_registrar_waiting',
      serviceId: 'svc_registrar',
      name: 'Registrar Waiting Area',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: -8, y: 10, z: -5),
      description: 'Waiting room monitoring',
      lastActive: DateTime.now(),
    ),

    // ICT Printing cameras
    SurveillanceCamera(
      id: 'cam_ict_printing_front',
      serviceId: 'svc_library_print',
      name: 'ICT Printing Front Desk',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 0, y: 15, z: 0),
      description: 'Main printing service counter',
      lastActive: DateTime.now(),
    ),

    SurveillanceCamera(
      id: 'cam_ict_printing_queue',
      serviceId: 'svc_library_print',
      name: 'ICT Printing Queue Area',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 5, y: 10, z: 3),
      description: 'Queue line for printing services',
      lastActive: DateTime.now(),
    ),

    // Medical Center cameras
    SurveillanceCamera(
      id: 'cam_medical_reception',
      serviceId: 'svc_medical',
      name: 'Medical Center Reception',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: false,
      position: const CameraPosition(x: -15, y: 12, z: -8),
      description: 'Medical reception and waiting area',
    ),

    // Accounts Office cameras
    SurveillanceCamera(
      id: 'cam_accounts_counter',
      serviceId: 'svc_accounts',
      name: 'Accounts Payment Counter',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 15, y: 12, z: 5),
      description: 'Payment and fee processing counter',
      lastActive: DateTime.now(),
    ),

    // Cafeteria cameras
    SurveillanceCamera(
      id: 'cam_cafeteria_main',
      serviceId: 'svc_cafeteria',
      name: 'Cafeteria Main Hall',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 15, y: 12, z: -5),
      description: 'Main dining area overview',
      lastActive: DateTime.now(),
    ),

    SurveillanceCamera(
      id: 'cam_cafeteria_queue',
      serviceId: 'svc_cafeteria',
      name: 'Cafeteria Queue Line',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 12, y: 10, z: 8),
      description: 'Food service queue monitoring',
      lastActive: DateTime.now(),
    ),

    // Library cameras
    SurveillanceCamera(
      id: 'cam_library_front',
      serviceId: 'svc_library',
      name: 'Library Front Entrance',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 8, y: 15, z: -10),
      description: 'Main library entrance',
      lastActive: DateTime.now(),
    ),

    SurveillanceCamera(
      id: 'cam_library_reading',
      serviceId: 'svc_library',
      name: 'Library Reading Area',
      streamUrl: baseIp, // Using same IP for testing
      type: CameraType.ipWebcam,
      isActive: true,
      position: const CameraPosition(x: 10, y: 12, z: -12),
      description: 'Main reading hall',
      lastActive: DateTime.now(),
    ),
  ];
}

/// Helper function to test a camera connection
Future<bool> testCameraConnection(String streamUrl) async {
  try {
    // For HTTP/MJPEG streams
    if (streamUrl.startsWith('http')) {
      final response = await http.get(Uri.parse(streamUrl));
      return response.statusCode == 200;
    }

    // For RTSP streams, we just return true
    // In production, you'd want to actually test the RTSP connection
    if (streamUrl.startsWith('rtsp')) {
      return true;
    }

    return false;
  } catch (e) {
    print('❌ Connection test failed: $e');
    return false;
  }
}

/// Get camera recommendations based on budget
Map<String, List<String>> getCameraRecommendations() {
  return {
    'budget_friendly': [
      'Use old smartphones with IP Webcam app',
      'Raspberry Pi with Camera Module v2 (~\$30)',
      'USB webcams with computer (~\$20-40)',
      'Wyze Cam v3 (~\$35)',
    ],
    'mid_range': [
      'TP-Link Tapo C200 (~\$30-40)',
      'Xiaomi Mi Home Security Camera 360° (~\$40)',
      'Reolink E1 Zoom (~\$50)',
      'Eufy Indoor Cam 2K (~\$50)',
    ],
    'professional': [
      'Hikvision DS-2CD2xxx series (~\$100-150)',
      'Dahua IPC-HDW2xxx (~\$80-120)',
      'Amcrest ProHD (~\$70-100)',
      'UniFi Protect cameras (~\$100-300)',
    ],
    'diy_solutions': [
      'ESP32-CAM module (~\$10) - requires programming',
      'OBS Studio on laptop - free software streaming',
      'DroidCam - turn Android into webcam',
      'Restream old GoPro or action cameras',
    ],
  };
}

/// Network configuration tips
const String networkSetupGuide = '''
NETWORK SETUP FOR CAMERAS
=========================

1. Static IP Assignment:
   - Router settings → DHCP → Reserve IP
   - Assign fixed IP to each camera device
   - Document all IP addresses

2. Port Forwarding (for remote access):
   - Forward ports 8080, 8554 (or custom)
   - Use different ports for each camera
   - Enable UPnP if available

3. WiFi Optimization:
   - Use 5GHz band for cameras
   - Place router centrally
   - Avoid physical obstacles
   - Consider WiFi extenders

4. Bandwidth Calculation:
   - 480p: ~1 Mbps per camera
   - 720p: ~2-3 Mbps per camera
   - 1080p: ~4-5 Mbps per camera
   
   Example: 5 cameras at 720p = 10-15 Mbps upload needed

5. Security:
   - Change default passwords
   - Use WPA3 encryption
   - Enable MAC filtering
   - Disable WPS
   - Use VPN for remote access
''';

/// iPhone XR IP Webcam setup guide
const String iphoneWebcamSetup = '''
IPHONE XR AS IP WEBCAM
======================

Option 1: IP Webcam App
-----------------------
1. Install "IP Webcam" from App Store
2. Open app and tap "Start Server"
3. Note the URL shown (e.g., http://192.168.1.102:8080/video)
4. Test in browser on another device
5. Add to QueeueLens with the video endpoint

Option 2: EpocCam
-----------------
1. Install EpocCam from App Store
2. Install EpocCam Viewer on computer
3. Connect via WiFi or USB
4. Stream URL: http://[computer-ip]:8080/video

Option 3: DroidCam (if jailbroken)
-----------------------------------
1. Install DroidCam on iPhone
2. Install DroidCam Client on computer
3. Connect and note the URL
4. Stream URL format: http://[ip]:4747/video

Configuration Tips:
-------------------
- Resolution: 720p (good balance)
- FPS: 15-20 (smooth enough, saves bandwidth)
- Quality: Medium-High
- Enable "Stay Awake" in app settings
- Connect charger for continuous operation
- Use airplane mode to disable calls/notifications
''';
