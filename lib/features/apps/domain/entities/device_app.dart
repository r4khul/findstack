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
  final Uint8List? icon;
  final String stack;
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

  final int totalTimeInForeground;
  final int lastTimeUsed;

  final AppCategory category;

  final int size;
  final String apkPath;
  final String dataDir;

  final int appSize;
  final int dataSize;
  final int cacheSize;
  final int externalCacheSize;

  final String installerStore;
  final String? signingSha1;
  final String? signingSha256;
  final String? kotlinVersion;
  final int activitiesCount;
  final int servicesCount;
  final int receiversCount;
  final int providersCount;
  final List<String> splitApks;
  final Map<String, String> techVersions;

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
    this.size = 0,
    this.appSize = 0,
    this.dataSize = 0,
    this.cacheSize = 0,
    this.externalCacheSize = 0,
    this.apkPath = '',
    this.dataDir = '',
    this.installerStore = 'Unknown',
    this.signingSha1,
    this.signingSha256,
    this.kotlinVersion,
    this.activitiesCount = 0,
    this.servicesCount = 0,
    this.receiversCount = 0,
    this.providersCount = 0,
    this.splitApks = const [],
    this.techVersions = const {},
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
      size: map['size'] as int? ?? 0,
      appSize: map['appSize'] as int? ?? 0,
      dataSize: map['dataSize'] as int? ?? 0,
      cacheSize: map['cacheSize'] as int? ?? 0,
      externalCacheSize: map['externalCacheSize'] as int? ?? 0,
      apkPath: map['apkPath'] as String? ?? '',
      dataDir: map['dataDir'] as String? ?? '',
      installerStore: map['installerStore'] as String? ?? 'Unknown',
      signingSha1: map['signingSha1'] as String?,
      signingSha256: map['signingSha256'] as String?,
      kotlinVersion: map['kotlinVersion'] as String?,
      activitiesCount: map['activitiesCount'] as int? ?? 0,
      servicesCount: map['servicesCount'] as int? ?? 0,
      receiversCount: map['receiversCount'] as int? ?? 0,
      providersCount: map['providersCount'] as int? ?? 0,
      splitApks:
          (map['splitApks'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      techVersions:
          (map['techVersions'] as Map<Object?, Object?>?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
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
      'icon': icon,
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
      'size': size,
      'appSize': appSize,
      'dataSize': dataSize,
      'cacheSize': cacheSize,
      'externalCacheSize': externalCacheSize,
      'apkPath': apkPath,
      'dataDir': dataDir,
      'installerStore': installerStore,
      'signingSha1': signingSha1,
      'signingSha256': signingSha256,
      'kotlinVersion': kotlinVersion,
      'activitiesCount': activitiesCount,
      'servicesCount': servicesCount,
      'receiversCount': receiversCount,
      'providersCount': providersCount,
      'splitApks': splitApks,
      'techVersions': techVersions,
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
    icon,
    size,
    appSize,
    dataSize,
    cacheSize,
    externalCacheSize,
    apkPath,
    dataDir,
    installerStore,
    signingSha1,
    signingSha256,
    kotlinVersion,
    activitiesCount,
    servicesCount,
    receiversCount,
    providersCount,
    splitApks,
    techVersions,
  ];
}
