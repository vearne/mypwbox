// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'password_list_screen.dart';
import 'helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 's3_config_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'reset_database_dialog.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WindowListener {
  bool _obscureText = true; // 控制是否显示明文

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 在窗口管理器上增加额外的监听逻辑
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // 在关闭窗口时执行额外操作
    bool shouldClose = await _showExitConfirmationDialog();
    if (shouldClose) {
      await windowManager.destroy(); // 允许窗口关闭
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)?.confirmExit ??
                'Exit Confirmation'),
            content: Text(AppLocalizations.of(context)?.areYouSureExit ??
                'Are you sure you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)?.yes ?? 'Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onLogin() async {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      String secureHash =
          computeSecureHash(_usernameController.text, _passwordController.text);

      final directory = await getApplicationDocumentsDirectory();
      String dbName = computeDbName(_usernameController.text);
      final dbPath = path.join(directory.path, dbName);
      bool databaseExists = await databaseFactory.databaseExists(dbPath);
      if (!databaseExists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)?.databaseNotExist ??
                'Database does not exist')));
        return;
      }

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PasswordListScreen(
                  username: _usernameController.text, secureHash: secureHash)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.enterUsernamePassword ??
              'Please enter username and password')));
    }
  }

  void _createDatabase() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.enterUsernamePassword ??
              'Please enter username and password')));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    String dbName = computeDbName(_usernameController.text);
    final dbPath = path.join(directory.path, dbName);

    bool databaseExists = await databaseFactory.databaseExists(dbPath);
    if (databaseExists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.databaseExists ??
              'Database already exists')));
      return;
    }

    String secureHash =
        computeSecureHash(_usernameController.text, _passwordController.text);

    try {
      await createDatabase(dbPath, secureHash);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.databaseCreated ??
              'Database created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${AppLocalizations.of(context)?.databaseCreationFailed ?? 'Database creation failed'}: $e')));
    }
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const ResetDatabaseDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.login ?? 'Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const S3ConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App icon
                      const Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: Color(0xFF818CF8),
                      ),
                      const SizedBox(height: 16),
                      // App name
                      const Text(
                        'mypwbox',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tagline subtitle
                      Text(
                        localizations?.login ?? 'Login',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Username field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: localizations?.username ?? 'Username',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: localizations?.password ?? 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText; // 切换显示/隐藏
                              });
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          _onLogin(); // Trigger login on Enter key press
                        },
                      ),
                      const SizedBox(height: 28),
                      // Login button (primary action)
                      GradientButton(
                        onPressed: _onLogin,
                        child: Text(localizations?.login ?? 'Login'),
                      ),
                      const SizedBox(height: 16),
                      // Secondary actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _createDatabase,
                            child: Text(localizations?.createDatabase ??
                                'Create Database'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _showResetPasswordDialog,
                            child: Text(
                                localizations?.resetPassword ?? 'Reset Password'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
