import 'dart:async';
import 'package:minio/io.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path; // Rename the import to avoid conflict
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';
import 'password_detail_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'helpers.dart';
import 'password_dialog.dart';
import 'l10n/app_localizations.dart'; // Import localization file

class PasswordListScreen extends StatefulWidget {
  final String username;
  final String secureHash;

  PasswordListScreen({required this.username, required this.secureHash});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen>
    with WindowListener {
  late Database _database;
  List<Map<String, dynamic>> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  static const int _pageSize = 5;
  bool _hasNextPage = false;
  bool _isStale = false;
  String dbName = "";
  String dbPath = "";

  @override
  void initState() {
    super.initState();
    // 在窗口管理器上增加额外的监听逻辑
    windowManager.addListener(this);

    _searchController.addListener(_filterPasswords);
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    dbName = "__mypwbox__" + widget.username;
    dbName = hashN(dbName, 100);
    dbPath = path.join(directory.path, dbName);

    try {
      _database = await openDatabase(dbPath,
          password: "${widget.secureHash}", version: 1);
      _loadPasswords();
    } catch (e) {
      debugPrint('Database open failed, Incorrect username or password: $e');
      // 密码错误，显示弹窗提示用户
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error!),
            content:
                Text(AppLocalizations.of(context)!.incorrectUsernamePassword!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭弹窗
                  Navigator.pushReplacementNamed(context, '/login'); // 跳转回登录页面
                },
                child: Text(AppLocalizations.of(context)!.confirm!),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadPasswords() async {
    final offset = _currentPage * _pageSize;
    final query = _searchController.text.toLowerCase();
    List<Map<String, Object?>> passwords;
    int totalCount;

    if (query.isEmpty) {
      passwords = await _database.query(
        'passwords',
        orderBy: 'id ASC',
        limit: _pageSize,
        offset: offset,
      );
      totalCount = Sqflite.firstIntValue(
              await _database.rawQuery('SELECT COUNT(*) FROM passwords')) ??
          0;
    } else {
      passwords = await _database.query(
        'passwords',
        where: 'LOWER(title) LIKE ? OR LOWER(account) LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'id ASC',
        limit: _pageSize,
        offset: offset,
      );
      totalCount = Sqflite.firstIntValue(await _database.rawQuery(
            'SELECT COUNT(*) FROM passwords WHERE LOWER(title) LIKE ? OR LOWER(account) LIKE ?',
            ['%$query%', '%$query%'],
          )) ??
          0;
    }

    setState(() {
      _filteredPasswords = passwords;
      _hasNextPage = (offset + _pageSize) < totalCount;
    });
  }

  Future<void> _filterPasswords() async {
    setState(() {
      _currentPage = 0; // Reset to the first page when filtering
    });
    _loadPasswords();
  }

  Future<void> _addPassword(Map<String, dynamic> newPassword) async {
    // 密码存储前进行加密
    newPassword["password"] =
        secureEncrypt(newPassword["password"], widget.secureHash);
    await _database.insert('passwords', newPassword);
    setState(() {
      _isStale = true;
    });
    _loadPasswords();
  }

  Future<void> _updatePassword(
      int id, Map<String, dynamic> updatedPassword) async {
    // 密码存储前进行加密
    updatedPassword["password"] =
        secureEncrypt(updatedPassword["password"], widget.secureHash);
    await _database
        .update('passwords', updatedPassword, where: 'id = ?', whereArgs: [id]);
    setState(() {
      _isStale = true;
    });
    _loadPasswords();
  }

  Future<void> _deletePassword(int id) async {
    await _database.delete('passwords', where: 'id = ?', whereArgs: [id]);
    setState(() {
      _isStale = true;
    });
    _loadPasswords();
  }

  void _showAddPasswordDialog({Map<String, dynamic>? passwordToUpdate}) {
    Map<String, dynamic>? mutablePasswordToUpdate;

    if (passwordToUpdate != null) {
      // Create a mutable copy of the passwordToUpdate map
      mutablePasswordToUpdate = Map<String, dynamic>.from(passwordToUpdate);
      mutablePasswordToUpdate["password"] =
          secureDecrypt(mutablePasswordToUpdate["password"], widget.secureHash);
    }

    showDialog(
      context: context,
      builder: (context) {
        return PasswordDialog(
          context: context,
          passwordToUpdate: mutablePasswordToUpdate,
          onSave: (newPassword) {
            if (passwordToUpdate == null) {
              _addPassword(newPassword);
            } else {
              _updatePassword(mutablePasswordToUpdate!['id'], newPassword);
            }
          },
        );
      },
    );
  }

  void _confirmDeletePassword(int id) {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);

        return AlertDialog(
          title: Text(localizations?.confirmDelete ?? '确认删除'),
          content: Text(localizations?.areYouSureDelete ?? '确定要删除此密码吗?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? '取消？'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePassword(id);
                Navigator.pop(context);
              },
              child: Text(localizations?.delete ?? '删除'),
            ),
          ],
        );
      },
    );
  }

  void _changePage(int newPage) {
    if (newPage >= 0 && (_hasNextPage || newPage < _currentPage)) {
      setState(() {
        _currentPage = newPage;
      });
      _loadPasswords();
    }
  }

  void _showPasswordDetails(Map<String, dynamic> password) {
    showDialog(
      context: context,
      builder: (context) {
        return PasswordDetailsDialog(
          password: password,
          secureHash: widget.secureHash,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Password Manager'),
            Text(
              'Database: ${widget.username}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredPasswords.isEmpty
                ? Center(child: Text('No passwords found.'))
                : ListView.builder(
                    itemCount: _filteredPasswords.length,
                    itemBuilder: (context, index) {
                      final password = _filteredPasswords[index];
                      return Card(
                        child: ListTile(
                          title: Text(password['title']),
                          subtitle: Text(password['account']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility),
                                onPressed: () => _showPasswordDetails(password),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showAddPasswordDialog(
                                    passwordToUpdate: password),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () =>
                                    _confirmDeletePassword(password['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => _changePage(_currentPage - 1)
                    : null,
              ),
              Text('Page ${_currentPage + 1}'),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed:
                    _hasNextPage ? () => _changePage(_currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPasswordDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // 在关闭窗口时执行额外操作
    bool shouldClose = await _showExitConfirmationDialog();
    if (shouldClose) {
      debugPrint("_isStale: $_isStale");
      if (_isStale) {
        debugPrint("Uploading database to S3...");
        await _uploadDatabase();
      }
      await windowManager.destroy(); // 允许窗口关闭
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.exitConfirmation!),
            content: Text(AppLocalizations.of(context)!.areYouSureExit!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel!),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.confirm!),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _uploadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getBool('offline') ?? false;

    if (!offline) {
      final endpoint = prefs.getString('endpoint') ?? '';
      final accessKeyID = prefs.getString('accessKeyID') ?? '';
      final secretAccessKey = prefs.getString('secretAccessKey') ?? '';
      final bucketName = prefs.getString('bucketName') ?? '';
      final dirpath = prefs.getString('dirpath') ?? '';

      final minio = Minio(
        endPoint: endpoint,
        accessKey: accessKeyID,
        secretKey: secretAccessKey,
        useSSL: true, // 如果使用 HTTPS，设置为 true
        // enableTrace: true,
      );

      final key = '$dirpath/$dbName';
      debugPrint("upload file [$dbPath] to: [$key]");

      try {
        final eTag = await minio.fPutObject(bucketName, key, dbPath);
        debugPrint("upload file [$dbPath] to: [$key], eTag: $eTag");
      } catch (e) {
        debugPrint('${AppLocalizations.of(context)!.uploadFailed!} $e');
      }
    }
  }
}
