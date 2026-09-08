import 'package:flutter/foundation.dart';
import 'package:petdate/models/discovery_profile.dart';

enum SparkBucket { received, sent, matched }

@immutable
class SparkItem {
  const SparkItem({
    required this.id,
    required this.profile,
    required this.bucket,
  });

  final String id;
  final DiscoveryProfile profile;
  final SparkBucket bucket;

  SparkItem copyWith({SparkBucket? bucket}) {
    return SparkItem(
      id: id,
      profile: profile,
      bucket: bucket ?? this.bucket,
    );
  }
}
