import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';
import '../../core/constants/services/firestore_service.dart';
import '../../core/constants/services/utils/date_formatter.dart';
import '../../models/report_card.dart';

class ReportCardScreen extends StatefulWidget {
  final List<String> studentIds;

  const ReportCardScreen({super.key, required this.studentIds});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  final FirestoreService _firestore = FirestoreService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Report Card',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: widget.studentIds.isEmpty
          ? const Center(child: Text('No linked students found.'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final studentId = widget.studentIds[_selectedIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.studentIds.length > 1) ...[
          _StudentSelector(
            studentIds: widget.studentIds,
            selectedIndex: _selectedIndex,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 16),
        ],
        StreamBuilder<ReportCardData?>(
          stream: _firestore.streamReportCard(studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ErrorCard(message: 'Unable to load the report card.');
            }

            final data = snapshot.data;
            if (data == null) return const _EmptyStateCard();

            return Column(
              children: [
                _HeaderCard(data: data),
                const SizedBox(height: 16),
                _SubjectGradesCard(subjects: data.subjects),
                if (data.observedValues.any(
                  (value) => value.ratingCode != null,
                )) ...[
                  const SizedBox(height: 16),
                  _ObservedValuesCard(values: data.observedValues),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentSelector extends StatelessWidget {
  final List<String> studentIds;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _StudentSelector({
    required this.studentIds,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex,
          isExpanded: true,
          items: List.generate(
            studentIds.length,
            (index) =>
                DropdownMenuItem(value: index, child: Text(studentIds[index])),
          ),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ReportCardData data;

  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final schoolYear = data.schoolYear ?? '—';
    final releasedAt = data.releasedAt;
    final releaseLabel = releasedAt == null
        ? null
        : 'Released ${DateFormatter.formatDate(releasedAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Progress Report Card',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 4),
          Text(
            'School Year $schoolYear · ${data.termLabel}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          if (releaseLabel != null) ...[
            const SizedBox(height: 4),
            Text(releaseLabel, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

class _SubjectGradesCard extends StatelessWidget {
  final List<ReportCardSubject> subjects;

  const _SubjectGradesCard({required this.subjects});

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Subject Grades',
      child: Column(
        children: [
          for (var index = 0; index < subjects.length; index++) ...[
            _ReportRow(
              label: subjects[index].name,
              value: subjects[index].grade ?? '—',
            ),
            if (index < subjects.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _ObservedValuesCard extends StatelessWidget {
  final List<ObservedValueRow> values;

  const _ObservedValuesCard({required this.values});

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Observed Values',
      child: Column(
        children: [
          for (var index = 0; index < values.length; index++) ...[
            _ReportRow(
              label: values[index].label,
              value: values[index].ratingLabel ?? '—',
            ),
            if (index < values.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySecondary.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        const SizedBox(width: 16),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No report card released yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Your child's report card will appear here when the school releases it.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: AppTextStyles.body));
  }
}
