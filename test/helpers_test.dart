import 'package:flutter_test/flutter_test.dart';
import 'package:mypwbox/helpers.dart';


void main() {
    test('secureEncrypt & secureDecrypt', () {
      String key = "0fefa622fa9c218ad931a54b55c1d7ed987278f6";
      String cipherText = secureEncrypt("abcdef", key);
      expect(secureDecrypt(cipherText, key), "abcdef");

      cipherText = secureEncrypt("1_abcdXd88EF", key);
      expect(secureDecrypt(cipherText, key), "1_abcdXd88EF");
    });
}