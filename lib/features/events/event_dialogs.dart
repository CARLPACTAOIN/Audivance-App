import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_selector.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../audit/domain/audit_models.dart';
import '../liquidation/liquidation_service.dart';
import '../organization/organization_service.dart';
import '../treasury/treasury_formatters.dart';
import '../treasury/treasury_service.dart';
import 'event_service.dart';

class CreateEventDialog extends StatefulWidget {
  const CreateEventDialog({
    super.key,
    required this.service,
    required this.sourceOptions,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final EventService service;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'Project';
  final _semesterController = TextEditingController(text: '1st Semester');
  final _schoolYearController = TextEditingController(text: '2026-2027');
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _permitDateController = TextEditingController();
  final _resolutionNumberController = TextEditingController();
  final List<_AllocationInput> _allocations = [];
  AttachmentRef? _resolutionAttachment;
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final input = _AllocationInput(
      sourceId: widget.sourceOptions.isEmpty
          ? null
          : widget.sourceOptions.first.id,
    );
    input.amountController.addListener(_refreshRemaining);
    _allocations.add(input);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _permitDateController.dispose();
    _resolutionNumberController.dispose();
    for (final allocation in _allocations) {
      allocation.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Create Event',
      maxWidth: 660,
      status: _formError == null && _serviceError == null
          ? null
          : InlineStatusPanel(
              title: _serviceError == null
                  ? 'Review required fields'
                  : 'Event could not be saved',
              message:
                  _serviceError ??
                  'Fix the highlighted fields before saving this event.',
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('eventCreateSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Event'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('eventNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('eventTypeField'),
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Event type'),
                items: const [
                  DropdownMenuItem(
                    key: Key('eventTypeOptionProject'),
                    value: 'Project',
                    child: Text('Project'),
                  ),
                  DropdownMenuItem(
                    key: Key('eventTypeOptionProgram'),
                    value: 'Program',
                    child: Text('Program'),
                  ),
                  DropdownMenuItem(
                    key: Key('eventTypeOptionActivity'),
                    value: 'Activity',
                    child: Text('Activity'),
                  ),
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'This field is required.'
                    : null,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventSemesterField'),
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventSchoolYearField'),
                controller: _schoolYearController,
                decoration: const InputDecoration(labelText: 'School year'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventStartDateField'),
                controller: _startDateController,
                labelText: 'Start date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventEndDateField'),
                controller: _endDateController,
                labelText: 'End date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventPermitDateField'),
                controller: _permitDateController,
                labelText: 'Permit approval date',
                helperText: 'Optional. Select date or enter YYYY-MM-DD.',
                validator: _optionalDateValidator,
                isRequired: false,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventResolutionNumberField'),
                controller: _resolutionNumberController,
                decoration: const InputDecoration(
                  labelText: 'Resolution number',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Resolution attachment',
                action: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              FormField<AttachmentRef>(
                key: const Key('eventResolutionAttachmentField'),
                validator: (_) => _resolutionAttachment == null
                    ? 'Select a resolution attachment.'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttachmentSelector(
                      owner: AttachmentOwner(
                        module: 'events',
                        purpose: 'resolution',
                        contextLabelProvider: () =>
                            _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : null,
                      ),
                      picker: widget.attachmentPicker,
                      storage: widget.attachmentStorage,
                      selectedAttachment: _resolutionAttachment,
                      selectButtonKey: const Key(
                        'eventResolutionAttachmentSelectButton',
                      ),
                      clearButtonKey: const Key(
                        'eventResolutionAttachmentClearButton',
                      ),
                      isEnabled: !_isSubmitting,
                      onChanged: (attachment) {
                        setState(() {
                          _resolutionAttachment = attachment;
                        });
                        field.didChange(attachment);
                      },
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: 6),
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Split funding / Budget sources',
                action: OutlinedButton.icon(
                  key: const Key('eventAddAllocationButton'),
                  onPressed: _addAllocation,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _allocations.length; index += 1)
                _AllocationRow(
                  key: ValueKey(_allocations[index]),
                  input: _allocations[index],
                  index: index,
                  sourceOptions: widget.sourceOptions,
                  canRemove: _allocations.length > 1,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeAllocation(index),
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Event Budget',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      formatPhpMoney(_totalBudget()),
                      key: const Key('eventDerivedTotalBudgetText'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addAllocation() {
    final input = _AllocationInput(
      sourceId: widget.sourceOptions.isEmpty
          ? null
          : widget.sourceOptions.first.id,
    );
    input.amountController.addListener(_refreshRemaining);
    setState(() {
      _allocations.add(input);
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      _allocations.removeAt(index).dispose();
    });
  }

  void _refreshRemaining() {
    if (mounted) {
      setState(() {});
    }
  }

  Money _totalBudget() {
    return _allocations.fold(
      Money.zero,
      (total, input) =>
          total + (parsePhpMoney(input.amountController.text) ?? Money.zero),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Fix the highlighted fields before saving this event.';
        _serviceError = null;
      });
      return;
    }
    final startDate = _parseDate(_startDateController.text)!;
    final endDate = _parseDate(_endDateController.text)!;
    if (endDate.isBefore(startDate)) {
      setState(() {
        _serviceError = 'Event end date cannot be before the start date.';
      });
      return;
    }

    final totalBudget = _totalBudget();
    if (!totalBudget.isPositive) {
      setState(() {
        _formError = 'Total budget must be greater than PHP 0.00.';
        _serviceError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _serviceError = null;
      _formError = null;
    });
    final result = await widget.service.createEvent(
      CreateEventCommand(
        name: _nameController.text,
        type: _selectedType,
        semester: _semesterController.text,
        schoolYear: _schoolYearController.text,
        startDate: startDate,
        endDate: endDate,
        permitApprovalDate: _parseDate(_permitDateController.text),
        resolutionNumber: _resolutionNumberController.text,
        budget: totalBudget,
        resolutionAttachment: _resolutionAttachment,
        allocations: _allocations
            .map(
              (input) => EventAllocationDraft(
                fundSourceId: input.sourceId!,
                amount: parsePhpMoney(input.amountController.text)!,
              ),
            )
            .toList(growable: false),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class EditEventDialog extends StatefulWidget {
  const EditEventDialog({
    super.key,
    required this.service,
    required this.event,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final EventService service;
  final EventCardView event;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  late final TextEditingController _semesterController;
  late final TextEditingController _schoolYearController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _permitDateController;
  late final TextEditingController _resolutionNumberController;
  AttachmentRef? _resolutionAttachment;

  String? _formError;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _nameController = TextEditingController(text: event.name);
    _selectedType = event.type;
    if (!const ['Project', 'Program', 'Activity'].contains(_selectedType)) {
      _selectedType = 'Activity';
    }
    _semesterController = TextEditingController(text: event.semester);
    _schoolYearController = TextEditingController(text: event.schoolYear);
    _startDateController = TextEditingController(
      text: _formatDateInput(event.startDate),
    );
    _endDateController = TextEditingController(
      text: _formatDateInput(event.endDate),
    );
    _permitDateController = TextEditingController(
      text: event.permitApprovalDate == null
          ? ''
          : _formatDateInput(event.permitApprovalDate!),
    );
    _resolutionNumberController = TextEditingController(
      text: event.resolutionNumber,
    );
    _resolutionAttachment = event.resolutionAttachment;
  }

  static String _formatDateInput(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _permitDateController.dispose();
    _resolutionNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Fix the highlighted fields before saving updates.';
        _serviceError = null;
      });
      return;
    }
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);
    if (startDate == null || endDate == null) {
      setState(() {
        _formError = 'Enter valid start and end dates.';
        _serviceError = null;
      });
      return;
    }
    if (endDate.isBefore(startDate)) {
      setState(() {
        _serviceError = 'Event end date cannot be before the start date.';
      });
      return;
    }
    if (_resolutionAttachment == null) {
      setState(() {
        _formError = 'Event resolution attachment is required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _serviceError = null;
      _formError = null;
    });

    final result = await widget.service.updateEvent(
      UpdateEventCommand(
        eventId: widget.event.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        semester: _semesterController.text.trim(),
        schoolYear: _schoolYearController.text.trim(),
        startDate: startDate,
        endDate: endDate,
        permitApprovalDate: _parseDate(_permitDateController.text),
        resolutionNumber: _resolutionNumberController.text.trim(),
        resolutionAttachment: _resolutionAttachment,
      ),
    );

    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Edit Event Details',
      maxWidth: 660,
      status: _formError == null && _serviceError == null
          ? null
          : InlineStatusPanel(
              title: _serviceError == null
                  ? 'Review required fields'
                  : 'Event could not be updated',
              message: _serviceError ?? _formError!,
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('eventEditSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Safeguards',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Approved Budget: ${widget.event.budgetLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Unutilized: ${widget.event.approvedBudgetBalanceLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Budget figures are protected by audit controls. To change allocations, use "Adjust Budget" on the event screen.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('eventEditNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: _requiredValidator,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('eventEditTypeField'),
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Event type'),
                items: const [
                  DropdownMenuItem(
                    key: Key('eventEditTypeOptionProject'),
                    value: 'Project',
                    child: Text('Project'),
                  ),
                  DropdownMenuItem(
                    key: Key('eventEditTypeOptionProgram'),
                    value: 'Program',
                    child: Text('Program'),
                  ),
                  DropdownMenuItem(
                    key: Key('eventEditTypeOptionActivity'),
                    value: 'Activity',
                    child: Text('Activity'),
                  ),
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'This field is required.'
                    : null,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventEditSemesterField'),
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                validator: _requiredValidator,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventEditSchoolYearField'),
                controller: _schoolYearController,
                decoration: const InputDecoration(labelText: 'School year'),
                validator: _requiredValidator,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventEditStartDateField'),
                controller: _startDateController,
                labelText: 'Start date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventEditEndDateField'),
                controller: _endDateController,
                labelText: 'End date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventEditPermitDateField'),
                controller: _permitDateController,
                labelText: 'Permit approval date',
                helperText: 'Optional. Select date or enter YYYY-MM-DD.',
                validator: _optionalDateValidator,
                isRequired: false,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventEditResolutionNumberField'),
                controller: _resolutionNumberController,
                decoration: const InputDecoration(
                  labelText: 'Resolution number',
                ),
                validator: _requiredValidator,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Resolution attachment',
                action: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              FormField<AttachmentRef>(
                key: const Key('eventEditResolutionAttachmentField'),
                validator: (_) => _resolutionAttachment == null
                    ? 'Select a resolution attachment.'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttachmentSelector(
                      owner: AttachmentOwner(
                        module: 'events',
                        purpose: 'resolution',
                        contextLabelProvider: () =>
                            _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : null,
                      ),
                      picker: widget.attachmentPicker,
                      storage: widget.attachmentStorage,
                      selectedAttachment: _resolutionAttachment,
                      selectButtonKey: const Key(
                        'eventEditResolutionAttachmentSelectButton',
                      ),
                      clearButtonKey: const Key(
                        'eventEditResolutionAttachmentClearButton',
                      ),
                      isEnabled: !_isSubmitting,
                      onChanged: (attachment) {
                        setState(() {
                          _resolutionAttachment = attachment;
                        });
                        field.didChange(attachment);
                      },
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: 6),
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdjustBudgetDialog extends StatefulWidget {
  const AdjustBudgetDialog({
    super.key,
    required this.service,
    required this.event,
    required this.sourceOptions,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final EventService service;
  final EventCardView event;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<AdjustBudgetDialog> createState() => _AdjustBudgetDialogState();
}

class _AdjustBudgetDialogState extends State<AdjustBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
  AttachmentRef? _resolutionAttachment;
  BudgetAdjustmentDirection _direction = BudgetAdjustmentDirection.increase;
  StableId? _sourceId;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sourceId = widget.sourceOptions.isEmpty
        ? null
        : widget.sourceOptions.first.id;
    _amountController.addListener(_refreshReview);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSource = _sourceById(widget.sourceOptions, _sourceId);
    final review = _review(selectedSource);
    return AlertDialog(
      title: const Text('Adjust Event Budget'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.event.name),
                const SizedBox(height: 4),
                Text(
                  'Current budget ${widget.event.budgetLabel} - '
                  'balance ${widget.event.approvedBudgetBalanceLabel}',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BudgetAdjustmentDirection>(
                  key: const Key('eventBudgetAdjustmentDirectionField'),
                  initialValue: _direction,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment direction',
                  ),
                  items: BudgetAdjustmentDirection.values
                      .map(
                        (direction) => DropdownMenuItem(
                          value: direction,
                          child: Text(
                            _budgetAdjustmentDirectionLabel(direction),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _direction = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StableId>(
                  key: const Key('eventBudgetAdjustmentSourceField'),
                  initialValue: _sourceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Treasury source',
                  ),
                  items: widget.sourceOptions
                      .map(
                        (source) => DropdownMenuItem(
                          value: source.id,
                          child: Text(
                            source.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select a Treasury source.' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _sourceId = value;
                          });
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  selectedSource == null
                      ? 'No source selected.'
                      : 'Source balance ${selectedSource.balanceLabel}',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('eventBudgetAdjustmentAmountField'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Adjustment amount',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                  validator: _moneyValidator,
                ),
                const SizedBox(height: 12),
                AppDatePickerFormField(
                  key: const Key('eventBudgetAdjustmentDateField'),
                  controller: _dateController,
                  labelText: 'Adjustment date',
                  validator: _dateValidator,
                  isEnabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('eventBudgetAdjustmentRemarksField'),
                  controller: _remarksController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment remarks',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Resolution attachment',
                  action: const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                FormField<AttachmentRef>(
                  key: const Key(
                    'eventBudgetAdjustmentResolutionAttachmentField',
                  ),
                  validator: (_) => _resolutionAttachment == null
                      ? 'Select an approved resolution attachment.'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AttachmentSelector(
                        owner: AttachmentOwner(
                          module: 'events',
                          purpose: 'budget_adjustment',
                          contextLabelProvider: () =>
                              '${widget.event.name} Budget Adjustment',
                        ),
                        picker: widget.attachmentPicker,
                        storage: widget.attachmentStorage,
                        selectedAttachment: _resolutionAttachment,
                        selectButtonKey: const Key(
                          'eventBudgetAdjustmentResolutionAttachmentSelectButton',
                        ),
                        clearButtonKey: const Key(
                          'eventBudgetAdjustmentResolutionAttachmentClearButton',
                        ),
                        isEnabled: !_isSubmitting,
                        onChanged: (attachment) {
                          setState(() {
                            _resolutionAttachment = attachment;
                          });
                          field.didChange(attachment);
                        },
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _BudgetAdjustmentReviewPanel(review: review),
                if (_serviceError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serviceError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('eventBudgetAdjustmentSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Adjustment'),
        ),
      ],
    );
  }

  BudgetAdjustmentReview _review(TreasurySourceAllocationOption? source) {
    final amount = parsePhpMoney(_amountController.text) ?? Money.zero;
    final isIncrease = _direction == BudgetAdjustmentDirection.increase;
    return BudgetAdjustmentReview(
      currentBudget: widget.event.budget,
      currentApprovedBudgetBalance: widget.event.approvedBudgetBalance,
      sourceBalance: source?.balance ?? Money.zero,
      projectedBudget: isIncrease
          ? widget.event.budget + amount
          : widget.event.budget - amount,
      projectedApprovedBudgetBalance: isIncrease
          ? widget.event.approvedBudgetBalance + amount
          : widget.event.approvedBudgetBalance - amount,
      projectedSourceBalance: isIncrease
          ? (source?.balance ?? Money.zero) - amount
          : (source?.balance ?? Money.zero) + amount,
    );
  }

  void _refreshReview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.adjustEventBudget(
      AdjustEventBudgetCommand(
        eventId: widget.event.id,
        direction: _direction,
        amount: parsePhpMoney(_amountController.text)!,
        treasurySourceId: _sourceId!,
        adjustmentDate: _parseDate(_dateController.text)!,
        remarks: _remarksController.text,
        resolutionAttachment: _resolutionAttachment,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class BudgetReviewDialog extends StatefulWidget {
  const BudgetReviewDialog({
    super.key,
    required this.service,
    required this.event,
    required this.asOf,
  });

  final EventService service;
  final EventCardView event;
  final DateTime asOf;

  @override
  State<BudgetReviewDialog> createState() => _BudgetReviewDialogState();
}

class _BudgetReviewDialogState extends State<BudgetReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _causeController = TextEditingController();
  final _recommendationController = TextEditingController();
  late Future<BudgetActualSnapshot?> _snapshotFuture;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.service.loadBudgetActual(
      widget.event.id,
      asOf: widget.asOf,
    );
  }

  @override
  void dispose() {
    _findingsController.dispose();
    _causeController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Budget vs Actual'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: FutureBuilder<BudgetActualSnapshot?>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Text('Selected event could not be loaded.');
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.eventName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _BudgetActualMetrics(snapshot: data),
                  const SizedBox(height: 16),
                  Text(
                    'Add Review Snapshot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('auditorReviewFindingsField'),
                          controller: _findingsController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Findings',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('auditorReviewCauseField'),
                          controller: _causeController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Cause'),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('auditorReviewRecommendationField'),
                          controller: _recommendationController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Recommendation',
                          ),
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                  ),
                  if (_serviceError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _serviceError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Review History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (data.reviews.isEmpty)
                    const _EmptyPanelMessage(
                      icon: Icons.rate_review_outlined,
                      text: 'No auditor review snapshots have been recorded.',
                    )
                  else
                    Column(
                      children: [
                        for (final review in data.reviews)
                          _AuditorReviewHistoryRow(review: review),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          key: const Key('auditorReviewSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Review'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.createAuditorReview(
      CreateAuditorReviewCommand(
        eventId: widget.event.id,
        findings: _findingsController.text,
        cause: _causeController.text,
        recommendation: _recommendationController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class SubmitLiquidationDialog extends StatefulWidget {
  const SubmitLiquidationDialog({
    super.key,
    required this.service,
    required this.event,
    required this.officers,
    required this.attachmentPicker,
    required this.attachmentStorage,
    required this.organizationService,
    this.treasuryService,
  });

  final LiquidationService service;
  final LiquidationEventView event;
  final List<OfficerOption> officers;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final OrganizationService organizationService;
  final TreasuryService? treasuryService;

  @override
  State<SubmitLiquidationDialog> createState() =>
      _SubmitLiquidationDialogState();
}

class _SubmitLiquidationDialogState extends State<SubmitLiquidationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payeeController = TextEditingController();
  final _dateController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _remarksController = TextEditingController();
  final List<_LiquidationLineInput> _lines = [_LiquidationLineInput()];
  AttachmentRef? _receiptAttachment;
  ReceiptType _receiptType = ReceiptType.officialReceipt;
  FundingMode _fundingMode = FundingMode.releasedFunds;
  late List<OfficerOption> _officers;
  StableId? _officerId;
  String? _officerGuidance;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _officers = [...widget.officers];
    _officerId = _fundingMode == FundingMode.releasedFunds
        ? _firstFundedOfficerId(_officers)
        : (_officers.isEmpty ? null : _officers.first.id);
    for (final line in _lines) {
      _attachListeners(line);
    }
  }

  void _attachListeners(_LiquidationLineInput line) {
    line.quantityController.addListener(_onLineUpdated);
    line.unitCostController.addListener(_onLineUpdated);
  }

  void _detachListeners(_LiquidationLineInput line) {
    line.quantityController.removeListener(_onLineUpdated);
    line.unitCostController.removeListener(_onLineUpdated);
  }

  void _onLineUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Money get _totalReceiptAmount {
    return _lines.fold<Money>(Money.zero, (sum, line) => sum + line.subtotal);
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _dateController.dispose();
    _evidenceController.dispose();
    _remarksController.dispose();
    for (final line in _lines) {
      _detachListeners(line);
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      title: Text('Liquidate ${widget.event.name}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approved budget balance ${widget.event.approvedBudgetBalanceLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('liquidationPayeeField'),
                  controller: _payeeController,
                  decoration: const InputDecoration(
                    labelText: 'Payee or merchant',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                AppDatePickerFormField(
                  key: const Key('liquidationDateField'),
                  controller: _dateController,
                  labelText: 'Receipt date',
                  validator: _dateValidator,
                  isEnabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('liquidationEvidenceField'),
                  controller: _evidenceController,
                  decoration: const InputDecoration(
                    labelText: 'Evidence number',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReceiptType>(
                  key: const Key('liquidationReceiptTypeField'),
                  initialValue: _receiptType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Receipt type'),
                  items: ReceiptType.values
                      .map(
                        (type) => DropdownMenuItem(
                          key: Key('liquidationReceiptTypeOption${type.name}'),
                          value: type,
                          child: Text(
                            receiptTypeDisplayLabel(type),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _receiptType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  key: const Key('liquidationFundingModeField'),
                  decoration: const InputDecoration(labelText: 'Funding mode'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FundingMode.releasedFunds,
                      FundingMode.outOfPocket,
                    ]
                        .map(
                          (mode) => ChoiceChip(
                            key: Key(
                              'liquidationFundingModeOption${mode.name}',
                            ),
                            label: Text(fundingModeDisplayLabel(mode)),
                            selected: _fundingMode == mode,
                            onSelected: (_) {
                              setState(() {
                                _fundingMode = mode;
                                if (_fundingMode == FundingMode.releasedFunds) {
                                  _officerId = _firstFundedOfficerId(_officers);
                                } else {
                                  _officerId ??= _officers.isEmpty
                                      ? null
                                      : _officers.first.id;
                                }
                                _officerGuidance = null;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: const Key('liquidationOfficerField'),
                  child: DropdownButtonFormField<StableId>(
                    key: ValueKey(
                      'liquidationOfficerDropdown-${_officerId ?? 'none'}-${_officers.length}',
                    ),
                    initialValue: _officerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Accountable officer',
                    ),
                    items: _officers
                        .map(
                          (officer) => DropdownMenuItem(
                            value: officer.id,
                            enabled:
                                _fundingMode != FundingMode.releasedFunds ||
                                officer.hasFundCustody,
                            child: Text(
                              _fundingMode == FundingMode.releasedFunds
                                  ? '${officer.fullName} — holds ${officer.fundCustodyBalanceLabel}'
                                  : officer.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    validator: (value) {
                      if (value == null) {
                        return 'Select an accountable officer.';
                      }
                      final selected = _officerById(_officers, value);
                      if (_fundingMode == FundingMode.releasedFunds &&
                          (selected == null || !selected.hasFundCustody)) {
                        return 'Select an officer with held funds for this event.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _officerId = value;
                        _officerGuidance = null;
                      });
                    },
                  ),
                ),
                // Mixed-funding split preview panel.
                if (_fundingMode == FundingMode.releasedFunds) ...[
                  Builder(
                    builder: (context) {
                      final selectedOfficer = _officerById(_officers, _officerId);
                      final custody = selectedOfficer?.fundCustodyBalance ?? Money.zero;
                      final receiptTotal = _totalReceiptAmount;
                      if (!receiptTotal.isPositive || custody >= receiptTotal) {
                        return const SizedBox.shrink();
                      }
                      final released = custody.isPositive ? custody : Money.zero;
                      final oop = Money.centavos(
                        receiptTotal.centavos - released.centavos,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          InlineStatusPanel(
                            tone: InlineStatusTone.info,
                            title: 'Auto-split funding',
                            message: 'Officer custody (${formatPhpMoney(custody)}) is less than '
                                'the receipt total (${formatPhpMoney(receiptTotal)}). '
                                'This will be recorded as:\n'
                                '  • Released from custody: ${formatPhpMoney(released)}\n'
                                '  • Out-of-pocket (reimbursable): ${formatPhpMoney(oop)}',
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (_officerGuidance != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InlineStatusPanel(
                    tone: InlineStatusTone.warning,
                    title: 'Fund custody required',
                    message: _officerGuidance!,
                  ),
                ],
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Receipt attachment',
                  action: const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                FormField<AttachmentRef>(
                  key: const Key('liquidationAttachmentField'),
                  validator: (_) => _receiptAttachment == null
                      ? 'Select a receipt attachment.'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AttachmentSelector(
                        owner: AttachmentOwner(
                          module: 'liquidation',
                          purpose: 'receipt',
                          contextLabel: widget.event.name,
                        ),
                        picker: widget.attachmentPicker,
                        storage: widget.attachmentStorage,
                        selectedAttachment: _receiptAttachment,
                        selectButtonKey: const Key(
                          'liquidationAttachmentSelectButton',
                        ),
                        clearButtonKey: const Key(
                          'liquidationAttachmentClearButton',
                        ),
                        isEnabled: !_isSubmitting,
                        onChanged: (attachment) {
                          setState(() {
                            _receiptAttachment = attachment;
                          });
                          field.didChange(attachment);
                        },
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Line items',
                  action: OutlinedButton.icon(
                    key: const Key('liquidationAddLineButton'),
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Row'),
                  ),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _lines.length; index += 1)
                  _LiquidationLineRow(
                    key: ValueKey(_lines[index]),
                    input: _lines[index],
                    index: index,
                    canRemove: _lines.length > 1,
                    onRemove: () => _removeLine(index),
                  ),
                const SizedBox(height: 8),
                _buildSummaryCard(context),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('liquidationRemarksField'),
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                ),
                if (_serviceError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serviceError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('liquidationSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Liquidation'),
        ),
      ],
    );
  }

  void _addLine() {
    setState(() {
      final line = _LiquidationLineInput();
      _attachListeners(line);
      _lines.add(line);
    });
  }

  void _removeLine(int index) {
    setState(() {
      final line = _lines.removeAt(index);
      _detachListeners(line);
      line.dispose();
    });
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final totalReceipt = _totalReceiptAmount;
    final selectedOfficer = _officerById(_officers, _officerId);
    final isReleasedFunds = _fundingMode == FundingMode.releasedFunds;
    final heldCustody = selectedOfficer?.fundCustodyBalance ?? Money.zero;
    final approvedBalance = widget.event.approvedBudgetBalance;

    final exceedsHeldCustody =
        isReleasedFunds &&
        totalReceipt.isPositive &&
        selectedOfficer != null &&
        totalReceipt > heldCustody;

    final exceedsApprovedBudget =
        !isReleasedFunds &&
        totalReceipt.isPositive &&
        totalReceipt > approvedBalance;

    final hasWarning = exceedsHeldCustody || exceedsApprovedBudget;
    final warningColor = theme.colorScheme.error;

    return Container(
      key: const Key('liquidationSummaryCard'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: hasWarning
            ? warningColor.withValues(alpha: 0.08)
            : AppColors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: hasWarning
              ? warningColor.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Receipt Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Total: ${formatPhpMoney(totalReceipt)}',
                key: const Key('liquidationGrandTotalText'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasWarning ? warningColor : AppColors.brandLight,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                isReleasedFunds
                    ? 'Officer held funds:'
                    : 'Approved budget balance:',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                isReleasedFunds
                    ? (selectedOfficer?.fundCustodyBalanceLabel ?? '₱0.00')
                    : widget.event.approvedBudgetBalanceLabel,
                key: const Key('liquidationComparisonTargetText'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (exceedsHeldCustody) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: warningColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Receipt total (${formatPhpMoney(totalReceipt)}) exceeds officer held custody (${selectedOfficer.fundCustodyBalanceLabel}). Reduce amount or switch to Out-of-Pocket for reimbursement.',
                    style: TextStyle(
                      fontSize: 12,
                      color: warningColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (exceedsApprovedBudget) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Receipt total (${formatPhpMoney(totalReceipt)}) exceeds approved budget balance (${widget.event.approvedBudgetBalanceLabel}). An event budget increase resolution will be needed.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.submitLiquidation(
      SubmitLiquidationCommand(
        eventId: widget.event.id,
        payeeOrMerchant: _payeeController.text,
        date: _parseDate(_dateController.text)!,
        evidenceNumber: _evidenceController.text,
        receiptType: _receiptType,
        fundingMode: _fundingMode,
        accountableOfficerId: _officerId!,
        attachment: _receiptAttachment,
        lines: _lines
            .map(
              (line) => SubmitLiquidationLineDraft(
                description: line.descriptionController.text,
                quantity: int.parse(line.quantityController.text.trim()),
                unitCost: parsePhpMoney(line.unitCostController.text)!,
              ),
            )
            .toList(growable: false),
        remarks: _remarksController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class PayReimbursementDialog extends StatefulWidget {
  const PayReimbursementDialog({
    super.key,
    required this.service,
    required this.claim,
  });

  final LiquidationService service;
  final ReimbursementClaimView claim;

  @override
  State<PayReimbursementDialog> createState() => _PayReimbursementDialogState();
}

class _PayReimbursementDialogState extends State<PayReimbursementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void dispose() {
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay Reimbursement'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.claim.eventName),
              const SizedBox(height: 6),
              Text('Claim amount ${widget.claim.amountLabel}'),
              Text('Available ${widget.claim.approvedBudgetBalanceLabel}'),
              Text('After payment ${widget.claim.projectedRemainingLabel}'),
              if (widget.claim.hasInsufficientBudget) ...[
                const SizedBox(height: 8),
                Text(
                  'Approved Budget is insufficient.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('reimbursementPaymentDateField'),
                controller: _dateController,
                labelText: 'Payment date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('reimbursementRemarksField'),
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if (_serviceError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _serviceError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('reimbursementPaymentSubmitButton'),
          onPressed: _isSubmitting || widget.claim.hasInsufficientBudget
              ? null
              : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Payment'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.payReimbursement(
      PayReimbursementCommand(
        claimId: widget.claim.id,
        paymentDate: _parseDate(_dateController.text)!,
        remarks: _remarksController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class AddFundToOfficerDialog extends StatefulWidget {
  const AddFundToOfficerDialog({
    super.key,
    required this.treasuryService,
    required this.eventId,
    required this.eventName,
    required this.approvedBudgetBalance,
    required this.approvedBudgetBalanceLabel,
    required this.officers,
    this.initialOfficerId,
  });

  final TreasuryService treasuryService;
  final StableId eventId;
  final String eventName;
  final Money approvedBudgetBalance;
  final String approvedBudgetBalanceLabel;
  final List<OfficerOption> officers;
  final StableId? initialOfficerId;

  @override
  State<AddFundToOfficerDialog> createState() => _AddFundToOfficerDialogState();
}

class _AddFundToOfficerDialogState extends State<AddFundToOfficerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  late final TextEditingController _purposeController;
  final _remarksController = TextEditingController();
  StableId? _selectedOfficerId;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _purposeController = TextEditingController(
      text: 'Fund release for ${widget.eventName}',
    );
    _selectedOfficerId =
        widget.initialOfficerId ??
        (widget.officers.isNotEmpty ? widget.officers.first.id : null);
    _amountController.addListener(_refreshReview);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _refreshReview() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid amount greater than zero.';
    }
    final parsed = parsePhpMoney(value.trim());
    if (parsed == null || !parsed.isPositive) {
      return 'Enter a valid amount greater than zero.';
    }
    if (parsed > widget.approvedBudgetBalance) {
      return 'Amount cannot exceed unutilized approved budget (${widget.approvedBudgetBalanceLabel}).';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedOfficerId == null) {
      setState(() {
        _serviceError = 'Select an officer to receive released funds.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });

    final amount = parsePhpMoney(_amountController.text)!;
    final date = _parseDate(_dateController.text) ?? DateTime.now();
    final purpose = _purposeController.text.trim().isNotEmpty
        ? _purposeController.text.trim()
        : 'Fund release for ${widget.eventName}';
    final remarks = _remarksController.text.trim().isNotEmpty
        ? _remarksController.text.trim()
        : null;

    final result = await widget.treasuryService.recordManualMovement(
      ManualFundMovementCommand(
        type: FundMovementType.fundRelease,
        amount: amount,
        date: date,
        purpose: purpose,
        remarks: remarks,
        eventId: widget.eventId,
        holderOfficerId: _selectedOfficerId,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }

    Navigator.pop(context, _selectedOfficerId);
  }

  @override
  Widget build(BuildContext context) {
    final selectedOfficer = widget.officers
        .where((o) => o.id == _selectedOfficerId)
        .firstOrNull;
    final amount = parsePhpMoney(_amountController.text) ?? Money.zero;
    final projectedBalance = widget.approvedBudgetBalance - amount;
    final currentCustody = selectedOfficer?.fundCustodyBalance ?? Money.zero;
    final projectedCustody = currentCustody + amount;

    return AlertDialog(
      title: const Text('Add Fund to Officer'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventName,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unutilized approved budget: ${widget.approvedBudgetBalanceLabel}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StableId>(
                  key: const Key('addFundToOfficerSelectField'),
                  initialValue: _selectedOfficerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Accountable officer',
                  ),
                  items: widget.officers
                      .map(
                        (officer) => DropdownMenuItem(
                          value: officer.id,
                          child: Text(
                            '${officer.fullName} (current held: ${officer.fundCustodyBalanceLabel})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select an accountable officer.' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedOfficerId = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('addFundToOfficerAmountField'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount to release',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                  validator: _amountValidator,
                ),
                const SizedBox(height: 12),
                AppDatePickerFormField(
                  key: const Key('addFundToOfficerDateField'),
                  controller: _dateController,
                  labelText: 'Release date',
                  validator: _dateValidator,
                  isEnabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('addFundToOfficerPurposeField'),
                  controller: _purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('addFundToOfficerRemarksField'),
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fund Release Impact',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Unutilized approved budget:'),
                          ),
                          Text(
                            formatPhpMoney(
                              projectedBalance < Money.zero
                                  ? Money.zero
                                  : projectedBalance,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: projectedBalance < Money.zero
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Officer custody balance:'),
                          ),
                          Text(
                            formatPhpMoney(projectedCustody),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_serviceError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serviceError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('addFundToOfficerSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Release Funds'),
        ),
      ],
    );
  }
}

// ── Private Helper Widgets & Validation ──────────────────────────────────────

class _AllocationInput {
  _AllocationInput({this.sourceId});

  StableId? sourceId;
  final TextEditingController amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    super.key,
    required this.input,
    required this.index,
    required this.sourceOptions,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _AllocationInput input;
  final int index;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Allocation ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: Key('eventRemoveAllocationButton$index'),
                    tooltip: 'Remove allocation row',
                    onPressed: canRemove ? onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<StableId>(
                key: Key('eventAllocationSourceField$index'),
                initialValue: input.sourceId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Treasury source'),
                items: sourceOptions
                    .map(
                      (source) => DropdownMenuItem(
                        value: source.id,
                        child: Text(
                          '${source.label} (${source.balanceLabel})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) =>
                    value == null ? 'Select a Treasury source.' : null,
                onChanged: (value) {
                  input.sourceId = value;
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('eventAllocationAmountField$index'),
                controller: input.amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Allocated amount',
                  prefixText: '₱ ',
                  hintText: '0.00',
                ),
                validator: _moneyValidator,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidationLineInput {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController unitCostController = TextEditingController();

  Money get subtotal {
    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    final cost = parsePhpMoney(unitCostController.text.trim());
    if (qty <= 0 || cost == null) {
      return Money.zero;
    }
    return cost * qty;
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitCostController.dispose();
  }
}

class _LiquidationLineRow extends StatelessWidget {
  const _LiquidationLineRow({
    super.key,
    required this.input,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _LiquidationLineInput input;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtotal = input.subtotal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Line ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          key: Key('liquidationLineSubtotal$index'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            'Subtotal: ${formatPhpMoney(subtotal)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subtotal.isPositive
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('liquidationRemoveLineButton$index'),
                    tooltip: 'Remove line',
                    onPressed: canRemove ? onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('liquidationLineDescriptionField$index'),
                controller: input.descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: Key('liquidationLineQuantityField$index'),
                      controller: input.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: '1',
                      ),
                      validator: _positiveIntValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: Key('liquidationLineUnitCostField$index'),
                      controller: input.unitCostController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit cost',
                        prefixText: '₱ ',
                        hintText: '0.00',
                      ),
                      validator: _moneyValidator,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetActualMetrics extends StatelessWidget {
  const _BudgetActualMetrics({required this.snapshot});

  final BudgetActualSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tileWidth = MediaQuery.sizeOf(context).width >= 560 ? 280.0 : 520.0;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Budget',
            value: snapshot.budgetLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Actual',
            value: snapshot.actualLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Variance',
            value: snapshot.varianceLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Utilization',
            value: snapshot.utilizationLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Unutilized Approved Budget',
            value: snapshot.approvedBudgetBalanceLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Health',
            value: snapshot.healthLabel,
          ),
        ),
      ],
    );
  }
}

class _BudgetMetricTile extends StatelessWidget {
  const _BudgetMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditorReviewHistoryRow extends StatelessWidget {
  const _AuditorReviewHistoryRow({required this.review});

  final AuditorReviewView review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetadataChip(label: review.createdAtLabel),
                  StatusBadge(label: review.healthLabel),
                  MetadataChip(label: review.utilizationLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text('Findings: ${review.findings}'),
              const SizedBox(height: 4),
              Text('Cause: ${review.cause}'),
              const SizedBox(height: 4),
              Text('Recommendation: ${review.recommendation}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetAdjustmentReviewPanel extends StatelessWidget {
  const _BudgetAdjustmentReviewPanel({required this.review});

  final BudgetAdjustmentReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projected Balances',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ReviewLine(
              label: 'Event budget',
              value: review.projectedBudgetLabel,
            ),
            _ReviewLine(
              label: 'Approved budget balance',
              value: review.projectedApprovedBudgetBalanceLabel,
            ),
            _ReviewLine(
              label: 'Treasury source balance',
              value: review.projectedSourceBalanceLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        action,
      ],
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF64748B)),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

TreasurySourceAllocationOption? _sourceById(
  List<TreasurySourceAllocationOption> sources,
  StableId? id,
) {
  for (final source in sources) {
    if (source.id == id) {
      return source;
    }
  }
  return null;
}

OfficerOption? _officerById(List<OfficerOption> officers, StableId? id) {
  for (final officer in officers) {
    if (officer.id == id) {
      return officer;
    }
  }
  return null;
}

StableId? _firstFundedOfficerId(List<OfficerOption> officers) {
  for (final officer in officers) {
    if (officer.hasFundCustody) {
      return officer.id;
    }
  }
  return null;
}

String _budgetAdjustmentDirectionLabel(BudgetAdjustmentDirection direction) {
  return switch (direction) {
    BudgetAdjustmentDirection.increase => 'Increase budget',
    BudgetAdjustmentDirection.decrease => 'Decrease budget',
  };
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String? _moneyValidator(String? value) {
  final money = parsePhpMoney(value ?? '');
  if (money == null) {
    return 'Enter a valid PHP amount.';
  }
  if (!money.isPositive) {
    return 'Amount must be greater than zero.';
  }
  return null;
}

String? _dateValidator(String? value) {
  if (_parseDate(value ?? '') == null) {
    return 'Enter a valid date.';
  }
  return null;
}

String? _optionalDateValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  return _dateValidator(text);
}

String? _positiveIntValidator(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null) {
    return 'Enter a valid number.';
  }
  if (parsed <= 0) {
    return 'Number must be greater than zero.';
  }
  return null;
}

DateTime? _parseDate(String input) {
  final text = input.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
