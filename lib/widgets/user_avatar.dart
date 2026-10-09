import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Reusable user avatar with network caching, gradient fallback initials, and online badge
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  String _getInitials(String str) {
    if (str.trim().isEmpty) return '?';
    final parts = str.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return str[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;

    Widget avatarContent;
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitialsPlaceholder(theme),
      );
    } else {
      avatarContent = _buildInitialsPlaceholder(theme);
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: avatarContent,
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6 > 14 ? 14 : radius * 0.6,
              height: radius * 0.6 > 14 ? 14 : radius * 0.6,
              decoration: BoxDecoration(
                color: isOnline ? AppConstants.onlineColor : AppConstants.offlineColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsPlaceholder(ThemeData theme) {
    // Generate deterministic pleasing colors based on name hash
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    final colors = [
      const [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo / Purple
      const [Color(0xFF0284C7), Color(0xFF0D9488)], // Cyan / Teal
      const [Color(0xFFEA580C), Color(0xFFD97706)], // Orange / Amber
      const [Color(0xFF059669), Color(0xFF10B981)], // Emerald
      const [Color(0xFFE11D48), Color(0xFFBE123C)], // Rose
    ];
    final selectedGradient = colors[hash % colors.length];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
