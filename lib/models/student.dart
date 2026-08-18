/// Represents the current RFID entry/exit state for a student, as reported
/// by the ESP32 + RC522 turnstile scanner and synced from MongoDB Atlas
/// through the Laravel backend on Railway.
enum ScanStatus { in_, out_ }

class Student {
  final String id; // Mongo document _id / RTDB node key
  final String fullName;
  final String gradeSection; // e.g. "Grade 3 - Faith"
  final String? photoUrl;
  final ScanStatus status;
  final DateTime lastScanTime;

  const Student({
    required this.id,
    required this.fullName,
    required this.gradeSection,
    required this.status,
    required this.lastScanTime,
    this.photoUrl,
  });

  /// Builds a Student from the JSON payload returned by the admin portal's
  /// entry/exit logs API (GET /api/students/{id}/status).
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      gradeSection: json['gradeSection'] as String,
      photoUrl: json['photoUrl'] as String?,
      status: (json['status'] as String).toLowerCase() == 'in'
          ? ScanStatus.in_
          : ScanStatus.out_,
      lastScanTime: DateTime.parse(json['lastScanTime'] as String),
    );
  }

  /// Builds a Student from the Firebase Realtime Database shape you provided.
  factory Student.fromRealtimeJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    final rawStatus = (json['status'] as String?)?.toLowerCase() ?? 'out';
    final rawTimestamp = json['lastScanTime'];
    final lastScanTime = rawTimestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
        : DateTime.parse(rawTimestamp.toString());

    return Student(
      id: id,
      fullName: json['fullName'] as String? ?? '',
      gradeSection: json['gradeSection'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      status: rawStatus == 'in' ? ScanStatus.in_ : ScanStatus.out_,
      lastScanTime: lastScanTime,
    );
  }
}
