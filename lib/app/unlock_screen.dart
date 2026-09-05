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
      body: AudivanceBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(key: Key('unlockBrandLogo'), size: 80),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Unlock workspace',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Enter the local PIN for this workspace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_errorText != null) ...[
                          InlineStatusPanel(
                            title: 'Unlock failed',
                            message: _errorText!,
                            tone: InlineStatusTone.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextFormField(
                          key: const Key('unlockPinField'),
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PIN',
                            helperText: 'Your PIN is verified on this device.',
                          ),
                          validator: _pinValidator,
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
    FocusScope.of(context).unfocus();
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

String? _pinValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  if (!RegExp(r'^\d{6}$').hasMatch(value)) {
    return 'PIN must be exactly 6 digits.';
  }
  return null;
}
