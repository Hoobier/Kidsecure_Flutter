import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/student.dart';

/// A single card showing one child's live RFID entry/exit status.
class StudentStatusCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;

  const StudentStatusCard({super.key, required this.student, this.onTap});

  bool get _isIn => student.status == ScanStatus.in_;

  @override
  Widget build(BuildContext context) {
    final statusColor = _isIn
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final statusLabel = _isIn ? 'IN' : 'OUT';
    final statusIcon = _isIn ? Icons.login_rounded : Icons.logout_rounded;
    final timeLabel = DateFormat("MMM d, h:mm a").format(student.lastScanTime);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: statusColor.withOpacity(0.25), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: student.photoUrl != null
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl == null
                    ? Text(
                        student.fullName.isNotEmpty ? student.fullName[0] : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.gradeSection,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last scan: $timeLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
