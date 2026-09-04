import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_selector.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import 'ledger_screen.dart';
import 'treasury_formatters.dart';
import 'treasury_service.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({
    super.key,
    required this.service,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.refreshTrigger = 0,
  });

  final TreasuryService service;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final int refreshTrigger;

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  late Future<TreasurySnapshot> _snapshotFuture;
  TreasurySnapshot? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TreasuryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  void _load() {
    _snapshotFuture = widget.service.loadSnapshot().then((snapshot) {
      if (mounted) {
        setState(() {
          _cachedSnapshot = snapshot;
        });
      }
      return snapshot;
    });
  }

  void _refresh() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedSnapshot != null) {
      return _TreasuryContent(
        key: const ValueKey('content'),
        snapshot: _cachedSnapshot!,
        onAddFund: _showAddFundDialog,
        onManualMovement: _showManualMovementDialog,
        onOpenFullLedger: () => _openFullLedger(_cachedSnapshot!.ledgerRows),
      );
    }

    return FutureBuilder<TreasurySnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const AppStateView.loading(
            key: ValueKey('loading'),
            title: 'Loading Treasury',
            message: 'Reading source balances and ledger rows.',
          );
        } else if (snapshot.hasError) {
          child = AppStateView.error(
            key: const ValueKey('error'),
            title: 'Treasury data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        } else {
          final data =
              snapshot.data ??
              const TreasurySnapshot(
                totalBalance: Money.zero,
                sources: [],
                ledgerRows: [],
                eventOptions: [],
                officerOptions: [],
              );
          _cachedSnapshot = data;
          child = _TreasuryContent(
            key: const ValueKey('content'),
            snapshot: data,
            onAddFund: _showAddFundDialog,
            onManualMovement: _showManualMovementDialog,
            onOpenFullLedger: () => _openFullLedger(data.ledgerRows),
          );
        }
        return AppCrossfade(child: child);
      },
    );
  }

  void _openFullLedger(List<TreasuryLedgerRow> rows) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LedgerScreen(service: widget.service, initialRows: rows),
      ),
    );
  }

  Future<void> _showAddFundDialog() async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _AddFundDialog(
        service: widget.service,
        sources: snapshot.sources,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showManualMovementDialog() async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _ManualMovementDialog(
        service: widget.service,
        sources: snapshot.sources,
        events: snapshot.eventOptions,
        officers: snapshot.officerOptions,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }
}

class _TreasuryContent extends StatelessWidget {
  const _TreasuryContent({
    super.key,
    required this.snapshot,
    required this.onAddFund,
    required this.onManualMovement,
    required this.onOpenFullLedger,
  });

  final TreasurySnapshot snapshot;
  final VoidCallback onAddFund;
  final VoidCallback onManualMovement;
  final VoidCallback onOpenFullLedger;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                16,
                isWide ? 32 : 16,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppSlideFadeIn(
                    child: _TreasuryHeader(
                      snapshot: snapshot,
                      onAddFund: onAddFund,
                      onManualMovement: onManualMovement,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep,
                    child: _SourceGridSection(sources: snapshot.sources),
                  ),
                  const SizedBox(height: 16),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep * 2,
                    child: _RecentLedgerSection(
                      rows: snapshot.ledgerRows,
                      onOpenFullLedger: onOpenFullLedger,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TreasuryHeader extends StatelessWidget {
  const _TreasuryHeader({
    required this.snapshot,
    required this.onAddFund,
    required this.onManualMovement,
  });

  final TreasurySnapshot snapshot;
  final VoidCallback onAddFund;
  final VoidCallback onManualMovement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Treasury', style: textTheme.headlineMedium),
            const SizedBox(height: 6),
            CompactStatRow(
              items: [
                CompactStat(
                  value: formatPhpMoney(snapshot.totalBalance),
                  label: 'Unallocated Treasury Balance',
                ),
                CompactStat(
                  value: snapshot.sources.length.toString(),
                  label: snapshot.sources.length == 1 ? 'source' : 'sources',
                ),
                CompactStat(
                  value: snapshot.ledgerRows.length.toString(),
                  label: 'ledger rows',
                ),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              key: const Key('treasuryManualMovementButton'),
              onPressed: snapshot.sources.isEmpty ? null : onManualMovement,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Manual Movement'),
            ),
            FilledButton.icon(
              key: const Key('treasuryAddFundButton'),
              onPressed: onAddFund,
              icon: const Icon(Icons.add),
              label: const Text('Add Fund'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceGridSection extends StatelessWidget {
  const _SourceGridSection({required this.sources});

  final List<TreasurySourceView> sources;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.account_balance,
            title: 'Fund Sources',
            trailing: StatusBadge(
              label:
                  '${sources.length} source${sources.length == 1 ? '' : 's'}',
              tone: InlineStatusTone.info,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (sources.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.account_balance_outlined,
              text: 'Add the first fund source to begin the Treasury ledger.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < sources.length; i += 2) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SourceCard(source: sources[i])),
                      const SizedBox(width: AppSpacing.md),
                      if (i + 1 < sources.length)
                        Expanded(child: _SourceCard(source: sources[i + 1]))
                      else
                        const Spacer(),
                    ],
                  ),
                  if (i + 2 < sources.length)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final TreasurySourceView source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            source.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source.balanceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          if (source.supportingAttachment != null) ...[
            const SizedBox(height: 2),
            Text(
              source.supportingAttachment!.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentLedgerSection extends StatelessWidget {
  const _RecentLedgerSection({
    required this.rows,
    required this.onOpenFullLedger,
  });

  final List<TreasuryLedgerRow> rows;
  final VoidCallback onOpenFullLedger;

  @override
  Widget build(BuildContext context) {
    final recentRows = rows.take(5).toList(growable: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.timeline_outlined,
            title: 'Ledger',
            trailing: OutlinedButton.icon(
              key: const Key('treasuryViewFullLedgerButton'),
              onPressed: onOpenFullLedger,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('View Full Ledger'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.timeline_outlined,
              text: 'Ledger movements appear after funds are added.',
            )
          else ...[
            for (var i = 0; i < recentRows.length; i++)
              _buildCompactLedgerRow(
                recentRows[i],
                i == recentRows.length - 1 && rows.length <= 5,
              ),
            if (rows.length > 5) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: onOpenFullLedger,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(
                    'View all ${rows.length} records in full ledger',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactLedgerRow(TreasuryLedgerRow row, bool isLast) {
    return ExpandableListRow(
      key: Key('treasuryLedgerRow${row.id}'),
      leading: Icon(
        row.isSystemGenerated ? Icons.lock_outline : Icons.edit_note,
        color: row.isSystemGenerated
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF59E0B),
        size: 18,
      ),
      title: Text(
        row.purpose,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      subtitle: Text(
        '${row.reference} · ${row.typeLabel} · ${row.dateLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
      ),
      trailing: Text(
        row.amountLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: row.isSystemGenerated
                ? 'System-generated, protected'
                : 'Manual movement',
            icon: row.isSystemGenerated ? Icons.lock_outline : Icons.edit_note,
            tone: row.isSystemGenerated
                ? InlineStatusTone.info
                : InlineStatusTone.warning,
          ),
          if (row.remarks != null && row.remarks!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Remarks: ${row.remarks!}',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      showDivider: !isLast,
    );
  }
}

class _AddFundDialog extends StatefulWidget {
  const _AddFundDialog({
    required this.service,
    required this.sources,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final TreasuryService service;
  final List<TreasurySourceView> sources;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<_AddFundDialog> createState() => _AddFundDialogState();
}

class _AddFundDialogState extends State<_AddFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  AttachmentRef? _supportingAttachment;
  TreasuryFundSourceType _type = TreasuryFundSourceType.previousAdmin;
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Add Fund',
      status: _formError == null && _serviceError == null
          ? null
          : InlineStatusPanel(
              title: _serviceError == null
                  ? 'Review required fields'
                  : 'Fund could not be saved',
              message:
                  _serviceError ??
                  'Fix the highlighted fields before saving this fund.',
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('addFundSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Fund'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TreasuryFundSourceType>(
                key: const Key('addFundTypeField'),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Source type'),
                items: TreasuryFundSourceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          treasurySourceTypeLabel(type),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  _type = value ?? _type;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('addFundAmountField'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: _moneyValidator,
              ),
              const SizedBox(height: 12),
              FormField<AttachmentRef>(
                key: const Key('addFundAttachmentField'),
                validator: (_) => _supportingAttachment == null
                    ? 'Select a supporting attachment.'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttachmentSelector(
                      label: 'Supporting attachment',
                      owner: AttachmentOwner(
                        module: 'treasury',
                        purpose: 'supporting',
                        contextLabelProvider: () =>
                            treasurySourceTypeLabel(_type),
                      ),
                      picker: widget.attachmentPicker,
                      storage: widget.attachmentStorage,
                      selectedAttachment: _supportingAttachment,
                      selectButtonKey: const Key(
                        'addFundAttachmentSelectButton',
                      ),
                      clearButtonKey: const Key('addFundAttachmentClearButton'),
                      isEnabled: !_isSubmitting,
                      onChanged: (attachment) {
                        setState(() {
                          _supportingAttachment = attachment;
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
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('addFundRemarksField'),
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Fix the highlighted fields before saving this fund.';
        _serviceError = null;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
      _formError = null;
    });
    final result = await widget.service.addFund(
      AddFundCommand(
        type: _type,
        amount: parsePhpMoney(_amountController.text)!,
        date: DateTime.now(),
        supportingAttachment: _supportingAttachment,
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

class _ManualMovementDialog extends StatefulWidget {
  const _ManualMovementDialog({
    required this.service,
    required this.sources,
    required this.events,
    required this.officers,
  });

  final TreasuryService service;
  final List<TreasurySourceView> sources;
  final List<TreasuryEventOption> events;
  final List<TreasuryOfficerOption> officers;

  @override
  State<_ManualMovementDialog> createState() => _ManualMovementDialogState();
}

class _ManualMovementDialogState extends State<_ManualMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();
  FundMovementType _type = FundMovementType.fundRelease;
  StableId? _fromFundSourceId;
  StableId? _toFundSourceId;
  StableId? _eventId;
  StableId? _officerId;
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fromFundSourceId = widget.sources.isEmpty ? null : widget.sources.first.id;
    _toFundSourceId = widget.sources.length > 1 ? widget.sources[1].id : null;
    _eventId = widget.events.isEmpty ? null : widget.events.first.id;
    _officerId = widget.officers.isEmpty ? null : widget.officers.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Manual Movement',
      status: _formError == null && _serviceError == null
          ? null
          : InlineStatusPanel(
              title: _serviceError == null
                  ? 'Review required fields'
                  : 'Movement could not be saved',
              message:
                  _serviceError ??
                  'Fix the highlighted fields before saving this movement.',
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('manualMovementSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Movement'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FundMovementType>(
                key: const Key('manualMovementTypeField'),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Movement type'),
                items: FundMovementRules.manualTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          fundMovementTypeLabel(type),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  _type = value ?? _type;
                }),
              ),
              const SizedBox(height: 12),
              if (_type == FundMovementType.fundRelease) ...[
                DropdownButtonFormField<StableId>(
                  key: const Key('manualMovementEventField'),
                  initialValue: _eventId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Event Approved Budget',
                  ),
                  items: widget.events
                      .map(
                        (event) => DropdownMenuItem(
                          value: event.id,
                          child: Text(
                            '${event.name} (${event.approvedBudgetBalanceLabel})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select an event Approved Budget.' : null,
                  onChanged: (value) => setState(() {
                    _eventId = value;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StableId>(
                  key: const Key('manualMovementOfficerField'),
                  initialValue: _officerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fund custodian officer',
                  ),
                  items: widget.officers
                      .map(
                        (officer) => DropdownMenuItem(
                          value: officer.id,
                          child: Text(
                            officer.fullName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select a fund custodian officer.' : null,
                  onChanged: (value) => setState(() {
                    _officerId = value;
                  }),
                ),
                const SizedBox(height: 12),
              ] else ...[
                if (_type == FundMovementType.transfer) ...[
                  DropdownButtonFormField<StableId>(
                    key: const Key('manualMovementFromSourceField'),
                    initialValue: _fromFundSourceId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Source fund'),
                    items: widget.sources
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
                        value == null ? 'Select a source fund.' : null,
                    onChanged: (value) => setState(() {
                      _fromFundSourceId = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<StableId?>(
                  key: const Key('manualMovementToSourceField'),
                  initialValue: _toFundSourceId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Target fund'),
                  items: [
                    const DropdownMenuItem<StableId?>(
                      child: Text(
                        'No target fund',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final source in widget.sources)
                      DropdownMenuItem<StableId?>(
                        value: source.id,
                        child: Text(
                          source.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (value) =>
                      value == null ? 'Select a target fund.' : null,
                  onChanged: (value) => setState(() {
                    _toFundSourceId = value;
                  }),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('manualMovementAmountField'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: _moneyValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('manualMovementPurposeField'),
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('manualMovementRemarksField'),
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Fix the highlighted fields before saving this movement.';
        _serviceError = null;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
      _formError = null;
    });
    final result = await widget.service.recordManualMovement(
      ManualFundMovementCommand(
        type: _type,
        amount: parsePhpMoney(_amountController.text)!,
        date: DateTime.now(),
        purpose: _purposeController.text,
        remarks: _remarksController.text,
        fromFundSourceId: _type == FundMovementType.returnRefund
            ? null
            : _type == FundMovementType.fundRelease
            ? null
            : _fromFundSourceId,
        toFundSourceId: _type == FundMovementType.fundRelease
            ? null
            : _toFundSourceId,
        holderOfficerId: _type == FundMovementType.fundRelease
            ? _officerId
            : null,
        eventId: _type == FundMovementType.fundRelease ? _eventId : null,
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

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
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
