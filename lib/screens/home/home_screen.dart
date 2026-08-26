import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/services/auth_service.dart';
import '../../core/constants/services/firestore_service.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/student_status_card.dart';
import '../../core/constants/services/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';
import '../../core/constants/services/utils/date_formatter.dart';
import '../../models/scan_log.dart';
import '../../core/constants/services/notification_service.dart';

// lib/screens/home/home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  bool _loading = true;
  String? _error;
  List<String> _studentIds = [];
  List<Student> _children = [];
  String _parentName = '';
  String _parentEmail = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadParentAndStudents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadParentAndStudents() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not logged in.';
        _loading = false;
      });
      return;
    }

    try {
      final response = await ApiService.instance.getMe();
      final profile = response['data'] as Map<String, dynamic>? ?? {};
      final childrenJson = (profile['children'] as List<dynamic>? ?? []);
      final ids = childrenJson
          .map((c) => (c as Map<String, dynamic>)['studentId'] as String)
          .toList();

      setState(() {
        _parentName = (profile['fullName'] as String?) ?? '';
        _parentEmail = (profile['email'] as String?) ?? uid;
        _studentIds = ids;
        _loading = false;
      });

      NotificationService.instance.initialize();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load your account. Please try again.';
        _loading = false;
      });
    }
  }

  void _handleDrawerSelection(DrawerDestination destination) {
    switch (destination) {
      case DrawerDestination.status:
        break;
      case DrawerDestination.settings:
        context.push(
          '/settings',
          extra: {
            'parentName': _parentName,
            'parentEmail': _parentEmail,
            'students': _children,
          },
        );
        break;
      case DrawerDestination.contactSchool:
        context.push('/contact');
        break;
      case DrawerDestination.logout:
        _handleLogout();
        break;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    NotificationService.instance.reset();
    await _authService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KidSecure'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        parentName: _parentName,
        parentEmail: _parentEmail,
        onSelect: _handleDrawerSelection,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _loading = true);
                _loadParentAndStudents();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_studentIds.isEmpty) {
      return const Center(child: Text('No linked students found.'));
    }

    return StreamBuilder<List<Student>>(
      stream: _firestoreService.streamStudents(_studentIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load attendance status.'));
        }

        final students = snapshot.data ?? [];
        _children = students;

        if (students.isEmpty) {
          return const Center(child: Text('No linked students found.'));
        }

        // Get current student
        final currentStudent =
            students[_currentIndex.clamp(0, students.length - 1)];
        final currentStudentId = currentStudent.id;

        return Column(
          children: [
            // "Attendance Status" Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attendance Status',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Swipeable Status Cards
            _buildStatusCards(students),
            const SizedBox(height: 8),
            // Student indicator (name + dots)
            _buildStudentIndicator(students),
            const SizedBox(height: 12),
            // Logs header
            _buildLogsHeader(),
            // Logs for current student
            Expanded(child: _buildLogsList(currentStudentId)),
          ],
        );
      },
    );
  }

  Widget _buildStatusCards(List<Student> students) {
    if (students.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: StudentStatusCard(student: students.first, onTap: null),
      );
    }

    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _pageController,
        itemCount: students.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final student = students[index];
          return StudentStatusCard(student: student, onTap: null);
        },
      ),
    );
  }

  Widget _buildStudentIndicator(List<Student> students) {
    if (students.length <= 1) return const SizedBox.shrink();

    final currentStudent = students[_currentIndex];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(students.length, (i) {
          final active = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          currentStudent.fullName,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLogsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Entry & Exit Logs',
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(String studentId) {
    return StreamBuilder<List<ScanLog>>(
      stream: _firestoreService.streamLogs(studentId, limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load logs right now.',
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
                ...entry.logs.map((log) => _LogTile(log: log)),
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

// Log tile widget
class _LogTile extends StatelessWidget {
  final ScanLog log;

  const _LogTile({required this.log});

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
                  label,
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

class _DayGroup {
  final String dayLabel;
  final List<ScanLog> logs;
  _DayGroup({required this.dayLabel, required this.logs});
}
