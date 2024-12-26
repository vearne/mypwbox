import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      routes: {
        '/login': (context) => LoginScreen(),
        // '/passwordList': (context) => PasswordListScreen(
        //   username: 'defaultUsername', // 这里需要动态传入
        //   secureHash: 'defaultSecureHash', // 这里需要动态传入
        // ),
      },
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // 启动时显示登录界面
    );
  }
}
