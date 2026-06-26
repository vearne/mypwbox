// In PasswordDetailsDialog.dart
import 'package:flutter/material.dart';
import 'package:mypwbox/helpers.dart';
import 'package:mypwbox/password.dart';
import 'dart:async';
import 'package:otp/otp.dart';
import 'l10n/app_localizations.dart'; // Import localization file
import 'theme/app_theme.dart';
import 'package:flutter/services.dart'; // 导入剪贴板服务

class PasswordDetailsDialog extends StatefulWidget {
  final Password password;
  final String secureHash;

  const PasswordDetailsDialog({super.key, 
    required this.password,
    required this.secureHash,
  });

  @override
  _PasswordDetailsDialogState createState() => _PasswordDetailsDialogState();
}

class _PasswordDetailsDialogState extends State<PasswordDetailsDialog> {
  Timer? _timer;
  Timer? _clipboardTimer;
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
        secureDecrypt(widget.password.password, widget.secureHash);
    // 判断是否是TOTP密钥
    if (password.startsWith('otpauth://totp/')) {
      _isTotp = true;
      // 从 password 字段中提取 TOTP 密钥
      // otpauth://totp/ut:vearne?algorithm=SHA1&digits=6&issuer=ut&period=30&secret=TSGDMWE5TRZP4Q77LFVRGRBOAYSJ4XBD
      calcTOTP(password);
    }

    if (_isTotp && _timer == null) {
      // 启动倒计时
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.title ?? 'Title'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Basic info section ---
            GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                      l10n?.title ?? 'Title', widget.password.title),
                  const Divider(),
                  _buildInfoRow(
                      l10n?.account ?? 'Account', widget.password.account),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Password section ---
            GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      l10n?.password ?? 'Password',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isPasswordVisible
                          ? secureDecrypt(
                              widget.password.password, widget.secureHash)
                          : '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
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
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      final password = secureDecrypt(
                          widget.password.password, widget.secureHash);
                      Clipboard.setData(ClipboardData(text: password)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n?.passwordCopied ??
                                  'Password copied! Clipboard clears in 30s.')),
                        );
                        _clipboardTimer?.cancel();
                        _clipboardTimer = Timer(const Duration(seconds: 30), () {
                          Clipboard.getData(Clipboard.kTextPlain).then((data) {
                            if (data?.text == password) {
                              Clipboard.setData(const ClipboardData(text: ''));
                            }
                          });
                        });
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Comment section ---
            GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: _buildInfoRow(
                  l10n?.comment ?? 'Comment', widget.password.comment),
            ),
            const SizedBox(height: 16),

            // --- Metadata section ---
            GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(l10n?.createdAt ?? 'Created',
                      _formatDate(widget.password.createdAt.toIso8601String())),
                  const Divider(),
                  _buildInfoRow(l10n?.updatedAt ?? 'Updated',
                      _formatDate(widget.password.updatedAt.toIso8601String())),
                ],
              ),
            ),

            // --- TOTP section ---
            if (_isTotp) ...[
              const SizedBox(height: 24),
              GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'TOTP',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _totpCode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontFamily: 'monospace',
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _timeRemaining / 30,
                                  strokeWidth: 4,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF818CF8)),
                                ),
                                Text(
                                  '$_timeRemaining',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.close ?? 'Close'),
        ),
      ],
    );
  }

  /// Builds a labeled info row: muted label on the left, white value on the right.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    return dateString.substring(0, 19).replaceAll("T", " ");
  }
}
