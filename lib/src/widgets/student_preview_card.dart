import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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
    
    // Extract last 2 digits of batch from studentID if batch is not provided
    String batch = student['batch'] ?? '';
    if (batch.isEmpty) {
      final studentID = student['studentID'] ?? student['studentId'] ?? '';
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
    }

    // Get simplified country name
    final originalCountry = student['country'] ?? '';
    final simplifiedCountry = _simplifyCountryName(originalCountry);

    // Get student ID (simplified - just the number without dashes)
    String studentIdDisplay = student['studentID'] ?? student['studentId'] ?? '';
    // Extract just the number part if it contains dashes
    if (studentIdDisplay.contains('-')) {
      final parts = studentIdDisplay.split('-');
      if (parts.length >= 4) {
        // Format: "2023-1-60-123" -> we want just "220021258" or last part
        // Assuming the last part is the student number
        studentIdDisplay = parts.last;
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
                // Country flag emoji
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
                  // Student ID Column
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
                          studentIdDisplay.isNotEmpty ? studentIdDisplay : 'Not available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.lightOnBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Vertical separator
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.lightBorder,
                  ),
                  // Batch Column
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

  // Helper to simplify country name
  String _simplifyCountryName(String country) {
    // Simple cleanup
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

  // Country emoji helper
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
    
    // Try exact match
    if (countryEmojiMap.containsKey(normalizedCountry)) {
      return countryEmojiMap[normalizedCountry]!;
    }
    
    // Try partial match
    for (final entry in countryEmojiMap.entries) {
      if (normalizedCountry.contains(entry.key) || entry.key.contains(normalizedCountry)) {
        return entry.value;
      }
    }
    
    return '👨‍🎓'; // Default student emoji
  }
}