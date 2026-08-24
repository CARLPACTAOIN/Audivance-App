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
import 'treasury_formatters.dart';
import 'treasury_service.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({
    super.key,
    required this.service,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final TreasuryService service;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  late Future<TreasurySnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.service.loadSnapshot();
  }

  @override
  void didUpdateWidget(TreasuryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _snapshotFuture = widget.service.loadSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TreasurySnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading Treasury',
            message: 'Reading source balances and ledger rows.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Treasury data could not be loaded',
            message: snapshot.error.toString(),
            onAction: () {
              setState(() {
                _snapshotFuture = widget.service.loadSnapshot();
              });
            },
          );
        }
        return _TreasuryContent(
          snapshot:
              snapshot.data ??
              const TreasurySnapshot(
                totalBalance: Money.zero,
                sources: [],
                ledgerRows: [],
              ),
          onAddFund: _showAddFundDialog,
          onManualMovement: _showManualMovementDialog,
        );
      },
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
    setState(() {
      _snapshotFuture = widget.service.loadSnapshot();
    });
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
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    setState(() {
      _snapshotFuture = widget.service.loadSnapshot();
    });
  }
}

class _TreasuryContent extends StatelessWidget {
  const _TreasuryContent({
    required this.snapshot,
    required this.onAddFund,
    required this.onManualMovement,
  });

  final TreasurySnapshot snapshot;
  final VoidCallback onAddFund;
  final VoidCallback onManualMovement;

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
                20,
                isWide ? 32 : 16,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _TreasuryHeader(
                    snapshot: snapshot,
                    onAddFund: onAddFund,
                    onManualMovement: onManualMovement,
                  ),
                  const SizedBox(height: 20),
                  _TreasurySummary(snapshot: snapshot),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _SourcePanel(sources: snapshot.sources),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _LedgerPanel(rows: snapshot.ledgerRows),
                        ),
                      ],
                    )
                  else ...[
                    _SourcePanel(sources: snapshot.sources),
                    const SizedBox(height: 20),
                    _LedgerPanel(rows: snapshot.ledgerRows),
                  ],
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Treasury',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Track local source funds, Add Fund support files, and auditable ledger movements.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
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

class _TreasurySummary extends StatelessWidget {
  const _TreasurySummary({required this.snapshot});

  final TreasurySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width >= 700 ? 3 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 184,
      ),
      itemBuilder: (context, index) {
        return switch (index) {
          0 => _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Unallocated Treasury Balance',
            value: formatPhpMoney(snapshot.totalBalance),
            detail: '${snapshot.sources.length} source funds',
          ),
          1 => _SummaryCard(
            icon: Icons.source_outlined,
            label: 'Source Funds',
            value: snapshot.sources.length.toString(),
            detail: snapshot.sources.isEmpty
                ? 'No encoded sources yet'
                : 'Balances update from ledger entries',
          ),
          _ => _SummaryCard(
            icon: Icons.receipt_long_outlined,
            label: 'Ledger Rows',
            value: snapshot.ledgerRows.length.toString(),
            detail: 'Newest movement first',
          ),
        };
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({required this.sources});

  final List<TreasurySourceView> sources;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Source Balances',
      child: sources.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.account_balance_outlined,
              text: 'Add the first fund source to begin the Treasury ledger.',
            )
          : Column(
              children: [
                for (final source in sources)
                  _SourceRow(
                    source: source,
                    showDivider: source != sources.last,
                  ),
              ],
            ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.showDivider});

  final TreasurySourceView source;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(source.typeLabel),
                    if (source.supportingAttachment != null) ...[
                      const SizedBox(height: 4),
                      Text(source.supportingAttachment!.fileName),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  source.balanceLabel,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _LedgerPanel extends StatelessWidget {
  const _LedgerPanel({required this.rows});

  final List<TreasuryLedgerRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Ledger',
      child: rows.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.timeline_outlined,
              text: 'Ledger movements appear after funds are added.',
            )
          : Column(
              children: [
                for (final row in rows)
                  _LedgerRow(row: row, showDivider: row != rows.last),
              ],
            ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.row, required this.showDivider});

  final TreasuryLedgerRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                row.isSystemGenerated ? Icons.lock_outline : Icons.edit_note,
                color: row.isSystemGenerated
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row.reference} - ${row.typeLabel} - ${row.dateLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(
                      label: row.isSystemGenerated
                          ? 'System-generated, protected'
                          : 'Manual movement',
                      icon: row.isSystemGenerated
                          ? Icons.lock_outline
                          : Icons.edit_note,
                      tone: row.isSystemGenerated
                          ? InlineStatusTone.info
                          : InlineStatusTone.warning,
                    ),
                    if (row.remarks != null) ...[
                      const SizedBox(height: 4),
                      Text(row.remarks!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  row.amountLabel,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
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
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  AttachmentRef? _supportingAttachment;
  TreasuryFundSourceType _type = TreasuryFundSourceType.previousAdmin;
  StableId? _existingSourceId;
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void dispose() {
    _labelController.dispose();
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
              if (widget.sources.isNotEmpty)
                DropdownButtonFormField<StableId?>(
                  key: const Key('addFundExistingSourceField'),
                  initialValue: _existingSourceId,
                  decoration: const InputDecoration(
                    labelText: 'Apply to source',
                  ),
                  items: [
                    const DropdownMenuItem<StableId?>(
                      child: Text('Create new source'),
                    ),
                    for (final source in widget.sources)
                      DropdownMenuItem<StableId?>(
                        value: source.id,
                        child: Text(source.label),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _existingSourceId = value;
                      final existing = _sourceById(widget.sources, value);
                      if (existing != null) {
                        _type = existing.type;
                        _labelController.text = existing.label;
                      }
                    });
                  },
                ),
              if (widget.sources.isNotEmpty) const SizedBox(height: 12),
              DropdownButtonFormField<TreasuryFundSourceType>(
                key: const Key('addFundTypeField'),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Source type'),
                items: TreasuryFundSourceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(treasurySourceTypeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _existingSourceId == null
                    ? (value) => setState(() {
                        _type = value ?? _type;
                      })
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('addFundLabelField'),
                controller: _labelController,
                enabled: _existingSourceId == null,
                decoration: const InputDecoration(labelText: 'Source label'),
                validator: _requiredValidator,
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
                      owner: const AttachmentOwner(module: 'treasury'),
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
        existingSourceId: _existingSourceId,
        type: _type,
        label: _labelController.text,
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
  const _ManualMovementDialog({required this.service, required this.sources});

  final TreasuryService service;
  final List<TreasurySourceView> sources;

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
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fromFundSourceId = widget.sources.isEmpty ? null : widget.sources.first.id;
    _toFundSourceId = widget.sources.length > 1 ? widget.sources[1].id : null;
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
                decoration: const InputDecoration(labelText: 'Movement type'),
                items: FundMovementRules.manualTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(fundMovementTypeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  _type = value ?? _type;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StableId>(
                key: const Key('manualMovementFromSourceField'),
                initialValue: _fromFundSourceId,
                decoration: const InputDecoration(labelText: 'Source fund'),
                items: widget.sources
                    .map(
                      (source) => DropdownMenuItem(
                        value: source.id,
                        child: Text(source.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  _fromFundSourceId = value;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StableId?>(
                key: const Key('manualMovementToSourceField'),
                initialValue: _toFundSourceId,
                decoration: const InputDecoration(labelText: 'Target fund'),
                items: [
                  const DropdownMenuItem<StableId?>(
                    child: Text('No target fund'),
                  ),
                  for (final source in widget.sources)
                    DropdownMenuItem<StableId?>(
                      value: source.id,
                      child: Text(source.label),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _toFundSourceId = value;
                }),
              ),
              const SizedBox(height: 12),
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
            : _fromFundSourceId,
        toFundSourceId: _type == FundMovementType.fundRelease
            ? null
            : _toFundSourceId,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
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

TreasurySourceView? _sourceById(
  List<TreasurySourceView> sources,
  StableId? id,
) {
  if (id == null) {
    return null;
  }
  for (final source in sources) {
    if (source.id == id) {
      return source;
    }
  }
  return null;
}
