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
import '../core/theme/app_colors.dart'; // Import AppColors

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
          Text('A verification email will be sent to:',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(email,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
              'Please check your inbox and verify your email before signing in.',
              style: TextStyle(color: AppColors.lightOnSurfaceVariant)),
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
                          studentIdDisplay.isNotEmpty ? studentIdDisplay : student['studentID'] ?? 'Not available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.lightOnBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // VERTICAL SEPARATOR
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.lightBorder,
                  ),
                  // BATCH COLUMN ONLY - NO COUNTRY COLUMN
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Batch',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          batch.isNotEmpty ? batch : '--',
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

  // Helper function to simplify country names
  String _simplifyCountryName(String country) {
    // Simple string replacement without regex
    return country
        .replaceAll('Islamic Republic of ', '')
        .replaceAll('Republic of ', '')
        .replaceAll('Kingdom of ', '')
        .replaceAll('State of ', '')
        .replaceAll('People\'s Republic of ', '')
        .replaceAll('People\'s Democratic Republic of ', '')
        .replaceAll('Federal Republic of ', '')
        .replaceAll('Hashemite Kingdom of ', '')
        .replaceAll('Sultanate of ', '')
        .replaceAll('Arab Republic of ', '')
        .replaceAll('Great Socialist People\'s ', '')
        .replaceAll('Union of The ', '')
        .trim();
  }

  // Helper function to get country emoji
  String _getCountryEmoji(String country) {
    final countryEmojiMap = {
      'afghanistan': '🇦🇫',
      'albania': '🇦🇱',
      'algeria': '🇩🇿',
      'azerbaijan': '🇦🇿',
      'bahrain': '🇧🇭',
      'bangladesh': '🇧🇩',
      'benin': '🇧🇯',
      'brunei': '🇧🇳',
      'burkina faso': '🇧🇫',
      'cameroon': '🇨🇲',
      'chad': '🇹🇩',
      'comoros': '🇰🇲',
      'côte d\'ivoire': '🇨🇮',
      'djibouti': '🇩🇯',
      'egypt': '🇪🇬',
      'gabon': '🇬🇦',
      'gambia': '🇬🇲',
      'guinea': '🇬🇳',
      'guinea-bissau': '🇬🇼',
      'guyana': '🇬🇾',
      'indonesia': '🇮🇩',
      'iran': '🇮🇷',
      'iraq': '🇮🇶',
      'jordan': '🇯🇴',
      'kazakhstan': '🇰🇿',
      'kuwait': '🇰🇼',
      'kyrgyzstan': '🇰🇬',
      'lebanon': '🇱🇧',
      'libya': '🇱🇾',
      'malaysia': '🇲🇾',
      'maldives': '🇲🇻',
      'mali': '🇲🇱',
      'mauritania': '🇲🇷',
      'morocco': '🇲🇦',
      'mozambique': '🇲🇿',
      'niger': '🇳🇪',
      'nigeria': '🇳🇬',
      'oman': '🇴🇲',
      'pakistan': '🇵🇰',
      'palestine': '🇵🇸',
      'qatar': '🇶🇦',
      'saudi arabia': '🇸🇦',
      'senegal': '🇸🇳',
      'sierra leone': '🇸🇱',
      'somalia': '🇸🇴',
      'sudan': '🇸🇩',
      'suriname': '🇸🇷',
      'syria': '🇸🇾',
      'tajikistan': '🇹🇯',
      'togo': '🇹🇬',
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
      if (normalizedCountry.contains(entry.key) || entry.key.contains(normalizedCountry)) {
        return entry.value;
      }
    }
    
    return '👨‍🎓';
  }
}

// Main SignupFormScreen (unchanged from your Version B)
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.scannedStudent['name'],
    );
    _passwordController.addListener(() => setState(() {}));
  }

  void _validateEmail() {
    final email = _emailController.text;
    if (email.isNotEmpty && !RegExp(r'@iut-dhaka\.edu$').hasMatch(email)) {
      setState(() => _emailError = 'Must use @iut-dhaka.edu email');
    } else {
      setState(() => _emailError = null);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationReminderDialog(
        email: _emailController.text,
        onClose: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationScreen(email: _emailController.text),
            ),
          );
        },
      ),
    );
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
                style: TextStyle(fontSize: 16, color: AppColors.lightOnSurfaceVariant),
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
                        onPressed: () {
                          if (_emailError == null && _emailController.text.isNotEmpty) {
                            _showVerificationDialog();
                          } else if (_emailController.text.isEmpty) {
                            setState(() => _emailError = 'Email is required');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
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