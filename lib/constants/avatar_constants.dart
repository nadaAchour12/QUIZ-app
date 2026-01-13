// lib/constants/avatar_constants.dart

/// Liste centralisée des avatars disponibles dans l'application
class AvatarConstants {
  static const List<String> avatarAssets = [
    'assets/avatar/avatar1.png',
    'assets/avatar/avatar2.png',
    'assets/avatar/avatar3.png',
    'assets/avatar/avatar4.png',
    'assets/avatar/avatar5.png',
    'assets/avatar/avatar6.png',
    'assets/avatar/avatar7.png',
    'assets/avatar/avatar8.png',
    'assets/avatar/avatar9.png',
    'assets/avatar/avatar10.png',
    'assets/avatar/avatar11.png',
    'assets/avatar/avatar12.png',
    'assets/avatar/avatar13.png',
    'assets/avatar/avatar14.png',
    'assets/avatar/avatar15.png',
    'assets/avatar/avatar16.png',
    'assets/avatar/avatar17.png',
    'assets/avatar/avatar18.png',
    'assets/avatar/avatar19.png',
    'assets/avatar/avatar20.png',
  ];

  /// Récupère l'asset d'avatar en toute sécurité
  static String getAvatarAsset(int index) {
    if (index >= 0 && index < avatarAssets.length) {
      return avatarAssets[index];
    }
    return avatarAssets[0]; // Avatar par défaut
  }
}