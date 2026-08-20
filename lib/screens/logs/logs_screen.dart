import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';
import '../../core/constants/services/firestore_service.dart';
import '../../core/constants/services/utils/date_formatter.dart';
import '../../models/scan_log.dart';
import '../../models/student.dart';

// lib/screens/logs/logs_screen.dart

/// Parent-facing, chronological entry/exit log grouped by day so it's
/// easy to scan at a glance.
class LogsScreen extends StatefulWidget {
  final List<Student> students;
  final String? initialStudentId;

  const LogsScreen({super.key, required this.students, this.initialStudentId});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId ?? 'all';
  }

  List<String> get _studentIds => widget.students.map((s) => s.id).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Entry & Exit Logs',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.students.length > 1) _buildStudentFilter(),
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildStudentFilter() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              selected: _selectedStudentId == 'all',
              onTap: () => setState(() => _selectedStudentId = 'all'),
            ),
            const SizedBox(width: 8),
            ...widget.students.map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: s.fullName.split(' ').first,
                  selected: _selectedStudentId == s.id,
                  onTap: () => setState(() => _selectedStudentId = s.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    final ids = _selectedStudentId == 'all'
        ? _studentIds
        : [_selectedStudentId];

    return StreamBuilder<List<ScanLog>>(
      stream: _firestoreService.streamLogsForStudents(ids),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // TEMP: print full error to see the real Firestore exception
          debugPrint('Firestore logs stream error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load logs right now.\n${snapshot.error}',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No entry or exit records yet.',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          );
        }

        final grouped = _groupByDay(logs);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    entry.dayLabel,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...entry.logs.map(
                  (log) =>
                      _LogTile(log: log, showName: widget.students.length > 1),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_DayGroup> _groupByDay(List<ScanLog> logs) {
    final map = <String, List<ScanLog>>{};
    for (final log in logs) {
      map
          .putIfAbsent(DateFormatter.formatDayLabel(log.timestamp), () => [])
          .add(log);
    }
    return map.entries
        .map((e) => _DayGroup(dayLabel: e.key, logs: e.value))
        .toList();
  }
}

class _DayGroup {
  final String dayLabel;
  final List<ScanLog> logs;
  _DayGroup({required this.dayLabel, required this.logs});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySecondary.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ScanLog log;
  final bool showName;

  const _LogTile({required this.log, required this.showName});

  @override
  Widget build(BuildContext context) {
    final isIn = log.status == ScanStatus.in_;
    final color = isIn ? AppColors.statusIn : AppColors.statusOut;
    final icon = isIn ? Icons.login_rounded : Icons.logout_rounded;
    final label = isIn ? 'Entered school' : 'Left school';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showName ? '${log.studentName} · $label' : label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatTime(log.timestamp),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isIn ? 'IN' : 'OUT',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
