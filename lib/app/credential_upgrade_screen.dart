import 'package:flutter/material.dart';

import 'brand_logo.dart';
import 'ui/app_ui.dart';

typedef CredentialUpgradeSubmit = Future<String?> Function(String pin);

class CredentialUpgradeScreen extends StatefulWidget {
  const CredentialUpgradeScreen({
    super.key,
    required this.onSubmitCredential,
    required this.onConfigured,
  });

  final CredentialUpgradeSubmit onSubmitCredential;
  final VoidCallback onConfigured;

  @override
  State<CredentialUpgradeScreen> createState() =>
      _CredentialUpgradeScreenState();
}

class _CredentialUpgradeScreenState extends State<CredentialUpgradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _pinConfirmationController = TextEditingController();
  var _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    _pinConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(
                          key: Key('credentialUpgradeBrandLogo'),
                          size: 84,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Secure workspace',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a local PIN for this existing workspace.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_errorText != null) ...[
                          InlineStatusPanel(
                            title: 'Workspace could not be secured',
                            message: _errorText!,
                            tone: InlineStatusTone.error,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          key: const Key('credentialUpgradePinField'),
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'New PIN',
                            helperText: 'Use at least 6 digits.',
                          ),
                          validator: _pinValidator,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key(
                            'credentialUpgradePinConfirmationField',
                          ),
                          controller: _pinConfirmationController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Confirm PIN',
                          ),
                          validator: _pinConfirmationValidator,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('credentialUpgradeSubmitButton'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.security_outlined),
                          label: const Text('Secure Workspace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorText = 'Fix the highlighted fields before securing workspace.';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    final errorText = await widget.onSubmitCredential(_pinController.text);
    if (errorText != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = errorText;
      });
      return;
    }

    if (mounted) {
      widget.onConfigured();
    }
  }

  String? _pinValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }
    if (!RegExp(r'^\d+$').hasMatch(value!)) {
      return 'PIN must use digits only.';
    }
    if (value.length < 6) {
      return 'PIN must be at least 6 digits.';
    }
    return null;
  }

  String? _pinConfirmationValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }
    if (value != _pinController.text) {
      return 'PIN confirmation must match.';
    }
    return null;
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}
