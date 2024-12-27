// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'password_list_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onLogin() {
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      String secureHash = _passwordController.text + "__mypwbox__" + _usernameController.text;
      for(int i=0;i< 100;i++){
        secureHash = sha1.convert(utf8.encode(secureHash)).toString();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PasswordListScreen(username: _usernameController.text, secureHash: secureHash))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请输入用户名和密码')));
    }
  }

  Future<void> _createDatabase() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请输入用户名')));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path,
        '${_usernameController.text}_encrypted_password_manager.db');

    bool databaseExists = await databaseFactory.databaseExists(dbPath);

    if (databaseExists) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据库已存在')));
      return;
    }

    try {
      await openDatabase(
        dbPath,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据库创建成功')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据库创建失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
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
