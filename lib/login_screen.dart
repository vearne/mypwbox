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

class LoginScreen extends StatefulWidget {
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
        title: Text(AppLocalizations.of(context)?.confirmExit ?? 'Exit Confirmation'),
        content: Text(AppLocalizations.of(context)?.areYouSureExit ?? 'Are you sure you want to exit the application?'),
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
          _passwordController.text + "__mypwbox__" + _usernameController.text;
      secureHash = hashN(secureHash, 100);

      final directory = await getApplicationDocumentsDirectory();
      String dbName = "__mypwbox__" + _usernameController.text;
      dbName = hashN(dbName, 100);
      final dbPath = path.join(directory.path, dbName);
      bool databaseExists = await databaseFactory.databaseExists(dbPath);
      if (!databaseExists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.databaseNotExist ?? 'Database does not exist')));
        return;
      }

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PasswordListScreen(
                  username: _usernameController.text, secureHash: secureHash)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.enterUsernamePassword ?? 'Please enter username and password')));
    }
  }

  void _createDatabase() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.enterUsernamePassword ?? 'Please enter username and password')));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    String dbName = "__mypwbox__" + _usernameController.text;
    dbName = hashN(dbName, 100);
    final dbPath = path.join(directory.path, dbName);

    bool databaseExists = await databaseFactory.databaseExists(dbPath);
    if (databaseExists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.databaseExists ?? 'Database already exists')));
      return;
    }

    String secureHash =
        _passwordController.text + "__mypwbox__" + _usernameController.text;
    secureHash = hashN(secureHash, 100);

    try {
      await createDatabase(dbPath, secureHash);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.databaseCreated ?? 'Database created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)?.databaseCreationFailed ?? 'Database creation failed'}: $e')));
    }
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ResetDatabaseDialog();
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
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => S3ConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                  labelText: localizations?.username ?? 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: localizations?.password ?? 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // 切换显示/隐藏
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onLogin,
              child: Text(localizations?.login ?? 'Login'),
            ),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: _createDatabase,
                child: Text(localizations?.createDatabase ?? 'Create Database'),
              ),
              SizedBox(width: 10), // 添加间距
              ElevatedButton(
                onPressed: _showResetPasswordDialog,
                child: Text(localizations?.resetPassword ?? 'Reset Password'),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
