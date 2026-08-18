import 'package:flutter/material.dart';

/// The parent app's side navigation drawer.
///
/// Attach this to your Scaffold's `drawer:` property. Flutter automatically
/// renders the top-left hamburger icon in the AppBar once a drawer is set —
/// no extra icon widget is needed.
class AppDrawer extends StatelessWidget {
  final String parentName;
  final String? parentEmail;
  final ValueChanged<DrawerDestination> onSelect;

  const AppDrawer({
    super.key,
    required this.parentName,
    required this.onSelect,
    this.parentEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(parentName),
              accountEmail: parentEmail != null ? Text(parentEmail!) : null,
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.family_restroom_rounded, size: 32),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            _DrawerItem(
              icon: Icons.school_rounded,
              label: 'Status',
              onTap: () => onSelect(DrawerDestination.status),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'Logs',
              onTap: () => onSelect(DrawerDestination.logs),
            ),
            _DrawerItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () => onSelect(DrawerDestination.settings),
            ),
            _DrawerItem(
              icon: Icons.phone_in_talk_rounded,
              label: 'Contact School',
              onTap: () => onSelect(DrawerDestination.contactSchool),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              onTap: () => onSelect(DrawerDestination.logout),
            ),
          ],
        ),
      ),
    );
  }
}

enum DrawerDestination { status, logs, settings, contactSchool, logout }

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer first
        onTap();
      },
    );
  }
}
