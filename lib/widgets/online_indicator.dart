import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Small visual dot indicator for online/offline presence
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppConstants.onlineColor : AppConstants.offlineColor,
        shape: BoxShape.circle,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppConstants.onlineColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }
}
