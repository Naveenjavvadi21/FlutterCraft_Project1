import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';

/// User profile and application preferences screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No active session')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // Profile Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    UserAvatar(
                      name: user.name,
                      photoUrl: user.photoUrl,
                      radius: 52,
                      showOnlineIndicator: true,
                      isOnline: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.onlineColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: AppConstants.onlineColor, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Active on ChatFlow',
                            style: TextStyle(
                              color: AppConstants.onlineColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1),

              // Settings & Preferences List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'PREFERENCES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Dark Theme'),
                      subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          authProvider.toggleTheme();
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.security_rounded, color: theme.colorScheme.primary),
                      title: const Text('Privacy & Security'),
                      subtitle: const Text('End-to-end Firestore rules enabled'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Security & Privacy'),
                            content: const Text(
                              'ChatFlow uses granular Firestore and Storage security rules. '
                              'Only verified participants in your chat rooms can read or write messages and shared images.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (user.createdAt != null)
                      ListTile(
                        leading: Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                        title: const Text('Member Since'),
                        subtitle: Text(
                          ChatDateUtils.formatDateSeparator(user.createdAt),
                        ),
                      ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppConstants.errorColor),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppConstants.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _confirmSignOut(context, authProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of ChatFlow?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
