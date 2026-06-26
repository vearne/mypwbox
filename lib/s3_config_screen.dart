// lib/s3_config_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart'; // Import AppLocalizations
import 'theme/app_theme.dart';

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

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFA5B4FC),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: GradientAppBar(title: Text(localizations.s3Config ?? 'S3 配置')),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Group 1: Mode ---
                  _buildSectionHeader('Mode'),
                  GlassCard(
                    child: SwitchListTile(
                      title: Text(localizations.offlineMode ?? '离线模式'),
                      subtitle: Text(
                        _offline
                            ? 'Cloud sync is disabled'
                            : 'Cloud sync is enabled',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      value: _offline,
                      onChanged: (value) {
                        setState(() {
                          _offline = value;
                        });
                      },
                    ),
                  ),
                  // --- Group 2 & 3: Only show when online ---
                  if (!_offline) ...[
                    // --- Group 2: Connection ---
                    _buildSectionHeader('Connection'),
                    GlassCard(
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _endpoint,
                            decoration: InputDecoration(
                                labelText:
                                    localizations.endpoint ?? 'Endpoint'),
                            onSaved: (value) => _endpoint = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _accessKeyID,
                            decoration: InputDecoration(
                                labelText: localizations.accessKeyID ??
                                    'Access Key ID'),
                            onSaved: (value) => _accessKeyID = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _secretAccessKey,
                            decoration: InputDecoration(
                                labelText: localizations.secretAccessKey ??
                                    'Secret Access Key'),
                            onSaved: (value) => _secretAccessKey = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _bucketName,
                            decoration: InputDecoration(
                                labelText:
                                    localizations.bucketName ?? 'Bucket Name'),
                            onSaved: (value) => _bucketName = value ?? '',
                          ),
                        ],
                      ),
                    ),
                    // --- Group 3: Storage Path ---
                    _buildSectionHeader('Storage Path'),
                    GlassCard(
                      child: TextFormField(
                        initialValue: _dirpath,
                        decoration: InputDecoration(
                            labelText: localizations.directoryPath ??
                                'Directory Path'),
                        onSaved: (value) => _dirpath = value ?? '',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GradientButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _saveConfig();
                        }
                      },
                      child: Text(localizations.saveConfig ?? '保存配置'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
