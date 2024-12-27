import 'package:minio/io.dart';
import 'package:otp/otp.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path; // Rename the import to avoid conflict
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';

class PasswordListScreen extends StatefulWidget {
  final String username;
  final String secureHash;

  PasswordListScreen({required this.username, required this.secureHash});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
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

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path,
        '${widget.username}_encrypted_password_manager.db'); // Use path.join

    bool databaseExists = await databaseFactory.databaseExists(dbPath);

    if (!databaseExists) {
      bool shouldCreate = await showDialog(
        context: context, // Use BuildContext here
        builder: (context) {
          return AlertDialog(
            title: Text('数据库不存在'),
            content: Text('是否创建新的数据库？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('创建'),
              ),
            ],
          );
        },
      );

      if (!shouldCreate) {
        Navigator.pop(context); // Use BuildContext here
        return;
      }
    }

    try {
      _database = await openDatabase(
        dbPath,
        password: "${widget.secureHash}",
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
      _loadPasswords();
    } catch (e) {
      print('Database open failed, Incorrect username or password: $e');
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
      totalCount = Sqflite.firstIntValue(await _database.rawQuery('SELECT COUNT(*) FROM passwords')) ?? 0;
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
      )) ?? 0;
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

  Future<void> _updatePassword(int id, Map<String, dynamic> updatedPassword) async {
    await _database.update('passwords', updatedPassword, where: 'id = ?', whereArgs: [id]);
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
    final _titleController = TextEditingController(text: passwordToUpdate?['title']);
    final _accountController = TextEditingController(text: passwordToUpdate?['account']);
    final _passwordController = TextEditingController(text: passwordToUpdate?['password']);
    final _commentController = TextEditingController(text: passwordToUpdate?['comment']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(passwordToUpdate == null ? 'Add New Password' : 'Update Password'),
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

  String _formatDate(String dateString) {
    return dateString.substring(0, 19).replaceAll("T", " ");
  }

  void _showPasswordDetails(Map<String, dynamic> password) {
    bool _isPasswordVisible = false;
    bool _isTotp = false;
    String _totpCode = '';
    int _timeRemaining = 30;

    // 判断是否是TOTP密钥
    if (password['password'].startsWith('otpauth://totp/')) {
      _isTotp = true;
      // 从 password 字段中提取 TOTP 密钥
      final uri = Uri.parse(password['password']);
      final secret = uri.queryParameters['secret'];
      if (secret != null) {
        _totpCode = OTP.generateTOTPCodeString(
          secret,
          DateTime.now().millisecondsSinceEpoch,
          interval: 30,
        );
        _timeRemaining = 30 - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 30;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (_isTotp) {
              // 启动倒计时
              Future.delayed(Duration(seconds: 1), () {
                if (_timeRemaining > 0) {
                  setState(() {
                    _timeRemaining--;
                  });
                } else {
                  setState(() {
                    _timeRemaining = 30;
                    final secret = Uri.parse(password['password']).queryParameters['secret'];
                    if (secret != null) {
                      _totpCode = OTP.generateTOTPCodeString(
                        secret,
                        DateTime.now().millisecondsSinceEpoch,
                        interval: 30,
                      );
                    }
                  });
                }
              });
            }

            return AlertDialog(
              title: Text('Password Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Title: ${password['title']}'),
                    SizedBox(height: 10),
                    Text('Account: ${password['account']}'),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Password: ${_isPasswordVisible
                            ? password['password']
                            : '********'}'),
                        IconButton(
                          icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons
                                  .visibility),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('Comment: ${password['comment']}'),
                    SizedBox(height: 10),
                    Text('Created At: ${_formatDate(password['created_at'])}'),
                    SizedBox(height: 10),
                    Text('Updated At: ${_formatDate(password['updated_at'])}'),
                    if (_isTotp) ...[
                      SizedBox(height: 20),
                      Text('TOTP Code: $_totpCode'),
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
                              '$_timeRemaining',
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
          },
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
                          onPressed: () => _showAddPasswordDialog(passwordToUpdate: password),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _confirmDeletePassword(password['id']),
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
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
              ),
              Text('Page ${_currentPage + 1}'),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _hasNextPage ? () => _changePage(_currentPage + 1) : null,
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
    if (_isStale) {
      _uploadDatabase();
    }
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
      final dbPath = path.join(
          directory.path, '${widget.username}_encrypted_password_manager.db');

      try {
        await minio.fPutObject(bucketName,
            '$dirpath/${widget.username}_encrypted_password_manager.db',
            dbPath);
      } catch (e) {
        print('Failed to upload database to S3: $e');
      }
    }
  }
}
