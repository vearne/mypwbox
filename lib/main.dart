import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';
import 's3_config_screen.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mypwbox/l10n/app_localizations.dart';

void main() async {
  // 确保 Flutter 框架初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 配置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    title: 'mypwbox',
    // size: Size(800, 600),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  windowManager.setPreventClose(true); // 阻止窗口直接关闭

  // 读取本地配置
  final prefs = await SharedPreferences.getInstance();
  final offline = prefs.getBool('offline') ?? true;

  // 如果用户不处于离线模式，连接 S3 并下载文件
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
      useSSL: true,
    );

    try {
      await for (var result
          in minio.listObjects(bucketName, prefix: dirpath, recursive: true)) {
        for (var object in result.objects) {
          if (object.key != null) {
            final localPath = await _getLocalFilePath(object.key!);
            final localModificationTime =
                await _getLocalFileModificationTime(localPath);
            final s3ModificationTime =
                object.lastModified; // Assume this is available

            // Debugging output
            debugPrint('Local Modification Time: $localModificationTime');
            debugPrint('S3 Modification Time: $s3ModificationTime');

            if (localModificationTime == null ||
                (s3ModificationTime != null &&
                    s3ModificationTime.isAfter(localModificationTime))) {
              await minio
                  .getObject(bucketName, object.key!)
                  .then((byteStream) async {
                final file = File(localPath);
                await file.create(recursive: true);
                await byteStream.pipe(file.openWrite());
              });
              debugPrint('Downloaded: ${object.key} to $localPath');
            } else {
              debugPrint('Skipped: ${object.key} (local file is up to date)');
            }
          } else {
            debugPrint('Skipping file with null key');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to download files from S3: $e');
    }
  }

  // 启动应用
  runApp(const MyApp());
}

// 应用主界面
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
      // 默认显示登录界面
      routes: {
        '/login': (context) => const LoginScreen(), // 登录界面
        '/s3config': (context) => const S3ConfigScreen(), // S3 配置界面
      },
    );
  }
}

// 获取本地文件路径
Future<String> _getLocalFilePath(String key) async {
  final directory = await getApplicationDocumentsDirectory(); // 获取应用文档目录
  return '${directory.path}/${key.split('/').last}'; // 返回本地文件路径
}

Future<DateTime?> _getLocalFileModificationTime(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    return await file.lastModified();
  }
  return null;
}
