import 'dart:async';
import 'package:minio/io.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path; // Rename the import to avoid conflict
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';
import 'password_detail_dialog.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordListScreen extends StatefulWidget {
  final String username;
  final String secureHash;

  PasswordListScreen({required this.username, required this.secureHash});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  Timer? _timer; // 定义一个 Timer 变量
  late Database _database;
  List<Map<String, dynamic>> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  static const int _pageSize = 5;
  bool _hasNextPage = false;
  bool _isStale = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPasswords);
    _initializeDatabase();
  }

  String hashN(String str, int n) {
    for (int i = 0; i < n; i++) {
      str = sha1.convert(utf8.encode(str)).toString();
    }
    return str;
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    String dbName = "__mypwbox__" + widget.username;
    dbName = hashN(dbName, 100);
    final dbPath = path.join(directory.path, dbName);

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
            title: Text('错误'),
            content: Text('输入的用户名或密码有误，请重试。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭弹窗
                  Navigator.pushReplacementNamed(context, '/login'); // 跳转回登录页面
                },
                child: Text('确定'),
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
    await _database.insert('passwords', newPassword);
    setState(() {
      _isStale = true;
    });
    _loadPasswords();
  }

  Future<void> _updatePassword(
      int id, Map<String, dynamic> updatedPassword) async {
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
    final _titleController =
        TextEditingController(text: passwordToUpdate?['title']);
    final _accountController =
        TextEditingController(text: passwordToUpdate?['account']);
    final _passwordController =
        TextEditingController(text: passwordToUpdate?['password']);
    final _commentController =
        TextEditingController(text: passwordToUpdate?['comment']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(passwordToUpdate == null
              ? 'Add New Password'
              : 'Update Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _accountController,
                  decoration: InputDecoration(labelText: 'Account'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(labelText: 'Comment'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPassword = {
                  'title': _titleController.text,
                  'account': _accountController.text,
                  'password': _passwordController.text,
                  'comment': _commentController.text,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                };

                if (passwordToUpdate == null) {
                  _addPassword(newPassword);
                } else {
                  _updatePassword(passwordToUpdate['id'], newPassword);
                }
                Navigator.pop(context);
              },
              child: Text(passwordToUpdate == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePassword(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this password?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePassword(id);
                Navigator.pop(context);
              },
              child: Text('Delete'),
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
    // debugPrint("_isStale: $_isStale");
    // if (_isStale) {
    //   debugPrint("Uploading database to S3...");
    //   _uploadDatabase();
    // }
    _searchController.dispose();
    super.dispose();
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
      );

      final directory = await getApplicationDocumentsDirectory();
      final key = '$dirpath/${widget.username}_encrypted_password_manager.db';
      final dbPath = path.join(
          directory.path, '${widget.username}_encrypted_password_manager.db');

      debugPrint("key: $key");
      debugPrint("filePath: $dbPath");
      try {
        await minio.fPutObject(bucketName, key, dbPath);
      } catch (e) {
        debugPrint('Failed to upload database to S3: $e');
      }
    }
  }
}
