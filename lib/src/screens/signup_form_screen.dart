import 'package:flutter/material.dart';
import '../injection_container.dart' as di;
import '../domain/usecases/sign_up_usecase.dart';
import '../domain/entities/student.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/custom_textfield.dart';
import '../core/utils/validators.dart';
import '../core/widgets/snackbars.dart';
import '../widgets/password_strength_indicator.dart';
import 'email_verification_screen.dart';
import '../core/utils/exceptions.dart';
import '../core/theme/app_colors.dart';

// VerificationReminderDialog Widget (same as before)
class VerificationReminderDialog extends StatelessWidget {
  final String email;
  final VoidCallback onClose;

  const VerificationReminderDialog({
    super.key,
    required this.email,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Email Verification Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A verification email will be sent to:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Please check your inbox and verify your email before signing in.',
            style: TextStyle(color: AppColors.lightOnSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// Updated StudentPreviewCard Widget
class StudentPreviewCard extends StatelessWidget {
  final Map<String, String> student;

  const StudentPreviewCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    // DEBUG: Print the received student data
    print('StudentPreviewCard received:');
    student.forEach((key, value) {
      print('  $key: $value');
    });

    // Extract last 2 digits of batch from studentID
    String batch = '';
    final studentID = student['studentID'] ?? '';
    if (studentID.isNotEmpty) {
      // Try to extract batch from studentID format like "2023-1-60-123"
      final parts = studentID.split('-');
      if (parts.isNotEmpty) {
        final year = parts[0];
        if (year.length >= 2) {
          batch = year.substring(year.length - 2);
        }
      }
    }

    // Get simplified country name
    final originalCountry = student['country'] ?? '';
    final simplifiedCountry = _simplifyCountryName(originalCountry);

    // Simplify student ID display - extract just the number
    String studentIdDisplay = student['studentID'] ?? '';
    if (studentIdDisplay.contains('-')) {
      final parts = studentIdDisplay.split('-');
      if (parts.length >= 4) {
        // Format: "2023-1-60-123" -> get just the number part
        studentIdDisplay = parts.last; // e.g., "123"
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      _getCountryEmoji(simplifiedCountry),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightOnBackground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (student['department']?.isNotEmpty ?? false)
                        Text(
                          student['department']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // COUNTRY UNDER DEPARTMENT
                      if (simplifiedCountry.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              simplifiedCountry,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceVariant.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // STUDENT ID COLUMN ONLY
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Student ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          studentIdDisplay.isNotEmpty
                              ? studentIdDisplay
                              : student['studentID'] ?? 'Not available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.lightOnBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _simplifyCountryName(String country) {
    if (country.isEmpty) return '';
    final lower = country.toLowerCase();
    if (lower.contains('bangladesh')) return 'Bangladesh';
    if (lower.contains('india')) return 'India';
    if (lower.contains('pakistan')) return 'Pakistan';
    if (lower.contains('nepal')) return 'Nepal';
    if (lower.contains('afghanistan')) return 'Afghanistan';
    if (lower.contains('bhutan')) return 'Bhutan';
    if (lower.contains('maldives')) return 'Maldives';
    if (lower.contains('sri lanka')) return 'Sri Lanka';
    return country;
  }

  String _getCountryEmoji(String country) {
    final countryEmojiMap = {
      'afghanistan': '🇦🇫',
      'bahrain': '🇧🇭',
      'bangladesh': '🇧🇩',
      'bhutan': '🇧🇹',
      'egypt': '🇪🇬',
      'ethiopia': '🇪🇹',
      'gambia': '🇬🇲',
      'ghana': '🇬🇭',
      'india': '🇮🇳',
      'indonesia': '🇮🇩',
      'iran': '🇮🇷',
      'iraq': '🇮🇶',
      'jordan': '🇯🇴',
      'kenya': '🇰🇪',
      'kuwait': '🇰🇼',
      'lebanon': '🇱🇧',
      'libya': '🇱🇾',
      'malaysia': '🇲🇾',
      'maldives': '🇲🇻',
      'morocco': '🇲🇦',
      'nepal': '🇳🇵',
      'nigeria': '🇳🇬',
      'oman': '🇴🇲',
      'pakistan': '🇵🇰',
      'palestine': '🇵🇸',
      'qatar': '🇶🇦',
      'saudi arabia': '🇸🇦',
      'senegal': '🇸🇳',
      'somalia': '🇸🇴',
      'south africa': '🇿🇦',
      'sri lanka': '🇱🇰',
      'sudan': '🇸🇩',
      'syria': '🇸🇾',
      'tanzania': '🇹🇿',
      'tunisia': '🇹🇳',
      'turkey': '🇹🇷',
      'turkmenistan': '🇹🇲',
      'uganda': '🇺🇬',
      'uae': '🇦🇪',
      'uzbekistan': '🇺🇿',
      'yemen': '🇾🇪',
    };

    final normalizedCountry = country.toLowerCase();

    if (countryEmojiMap.containsKey(normalizedCountry)) {
      return countryEmojiMap[normalizedCountry]!;
    }

    for (final entry in countryEmojiMap.entries) {
      if (normalizedCountry.contains(entry.key) ||
          entry.key.contains(normalizedCountry)) {
        return entry.value;
      }
    }

    return '👨‍🎓';
  }
}

// Main SignupFormScreen - FIXED VERSION
class SignupFormScreen extends StatefulWidget {
  final Map<String, String> scannedStudent;

  const SignupFormScreen({super.key, required this.scannedStudent});

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  bool _isLoading = false; // ✅ ADDED
  late final SignUpUseCase _signUpUseCase; // ✅ ADDED

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.scannedStudent['name'],
    );
    _passwordController.addListener(() => setState(() {}));
    _signUpUseCase = di.sl<SignUpUseCase>(); // ✅ ADDED
  }

  void _validateEmail() {
    final email = _emailController.text;
    if (email.isNotEmpty && !RegExp(r'@iut-dhaka\.edu$').hasMatch(email)) {
      setState(() => _emailError = 'Must use @iut-dhaka.edu email');
    } else {
      setState(() => _emailError = null);
    }
  }

  // ✅ ADDED - ACTUAL SIGNUP FUNCTION
  Future<void> _performSignup() async {
    // Validate inputs
    if (_emailError != null) {
      showErrorSnackbar(context, _emailError!);
      return;
    }

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }

    if (_passwordController.text.isEmpty) {
      showErrorSnackbar(context, 'Password is required');
      return;
    }

    if (_passwordController.text.length < 8) {
      showErrorSnackbar(context, 'Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final student = Student(
        uid: '', // Will be filled by Firebase
        name: _nameController.text.trim(),
        studentId: widget.scannedStudent['studentID']!,
        email: _emailController.text.trim(),
        country: widget.scannedStudent['country'] ?? '',
        department: widget.scannedStudent['department'] ?? '',
      );

      await _signUpUseCase.call(
        SignUpParams(student: student, password: _passwordController.text),
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account Created'),
          content: Text(
            'A verification email has been sent to:\n\n'
            '${_emailController.text}\n\n'
            'Please verify your email before signing in.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate back to login
                int count = 0;
                Navigator.popUntil(context, (route) {
                  return count++ == 3; // Go back 3 screens to login
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Signup failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightOnBackground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in your details to create your account',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              StudentPreviewCard(student: widget.scannedStudent),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Full Name',
                      hint: widget.scannedStudent['name']!,
                      controller: _nameController,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email Address',
                      hint: 'your.email@iut-dhaka.edu',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (value) => _validateEmail(),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Phone Number',
                      hint: '+880 1XXX-XXXXXX',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PasswordStrengthIndicator(
                        password: _passwordController.text,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _performSignup, // ✅ FIXED
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading // ✅ ADDED LOADING STATE
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
