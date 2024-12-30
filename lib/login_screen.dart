// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'password_list_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 's3_config_screen.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WindowListener {
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
            title: Text('退出确认'),
            content: Text('确定要退出应用吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('确定'),
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
            .showSnackBar(SnackBar(content: Text('数据库不存在')));
        return;
      }

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PasswordListScreen(
                  username: _usernameController.text, secureHash: secureHash)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('请输入用户名和密码')));
    }
  }

  String hashN(String str, int n) {
    for (int i = 0; i < n; i++) {
      str = sha1.convert(utf8.encode(str)).toString();
    }
    return str;
  }

  Future<void> _createDatabase() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('请输入用户名和密码')));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    String dbName = "__mypwbox__" + _usernameController.text;
    dbName = hashN(dbName, 100);
    final dbPath = path.join(directory.path, dbName);

    bool databaseExists = await databaseFactory.databaseExists(dbPath);
    if (databaseExists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('数据库已存在')));
      return;
    }

    String secureHash =
        _passwordController.text + "__mypwbox__" + _usernameController.text;
    secureHash = hashN(secureHash, 100);

    try {
      await openDatabase(
        dbPath,
        password: secureHash,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE passwords (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              account TEXT NOT NULL,
              password TEXT NOT NULL,
              comment TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('数据库创建成功')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('数据库创建失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录'),
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
              decoration: InputDecoration(labelText: '用户名'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(labelText: '密码'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onLogin,
              child: Text('登录'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _createDatabase,
              child: Text('创建数据库'),
            ),
          ],
        ),
      ),
    );
  }
}
