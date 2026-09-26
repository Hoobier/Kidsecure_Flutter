// lib/models/report_card.dart

/// One subject row on the parent-facing report card.
class ReportCardSubject {
  final String code;
  final String name;
  final String? grade;
  final bool computed;

  const ReportCardSubject({
    required this.code,
    required this.name,
    required this.grade,
    required this.computed,
  });
}

/// One observed value row (God-centered, Humane, etc.) with its rating.
class ObservedValueRow {
  final String code;
  final String label;
  final String? ratingCode;
  final String? ratingLabel;

  const ObservedValueRow({
    required this.code,
    required this.label,
    required this.ratingCode,
    required this.ratingLabel,
  });
}

/// Full report card payload as read from Firebase RTDB.
class ReportCardData {
  final String? schoolYear;
  final String term; // 'T1' | 'T2' | 'T3'
  final DateTime? releasedAt;
  final List<ReportCardSubject> subjects;
  final List<ObservedValueRow> observedValues;

  const ReportCardData({
    required this.schoolYear,
    required this.term,
    required this.releasedAt,
    required this.subjects,
    required this.observedValues,
  });

  static String _termLabel(String t) {
    switch (t) {
      case 'T1':
        return 'First Term';
      case 'T2':
        return 'Second Term';
      case 'T3':
        return 'Third Term';
      default:
        return t;
    }
  }

  String get termLabel => _termLabel(term);
}
