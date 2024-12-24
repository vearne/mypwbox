import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'database_helper.dart';

class PasswordListScreen extends StatefulWidget {
  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  late Database _database;
  List<Map<String, dynamic>> _passwords = [];
  List<Map<String, dynamic>> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _searchController.addListener(_filterPasswords);
  }

  Future<void> _initializeDatabase() async {
    _database = await DatabaseHelper.getDatabase();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final passwords = await _database.query('passwords');
    setState(() {
      _passwords = passwords;
      _filteredPasswords = passwords;
    });
  }

  void _filterPasswords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPasswords = _passwords.where((password) {
        return password['title'].toLowerCase().contains(query) ||
            password['account'].toLowerCase().contains(query);
      }).toList();
    });
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
