import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../injection_container.dart' as di;
import '../domain/usecases/sign_in_usecase.dart';
import '../domain/entities/student.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/custom_textfield.dart';
import '../core/widgets/snackbars.dart';
import 'home_screen.dart';
import 'signup_web_screen.dart';
import 'signup_scan_qr_screen.dart';
import 'forgot_password_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exceptions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final SignInUseCase _signInUseCase;

  @override
  void initState() {
    super.initState();
    _signInUseCase = di.sl<SignInUseCase>();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final params = SignInParams(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _signInUseCase.call(params);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      showErrorSnackbar(context, e.message);
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      showErrorSnackbar(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to IUT',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        EmailTextField(controller: _emailController),
                        const SizedBox(height: 16),
                        PasswordTextField(
                          controller: _passwordController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Password required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Sign In',
                          onPressed: _isLoading ? null : _signIn,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (kIsWeb) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // builder: (_) => const SignupWebScreen()),
                                builder: (_) => const SignupScanQrScreen(),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScanQrScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
