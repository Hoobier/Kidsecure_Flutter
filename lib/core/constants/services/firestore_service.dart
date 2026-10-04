import 'package:firebase_database/firebase_database.dart';
import '../../../models/student.dart';
import '../../../models/scan_log.dart';
import '../../../models/report_card.dart';

// lib/core/constants/services/firestore_service.dart

/// Reads student status and entry/exit history from Firebase Realtime Database.
class FirestoreService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference get _students => _db.child('students');
  DatabaseReference get _logs => _db.child('entryExitLogs');
  DatabaseReference get _parents => _db.child('parents');

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  Student _fallbackStudent(String studentId) {
    return Student(
      id: studentId,
      fullName: '',
      gradeSection: '',
      status: ScanStatus.out_,
      lastScanTime: DateTime.now(),
    );
  }

  /// Fetches the student IDs linked to a parent account (supports siblings).
  Future<List<String>> getLinkedStudentIds(String parentUid) async {
    final snapshot = await _parents.child(parentUid).get();
    if (!snapshot.exists) return [];

    final parentData = _asStringMap(snapshot.value);
    if (parentData == null) return [];

    final studentIdsValue = parentData['studentIds'];
    if (studentIdsValue is Map) {
      return studentIdsValue.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getParentProfile(String parentUid) async {
    final snapshot = await _parents.child(parentUid).get();
    if (!snapshot.exists) return null;

    return _asStringMap(snapshot.value);
  }

  /// Streams the live document for a single student (current IN/OUT status).
  Stream<Student> streamStudent(String studentId) {
    return _students.child(studentId).onValue.map((event) {
      final data = _asStringMap(event.snapshot.value);
      if (data == null || data.isEmpty) {
        return _fallbackStudent(studentId);
      }
      return Student.fromRealtimeJson(id: studentId, json: data);
    });
  }

  /// Streams live documents for multiple students, e.g. all siblings.
  Stream<List<Student>> streamStudents(List<String> studentIds) {
    if (studentIds.isEmpty) return const Stream.empty();

    return _students.onValue.map((event) {
      final root = _asStringMap(event.snapshot.value);
      if (root == null || root.isEmpty) return <Student>[];

      final students = <Student>[];
      for (final studentId in studentIds) {
        final studentData = root[studentId];
        if (studentData is Map) {
          students.add(
            Student.fromRealtimeJson(
              id: studentId,
              json: _asStringMap(studentData) ?? <String, dynamic>{},
            ),
          );
        }
      }
      return students;
    });
  }

  /// Streams entry/exit log history for one student, most recent first.
  Stream<List<ScanLog>> streamLogs(String studentId, {int limit = 100}) {
    return _logs.child(studentId).onValue.map((event) {
      final root = _asStringMap(event.snapshot.value);
      if (root == null || root.isEmpty) return <ScanLog>[];

      final logs = root.entries.map((entry) {
        final logData = _asStringMap(entry.value);
        return ScanLog.fromRealtimeJson(
          id: entry.key.toString(),
          studentId: studentId,
          json: logData ?? <String, dynamic>{},
        );
      }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs.take(limit).toList();
    });
  }

  /// Streams combined entry/exit log history for multiple students.
  Stream<List<ScanLog>> streamLogsForStudents(
    List<String> studentIds, {
    int limit = 100,
  }) {
    if (studentIds.isEmpty) return const Stream.empty();

    return _logs.onValue.map((event) {
      final root = _asStringMap(event.snapshot.value);
      if (root == null || root.isEmpty) return <ScanLog>[];

      final logs = <ScanLog>[];

      for (final studentId in studentIds) {
        final studentLogs = root[studentId];
        if (studentLogs is Map) {
          final studentLogsMap = _asStringMap(studentLogs);
          if (studentLogsMap == null) continue;

          for (final entry in studentLogsMap.entries) {
            logs.add(
              ScanLog.fromRealtimeJson(
                id: entry.key.toString(),
                studentId: studentId,
                json: _asStringMap(entry.value) ?? <String, dynamic>{},
              ),
            );
          }
        }
      }

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs.take(limit).toList();
    });
  }

  /// Streams the parent-facing report card data for one student.
  /// Emits null when nothing is released yet (no meta node present).
  Stream<ReportCardData?> streamReportCard(String studentId) {
    return _students.child(studentId).onValue.map((event) {
      final root = _asStringMap(event.snapshot.value);
      if (root == null || root.isEmpty) return null;

      final card = _asStringMap(root['reportCard']);
      final meta = _asStringMap(root['reportCardMeta']);
      final obs = _asStringMap(root['observedValues']);

      // No meta node means nothing has been released for this student.
      if (meta == null || card == null) return null;

      final term = (meta['term'] as String?) ?? '';
      final displayOrder =
          (meta['displayOrder'] as List?)?.map((e) => e.toString()).toList() ??
          [];
      final subjectNames = _asStringMap(meta['subjectNames']) ?? {};

      final subjects = <ReportCardSubject>[];
      for (final code in displayOrder) {
        final entry = _asStringMap(card[code]);
        final termEntry = _asStringMap(entry?[term]);
        final rawGrade = termEntry?['grade'];
        final grade = rawGrade?.toString();

        subjects.add(
          ReportCardSubject(
            code: code,
            name: (subjectNames[code] as String?) ?? code,
            grade: (grade == null || grade.isEmpty) ? null : grade,
            computed: termEntry?['computed'] == true,
          ),
        );
      }

      final observedLabels = _asStringMap(meta['observedValueLabels']) ?? {};
      final ratingLabels = _asStringMap(meta['ratingLabels']) ?? {};
      final termValues = obs != null ? _asStringMap(obs[term]) : null;

      // Iterate the explicit order array when present (avoids RTDB's unordered
      // map iteration). Fall back to labels.entries for cards that predate the
      // order key — renders in the old order rather than showing nothing.
      final observedOrder =
          (meta['observedValueOrder'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final orderedCodes = observedOrder.isNotEmpty
          ? observedOrder
          : observedLabels.keys.toList();

      final observedValues = <ObservedValueRow>[];
      for (final code in orderedCodes) {
        final label = observedLabels[code]?.toString() ?? code;
        final ratingCode = termValues?[code]?.toString();
        final ratingLabel = ratingCode != null
            ? (ratingLabels[ratingCode] as String?) ?? ratingCode
            : null;

        observedValues.add(
          ObservedValueRow(
            code: code,
            label: label,
            ratingCode: ratingCode,
            ratingLabel: ratingLabel,
          ),
        );
      }

      final releasedMs = meta['releasedAt'];
      final releasedAt = releasedMs is int
          ? DateTime.fromMillisecondsSinceEpoch(releasedMs)
          : null;

      return ReportCardData(
        schoolYear: meta['schoolYear'] as String?,
        term: term,
        releasedAt: releasedAt,
        subjects: subjects,
        observedValues: observedValues,
      );
    });
  }
}
