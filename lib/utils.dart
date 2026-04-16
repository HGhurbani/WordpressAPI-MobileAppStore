// lib/utils.dart
String formatNumber(double number) {
  if (!number.isFinite) {
    return '0';
  }
  if (number == number.roundToDouble()) {
    return number.toInt().toString();
  } else {
    return number.toStringAsFixed(0);
  }
}
