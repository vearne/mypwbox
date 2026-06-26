import 'dart:async';
import 'package:minio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path; // Rename the import to avoid conflict
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';
import 'password_detail_dialog.dart';
import 'password.dart';
import 'package:window_manager/window_manager.dart';
import 'helpers.dart';
import 'password_dialog.dart';
import 'l10n/app_localizations.dart'; // Import localization file
import 'theme/app_theme.dart';

class PasswordListScreen extends StatefulWidget {
  final String username;
  final String secureHash;

  const PasswordListScreen({super.key, required this.username, required this.secureHash});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen>
    with WindowListener {
  late Database _database;
  List<Password> _filteredPasswords = [];
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
    dbName = computeDbName(widget.username);
    dbPath = path.join(directory.path, dbName);

    try {
      _database = await openDatabase(dbPath,
          password: widget.secureHash, version: 1);
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
        where: 'LOWER(title) LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'id ASC',
        limit: _pageSize,
        offset: offset,
      );
      totalCount = Sqflite.firstIntValue(await _database.rawQuery(
            'SELECT COUNT(*) FROM passwords WHERE LOWER(title) LIKE ?',
            ['%$query%'],
          )) ??
          0;
    }

    setState(() {
      _filteredPasswords =
          passwords.map((m) => Password.fromMap(m.cast<String, dynamic>())).toList();
      _hasNextPage = (offset + _pageSize) < totalCount;
    });
  }

  Future<void> _filterPasswords() async {
    setState(() {
      _currentPage = 0; // Reset to the first page when filtering
    });
    _loadPasswords();
  }

  Future<void> _addPassword(Password newPassword) async {
    // 密码存储前进行加密
    newPassword.password =
        secureEncrypt(newPassword.password, widget.secureHash);
    await _database.insert('passwords', newPassword.toMap());
    setState(() {
      _isStale = true;
    });
    _loadPasswords();
  }

  Future<void> _updatePassword(
      int id, Password updatedPassword) async {
    // 密码存储前进行加密
    updatedPassword.password =
        secureEncrypt(updatedPassword.password, widget.secureHash);
    await _database
        .update('passwords', updatedPassword.toMap(), where: 'id = ?', whereArgs: [id]);
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

  void _showAddPasswordDialog({Password? passwordToUpdate}) {
    Password? decryptedPassword;

    if (passwordToUpdate != null) {
      decryptedPassword = passwordToUpdate.copyWith(
        password: secureDecrypt(passwordToUpdate.password, widget.secureHash),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return PasswordDialog(
          passwordToUpdate: decryptedPassword,
          onSave: (Password newPassword) {
            if (passwordToUpdate == null) {
              _addPassword(newPassword);
            } else {
              _updatePassword(
                passwordToUpdate.id!,
                newPassword.copyWith(
                  id: passwordToUpdate.id,
                  createdAt: passwordToUpdate.createdAt,
                ),
              );
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

  void _showPasswordDetails(Password password) {
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations?.passwordManager ?? 'Password Manager'),
            Text(
              '${localizations?.database ?? 'Database'}: ${widget.username}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: localizations?.search ?? 'Search',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _filteredPasswords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            localizations?.noPasswordsFound ??
                                'No passwords found.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPasswords.length,
                      itemBuilder: (context, index) {
                        final password = _filteredPasswords[index];
                        return GlassCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF312E81),
                              child: Text(
                                password.title.isNotEmpty
                                    ? password.title[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              password.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              password.account,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () =>
                                      _showPasswordDetails(password),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showAddPasswordDialog(
                                      passwordToUpdate: password),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _confirmDeletePassword(password.id!),
                                ),
                              ],
                            ),
                            onTap: () => _showPasswordDetails(password),
                          ),
                        );
                      },
                    ),
            ),
            GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => _changePage(_currentPage - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${localizations?.page ?? 'Page'} ${_currentPage + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _hasNextPage
                        ? () => _changePage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPasswordDialog(),
        child: const Icon(Icons.add),
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
      // 清空剪贴板，防止密码残留
      await Clipboard.setData(const ClipboardData(text: ''));
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
