import 'package:flutter/material.dart';
import 'password.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

class PasswordDialog extends StatefulWidget {
  final Password? passwordToUpdate;
  final Function(Password) onSave;

  const PasswordDialog({
    super.key,
    this.passwordToUpdate,
    required this.onSave,
  });

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _accountController;
  late TextEditingController _passwordController;
  late TextEditingController _commentController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.passwordToUpdate?.title);
    _accountController =
        TextEditingController(text: widget.passwordToUpdate?.account);
    _passwordController = TextEditingController(
        text: widget.passwordToUpdate?.password ?? '');
    _commentController =
        TextEditingController(text: widget.passwordToUpdate?.comment);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final titleText = widget.passwordToUpdate == null
        ? localizations!.add!
        : localizations!.update!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.passwordToUpdate == null
                ? Icons.add_circle
                : Icons.edit,
            color: const Color(0xFF818CF8),
          ),
          const SizedBox(width: 8),
          Text(titleText),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: localizations.title),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.titleRequired ?? 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(labelText: localizations.account),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.accountRequired ??
                        'Account is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
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
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.passwordRequired ??
                        'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(labelText: localizations.comment),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel!),
        ),
        GradientButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newPassword = Password(
                title: _titleController.text.trim(),
                account: _accountController.text.trim(),
                password: _passwordController.text,
                comment: _commentController.text,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSave(newPassword);
              Navigator.pop(context);
            }
          },
          expanded: false,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
