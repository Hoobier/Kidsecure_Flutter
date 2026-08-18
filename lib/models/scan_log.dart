import 'student.dart';

/// Represents a single RFID entry/exit event for a student, synced to
/// Firebase Realtime Database from the admin portal's Laravel + MongoDB backend.
class ScanLog {
  final String id;
  final String studentId;
  final String studentName;
  final ScanStatus status;
  final DateTime timestamp;

  const ScanLog({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.timestamp,
  });

  factory ScanLog.fromRealtimeJson({
    required String id,
    required String studentId,
    required Map<String, dynamic> json,
  }) {
    final rawStatus = (json['status'] as String?)?.toLowerCase() ?? 'out';
    final rawTimestamp = json['timestamp'];
    final timestamp = rawTimestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
        : DateTime.parse(rawTimestamp.toString());

    return ScanLog(
      id: id,
      studentId: studentId,
      studentName: json['studentName'] as String? ?? 'Student',
      status: rawStatus == 'in' ? ScanStatus.in_ : ScanStatus.out_,
      timestamp: timestamp,
    );
  }
}
