import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _schoolName = 'Rainbow 5 Christian Academy of Caloocan, Inc.';
  static const _email = 'rainbow5.christianacademy@gmail.com';
  static const _address =
      'Blk. 31 Lot 44 Acacia St., Rainbow Village 5 Phase II,\nBagumbong, Caloocan City, 1421';
  static const _mapUrl =
      'https://www.bing.com/maps/default.aspx?v=2&pc=FACEBK&mid=8100&where1=Blk.%2031%20Lot%2044%20Acasia%20St.%20Rainbow%20Village%205%20Phase%20II%20Bagumbong%2C%20Caloocan%20City%2C%201421&FORM=FBKPL1&mkt=en-US';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email);
    final launched = await launchUrl(uri);
    if (!launched)
      await _copyFallback(context, _email, 'Email address copied.');
  }

  Future<void> _openMap(BuildContext context) async {
    final uri = Uri.parse(_mapUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) await _copyFallback(context, _address, 'Address copied.');
  }

  Future<void> _copyFallback(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Contact School',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  _schoolName,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "We're here to help.",
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ContactCard(
            icon: Icons.email_rounded,
            label: 'Email',
            value: _email,
            actionLabel: 'Send Email',
            onTap: () => _openEmail(context),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: _address,
            actionLabel: 'View on Map',
            onTap: () => _openMap(context),
          ),
          const SizedBox(height: 12),
          const _ContactCard(
            icon: Icons.phone_rounded,
            label: 'Phone Number',
            value: '-',
            subtitle: 'Not available yet',
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.caption),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        actionLabel!,
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
