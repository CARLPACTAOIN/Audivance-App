import 'package:flutter/material.dart';

import '../../app/brand_logo.dart';
import '../../app/ui/app_ui.dart';
import '../../core/domain/stable_id_generator.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';

typedef SetupWorkspaceSubmit = Future<ValidationResult> Function(
  SetupWorkspaceDraft draft,
);

class SetupWorkspaceDraft {
  const SetupWorkspaceDraft({
    required this.pin,
    required this.account,
    required this.organization,
  });

  final String pin;
  final LocalAccountProfile account;
  final OrganizationProfile organization;
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.idGenerator,
    required this.onSubmitWorkspace,
    required this.onSetupComplete,
    this.now,
  });

  final StableIdGenerator idGenerator;
  final SetupWorkspaceSubmit onSubmitWorkspace;
  final VoidCallback onSetupComplete;
  final DateTime Function()? now;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailOrStudentIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmationController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _organizationTypeController = TextEditingController(text: 'Academic');
  final _adviserController = TextEditingController();
  final _semesterController = TextEditingController(text: '1st Semester');
  final _schoolYearController = TextEditingController(text: '2026-2027');
  final _signatoryNamesController = TextEditingController();
  var _isSubmitting = false;
  String? _submitError;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailOrStudentIdController.dispose();
    _pinController.dispose();
    _pinConfirmationController.dispose();
    _organizationNameController.dispose();
    _organizationTypeController.dispose();
    _adviserController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _signatoryNamesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth >= 800 ? 32 : 16,
                24,
                constraints.maxWidth >= 800 ? 32 : 16,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: BrandLogo(
                            key: Key('setupBrandLogo'),
                            size: 88,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Set up Audivance',
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create the local account and organization workspace for this device.',
                        ),
                        const SizedBox(height: 24),
                        if (_submitError != null) ...[
                          InlineStatusPanel(
                            title: 'Workspace could not be created',
                            message: _submitError!,
                            tone: InlineStatusTone.error,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SetupSection(
                          title: 'Local Account',
                          icon: Icons.person_outline,
                          children: [
                            _LabeledTextField(
                              key: const Key('setupDisplayNameField'),
                              controller: _displayNameController,
                              label: 'Account name',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupEmailOrStudentIdField'),
                              controller: _emailOrStudentIdController,
                              label: 'Email or student ID',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupPinField'),
                              controller: _pinController,
                              label: 'PIN',
                              helperText: 'Use at least 6 digits.',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              validator: _pinValidator,
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupPinConfirmationField'),
                              controller: _pinConfirmationController,
                              label: 'Confirm PIN',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              validator: _pinConfirmationValidator,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SetupSection(
                          title: 'Organization Profile',
                          icon: Icons.apartment_outlined,
                          children: [
                            _LabeledTextField(
                              key: const Key('setupOrganizationNameField'),
                              controller: _organizationNameController,
                              label: 'Organization name',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupOrganizationTypeField'),
                              controller: _organizationTypeController,
                              label: 'Organization type',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupAdviserField'),
                              controller: _adviserController,
                              label: 'Adviser',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupSemesterField'),
                              controller: _semesterController,
                              label: 'Semester',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupSchoolYearField'),
                              controller: _schoolYearController,
                              label: 'School year',
                              textInputAction: TextInputAction.next,
                            ),
                            _LabeledTextField(
                              key: const Key('setupSignatoryNamesField'),
                              controller: _signatoryNamesController,
                              label: 'Signatory names',
                              helperText:
                                  'Separate multiple names with commas.',
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const Key('setupSubmitButton'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Create Local Workspace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _submitError =
            'Fix the highlighted fields before creating the workspace.';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    final account = LocalAccountProfile(
      id: widget.idGenerator.nextId('account'),
      displayName: _displayNameController.text.trim(),
      emailOrStudentId: _emailOrStudentIdController.text.trim(),
      createdAt: _now,
      isCredentialConfigured: true,
    );
    final organization = OrganizationProfile(
      id: widget.idGenerator.nextId('organization'),
      name: _organizationNameController.text.trim(),
      type: _organizationTypeController.text.trim(),
      adviser: _adviserController.text.trim(),
      semester: _semesterController.text.trim(),
      schoolYear: _schoolYearController.text.trim(),
      signatoryNames: _parseSignatoryNames(_signatoryNamesController.text),
    );

    final result = await widget.onSubmitWorkspace(
      SetupWorkspaceDraft(
        pin: _pinController.text,
        account: account,
        organization: organization,
      ),
    );
    if (result.isInvalid) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _submitError = result.summary;
      });
      return;
    }

    if (mounted) {
      widget.onSetupComplete();
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

class _SetupSection extends StatelessWidget {
  const _SetupSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            for (final child in children) ...[
              child,
              if (child != children.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: label, helperText: helperText),
      validator: validator ?? _requiredValidator,
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

List<String> _parseSignatoryNames(String value) {
  return value
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}
