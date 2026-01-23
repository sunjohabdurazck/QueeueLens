class QRData {
  final String name;
  final String studentID;
  final String country;
  final String department;

  const QRData({
    required this.name,
    required this.studentID,
    required this.country,
    required this.department,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QRData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          studentID == other.studentID &&
          country == other.country &&
          department == other.department;

  @override
  int get hashCode =>
      name.hashCode ^
      studentID.hashCode ^
      country.hashCode ^
      department.hashCode;

  @override
  String toString() =>
      'QRData(name: $name, studentID: $studentID, country: $country, department: $department)';
}
