/// Official MVP document IDs. Keep in sync with `firestore.rules`.
abstract final class FirestoreIds {
  static String likeId({
    required String fromUid,
    required String toPetId,
  }) =>
      '${fromUid}_$toPetId';

  /// `minUid_maxUid` (lexicographic).
  static String matchId(String a, String b) {
    final sorted = sortedUids(a, b);
    return '${sorted[0]}_${sorted[1]}';
  }

  static List<String> sortedUids(String a, String b) {
    return a.compareTo(b) <= 0 ? <String>[a, b] : <String>[b, a];
  }

  /// petIds[i] is the pet of userIds[i]. MVP: petId == ownerId == uid.
  static List<String> petIdsForUsers(List<String> userIds) =>
      List<String>.from(userIds);

  static String blockId({
    required String blockerId,
    required String blockedId,
  }) =>
      '${blockerId}_$blockedId';

  static String photoPath({
    required String petId,
    required String fileName,
  }) =>
      'pets/$petId/$fileName';

  static int seedFromPhotoPath(String path) {
    final name = path.split('/').last;
    final match = RegExp(r'(\d+)').firstMatch(name);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return path.hashCode.abs() % 997;
  }
}
