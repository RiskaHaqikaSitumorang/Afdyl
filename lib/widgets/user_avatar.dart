import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Widget untuk menampilkan avatar user dengan fallback ke icon default
///
/// Menangani loading state, error state, dan fallback ke icon jika tidak ada gambar
class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.grey[200];
    final iconCol = iconColor ?? Colors.grey[400];

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: _getBackgroundImage(),
      child:
          _getBackgroundImage() == null
              ? Icon(Icons.person, size: radius * 1.2, color: iconCol)
              : null,
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return NetworkImage(user!.profileImageUrl!);
    }
    return null;
  }
}

/// Widget untuk menampilkan avatar dengan loading dan error handling
class UserAvatarWithLoading extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserAvatarWithLoading({
    super.key,
    required this.user,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.grey[200];
    final iconCol = iconColor ?? Colors.grey[400];

    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: ClipOval(
          child: Image.network(
            user!.profileImageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconCol ?? Colors.grey,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: radius * 1.2, color: iconCol);
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(Icons.person, size: radius * 1.2, color: iconCol),
    );
  }
}
