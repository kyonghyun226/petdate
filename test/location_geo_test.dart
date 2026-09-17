import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/location/geo.dart';

void main() {
  test('haversine Seoul → Busan is roughly 325km', () {
    const seoul = ApproxLatLng(37.57, 126.98);
    const busan = ApproxLatLng(35.18, 129.08);
    final km = Geo.distanceKm(seoul, busan);
    expect(km, greaterThan(300));
    expect(km, lessThan(350));
  });

  test('same point is ~0km', () {
    const a = ApproxLatLng(37.57, 126.98);
    expect(Geo.distanceKm(a, a), closeTo(0, 0.001));
  });

  test('approximate rounds to 2 decimals', () {
    final p = ApproxLatLng.approximate(37.5665, 126.9780);
    expect(p.latitude, 37.57);
    expect(p.longitude, 126.98);
  });

  test('geohash length and alphabet', () {
    const p = ApproxLatLng(37.57, 126.98);
    final hash = Geo.encodeGeohash(p);
    expect(hash.length, Geo.petGeohashPrecision);
    expect(RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]+$').hasMatch(hash), isTrue);
  });

  test('nearby points share geohash prefix', () {
    const a = ApproxLatLng(37.57, 126.98);
    const b = ApproxLatLng(37.571, 126.981);
    final ha = Geo.encodeGeohash(a);
    final hb = Geo.encodeGeohash(b);
    expect(ha.substring(0, 4), hb.substring(0, 4));
  });
}
