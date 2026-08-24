import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import 'organization_service.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key, required this.service});

  final OrganizationService service;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late Future<OrganizationWorkspaceSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _resetFuture();
  }

  @override
  void didUpdateWidget(OrganizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _resetFuture();
    }
  }

  void _resetFuture() {
    _snapshotFuture = widget.service.loadSnapshot();
  }

  void _refresh() {
    setState(_resetFuture);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrganizationWorkspaceSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading Profile',
            message: 'Reading organization and officer records.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Profile data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        }
        return _OrganizationContent(
          snapshot: snapshot.data!,
          onEditOrganization: _showEditOrganizationDialog,
          onAddOfficer: () => _showOfficerDialog(),
          onEditOfficer: _showOfficerDialog,
          onArchiveOfficer: (officer) =>
              _confirmOfficerArchive(officer: officer, isArchived: true),
          onRestoreOfficer: (officer) =>
              _confirmOfficerArchive(officer: officer, isArchived: false),
        );
      },
    );
  }

  Future<void> _showEditOrganizationDialog() async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _OrganizationDialog(
        service: widget.service,
        organization: snapshot.organization,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showOfficerDialog([OfficerRowView? officer]) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) =>
          _OfficerDialog(service: widget.service, officer: officer),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _confirmOfficerArchive({
    required OfficerRowView officer,
    required bool isArchived,
  }) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _OfficerArchiveDialog(
        service: widget.service,
        officer: officer,
        isArchived: isArchived,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }
}

class _OrganizationContent extends StatelessWidget {
  const _OrganizationContent({
    required this.snapshot,
    required this.onEditOrganization,
    required this.onAddOfficer,
    required this.onEditOfficer,
    required this.onArchiveOfficer,
    required this.onRestoreOfficer,
  });

  final OrganizationWorkspaceSnapshot snapshot;
  final VoidCallback onEditOrganization;
  final VoidCallback onAddOfficer;
  final ValueChanged<OfficerRowView> onEditOfficer;
  final ValueChanged<OfficerRowView> onArchiveOfficer;
  final ValueChanged<OfficerRowView> onRestoreOfficer;

  @override
  Widget build(BuildContext context) {
    return ResponsivePageScaffold(
      children: [
        _ProfileHeader(
          snapshot: snapshot,
          onEditOrganization: onEditOrganization,
        ),
        const SizedBox(height: 16),
        if (snapshot.readinessHints.isNotEmpty) ...[
          _ReadinessPanel(hints: snapshot.readinessHints),
          const SizedBox(height: 16),
        ],
        _CommitteeSummaryPanel(summaries: snapshot.committeeSummaries),
        const SizedBox(height: 16),
        _OfficerRosterPanel(
          activeOfficers: snapshot.activeOfficers,
          archivedOfficers: snapshot.archivedOfficers,
          onAddOfficer: onAddOfficer,
          onEditOfficer: onEditOfficer,
          onArchiveOfficer: onArchiveOfficer,
          onRestoreOfficer: onRestoreOfficer,
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.snapshot,
    required this.onEditOrganization,
  });

  final OrganizationWorkspaceSnapshot snapshot;
  final VoidCallback onEditOrganization;

  @override
  Widget build(BuildContext context) {
    final organization = snapshot.organization;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.organizationName,
                        key: const Key('profileOrganizationName'),
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MetadataChip(
                            icon: Icons.calendar_month_outlined,
                            label: snapshot.termLabel,
                          ),
                          MetadataChip(
                            icon: Icons.school_outlined,
                            label: organization?.type ?? 'No type',
                          ),
                          StatusBadge(
                            label: snapshot.hasActiveOfficers
                                ? 'Officer-ready'
                                : 'Needs officers',
                            icon: snapshot.hasActiveOfficers
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            tone: snapshot.hasActiveOfficers
                                ? InlineStatusTone.success
                                : InlineStatusTone.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const Key('profileEditOrganizationButton'),
                  onPressed: onEditOrganization,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (organization == null)
              const Text('Complete the organization profile for COA export.')
            else
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _InfoBlock(label: 'Adviser', value: organization.adviser),
                  _InfoBlock(
                    label: 'Signatories',
                    value: organization.signatoryNames.join(', '),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({required this.hints});

  final List<OrganizationReadinessHint> hints;

  @override
  Widget build(BuildContext context) {
    return InlineStatusPanel(
      title: 'Profile readiness needs attention',
      message: hints.map((hint) => hint.message).join('\n'),
      tone: InlineStatusTone.warning,
    );
  }
}

class _CommitteeSummaryPanel extends StatelessWidget {
  const _CommitteeSummaryPanel({required this.summaries});

  final List<CommitteeSummaryView> summaries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Committee Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final cards = summaries
                    .map((summary) => _CommitteeSummaryCard(summary: summary))
                    .toList();
                if (!isWide) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        if (card != cards.last) const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (final card in cards) ...[
                      Expanded(child: card),
                      if (card != cards.last) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitteeSummaryCard extends StatelessWidget {
  const _CommitteeSummaryCard({required this.summary});

  final CommitteeSummaryView summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.committeeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Head: ${summary.headName ?? 'Not assigned'}'),
            const SizedBox(height: 4),
            Text('Members: ${summary.memberCount}'),
          ],
        ),
      ),
    );
  }
}

class _OfficerRosterPanel extends StatelessWidget {
  const _OfficerRosterPanel({
    required this.activeOfficers,
    required this.archivedOfficers,
    required this.onAddOfficer,
    required this.onEditOfficer,
    required this.onArchiveOfficer,
    required this.onRestoreOfficer,
  });

  final List<OfficerRowView> activeOfficers;
  final List<OfficerRowView> archivedOfficers;
  final VoidCallback onAddOfficer;
  final ValueChanged<OfficerRowView> onEditOfficer;
  final ValueChanged<OfficerRowView> onArchiveOfficer;
  final ValueChanged<OfficerRowView> onRestoreOfficer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Officer Roster',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StatusBadge(
                  label: '${activeOfficers.length} active',
                  icon: Icons.person_outline,
                  tone: InlineStatusTone.info,
                ),
                StatusBadge(
                  label: '${archivedOfficers.length} archived',
                  icon: Icons.inventory_2_outlined,
                  tone: InlineStatusTone.warning,
                ),
                FilledButton.icon(
                  key: const Key('profileAddOfficerButton'),
                  onPressed: onAddOfficer,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Officer'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (activeOfficers.isEmpty)
              const AppStateView.empty(
                title: 'No Active Officers',
                message: 'Add at least one active officer so liquidations and COA export can identify accountable people.',
              )
            else
              for (final officer in activeOfficers)
                _OfficerRow(
                  officer: officer,
                  onEdit: () => onEditOfficer(officer),
                  onArchive: () => onArchiveOfficer(officer),
                ),
            if (archivedOfficers.isNotEmpty) ...[
              const Divider(height: 28),
              ExpansionTile(
                key: const Key('profileArchivedOfficersTile'),
                tilePadding: EdgeInsets.zero,
                title: const Text('Archived Officers'),
                children: [
                  for (final officer in archivedOfficers)
                    _OfficerRow(
                      officer: officer,
                      onEdit: () => onEditOfficer(officer),
                      onArchive: () => onRestoreOfficer(officer),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfficerRow extends StatelessWidget {
  const _OfficerRow({
    required this.officer,
    required this.onEdit,
    required this.onArchive,
  });

  final OfficerRowView officer;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final badgeTone = officer.isArchived
        ? InlineStatusTone.warning
        : InlineStatusTone.success;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                officer.isArchived
                    ? Icons.inventory_2_outlined
                    : Icons.badge_outlined,
                color: const Color(0xFF1E3A8A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officer.fullName,
                      key: Key('profileOfficerName${officer.id}'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: officer.isArchived ? 'Archived' : 'Active',
                          icon: officer.isArchived
                              ? Icons.inventory_2_outlined
                              : Icons.check_circle_outline,
                          tone: badgeTone,
                        ),
                        MetadataChip(
                          icon: Icons.assignment_ind_outlined,
                          label: officer.positionLabel,
                        ),
                        MetadataChip(
                          icon: Icons.groups_outlined,
                          label: officer.committeeLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    key: Key('profileOfficerEdit${officer.id}'),
                    tooltip: 'Edit officer',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: Key(
                      officer.isArchived
                          ? 'profileOfficerRestore${officer.id}'
                          : 'profileOfficerArchive${officer.id}',
                    ),
                    tooltip: officer.isArchived
                        ? 'Restore officer'
                        : 'Archive officer',
                    onPressed: onArchive,
                    icon: Icon(
                      officer.isArchived
                          ? Icons.restore_outlined
                          : Icons.archive_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _OrganizationDialog extends StatefulWidget {
  const _OrganizationDialog({required this.service, this.organization});

  final OrganizationService service;
  final OrganizationProfile? organization;

  @override
  State<_OrganizationDialog> createState() => _OrganizationDialogState();
}

class _OrganizationDialogState extends State<_OrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _adviserController;
  late final TextEditingController _semesterController;
  late final TextEditingController _schoolYearController;
  late final TextEditingController _signatoriesController;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final organization = widget.organization;
    _nameController = TextEditingController(text: organization?.name ?? '');
    _typeController = TextEditingController(text: organization?.type ?? '');
    _adviserController = TextEditingController(
      text: organization?.adviser ?? '',
    );
    _semesterController = TextEditingController(
      text: organization?.semester ?? '',
    );
    _schoolYearController = TextEditingController(
      text: organization?.schoolYear ?? '',
    );
    _signatoriesController = TextEditingController(
      text: organization?.signatoryNames.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _adviserController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _signatoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Edit Organization Profile',
      status: _serviceError == null
          ? null
          : InlineStatusPanel(
              title: 'Profile could not be saved',
              message: _serviceError!,
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('profileOrganizationSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save Profile'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledTextField(
                key: const Key('profileOrganizationNameField'),
                controller: _nameController,
                label: 'Organization name',
              ),
              _LabeledTextField(
                key: const Key('profileOrganizationTypeField'),
                controller: _typeController,
                label: 'Organization type',
              ),
              _LabeledTextField(
                key: const Key('profileAdviserField'),
                controller: _adviserController,
                label: 'Adviser',
              ),
              _LabeledTextField(
                key: const Key('profileSemesterField'),
                controller: _semesterController,
                label: 'Semester',
              ),
              _LabeledTextField(
                key: const Key('profileSchoolYearField'),
                controller: _schoolYearController,
                label: 'School year',
              ),
              _LabeledTextField(
                key: const Key('profileSignatoriesField'),
                controller: _signatoriesController,
                label: 'Signatory names',
                helperText: 'Separate names with commas or new lines.',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _serviceError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _serviceError = 'Fix the highlighted fields before saving.';
      });
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.service.updateOrganization(
      UpdateOrganizationCommand(
        name: _nameController.text,
        type: _typeController.text,
        adviser: _adviserController.text,
        semester: _semesterController.text,
        schoolYear: _schoolYearController.text,
        signatoryNamesText: _signatoriesController.text,
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

class _OfficerDialog extends StatefulWidget {
  const _OfficerDialog({required this.service, this.officer});

  final OrganizationService service;
  final OfficerRowView? officer;

  @override
  State<_OfficerDialog> createState() => _OfficerDialogState();
}

class _OfficerDialogState extends State<_OfficerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late OfficerPosition _position;
  Committee? _committee;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final officer = widget.officer;
    _nameController = TextEditingController(text: officer?.fullName ?? '');
    _position = officer?.position ?? OfficerPosition.member;
    _committee = officer?.committee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.officer != null;
    return AppDialogFrame(
      title: isEditing ? 'Edit Officer' : 'Add Officer',
      status: _serviceError == null
          ? null
          : InlineStatusPanel(
              title: 'Officer could not be saved',
              message: _serviceError!,
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('profileOfficerSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save Officer'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledTextField(
                key: const Key('profileOfficerNameField'),
                controller: _nameController,
                label: 'Officer name',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<OfficerPosition>(
                key: const Key('profileOfficerPositionField'),
                initialValue: _position,
                decoration: const InputDecoration(labelText: 'Position'),
                items: const [
                  DropdownMenuItem(
                    value: OfficerPosition.member,
                    child: Text('Member'),
                  ),
                  DropdownMenuItem(
                    value: OfficerPosition.head,
                    child: Text('Head'),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _position = value);
                      },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Committee?>(
                key: const Key('profileOfficerCommitteeField'),
                initialValue: _committee,
                decoration: const InputDecoration(labelText: 'Committee'),
                items: const [
                  DropdownMenuItem<Committee?>(
                    value: null,
                    child: Text('No committee'),
                  ),
                  DropdownMenuItem<Committee?>(
                    value: Committee.finance,
                    child: Text('Finance Committee'),
                  ),
                  DropdownMenuItem<Committee?>(
                    value: Committee.audit,
                    child: Text('Audit Committee'),
                  ),
                ],
                validator: (value) {
                  if (_position == OfficerPosition.head && value == null) {
                    return 'Committee heads must be assigned to a committee.';
                  }
                  return null;
                },
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _committee = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _serviceError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _serviceError = 'Fix the highlighted fields before saving.';
      });
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.service.saveOfficer(
      SaveOfficerCommand(
        id: widget.officer?.id,
        fullName: _nameController.text,
        position: _position,
        committee: _committee,
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

class _OfficerArchiveDialog extends StatefulWidget {
  const _OfficerArchiveDialog({
    required this.service,
    required this.officer,
    required this.isArchived,
  });

  final OrganizationService service;
  final OfficerRowView officer;
  final bool isArchived;

  @override
  State<_OfficerArchiveDialog> createState() => _OfficerArchiveDialogState();
}

class _OfficerArchiveDialogState extends State<_OfficerArchiveDialog> {
  String? _serviceError;
  var _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.isArchived ? 'Archive' : 'Restore';
    return AppDialogFrame(
      title: '$action Officer',
      status: _serviceError == null
          ? null
          : InlineStatusPanel(
              title: 'Officer status could not be changed',
              message: _serviceError!,
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: Key(
            widget.isArchived
                ? 'profileArchiveConfirmButton'
                : 'profileRestoreConfirmButton',
          ),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.isArchived
                      ? Icons.archive_outlined
                      : Icons.restore_outlined,
                ),
          label: Text(action),
        ),
      ],
      children: [
        Text(
          widget.isArchived
              ? 'Archive ${widget.officer.fullName}? Historical records will keep this officer, but they will no longer appear in new liquidation selections.'
              : 'Restore ${widget.officer.fullName} to the active officer roster?',
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.setOfficerArchived(
      officerId: widget.officer.id,
      isArchived: widget.isArchived,
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

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, helperText: helperText),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required.';
          }
          return null;
        },
      ),
    );
  }
}
