import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'username': 'Username',
      'password': 'Password',
      'createDatabase': 'Create Database',
      'databaseExists': 'Database already exists',
      'resetPassword': 'Reset Password',
      'confirmDelete': 'Confirm Delete',
      'areYouSureDelete': 'Are you sure you want to delete this password?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'add': 'Add',
      'update': 'Update',
      'title': 'Title',
      'account': 'Account',
      'comment': 'Comment',
      'createdAt': 'Created At',
      'updatedAt': 'Updated At',
      'close': 'Close',
      'search': 'Search',
      'noPasswordsFound': 'No passwords found.',
      'passwordManager': 'Password Manager',
      'database': 'Database',
      's3Config': 'S3 Config',
      'offlineMode': 'Offline Mode',
      'endpoint': 'Endpoint',
      'accessKeyID': 'Access Key ID',
      'secretAccessKey': 'Secret Access Key',
      'bucketName': 'Bucket Name',
      'directoryPath': 'Directory Path',
      'saveConfig': 'Save Config',
      'confirmExit': 'Confirm Exit',
      'areYouSureExit': 'Are you sure you want to exit the application?',
      'yes': 'Yes',
      'no': 'No',
      'databaseCreated': 'Database created successfully',
      'databaseNotExist': 'Database does not exist',
      'enterUsernamePassword': 'Please enter username and password',
      'databaseCreationFailed': 'Database creation failed',
      'error': 'Error',
      'incorrectUsernamePassword': 'Incorrect username or password, please try again.',
      'confirm': 'Confirm',
      'exitConfirmation': 'Exit Confirmation',
      'uploadingDatabase': 'Uploading database to S3...',
      'uploadFailed': 'Failed to upload database to S3:',
      'passwordCopied': 'Password copied!',
    },
    'zh': {
      'login': '登录',
      'username': '用户名',
      'password': '密码',
      'createDatabase': '创建数据库',
      'databaseExists': '数据库已经存在',
      'resetPassword': '重置密码',
      'confirmDelete': '确认删除',
      'areYouSureDelete': '确定要删除此密码吗？',
      'cancel': '取消',
      'delete': '删除',
      'add': '添加',
      'update': '更新',
      'title': '标题',
      'account': '账户',
      'comment': '备注',
      'createdAt': '创建时间',
      'updatedAt': '更新时间',
      'close': '关闭',
      'search': '搜索',
      'noPasswordsFound': '未找到密码。',
      'passwordManager': '密码管理器',
      'database': '数据库',
      's3Config': 'S3 配置',
      'offlineMode': '离线模式',
      'endpoint': '端点',
      'accessKeyID': '访问密钥 ID',
      'secretAccessKey': '秘密访问密钥',
      'bucketName': '存储桶名称',
      'directoryPath': '目录路径',
      'saveConfig': '保存配置',
      'confirmExit': '确认退出',
      'areYouSureExit': '确定要退出应用吗？',
      'yes': '确定',
      'no': '取消',
      'databaseCreated': '数据库创建成功',
      'databaseNotExist': '数据库不存在',
      'enterUsernamePassword': '请输入用户名和密码',
      'databaseCreationFailed': '数据库创建失败',
      'error': '错误',
      'incorrectUsernamePassword': '输入的用户名或密码有误，请重试。',
      'confirm': '确定',
      'exitConfirmation': '退出确认',
      'uploadingDatabase': '正在上传数据库到 S3...',
      'uploadFailed': '上传数据库到 S3 失败:',
      'passwordCopied': '密码已复制',
    },
  };

  String? get login => _localizedValues[locale.languageCode]?['login'];
  String? get username => _localizedValues[locale.languageCode]?['username'];
  String? get password => _localizedValues[locale.languageCode]?['password'];
  String? get createDatabase => _localizedValues[locale.languageCode]?['createDatabase'];
  String? get resetPassword => _localizedValues[locale.languageCode]?['resetPassword'];
  String? get confirmDelete => _localizedValues[locale.languageCode]?['confirmDelete'];
  String? get areYouSureDelete => _localizedValues[locale.languageCode]?['areYouSureDelete'];
  String? get cancel => _localizedValues[locale.languageCode]?['cancel'];
  String? get delete => _localizedValues[locale.languageCode]?['delete'];
  String? get add => _localizedValues[locale.languageCode]?['add'];
  String? get update => _localizedValues[locale.languageCode]?['update'];
  String? get title => _localizedValues[locale.languageCode]?['title'];
  String? get account => _localizedValues[locale.languageCode]?['account'];
  String? get comment => _localizedValues[locale.languageCode]?['comment'];
  String? get createdAt => _localizedValues[locale.languageCode]?['createdAt'];
  String? get updatedAt => _localizedValues[locale.languageCode]?['updatedAt'];
  String? get close => _localizedValues[locale.languageCode]?['close'];
  String? get search => _localizedValues[locale.languageCode]?['search'];
  String? get noPasswordsFound => _localizedValues[locale.languageCode]?['noPasswordsFound'];
  String? get passwordManager => _localizedValues[locale.languageCode]?['passwordManager'];
  String? get database => _localizedValues[locale.languageCode]?['database'];
  String? get s3Config => _localizedValues[locale.languageCode]?['s3Config'];
  String? get offlineMode => _localizedValues[locale.languageCode]?['offlineMode'];
  String? get endpoint => _localizedValues[locale.languageCode]?['endpoint'];
  String? get accessKeyID => _localizedValues[locale.languageCode]?['accessKeyID'];
  String? get secretAccessKey => _localizedValues[locale.languageCode]?['secretAccessKey'];
  String? get bucketName => _localizedValues[locale.languageCode]?['bucketName'];
  String? get directoryPath => _localizedValues[locale.languageCode]?['directoryPath'];
  String? get saveConfig => _localizedValues[locale.languageCode]?['saveConfig'];
  String? get confirmExit => _localizedValues[locale.languageCode]?['confirmExit'];
  String? get areYouSureExit => _localizedValues[locale.languageCode]?['areYouSureExit'];
  String? get yes => _localizedValues[locale.languageCode]?['yes'];
  String? get no => _localizedValues[locale.languageCode]?['no'];
  String? get databaseCreated => _localizedValues[locale.languageCode]?['databaseCreated'];
  String? get databaseExists => _localizedValues[locale.languageCode]?['databaseExists'];
  String? get databaseNotExist => _localizedValues[locale.languageCode]?['databaseNotExist'];
  String? get enterUsernamePassword => _localizedValues[locale.languageCode]?['enterUsernamePassword'];
  String? get databaseCreationFailed => _localizedValues[locale.languageCode]?['databaseCreationFailed'];
  String? get error => _localizedValues[locale.languageCode]?['error'];
  String? get incorrectUsernamePassword => _localizedValues[locale.languageCode]?['incorrectUsernamePassword'];
  String? get confirm => _localizedValues[locale.languageCode]?['confirm'];
  String? get uploadingDatabase => _localizedValues[locale.languageCode]?['uploadingDatabase'];
  String? get uploadFailed => _localizedValues[locale.languageCode]?['uploadFailed'];
  String? get exitConfirmation => _localizedValues[locale.languageCode]?['exitConfirmation'];
  String? get passwordCopied => _localizedValues[locale.languageCode]?['passwordCopied'];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
