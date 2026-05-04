/// 应用信息
class AppInfo {
  final String versionName;
  final String versionCode;
  final String minSdk;
  final String targetSdk;
  final String compileSdk;
  final List<AppPermission> permissions;

  AppInfo({
    this.versionName = '',
    this.versionCode = '',
    this.minSdk = '',
    this.targetSdk = '',
    this.compileSdk = '',
    this.permissions = const [],
  });
}

/// 应用权限项
class AppPermission {
  final String name;
  final bool granted;

  AppPermission({
    required this.name,
    this.granted = false,
  });
}
