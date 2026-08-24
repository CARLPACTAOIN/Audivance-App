import 'package:flutter/material.dart';

import 'brand_logo.dart';
import 'local_unlock_service.dart';
import 'ui/app_ui.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.unlockService,
    required this.onUnlocked,
  });

  final LocalUnlockService unlockService;
  final Future<void> Function() onUnlocked;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  var _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(key: Key('unlockBrandLogo'), size: 84),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock workspace',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the local PIN for this workspace.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_errorText != null) ...[
                          InlineStatusPanel(
                            title: 'Unlock failed',
                            message: _errorText!,
                            tone: InlineStatusTone.error,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          key: const Key('unlockPinField'),
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            helperText: 'Your PIN is verified on this device.',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('unlockSubmitButton'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_outlined),
                          label: const Text('Unlock'),
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
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.unlockService.unlock(_pinController.text);
    if (!mounted) {
      return;
    }

    if (!result.isUnlocked) {
      setState(() {
        _isSubmitting = false;
        _errorText = result.message;
      });
      return;
    }

    try {
      await widget.onUnlocked();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = error.toString();
      });
    }
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}
