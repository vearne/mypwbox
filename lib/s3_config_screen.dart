// lib/s3_config_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class S3ConfigScreen extends StatefulWidget {
  @override
  _S3ConfigScreenState createState() => _S3ConfigScreenState();
}

class _S3ConfigScreenState extends State<S3ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _offline = true;
  String _endpoint = '';
  String _accessKeyID = '';
  String _secretAccessKey = '';
  String _bucketName = '';
  String _dirpath = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _offline = prefs.getBool('offline') ?? true;
      _endpoint = prefs.getString('endpoint') ?? '';
      _accessKeyID = prefs.getString('accessKeyID') ?? '';
      _secretAccessKey = prefs.getString('secretAccessKey') ?? '';
      _bucketName = prefs.getString('bucketName') ?? '';
      _dirpath = prefs.getString('dirpath') ?? '';
    });
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline', _offline);
    await prefs.setString('endpoint', _endpoint);
    await prefs.setString('accessKeyID', _accessKeyID);
    await prefs.setString('secretAccessKey', _secretAccessKey);
    await prefs.setString('bucketName', _bucketName);
    await prefs.setString('dirpath', _dirpath);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('配置已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('S3 配置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: Text('离线模式'),
                value: _offline,
                onChanged: (value) {
                  setState(() {
                    _offline = value;
                  });
                },
              ),
              if (!_offline) ...[
                TextFormField(
                  initialValue: _endpoint,
                  decoration: InputDecoration(labelText: 'Endpoint'),
                  onSaved: (value) => _endpoint = value ?? '',
                ),
                TextFormField(
                  initialValue: _accessKeyID,
                  decoration: InputDecoration(labelText: 'Access Key ID'),
                  onSaved: (value) => _accessKeyID = value ?? '',
                ),
                TextFormField(
                  initialValue: _secretAccessKey,
                  decoration: InputDecoration(labelText: 'Secret Access Key'),
                  onSaved: (value) => _secretAccessKey = value ?? '',
                ),
                TextFormField(
                  initialValue: _bucketName,
                  decoration: InputDecoration(labelText: 'bucket name'),
                  onSaved: (value) => _bucketName = value ?? '',
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: _dirpath,
                  decoration: InputDecoration(labelText: '目录路径'),
                  onSaved: (value) => _dirpath = value ?? '',
                ),
                SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _saveConfig();
                  }
                },
                child: Text('保存配置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
