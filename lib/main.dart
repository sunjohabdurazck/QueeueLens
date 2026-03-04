// lib/main.dart - Complete Firestore debugger version (Multi-platform)
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-specific WebView imports
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// Conditionally import platform-specific implementations
import 'package:webview_flutter_android/webview_flutter_android.dart'
    if (dart.library.html) 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'
    if (dart.library.html) 'package:webview_flutter_web/webview_flutter_web.dart';

import 'core/notifications/notification_manager.dart';
import 'core/geofencing/geofence_background_service.dart';

import 'features/services/presentation/pages/queue_test_page.dart';
import 'features/surveillance/data/sample_camera_data.dart';

import 'src/injection_container.dart' as di;
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'firebase_options.dart';

// ============================
// FIRESTORE DEBUGGER CLASS
// ============================
class FirestoreDebugger {
  static final List<Map<String, dynamic>> _operations = [];

  static void logRequest({
    required String operation,
    required String path,
    required Map<String, dynamic>? data,
    required String method,
    StackTrace? stackTrace,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final timestamp = DateTime.now();

    final logEntry = {
      'timestamp': timestamp,
      'operation': operation,
      'path': path,
      'method': method,
      'data': data,
      'userUid': user?.uid,
      'userEmail': user?.email,
      'stackTrace': stackTrace?.toString().split('\n').take(5).join('\n'),
    };

    _operations.add(logEntry);

    dev.log(
      '''
📡 FIRESTORE REQUEST [${timestamp.toIso8601String()}]
  Operation: $operation
  Path: $path
  Method: $method
  User: ${user?.uid} (${user?.email})
  Data: ${data?.toString() ?? 'N/A'}
''',
      name: "FIRESTORE_DEBUG",
      stackTrace: stackTrace,
    );

    if (_operations.length > 100) {
      _operations.removeAt(0);
    }
  }

  static void logResponse({
    required String path,
    required String method,
    required dynamic result,
    required Duration duration,
  }) {
    dev.log('''
✅ FIRESTORE SUCCESS
  Path: $path
  Method: $method
  Duration: ${duration.inMilliseconds}ms
  Result: ${result is DocumentSnapshot
        ? 'Document (exists: ${result.exists})'
        : result is QuerySnapshot
        ? 'Query (${result.docs.length} docs)'
        : result.toString()}
''', name: "FIRESTORE_DEBUG");
  }

  static void logError({
    required String path,
    required String method,
    required dynamic error,
    required StackTrace stackTrace,
    required Map<String, dynamic>? data,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    dev.log(
      '''
🔥 FIRESTORE ERROR
  Path: $path
  Method: $method
  User: ${user?.uid} (${user?.email})
  Error Type: ${error.runtimeType}
  Error: $error
  Data Attempted: ${data?.toString() ?? 'N/A'}
  
  ${error is FirebaseException ? '''
  FIREBASE EXCEPTION DETAILS:
    Code: ${error.code}
    Message: ${error.message}
    Plugin: ${error.plugin}
    
  PERMISSION_DENIED TROUBLESHOOTING:
    1. Check Firestore rules for: $path
    2. Verify user ${user?.uid} has access to ${method.toUpperCase()} operation
    3. Check if collection/document exists
    4. Verify field names in data match rules
  ''' : ''}
  
  Stack Trace (first 5 lines):
  ${stackTrace.toString().split('\n').take(5).join('\n')}
''',
      name: "FIRESTORE_ERROR",
      error: error,
      stackTrace: stackTrace,
    );

    // Print to console for easy copying
    // ignore: avoid_print
    print('\n' + '=' * 80);
    // ignore: avoid_print
    print('🚨 FIRESTORE ERROR DETECTED 🚨');
    // ignore: avoid_print
    print('=' * 80);
    // ignore: avoid_print
    print('Time: ${DateTime.now().toIso8601String()}');
    // ignore: avoid_print
    print('User: ${user?.uid} (${user?.email})');
    // ignore: avoid_print
    print('Operation: $method $path');
    // ignore: avoid_print
    print('Error: $error');

    if (error is FirebaseException) {
      // ignore: avoid_print
      print('\n🔧 FIREBASE DIAGNOSTICS:');
      // ignore: avoid_print
      print('  Code: ${error.code}');
      // ignore: avoid_print
      print('  Message: ${error.message}');
      // ignore: avoid_print
      print('  Plugin: ${error.plugin}');

      if (error.code == 'permission-denied') {
        // ignore: avoid_print
        print('\n🔒 PERMISSION DENIED - COMMON FIXES:');
        // ignore: avoid_print
        print('  1. Go to Firebase Console → Firestore → Rules');
        // ignore: avoid_print
        print('  2. Check rules for collection: ${path.split('/').first}');
        // ignore: avoid_print
        print(
          '  3. Ensure rule allows ${method.toUpperCase()} for user ${user?.uid}',
        );
        // ignore: avoid_print
        print('  4. Add debug rule temporarily:');
        // ignore: avoid_print
        print('     allow read, write: if true;');
      }
    }

    // ignore: avoid_print
    print('\n📊 LAST 5 FIRESTORE OPERATIONS:');
    final recentOps = _operations.reversed.take(5).toList();
    for (var op in recentOps) {
      // ignore: avoid_print
      print(
        '  - ${op['timestamp'].toIso8601String()} ${op['method']} ${op['path']}',
      );
    }

    // ignore: avoid_print
    print('=' * 80 + '\n');
  }

  static Future<T> debugOperation<T>({
    required Future<T> Function() operation,
    required String path,
    required String method,
    Map<String, dynamic>? data,
    String? description,
  }) async {
    final startTime = DateTime.now();
    final stackTrace = StackTrace.current;

    logRequest(
      operation: description ?? method,
      path: path,
      data: data,
      method: method,
      stackTrace: stackTrace,
    );

    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime);

      logResponse(
        path: path,
        method: method,
        result: result,
        duration: duration,
      );

      return result;
    } catch (e, st) {
      logError(
        path: path,
        method: method,
        error: e,
        stackTrace: st,
        data: data,
      );
      rethrow;
    }
  }
}

// ============================
// FIRESTORE WRAPPER FUNCTIONS
// ============================
extension FirestoreDebugging on FirebaseFirestore {
  /// Build a CollectionReference from a slash path like:
  /// - "students"
  /// - "services/svc_library_print/entries"
  ///
  /// NOTE: This accepts only *collection* paths (odd number of segments).
  CollectionReference<Map<String, dynamic>> collectionPath(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) throw ArgumentError('Empty path');

    // collection paths have odd number of segments: col (1), col/doc/col (3), ...
    if (parts.length % 2 == 0) {
      throw ArgumentError(
        'Invalid collection path (looks like a document path): $path',
      );
    }

    CollectionReference<Map<String, dynamic>> ref = collection(parts.first);

    for (int i = 1; i < parts.length; i += 2) {
      ref = ref.doc(parts[i]).collection(parts[i + 1]);
    }

    return ref;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> debugGetDoc(
    String docPath, {
    String? description,
  }) {
    final parts = docPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length % 2 != 0)
      throw ArgumentError('Invalid document path: $docPath');

    final colPath = parts.sublist(0, parts.length - 1).join('/');
    final docId = parts.last;

    return FirestoreDebugger.debugOperation(
      operation: () => collectionPath(colPath).doc(docId).get(),
      path: docPath,
      method: 'GET',
      description: description ?? 'Get document $docPath',
    );
  }

  Future<void> debugSetDoc(
    String docPath,
    Map<String, dynamic> data, {
    SetOptions? options,
    String? description,
  }) {
    final parts = docPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length % 2 != 0)
      throw ArgumentError('Invalid document path: $docPath');

    final colPath = parts.sublist(0, parts.length - 1).join('/');
    final docId = parts.last;

    return FirestoreDebugger.debugOperation(
      operation: () => collectionPath(colPath).doc(docId).set(data, options),
      path: docPath,
      method: 'SET',
      data: data,
      description: description ?? 'Set document $docPath',
    );
  }
}

// ============================
// AUTOMATED FIRESTORE TESTER
// ============================
class FirestoreTester {
  static Future<void> runAllTests(User user) async {
    dev.log('🧪 Starting Firestore tests for ${user.email}', name: "TEST");

    await testCollectionAccess(user);
    await testDocumentOperations(user);
    await testRulesPermissions(user);
  }

  static Future<void> testCollectionAccess(User user) async {
    final collectionsToTest = [
      'students',
      'users',
      'services',
      'queue',
      'settings',
      'surveillance_cameras',
    ];

    for (final collection in collectionsToTest) {
      try {
        dev.log('Testing access to collection: $collection', name: "TEST");

        final result = await FirestoreDebugger.debugOperation(
          operation: () =>
              FirebaseFirestore.instance.collection(collection).limit(1).get(),
          path: collection,
          method: 'QUERY',
          description: 'Test read access to $collection',
        );

        dev.log(
          '✅ $collection: Can read (${result.docs.length} docs)',
          name: "TEST",
        );
      } catch (e) {
        dev.log('❌ $collection: Cannot read - $e', name: "TEST");
      }
    }
  }

  static Future<void> testDocumentOperations(User user) async {
    // Test 1: Try to read student document
    try {
      await FirestoreDebugger.debugOperation(
        operation: () => FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get(),
        path: 'students/${user.uid}',
        method: 'GET',
        description: 'Test read student by UID as doc ID',
      );
      dev.log('✅ Can read students/${user.uid}', name: "TEST");
    } catch (e) {
      dev.log('❌ Cannot read students/${user.uid}', name: "TEST");

      // Try query by uid field instead
      try {
        await FirestoreDebugger.debugOperation(
          operation: () => FirebaseFirestore.instance
              .collection('students')
              .where('uid', isEqualTo: user.uid)
              .limit(1)
              .get(),
          path: 'students',
          method: 'QUERY',
          description: 'Test query student by uid field',
        );
        dev.log('✅ Can query students where uid=${user.uid}', name: "TEST");
      } catch (e) {
        dev.log('❌ Cannot query students by uid field', name: "TEST");
      }
    }

    // Test 2: Try to create user document
    try {
      final testData = {
        'uid': user.uid,
        'email': user.email,
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirestoreDebugger.debugOperation(
        operation: () => FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(testData),
        path: 'users/${user.uid}',
        method: 'SET',
        data: testData,
        description: 'Test create user document',
      );
      dev.log('✅ Can create users/${user.uid}', name: "TEST");
    } catch (e) {
      dev.log('❌ Cannot create users/${user.uid}', name: "TEST");
    }

    // Test 3: Try to read surveillance cameras
    try {
      await FirestoreDebugger.debugOperation(
        operation: () => FirebaseFirestore.instance
            .collection('surveillance_cameras')
            .limit(2)
            .get(),
        path: 'surveillance_cameras',
        method: 'QUERY',
        description: 'Test read surveillance cameras',
      );
      dev.log('✅ Can read surveillance cameras', name: "TEST");
    } catch (e) {
      dev.log('❌ Cannot read surveillance cameras', name: "TEST");
    }
  }

  static Future<void> testRulesPermissions(User user) async {
    dev.log('Testing Firestore rules permissions...', name: "TEST");

    final tests = [
      {
        'path': 'services/test-service',
        'method': 'GET',
        'operation': () => FirebaseFirestore.instance
            .collection('services')
            .doc('test-service')
            .get(),
        'description': 'Test read service (should work for all)',
      },
      {
        'path': 'settings/app',
        'method': 'GET',
        'operation': () =>
            FirebaseFirestore.instance.collection('settings').doc('app').get(),
        'description': 'Test read settings (should work if authenticated)',
      },
    ];

    for (final test in tests) {
      try {
        await (test['operation'] as Future Function())();
        dev.log('✅ ${test['description']}', name: "TEST");
      } catch (e) {
        dev.log('❌ ${test['description']}: $e', name: "TEST");
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Init notifications + geofencing (web-safe)
  await NotificationManager.instance.init();

  if (!kIsWeb) {
    // Configure background service / geofence isolate only on Android/iOS
    await GeofenceBackgroundService.configure();
  }

  await Future.wait([
    Hive.openBox('ai_wait_stats'),
    Hive.openBox('logged_entries'),
  ]);

  // Initialize DI
  await di.initDI();

  // Seed sample cameras (only if collection is empty)
  try {
    final camerasSnapshot = await FirebaseFirestore.instance
        .collection('surveillance_cameras')
        .limit(1)
        .get();

    if (camerasSnapshot.docs.isEmpty) {
      await seedSampleCameras();
      dev.log('✅ Sample cameras seeded successfully', name: "SETUP");
    } else {
      dev.log('📊 Cameras already exist, skipping seeding', name: "SETUP");
    }
  } catch (e) {
    dev.log('⚠️ Could not check/seed cameras: $e', name: "SETUP");
  }

  // Setup auth state listener with debugging
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      dev.log('👤 User logged in: ${user.email} (${user.uid})', name: "AUTH");

      // Run Firestore tests automatically in background
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FirestoreTester.runAllTests(user);
      });
    } else {
      dev.log('👤 User logged out', name: "AUTH");
    }
  });

  // Monitor all Firestore operations
  _setupFirestoreMonitor();

  runApp(const IUTAuthApp());
}

void _setupFirestoreMonitor() {
  dev.log('🔍 Firestore debug monitor enabled', name: "DEBUG");
}

class IUTAuthApp extends StatelessWidget {
  const IUTAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'QueueLens - AI Queue Management',
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // User is logged in - go directly to HomeScreen
          return const HomeScreen();
        } else {
          // User is not logged in - show LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}
