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
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _emailOrStudentIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmationController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _organizationTypeController = TextEditingController(text: 'Academic');
  final _adviserController = TextEditingController();
  final _semesterController = TextEditingController(text: '1st Semester');
  final _schoolYearController = TextEditingController(text: '2026-2027');

  var _isSubmitting = false;
  String? _submitError;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _emailOrStudentIdController.dispose();
    _pinController.dispose();
    _pinConfirmationController.dispose();
    _organizationNameController.dispose();
    _organizationTypeController.dispose();
    _adviserController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitError = null;
    });
    _pageController.animateToPage(
      step,
      duration: AppMotion.durationStandard,
      curve: AppMotion.curveInOut,
    );
  }

  void _onStep1Next() {
    FocusScope.of(context).unfocus();
    setState(() => _submitError = null);
    if (!_step1FormKey.currentState!.validate()) {
      return;
    }
    _goToStep(2);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitError = null);
    final isStep1Valid = _step1FormKey.currentState?.validate() ?? true;
    final isStep2Valid = _step2FormKey.currentState?.validate() ?? true;

    if (!isStep1Valid) {
      _goToStep(1);
      return;
    }
    if (!isStep2Valid) {
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
    if (value.length != 6) {
      return 'PIN must be exactly 6 digits.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AudivanceBackground(
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WelcomeScreen(onGetStarted: () => _goToStep(1)),
              _Step1AccountScreen(
                formKey: _step1FormKey,
                displayNameController: _displayNameController,
                emailOrStudentIdController: _emailOrStudentIdController,
                pinController: _pinController,
                pinConfirmationController: _pinConfirmationController,
                pinValidator: _pinValidator,
                pinConfirmationValidator: _pinConfirmationValidator,
                onBack: () => _goToStep(0),
                onNext: _onStep1Next,
              ),
              _Step2OrganizationScreen(
                formKey: _step2FormKey,
                organizationNameController: _organizationNameController,
                organizationTypeController: _organizationTypeController,
                adviserController: _adviserController,
                semesterController: _semesterController,
                schoolYearController: _schoolYearController,
                isSubmitting: _isSubmitting,
                submitError: _submitError,
                onBack: () => _goToStep(1),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 0: WELCOME SPLASH
// ---------------------------------------------------------------------------
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Upper / Hero Area: Centered Circular Brand Logo & Typography
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 114,
                              height: 114,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF141A23),
                                border: Border.all(
                                  color: const Color(0xFFD97706)
                                      .withValues(alpha: 0.38),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD97706)
                                        .withValues(alpha: 0.16),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const BrandLogo(
                                key: Key('setupBrandLogo'),
                                size: 68,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Audivance',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF8FAFC),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your offline audit workspace.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        // CTA Section
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                key: const Key('setupGetStartedButton'),
                                onPressed: onGetStarted,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: const Color(0xFF0F172A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Local-only • No internet required',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 1: STEP 1 OF 2 — LOCAL ACCOUNT & PIN
// ---------------------------------------------------------------------------
class _Step1AccountScreen extends StatelessWidget {
  const _Step1AccountScreen({
    required this.formKey,
    required this.displayNameController,
    required this.emailOrStudentIdController,
    required this.pinController,
    required this.pinConfirmationController,
    required this.pinValidator,
    required this.pinConfirmationValidator,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailOrStudentIdController;
  final TextEditingController pinController;
  final TextEditingController pinConfirmationController;
  final FormFieldValidator<String> pinValidator;
  final FormFieldValidator<String> pinConfirmationValidator;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                const _StepHeader(
                  currentStep: 1,
                  totalSteps: 2,
                  title: 'Local Account',
                  subtitle: 'Set up your local auditor identity and 6-digit access PIN.',
                ),
                const SizedBox(height: 24),

                // Form Container
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.12),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: const Icon(
                              Icons.lock_person_outlined,
                              color: AppColors.brandLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Account & Security Details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LabeledTextField(
                        key: const Key('setupDisplayNameField'),
                        controller: displayNameController,
                        label: 'Account name',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupEmailOrStudentIdField'),
                        controller: emailOrStudentIdController,
                        label: 'Email or student ID',
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupPinField'),
                        controller: pinController,
                        label: 'PIN',
                        helperText: 'Use exactly 6 digits.',
                        prefixIcon: Icons.password_outlined,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        validator: pinValidator,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupPinConfirmationField'),
                        controller: pinConfirmationController,
                        label: 'Confirm PIN',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        validator: pinConfirmationValidator,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('setupContinueToOrgButton'),
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'Continue to Organization',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: STEP 2 OF 2 — ORGANIZATION PROFILE
// ---------------------------------------------------------------------------
class _Step2OrganizationScreen extends StatelessWidget {
  const _Step2OrganizationScreen({
    required this.formKey,
    required this.organizationNameController,
    required this.organizationTypeController,
    required this.adviserController,
    required this.semesterController,
    required this.schoolYearController,
    required this.isSubmitting,
    required this.submitError,
    required this.onBack,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController organizationNameController;
  final TextEditingController organizationTypeController;
  final TextEditingController adviserController;
  final TextEditingController semesterController;
  final TextEditingController schoolYearController;
  final bool isSubmitting;
  final String? submitError;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                const _StepHeader(
                  currentStep: 2,
                  totalSteps: 2,
                  title: 'Organization Profile',
                  subtitle: 'Enter institutional details, adviser, and academic period.',
                ),
                const SizedBox(height: 20),

                if (submitError != null) ...[
                  InlineStatusPanel(
                    title: 'Workspace could not be created',
                    message: submitError!,
                    tone: InlineStatusTone.error,
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Container 1: Organization Information
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: const Icon(
                              Icons.corporate_fare_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Organization Information',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LabeledTextField(
                        key: const Key('setupOrganizationNameField'),
                        controller: organizationNameController,
                        label: 'Organization name',
                        prefixIcon: Icons.domain_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupOrganizationTypeField'),
                        controller: organizationTypeController,
                        label: 'Organization type',
                        prefixIcon: Icons.category_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupAdviserField'),
                        controller: adviserController,
                        label: 'Adviser',
                        prefixIcon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupSemesterField'),
                        controller: semesterController,
                        label: 'Semester',
                        prefixIcon: Icons.calendar_month_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        key: const Key('setupSchoolYearField'),
                        controller: schoolYearController,
                        label: 'School year',
                        prefixIcon: Icons.date_range_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Navigation Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('setupSubmitButton'),
                        onPressed: isSubmitting ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMd,
                          ),
                        ),
                        icon: isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          'Create Local Workspace',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'All data is encrypted and stays strictly on this device.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE STEP HEADER & PROGRESS BAR
// ---------------------------------------------------------------------------
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = currentStep / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  color: AppColors.brandLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _LabeledTextField extends StatefulWidget {
  const _LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  State<_LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<_LabeledTextField> {
  final _focusNode = FocusNode();
  String? _displayedError;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _LabeledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _displayedError != null) {
      _clearError();
    }
  }

  void _onTextChange() {
    if (_displayedError != null) {
      _clearError();
    }
  }

  void _clearError() {
    if (_displayedError != null) {
      setState(() {
        _displayedError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (_) {
        final error = (widget.validator ?? _requiredValidator)(
          widget.controller.text,
        );
        if (_displayedError != error) {
          _displayedError = error;
        }
        return error;
      },
      builder: (fieldState) {
        return TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onTap: _clearError,
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: const Color(0xFF64748B),
                  )
                : null,
            errorText: _displayedError,
          ),
        );
      },
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}
