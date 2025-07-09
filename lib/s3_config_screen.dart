// lib/s3_config_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart'; // Import AppLocalizations

class S3ConfigScreen extends StatefulWidget {
  const S3ConfigScreen({super.key});

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.saveConfig ?? '配置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.s3Config ?? 'S3 配置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(localizations.offlineMode ?? '离线模式'),
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
                  decoration: InputDecoration(
                      labelText: localizations.endpoint ?? 'Endpoint'),
                  onSaved: (value) => _endpoint = value ?? '',
                ),
                TextFormField(
                  initialValue: _accessKeyID,
                  decoration: InputDecoration(
                      labelText: localizations.accessKeyID ?? 'Access Key ID'),
                  onSaved: (value) => _accessKeyID = value ?? '',
                ),
                TextFormField(
                  initialValue: _secretAccessKey,
                  decoration: InputDecoration(
                      labelText:
                          localizations.secretAccessKey ?? 'Secret Access Key'),
                  onSaved: (value) => _secretAccessKey = value ?? '',
                ),
                TextFormField(
                  initialValue: _bucketName,
                  decoration: InputDecoration(
                      labelText: localizations.bucketName ?? 'Bucket Name'),
                  onSaved: (value) => _bucketName = value ?? '',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: _dirpath,
                  decoration: InputDecoration(
                      labelText:
                          localizations.directoryPath ?? 'Directory Path'),
                  onSaved: (value) => _dirpath = value ?? '',
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _saveConfig();
                  }
                },
                child: Text(localizations.saveConfig ?? '保存配置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
