import 'package:flutter_test/flutter_test.dart';
import 'parse_qr_data.dart';

void main() {
  late ParseQRData parseQRData;

  setUp(() {
    parseQRData = ParseQRData();
  });

  group('ParseQRData', () {
    const validQRJson = '''
    {
      "name": "Sunjoh Abdurazack",
      "studentID": "220041258",
      "country": "Cameroon",
      "department": "Computer Science & Engineering"
    }
    ''';

    test('should parse valid QR code successfully', () {
      final result = parseQRData(validQRJson);

      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Should not return error: ${error.message}'),
        (data) {
          expect(data.name, 'Sunjoh Abdurazack');
          expect(data.studentID, '220041258');
          expect(data.country, 'Cameroon');
          expect(data.department, 'Computer Science & Engineering');
        },
      );
    });

    test('should return error for invalid JSON format', () {
      const invalidJson = 'not a json';
      final result = parseQRData(invalidJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.invalidFormat),
        (_) => fail('Should return error'),
      );
    });

    test('should return error for invalid student ID format', () {
      const invalidIDJson = '''
      {
        "name": "Sujoh Abdurazack",
        "studentID": "12345",
        "country": "Bangladesh",
        "department": "CSE"
      }
      ''';

      final result = parseQRData(invalidIDJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.invalidStudentIDFormat),
        (_) => fail('Should return error'),
      );
    });

    test('should return error for missing name', () {
      const missingNameJson = '''
      {
        "name": "",
        "studentID": "220041258",
        "country": "Cameroon",
        "department": "CSE"
      }
      ''';

      final result = parseQRData(missingNameJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.missingName),
        (_) => fail('Should return error'),
      );
    });

    test('should return error for missing student ID', () {
      const missingIDJson = '''
      {
        "name": "Sunjoh Abdurazack",
        "studentID": "",
        "country": "Cameroon",
        "department": "CSE"
      }
      ''';

      final result = parseQRData(missingIDJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.missingStudentID),
        (_) => fail('Should return error'),
      );
    });

    test('should return error for missing country', () {
      const missingCountryJson = '''
      {
        "name": "Ahmed Rahman",
        "studentID": "220031263",
        "country": "",
        "department": "CSE"
      }
      ''';

      final result = parseQRData(missingCountryJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.missingCountry),
        (_) => fail('Should return error'),
      );
    });

    test('should return error for missing department', () {
      const missingDeptJson = '''
      {
        "name": "Ahmed Rahman",
        "studentID": "220031263",
        "country": "Bangladesh",
        "department": ""
      }
      ''';

      final result = parseQRData(missingDeptJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.missingDepartment),
        (_) => fail('Should return error'),
      );
    });

    test('should handle parsing failed error', () {
      // Test with malformed JSON that doesn't match the model
      const malformedJson = '''
      {
        "name": "Ahmed Rahman",
        "studentID": "220031263",
        "country": "Bangladesh"
        // Missing department field
      }
      ''';

      final result = parseQRData(malformedJson);

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, QRParseError.parsingFailed),
        (_) => fail('Should return error'),
      );
    });
  });
}