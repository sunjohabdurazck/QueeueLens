import 'package:flutter/material.dart';
import '../injection_container.dart' as di;

import '../core/utils/validators.dart';
import '../core/widgets/custom_textfield.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/snackbars.dart';
import '../core/theme/app_colors.dart';

import '../domain/entities/student.dart';
import '../domain/usecases/sign_up_usecase.dart';
import '../domain/repositories/auth_repository.dart' as domain;

class SignupWebScreen extends StatefulWidget {
  const SignupWebScreen({super.key});

  @override
  State<SignupWebScreen> createState() => _SignupWebScreenState();
}

class _SignupWebScreenState extends State<SignupWebScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _countryController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  late final SignUpUseCase _signUpUseCase;

  @override
  void initState() {
    super.initState();
    _signUpUseCase = di.sl<SignUpUseCase>();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final student = Student(
        uid: '', // repository will replace with Firebase UID
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(), // must be 9 digits
        email: _emailController.text.trim(),
        country: _countryController.text.trim(),
        department: _departmentController.text.trim(),
      );

      await _signUpUseCase.call(
        SignUpParams(
          student: student,
          password: _passwordController.text,
        ),
      );

      // signUp() already sends verification email.
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Account created'),
          content: Text(
            'A verification email was sent to:\n\n${_emailController.text.trim()}\n\n'
            'Please verify your email, then sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } on domain.AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Login'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Web sign up (no QR). Use your @iut-dhaka.edu email and a 9-digit Student ID.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightShadow,
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Your full name',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateName,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Student ID (9 digits)',
                            hint: 'e.g. 190041123',
                            controller: _studentIdController,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateStudentId,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Department',
                            hint: 'e.g. CSE',
                            controller: _departmentController,
                            prefixIcon: Icons.apartment_outlined,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateDepartment,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Country',
                            hint: 'e.g. Bangladesh',
                            controller: _countryController,
                            prefixIcon: Icons.public_outlined,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateCountry,
                          ),
                          const SizedBox(height: 14),
                          EmailTextField(
                            controller: _emailController,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Password',
                            hint: 'At least 8 chars (A-z + 0-9)',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: Validators.validatePassword,
                            onSubmitted: (_) => _isLoading ? null : _signUp(),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            text: 'Create Account',
                            onPressed: _isLoading ? null : _signUp,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
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
    _nameController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
