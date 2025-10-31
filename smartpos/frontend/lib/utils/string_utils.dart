import 'dart:math';

String generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}

String generateUniqueEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final random = generateRandomString(6);
  return 'user_${timestamp}_$random@smartpos.local';
}
