import 'package:flutter/material.dart';
import '../../../models/student.dart';
import 'student_status_card.dart';

/// - 1 child  -> a single full-width card.
/// - 2+ children -> a swipeable carousel with dot indicators.
class StatusCardsSection extends StatefulWidget {
  final List<Student> students;
  final ValueChanged<Student>? onCardTap;

  const StatusCardsSection({super.key, required this.students, this.onCardTap});

  @override
  State<StatusCardsSection> createState() => _StatusCardsSectionState();
}

class _StatusCardsSectionState extends State<StatusCardsSection> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No enrolled students linked to this account.'),
        ),
      );
    }

    if (widget.students.length == 1) {
      return StudentStatusCard(
        student: widget.students.first,
        onTap: () => widget.onCardTap?.call(widget.students.first),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.students.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final student = widget.students[index];
              return StudentStatusCard(
                student: student,
                onTap: () => widget.onCardTap?.call(student),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.students.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
