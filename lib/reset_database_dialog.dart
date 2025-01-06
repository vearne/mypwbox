import 'package:flutter/material.dart';
import 'package:mypwbox/helpers.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'password.dart';
import 'dart:io';
import 'l10n/app_localizations.dart'; // Import AppLocalizations

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

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  void _modifyPassword() async {
    final localizations = AppLocalizations.of(context);

    if (_usernameController.text.isEmpty ||
        _oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations!.enterUsernamePassword!)));
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations!.incorrectUsernamePassword!)));
      return;
    }

    String newSecureHash =
        _newPasswordController.text + "__mypwbox__" + _usernameController.text;
    newSecureHash = hashN(newSecureHash, 100);

    try {
      passwords = await _oldDatabase.query(
        'passwords',
        orderBy: 'id ASC',
      );
      await _oldDatabase.close();

      final oldFile = File(dbPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      _newDatabase = await createDatabase(dbPath, newSecureHash);
      for (var item in passwords) {
        String password =
            secureDecrypt(item['password'] as String, oldSecureHash);
        Password newItem = Password.fromMap(item);
        newItem.password = secureEncrypt(password, newSecureHash);
        await _newDatabase.insert('passwords', newItem.toMap());
      }

      await _newDatabase.close();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(localizations!.resetPassword!)));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations!.error!}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations!.resetPassword!),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: localizations.username!),
          ),
          TextField(
            controller: _oldPasswordController,
            obscureText: !_isOldPasswordVisible,
            decoration: InputDecoration(
              labelText: localizations.password!,
              suffixIcon: IconButton(
                icon: Icon(
                  _isOldPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
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
            obscureText: !_isNewPasswordVisible,
            decoration: InputDecoration(
              labelText: localizations.password!,
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
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
          child: Text(localizations.cancel!),
        ),
        ElevatedButton(
          onPressed: _modifyPassword,
          child: Text(localizations.confirm!),
        ),
      ],
    );
  }
}
