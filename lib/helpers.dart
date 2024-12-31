import 'package:crclib/catalog.dart';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

String secureEncrypt(String plainText, String key) {
  int padLength = hashStringToUint64(key) % 30 + 60;
  plainText = generateRandomString(padLength) + plainText;

  String iv = calcIV(key);
  return aesEncrypt(plainText, calcRealKey(key), iv);
}

String secureDecrypt(String cipherText, String key) {
  String iv = calcIV(key);
  String plainText = aesDecrypt(cipherText, calcRealKey(key), iv);

  int padLength = hashStringToUint64(key) % 30 + 60;
  return plainText.substring(padLength, plainText.length);
}

String calcIV(String key) {
  String str = hashN(key, 3);
  return str.substring(0, 16);
}

String calcRealKey(String key) {
  String str = hashN(key, 1);
  return str.substring(0, 16);
}

String hashN(String str, int n) {
  for (int i = 0; i < n; i++) {
    str = sha1.convert(utf8.encode(str)).toString();
  }
  return str;
}

/// 加密函数
String aesEncrypt(String plainText, String key, String iv) {
  final keyBytes = encrypt.Key.fromUtf8(key);
  final ivBytes = encrypt.IV.fromUtf8(iv);
  final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes));

  final encrypted = encrypter.encrypt(plainText, iv: ivBytes);
  return encrypted.base64; // 返回加密后的 Base64 编码字符串
}

/// 解密函数
String aesDecrypt(String cipherText, String key, String iv) {
  final keyBytes = encrypt.Key.fromUtf8(key);
  final ivBytes = encrypt.IV.fromUtf8(iv);
  final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes));

  final decrypted = encrypter.decrypt64(cipherText, iv: ivBytes);
  return decrypted; // 返回解密后的明文
}

/// 使用 CRC64 算法计算哈希值
int hashStringToUint64(String input) {
  final crc = Crc64().convert(input.codeUnits);
  return crc.toBigInt().toInt(); // 将哈希值转换为 uint64
}

/// 生成指定长度的随机字符串，包含大小写英文字母和数字
String generateRandomString(int length) {
  const String chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-+,';
  final Random random = Random();

  return List.generate(length, (index) => chars[random.nextInt(chars.length)])
      .join();
}
