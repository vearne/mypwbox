import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart'; // Import AppLocalizations

class PasswordDialog extends StatefulWidget {
  final BuildContext context;
  final Map<String, dynamic>? passwordToUpdate;
  final Function(Map<String, dynamic>) onSave;

  const PasswordDialog({super.key, 
    required this.context,
    this.passwordToUpdate,
    required this.onSave,
  });

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  late TextEditingController _titleController;
  late TextEditingController _accountController;
  late TextEditingController _passwordController;
  late TextEditingController _commentController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.passwordToUpdate?['title']);
    _accountController =
        TextEditingController(text: widget.passwordToUpdate?['account']);
    _passwordController = TextEditingController(
        text: widget.passwordToUpdate != null
            ? widget.passwordToUpdate!["password"]
            : '');
    _commentController =
        TextEditingController(text: widget.passwordToUpdate?['comment']);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context); // Get localized strings

    return AlertDialog(
      title: Text(widget.passwordToUpdate == null
          ? localizations!.add!
          : localizations!.update!),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: localizations.title),
            ),
            TextField(
              controller: _accountController,
              decoration: InputDecoration(labelText: localizations.account),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: localizations.password,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Toggle visibility
                    });
                  },
                ),
              ),
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: localizations.comment),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel!),
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

            widget.onSave(newPassword);
            Navigator.pop(context);
          },
          child: Text(widget.passwordToUpdate == null
              ? localizations.add!
              : localizations.update!),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
