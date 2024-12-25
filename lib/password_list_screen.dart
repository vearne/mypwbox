import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path; // Rename the import to avoid conflict
import 'package:path_provider/path_provider.dart';

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

    _database = await openDatabase(
      dbPath,
      password: "${widget.secureHash}", // 加密的密码
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
    _loadPasswords();
  }

  Future<void> _updatePassword(int id, Map<String, dynamic> updatedPassword) async {
    await _database.update('passwords', updatedPassword, where: 'id = ?', whereArgs: [id]);
    _loadPasswords();
  }

  Future<void> _deletePassword(int id) async {
    await _database.delete('passwords', where: 'id = ?', whereArgs: [id]);
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

  void _showPasswordDetails(Map<String, dynamic> password) {
    showDialog(
      context: context,
      builder: (context) {
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
                Text('Password: ${password['password']}'),
                SizedBox(height: 10),
                Text('Comment: ${password['comment']}'),
                SizedBox(height: 10),
                Text('Created At: ${password['created_at']}'),
                SizedBox(height: 10),
                Text('Updated At: ${password['updated_at']}'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password Manager'),
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
    _searchController.dispose();
    super.dispose();
  }
}
