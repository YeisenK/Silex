import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SafetyNumberService {
  /// Generates a 60-digit safety number from two identity keys.
  /// Both users will get the same number because the keys are sorted.
  static String generate({
    required String myIdentityKey,
    required String theirIdentityKey,
  }) {
    final myBytes = base64Decode(myIdentityKey);
    final theirBytes = base64Decode(theirIdentityKey);

    // sort so both sides produce the same result
    final sorted = _sortKeys(myBytes, theirBytes);

    // hash: SHA-256(key1 + key2) iterated 5200 times (Signal does similar)
    var hash = Uint8List.fromList([...sorted[0], ...sorted[1]]);
    for (int i = 0; i < 5200; i++) {
      hash = Uint8List.fromList(sha256.convert(hash).bytes);
    }

    // convert 32 bytes to 60 decimal digits
    // take 30 bytes, each pair of bytes → 5 digits
    final digits = StringBuffer();
    for (int i = 0; i < 30; i += 2) {
      final value = (hash[i] << 8) | hash[i + 1];
      digits.write(value.toString().padLeft(5, '0'));
    }

    return digits.toString().substring(0, 60);
  }

  /// Formats the 60-digit number into groups of 5 for display
  static String format(String safetyNumber) {
    final buffer = StringBuffer();
    for (int i = 0; i < safetyNumber.length; i += 5) {
      if (i > 0) buffer.write(' ');
      final end = (i + 5 > safetyNumber.length) ? safetyNumber.length : i + 5;
      buffer.write(safetyNumber.substring(i, end));
    }
    return buffer.toString();
  }

  /// Formats into rows of 20 digits (4 groups of 5) for display
  static List<String> formatRows(String safetyNumber) {
    final rows = <String>[];
    for (int i = 0; i < safetyNumber.length; i += 20) {
      final end =
          (i + 20 > safetyNumber.length) ? safetyNumber.length : i + 20;
      final chunk = safetyNumber.substring(i, end);
      final buffer = StringBuffer();
      for (int j = 0; j < chunk.length; j += 5) {
        if (j > 0) buffer.write('  ');
        final e = (j + 5 > chunk.length) ? chunk.length : j + 5;
        buffer.write(chunk.substring(j, e));
      }
      rows.add(buffer.toString());
    }
    return rows;
  }

  static List<Uint8List> _sortKeys(Uint8List a, Uint8List b) {
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (a[i] < b[i]) return [a, b];
      if (a[i] > b[i]) return [b, a];
    }
    return [a, b];
  }
}