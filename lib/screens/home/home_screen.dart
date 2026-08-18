import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/services/auth_service.dart';
import '../../core/constants/services/firestore_service.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/status_cards_section.dart';
import '../../core/constants/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  String? _error;
  List<String> _studentIds = [];
  List<Student> _children = []; // kept in sync for drawer navigation
  String _parentName = '';
  String _parentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadParentAndStudents();
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
        break; // already on the status screen
      case DrawerDestination.logs:
        context.push(
          '/logs',
          extra: {'students': _children, 'initialStudentId': null},
        );
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

    await _authService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KidSecure')),
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
        _children = students; // keep for drawer navigation

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Attendance Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            StatusCardsSection(
              students: students,
              onCardTap: (student) {
                context.push(
                  '/logs',
                  extra: {'students': students, 'initialStudentId': student.id},
                );
              },
            ),
          ],
        );
      },
    );
  }
}
