import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/injection_container.dart' as di;
import 'src/screens/login_screen.dart';
import 'src/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await di.initDI(); 
  runApp(const IUTAuthApp()); 
}

class IUTAuthApp extends StatelessWidget {
  const IUTAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QueueLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
