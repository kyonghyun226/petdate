import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Approximate coordinates for discovery (privacy: no street-level precision).
@immutable
class ApproxLatLng {
  const ApproxLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// ~1.1km grid (2 decimal places) — matches privacy policy (no precise GPS).
  static ApproxLatLng approximate(double lat, double lng) {
    return ApproxLatLng(_round2(lat), _round2(lng));
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}

/// Pure geo helpers (haversine + geohash). No platform plugins.
abstract final class Geo {
  /// Earth radius in km.
  static const earthRadiusKm = 6371.0;

  /// Geohash length stored on pets (rules: 1–12). ~4.9km × 4.9km cells.
  static const petGeohashPrecision = 5;

  static double distanceKm(ApproxLatLng a, ApproxLatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  /// Encode to a geohash of [precision] (default [petGeohashPrecision]).
  static String encodeGeohash(
    ApproxLatLng point, {
    int precision = petGeohashPrecision,
  }) {
    assert(precision >= 1 && precision <= 12);
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var minLat = -90.0;
    var maxLat = 90.0;
    var minLng = -180.0;
    var maxLng = 180.0;
    var hash = 0;
    var bit = 0;
    var even = true;
    final chars = StringBuffer();

    while (chars.length < precision) {
      if (even) {
        final mid = (minLng + maxLng) / 2;
        if (point.longitude >= mid) {
          hash = (hash << 1) + 1;
          minLng = mid;
        } else {
          hash <<= 1;
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (point.latitude >= mid) {
          hash = (hash << 1) + 1;
          minLat = mid;
        } else {
          hash <<= 1;
          maxLat = mid;
        }
      }
      even = !even;
      if (++bit == 5) {
        chars.write(base32[hash]);
        bit = 0;
        hash = 0;
      }
    }
    return chars.toString();
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
