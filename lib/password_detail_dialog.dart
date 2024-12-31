import 'package:flutter/material.dart';
import 'package:mypwbox/helpers.dart';
import 'dart:async';
import 'package:otp/otp.dart';

class PasswordDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> password;
  final String secureHash;

  PasswordDetailsDialog({
    required this.password,
    required this.secureHash,
  });

  @override
  _PasswordDetailsDialogState createState() => _PasswordDetailsDialogState();
}

class _PasswordDetailsDialogState extends State<PasswordDetailsDialog> {
  Timer? _timer;
  bool _isPasswordVisible = false;
  bool _isTotp = false;
  int _timeRemaining = 30;
  String _totpCode = "";

  Algorithm getAlgorithm(String? str) {
    str ??= "SHA1";

    str = str.toUpperCase();
    if (str == "SHA1") {
      return Algorithm.SHA1;
    } else if (str == "SHA256") {
      return Algorithm.SHA256;
    } else {
      return Algorithm.SHA512;
    }
  }

  void calcTOTP(String str) {
    // 从 password 字段中提取 TOTP 密钥
    // otpauth://totp/ut:vearne?algorithm=SHA1&digits=6&issuer=ut&period=30&secret=TSGDMWE5TRZP4Q77LFVRGRBOAYSJ4XBD
    final uri = Uri.parse(str);
    final secret = uri.queryParameters['secret'];
    final alg = getAlgorithm(uri.queryParameters["algorithm"]);

    if (secret != null) {
      _totpCode = OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: alg,
        interval: 30,
        isGoogle: true,
      );
      _timeRemaining =
          30 - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 30;
    }
  }

  @override
  void initState() {
    super.initState();
    String password =
        secureDecrypt(widget.password['password'], widget.secureHash);
    // 判断是否是TOTP密钥
    if (password.startsWith('otpauth://totp/')) {
      _isTotp = true;
      // 从 password 字段中提取 TOTP 密钥
      // otpauth://totp/ut:vearne?algorithm=SHA1&digits=6&issuer=ut&period=30&secret=TSGDMWE5TRZP4Q77LFVRGRBOAYSJ4XBD
      calcTOTP(password);
    }

    if (_isTotp && _timer == null) {
      // 启动倒计时
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          // 检查 mounted 属性
          if (_timeRemaining > 0) {
            setState(() {
              _timeRemaining--;
            });
          } else {
            setState(() {
              calcTOTP(password);
              _timeRemaining = 30;
            });
          }
        } else {
          _timer?.cancel(); // 取消定时器
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Password Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${widget.password['title']}'),
            SizedBox(height: 10),
            Text('Account: ${widget.password['account']}'),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                      'Password: ${_isPasswordVisible ?
                      secureDecrypt(widget.password['password'], widget.secureHash) : '********'}'),
                ),
                IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('Comment: ${widget.password['comment']}'),
            SizedBox(height: 10),
            Text('Created At: ${_formatDate(widget.password['created_at'])}'),
            SizedBox(height: 10),
            Text('Updated At: ${_formatDate(widget.password['updated_at'])}'),
            if (_isTotp) ...[
              SizedBox(height: 20),
              Text('TOTP Code: ${_totpCode}'),
              SizedBox(height: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _timeRemaining / 30,
                      strokeWidth: 4,
                    ),
                    Text(
                      '${_timeRemaining}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    return dateString.substring(0, 19).replaceAll("T", " ");
  }
}
