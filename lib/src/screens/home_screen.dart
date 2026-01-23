import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back! 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: IUTColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Here's what's happening today",
                        style: TextStyle(
                          fontSize: 16,
                          color: IUTColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: IUTColors.border, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: IUTColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    value: 'Complete',
                    color: IUTColors.primary,
                  ),
                  _buildStatCard(
                    icon: Icons.shield_outlined,
                    label: 'Security',
                    value: 'Verified',
                    color: IUTColors.success,
                  ),
                  _buildStatCard(
                    icon: Icons.mail_outline,
                    label: 'Messages',
                    value: '12 New',
                    color: IUTColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: IUTColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: IUTColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Dashboard Coming Soon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: IUTColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your personalized dashboard with courses, grades, and more will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: IUTColors.textSecondary,
                        height: 1.5,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IUTColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: IUTColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: IUTColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
