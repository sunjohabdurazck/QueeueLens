import 'dart:convert'; // Add this for jsonDecode
import '/src/features/shared/qr_scanner/domain/entities/qr_data.dart';
import 'package:dartz/dartz.dart';
// Make sure this path is correct - based on your structure:
import '../../data/models/qr_data_model.dart'; // This should import QRDataModel

class ParseQRData {
  Either<QRParseError, QRData> call(String qrCodeData) {
    try {
      // Try to parse as JSON first
      try {
        final json = jsonDecode(qrCodeData) as Map<String, dynamic>;
        final model = QRDataModel.fromJson(json);
        return _validateAndReturn(model);
      } catch (_) {
        // If not JSON, try parsing as plain text format
        return _parsePlainText(qrCodeData);
      }
    } catch (e) {
      print('Parse error: $e'); // For debugging
      return Left(QRParseError.parsingFailed);
    }
  }

  Either<QRParseError, QRData> _parsePlainText(String text) {
    final lines = text.trim().split('\n');

    // Remove any empty lines
    final nonEmptyLines =
        lines.where((line) => line.trim().isNotEmpty).toList();

    print(
        'Parsing plain text with ${nonEmptyLines.length} lines: $nonEmptyLines'); // Debug

    // We need at least 4 lines for the basic format
    if (nonEmptyLines.length < 4) {
      return Left(QRParseError.invalidFormat);
    }

    String studentID = '';
    String name = '';
    String country = '';
    String department = '';

    // Try to extract data - look for patterns
    for (final line in nonEmptyLines) {
      final trimmedLine = line.trim();

      // Check if it's a student ID (9 digits)
      if (RegExp(r'^\d{9}$').hasMatch(trimmedLine) && studentID.isEmpty) {
        studentID = trimmedLine;
      }
      // Check if it looks like a name (contains letters and spaces)
      else if (RegExp(r'^[A-Za-z\s]+$').hasMatch(trimmedLine) &&
          trimmedLine.length > 2 &&
          name.isEmpty &&
          !_isCountry(trimmedLine) &&
          !_isDepartment(trimmedLine)) {
        name = trimmedLine;
      }
      // Check for known countries
      else if (_isCountry(trimmedLine) && country.isEmpty) {
        country = trimmedLine;
      }
      // Check for department (short codes like EEE, CSE, etc.)
      else if (_isDepartment(trimmedLine) && department.isEmpty) {
        department = trimmedLine;
      }
    }

    // If we couldn't find by pattern, use positional fallback
    if (studentID.isEmpty && nonEmptyLines[0].trim().isNotEmpty) {
      studentID = nonEmptyLines[0].trim();
    }
    if (name.isEmpty && nonEmptyLines.length > 1) {
      name = nonEmptyLines[1].trim();
    }
    if (country.isEmpty && nonEmptyLines.length > 2) {
      country = nonEmptyLines[2].trim();
    }
    if (department.isEmpty && nonEmptyLines.length > 3) {
      department = nonEmptyLines[3].trim();
    }

    // Filter out promotional text
    final promotionalKeywords = [
      'Open an Account Online',
      'No Monthly Fees',
      'Member FDIC',
      'Apply Now',
      'Open in Minutes'
    ];

    for (final keyword in promotionalKeywords) {
      if (department.contains(keyword)) {
        department = department.replaceAll(keyword, '').trim();
      }
    }

    final model = QRDataModel(
      name: name,
      studentID: studentID,
      country: country,
      department: department,
    );

    print('Parsed: $model'); // Debug
    return _validateAndReturn(model);
  }

  bool _isCountry(String text) {
    final countries = [
      'Cameroon',
      'Bangladesh',
      'Chad',
      'Gambia',
      'Egypt',
      'Nigeria'
    ];
    return countries.contains(text);
  }

  bool _isDepartment(String text) {
    final departments = [
      'EEE',
      'CSE',
      'MPE',
      'ME',
      'CEE',
      'Computer Science',
      'Engineering'
    ];
    return departments.contains(text);
  }

  Either<QRParseError, QRData> _validateAndReturn(QRDataModel model) {
    final validationError = _validateData(model);
    if (validationError != null) {
      return Left(validationError);
    }
    return Right(model.toEntity());
  }

  QRParseError? _validateData(QRDataModel model) {
    if (model.name.trim().isEmpty) {
      return QRParseError.missingName;
    }
    if (model.studentID.trim().isEmpty) {
      return QRParseError.missingStudentID;
    }
    if (model.country.trim().isEmpty) {
      return QRParseError.missingCountry;
    }
    if (model.department.trim().isEmpty) {
      return QRParseError.missingDepartment;
    }

    final studentID = model.studentID.trim();
    if (!RegExp(r'^\d{9}$').hasMatch(studentID)) {
      return QRParseError.invalidStudentIDFormat;
    }

    return null;
  }
}

enum QRParseError {
  invalidFormat,
  parsingFailed,
  missingName,
  missingStudentID,
  missingCountry,
  missingDepartment,
  invalidStudentIDFormat,
}

extension QRParseErrorExtension on QRParseError {
  String get message {
    switch (this) {
      case QRParseError.invalidFormat:
        return 'Invalid QR code format';
      case QRParseError.parsingFailed:
        return 'Failed to parse QR code data';
      case QRParseError.missingName:
        return 'Student name is missing';
      case QRParseError.missingStudentID:
        return 'Student ID is missing';
      case QRParseError.missingCountry:
        return 'Country is missing';
      case QRParseError.missingDepartment:
        return 'Department is missing';
      case QRParseError.invalidStudentIDFormat:
        return 'Student ID must be exactly 9 digits';
    }
  }
}
