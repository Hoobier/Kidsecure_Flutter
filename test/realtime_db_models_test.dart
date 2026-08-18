import 'package:flutter_test/flutter_test.dart';
import 'package:kidsecure_parent_app/models/scan_log.dart';
import 'package:kidsecure_parent_app/models/student.dart';

void main() {
  group('Realtime Database model parsing', () {
    test('parses a student snapshot from the RTDB structure', () {
      final student = Student.fromRealtimeJson(
        id: 'STU-00123',
        json: {
          'fullName': 'Juan Dela Cruz',
          'gradeSection': 'Grade 3 - Faith',
          'status': 'out',
          'lastScanTime': 1733304600000,
          'photoUrl': '',
          'rfidTag': 'A1B2C3D4',
        },
      );

      expect(student.id, 'STU-00123');
      expect(student.fullName, 'Juan Dela Cruz');
      expect(student.gradeSection, 'Grade 3 - Faith');
      expect(student.status, ScanStatus.out_);
      expect(
        student.lastScanTime,
        DateTime.fromMillisecondsSinceEpoch(1733304600000),
      );
    });

    test('parses an entry/exit log from the RTDB structure', () {
      final log = ScanLog.fromRealtimeJson(
        id: '-Nab12cD3eFexample',
        studentId: 'STU-00123',
        json: {
          'studentName': 'Juan Dela Cruz',
          'status': 'out',
          'timestamp': 1733304600000,
        },
      );

      expect(log.id, '-Nab12cD3eFexample');
      expect(log.studentId, 'STU-00123');
      expect(log.studentName, 'Juan Dela Cruz');
      expect(log.status, ScanStatus.out_);
      expect(log.timestamp, DateTime.fromMillisecondsSinceEpoch(1733304600000));
    });
  });
}
