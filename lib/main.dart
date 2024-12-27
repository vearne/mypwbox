import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';
import 's3_config_screen.dart';
import 'dart:io'; // 导入 dart:io，使用 File 类

void main() async {
  // 确保 Flutter 框架初始化完成
  WidgetsFlutterBinding.ensureInitialized();

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

    // 初始化 Minio 客户端
    final minio = Minio(
      endPoint: endpoint,
      accessKey: accessKeyID,
      secretKey: secretAccessKey,
      useSSL: true, // 如果使用 HTTPS，设置为 true
    );

    try {
      // 列出指定路径下的所有文件
      await for (var result in minio.listObjects(bucketName, prefix: dirpath)) {
        for (var object in result.objects) {
          // 下载文件到本地
          if (object.key != null) { // 检查 object.key 是否为空
            final localPath = await _getLocalFilePath(object.key!); // 使用空断言操作符
            await minio.getObject(bucketName, object.key!).then((
                byteStream) async {
              final file = File(localPath); // 创建本地文件
              await file.create(recursive: true); // 递归创建目录
              await byteStream.pipe(file.openWrite()); // 将文件内容写入本地文件
            });
            debugPrint('Downloaded: ${object.key} to $localPath');
          } else {
            debugPrint('Skipping file with null key'); // 如果 object.key 为空，跳过该文件
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to download files from S3: $e'); // 捕获并打印错误
    }
  }

  // 启动应用
  runApp(MyApp());
}

// 应用主界面
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // 默认显示登录界面
      routes: {
        '/s3config': (context) => S3ConfigScreen(), // S3 配置界面
        '/login': (context) => LoginScreen(), // 登录界面
      },
    );
  }
}

// 获取本地文件路径
Future<String> _getLocalFilePath(String key) async {
  final directory = await getApplicationDocumentsDirectory(); // 获取应用文档目录
  return '${directory.path}/${key
      .split('/')
      .last}'; // 返回本地文件路径
}
