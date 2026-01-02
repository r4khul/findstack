import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

enum AppCategory {
  game,
  audio,
  video,
  image,
  social,
  news,
  maps,
  productivity,
  tools,
  unknown,
}

class DeviceApp extends Equatable {
  final String appName;
  final String packageName;
  final String version;
  final Uint8List? icon; // Only simple icon passing for now
  final String stack; // Detected stack (Flutter, React Native, etc.)
  final List<String> nativeLibraries;
  final List<String> permissions;
  final List<String> services;
  final List<String> receivers;
  final List<String> providers;
  final DateTime installDate;
  final DateTime updateDate;
  final int minSdkVersion;
  final int targetSdkVersion;
  final int uid;
  final int versionCode;

  // Usage stats (requires permission)
  final int totalTimeInForeground; // in milliseconds
  final int lastTimeUsed; // timestamp

  final AppCategory category; // New field

  const DeviceApp({
    required this.appName,
    required this.packageName,
    this.version = '',
    this.icon,
    required this.stack,
    required this.nativeLibraries,
    required this.permissions,
    required this.services,
    required this.receivers,
    required this.providers,
    required this.installDate,
    required this.updateDate,
    required this.minSdkVersion,
    required this.targetSdkVersion,
    required this.uid,
    required this.versionCode,
    this.totalTimeInForeground = 0,
    this.lastTimeUsed = 0,
    this.category = AppCategory.unknown,
  });

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    return DeviceApp(
      appName: map['appName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? 'Unknown',
      version: map['version'] as String? ?? '',
      icon: map['icon'] as Uint8List?,
      stack: map['stack'] as String? ?? 'Unknown',
      nativeLibraries:
          (map['nativeLibraries'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      permissions:
          (map['permissions'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      services:
          (map['services'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      receivers:
          (map['receivers'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      providers:
          (map['providers'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      installDate: DateTime.fromMillisecondsSinceEpoch(
        map['firstInstallTime'] as int? ?? 0,
      ),
      updateDate: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdateTime'] as int? ?? 0,
      ),
      minSdkVersion: map['minSdkVersion'] as int? ?? 0,
      targetSdkVersion: map['targetSdkVersion'] as int? ?? 0,
      uid: map['uid'] as int? ?? 0,
      versionCode: map['versionCode'] as int? ?? 0,
      totalTimeInForeground: map['totalTimeInForeground'] as int? ?? 0,
      lastTimeUsed: map['lastTimeUsed'] as int? ?? 0,
      category: _parseCategory(map['category'] as String?),
    );
  }

  static AppCategory _parseCategory(String? category) {
    if (category == null) return AppCategory.unknown;
    try {
      return AppCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => AppCategory.unknown,
      );
    } catch (_) {
      return AppCategory.unknown;
    }
  }

  Duration get totalUsageDuration =>
      Duration(milliseconds: totalTimeInForeground);
  DateTime get lastUsedDate =>
      DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'icon':
          icon, // Assuming icon is Uint8List which might need base64 encoding for JSON
      'stack': stack,
      'nativeLibraries': nativeLibraries,
      'permissions': permissions,
      'services': services,
      'receivers': receivers,
      'providers': providers,
      'firstInstallTime': installDate.millisecondsSinceEpoch,
      'lastUpdateTime': updateDate.millisecondsSinceEpoch,
      'minSdkVersion': minSdkVersion,
      'targetSdkVersion': targetSdkVersion,
      'uid': uid,
      'versionCode': versionCode,
      'totalTimeInForeground': totalTimeInForeground,
      'lastTimeUsed': lastTimeUsed,
      'category': category.name,
    };
  }

  @override
  List<Object?> get props => [
    appName,
    packageName,
    stack,
    nativeLibraries,
    permissions,
    installDate,
    updateDate,
    versionCode,
    totalTimeInForeground,
    lastTimeUsed,
    category,
  ];
}
