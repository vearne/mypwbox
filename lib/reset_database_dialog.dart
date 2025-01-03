import 'package:flutter/material.dart';
import 'package:mypwbox/helpers.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'password.dart';
import 'dart:io'; // Add this import at the top of the file

class ResetDatabaseDialog extends StatefulWidget {
  ResetDatabaseDialog();

  @override
  _ResetDatabaseDialogState createState() => _ResetDatabaseDialogState();
}

class _ResetDatabaseDialogState extends State<ResetDatabaseDialog> {
  late Database _oldDatabase;
  late Database _newDatabase;

  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  List<Map<String, Object?>> passwords = [];

  bool _isOldPasswordVisible = false; // State for old password visibility
  bool _isNewPasswordVisible = false; // State for new password visibility

  void _modifyPassword() async{
    if (_usernameController.text.isEmpty ||
        _oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('请输入所有字段')));
      return;
    }

    // Validate old password
    String oldSecureHash =
        _oldPasswordController.text + "__mypwbox__" + _usernameController.text;
    oldSecureHash = hashN(oldSecureHash, 100);

    final directory = await getApplicationDocumentsDirectory();
    String dbName = "__mypwbox__" + _usernameController.text;
    dbName = hashN(dbName, 100);
    final dbPath = path.join(directory.path, dbName);

    try {
      _oldDatabase = await openDatabase(
        dbPath,
        password: oldSecureHash,
        version: 1,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('旧密码错误')));
      return;
    }

    // Update to new password
    String newSecureHash =
        _newPasswordController.text + "__mypwbox__" + _usernameController.text;
    newSecureHash = hashN(newSecureHash, 100);

    try {

      passwords = await _oldDatabase.query(
        'passwords',
        orderBy: 'id ASC',
      );
      await _oldDatabase.close();

      // 删除旧的数据库文件
      final oldFile = File(dbPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // 创建新的数据库
      _newDatabase = await createDatabase(dbPath, newSecureHash);
      for (var item in passwords) {
          String password = secureDecrypt(item['password'] as String, oldSecureHash);
          Password newItem = Password.fromMap(item);
          newItem.password = secureEncrypt(password, newSecureHash);
          await _newDatabase.insert('passwords', newItem.toMap());
      }

      await _newDatabase.close();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('密码重置成功')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('密码重置失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('重置密码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: '用户名'),
          ),
          TextField(
            controller: _oldPasswordController,
            obscureText: !_isOldPasswordVisible, // Toggle visibility
            decoration: InputDecoration(
              labelText: '旧密码',
              suffixIcon: IconButton(
                icon: Icon(
                  _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isOldPasswordVisible = !_isOldPasswordVisible;
                  });
                },
              ),
            ),
          ),
          TextField(
            controller: _newPasswordController,
            obscureText: !_isNewPasswordVisible, // Toggle visibility
            decoration: InputDecoration(
              labelText: '新密码',
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _modifyPassword,
          child: Text('提交'),
        ),
      ],
    );
  }
}
