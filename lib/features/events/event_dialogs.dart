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
import '../organization/widgets/officer_editor_dialog.dart';
import '../treasury/treasury_formatters.dart';
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

class AdjustBudgetDialog extends StatefulWidget {
  const AdjustBudgetDialog({
    super.key,
    required this.service,
    required this.event,
    required this.sourceOptions,
  });

  final EventService service;
  final EventCardView event;
  final List<TreasurySourceAllocationOption> sourceOptions;

  @override
  State<AdjustBudgetDialog> createState() => _AdjustBudgetDialogState();
}

class _AdjustBudgetDialogState extends State<AdjustBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
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
                  decoration: const InputDecoration(labelText: 'Amount'),
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
  });

  final LiquidationService service;
  final LiquidationEventView event;
  final List<OfficerOption> officers;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final OrganizationService organizationService;

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
    _officerId =
        _firstFundedOfficerId(_officers) ??
        (_officers.isEmpty ? null : _officers.first.id);
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _dateController.dispose();
    _evidenceController.dispose();
    _remarksController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                    children: FundingMode.values
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
                                  final selected = _officerById(
                                    _officers,
                                    _officerId,
                                  );
                                  if (selected == null ||
                                      !selected.hasFundCustody) {
                                    _officerId = _firstFundedOfficerId(
                                      _officers,
                                    );
                                  }
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
                                  ? '${officer.fullName} - held ${officer.fundCustodyBalanceLabel}'
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
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('liquidationAddOfficerButton'),
                    onPressed: _isSubmitting ? null : _addOfficer,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add officer'),
                  ),
                ),
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
      _lines.add(_LiquidationLineInput());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index).dispose();
    });
  }

  Future<void> _addOfficer() async {
    final result = await showDialog<OfficerEditorResult>(
      context: context,
      builder: (context) =>
          OfficerEditorDialog(service: widget.organizationService),
    );
    if (!mounted || result == null) {
      return;
    }

    final officers = await widget.service.listOfficerOptionsForEvent(
      widget.event.id,
    );
    if (!mounted) {
      return;
    }
    final createdOfficer = _officerById(officers, result.officerId);
    setState(() {
      _officers = officers;
      if (_fundingMode == FundingMode.outOfPocket) {
        _officerId = createdOfficer?.id;
        _officerGuidance = null;
      } else if (createdOfficer?.hasFundCustody ?? false) {
        _officerId = createdOfficer!.id;
        _officerGuidance = null;
      } else {
        final selected = _officerById(_officers, _officerId);
        if (selected == null || !selected.hasFundCustody) {
          _officerId = _firstFundedOfficerId(_officers);
        }
        _officerGuidance =
            '${createdOfficer?.fullName ?? 'The new officer'} was added, but Released Funds liquidation requires funds released to that officer for this event.';
      }
    });
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
                decoration: const InputDecoration(labelText: 'Amount'),
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
                      'Line ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
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
              TextFormField(
                key: Key('liquidationLineQuantityField$index'),
                controller: input.quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: _positiveIntValidator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('liquidationLineUnitCostField$index'),
                controller: input.unitCostController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Unit cost'),
                validator: _moneyValidator,
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
            label: 'Remaining Approved',
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
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
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
