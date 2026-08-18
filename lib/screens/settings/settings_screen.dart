import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';
import '../../core/constants/services/auth_service.dart';
import '../../models/student.dart';

/// Parent-facing settings: profile info, linked children, notification
/// preference, password change, and app version. Kept intentionally simple —
/// enrollment and child records stay admin-managed, so nothing here is
/// editable beyond the parent's own notification preference and password.
class SettingsScreen extends StatefulWidget {
  final String parentName;
  final String? parentEmail;
  final List<Student> students;

  const SettingsScreen({
    super.key,
    required this.parentName,
    required this.students,
    this.parentEmail,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsPrefKey = 'notifications_enabled';

  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _loadingPref = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
    _loadAppVersion();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsPrefKey) ?? true;
      _loadingPref = false;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPrefKey, value);
  }

  Future<void> _handleChangePassword() async {
    if (widget.parentEmail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
          "We'll send a password reset link to ${widget.parentEmail}. Follow the link to set a new password.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authService.sendPasswordResetEmail(widget.parentEmail!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Check your email.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't send reset link. Please try again."),
          ),
        );
      }
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Profile',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Name',
                  value: widget.parentName,
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: widget.parentEmail ?? 'Not available',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: widget.students.length > 1
                ? 'Linked Children'
                : 'Linked Child',
            child: widget.students.isEmpty
                ? Text(
                    'No linked students found.',
                    style: AppTextStyles.bodySecondary,
                  )
                : Column(
                    children: widget.students
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _InfoRow(
                              icon: Icons.school_rounded,
                              label: s.fullName,
                              value: s.gradeSection,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notifications',
            child: _loadingPref
                ? const Center(child: CircularProgressIndicator())
                : SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Entry & exit alerts',
                      style: AppTextStyles.body,
                    ),
                    subtitle: Text(
                      'Get notified when your child scans in or out at school.',
                      style: AppTextStyles.caption,
                    ),
                    value: _notificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleNotifications,
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Account',
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.lock_reset_rounded,
                  label: 'Change Password',
                  onTap: _handleChangePassword,
                ),
                const Divider(height: 20),
                _ActionRow(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'About',
            child: _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'App Version',
              value: _appVersion.isEmpty ? '—' : _appVersion,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
            color: Colors.black.withOpacity(0.04),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
