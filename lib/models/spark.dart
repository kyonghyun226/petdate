import 'package:flutter/foundation.dart';
import 'package:petdate/models/discovery_profile.dart';

enum SparkBucket { received, sent, matched }

@immutable
class SparkItem {
  SparkItem({
    required this.id,
    required this.profile,
    required this.bucket,
    DateTime? createdAt,
    this.seen = true,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final DiscoveryProfile profile;
  final SparkBucket bucket;
  final DateTime createdAt;

  /// Unseen received likes drive the BottomNav 반짝 badge.
  final bool seen;

  SparkItem copyWith({SparkBucket? bucket, DateTime? createdAt, bool? seen}) {
    return SparkItem(
      id: id,
      profile: profile,
      bucket: bucket ?? this.bucket,
      createdAt: createdAt ?? this.createdAt,
      seen: seen ?? this.seen,
    );
  }

  /// Caption: 「거리 · 상대시간」.
  String metaCaption({DateTime? now}) =>
      '${formatSparkDistance(profile.distanceKm)} · ${formatSparkRelativeTime(createdAt, now: now)}';
}

String formatSparkDistance(double km) => formatPetDistance(km);

String formatSparkRelativeTime(DateTime at, {DateTime? now}) {
  final delta = (now ?? DateTime.now()).difference(at);
  if (delta.isNegative || delta.inSeconds < 60) return '방금';
  if (delta.inMinutes < 60) return '${delta.inMinutes}분 전';
  if (delta.inHours < 24) return '${delta.inHours}시간 전';
  if (delta.inDays == 1) return '어제';
  return '${delta.inDays}일 전';
}
