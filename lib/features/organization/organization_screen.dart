import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import 'organization_service.dart';
import 'widgets/officer_editor_dialog.dart';
import 'widgets/signature_block_preview.dart';

enum OrganizationSection { profile, officers }

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({
    super.key,
    required this.service,
    this.initialSection = OrganizationSection.officers,
  });

  final OrganizationService service;
  final OrganizationSection initialSection;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late Future<OrganizationWorkspaceSnapshot> _snapshotFuture;
  late OrganizationSection _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _resetFuture();
  }

  @override
  void didUpdateWidget(OrganizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _resetFuture();
    }
    if (oldWidget.initialSection != widget.initialSection) {
      _currentSection = widget.initialSection;
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
        final Widget child;
        if (snapshot.hasError) {
          child = AppStateView.error(
            key: const ValueKey('error'),
            title: 'Profile data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        } else if (snapshot.hasData) {
          child = _OrganizationContent(
            key: const ValueKey('content'),
            snapshot: snapshot.data!,
            initialSection: _currentSection,
            onSectionChanged: (section) => _currentSection = section,
            onEditOrganization: _showEditOrganizationDialog,
            onAddOfficer: () => _showOfficerDialog(),
            onEditOfficer: _showOfficerDialog,
            onArchiveOfficer: (officer) =>
                _confirmOfficerArchive(officer: officer, isArchived: true),
            onRestoreOfficer: (officer) =>
                _confirmOfficerArchive(officer: officer, isArchived: false),
          );
        } else {
          child = const AppStateView.loading(
            key: ValueKey('loading'),
            title: 'Loading Profile',
            message: 'Reading organization and officer records.',
          );
        }
        return AppCrossfade(child: child);
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
    final result = await showDialog<OfficerEditorResult>(
      context: context,
      builder: (context) =>
          OfficerEditorDialog(service: widget.service, officer: officer),
    );
    if (!mounted || result == null) {
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

class _OrganizationContent extends StatefulWidget {
  const _OrganizationContent({
    super.key,
    required this.snapshot,
    required this.initialSection,
    this.onSectionChanged,
    required this.onEditOrganization,
    required this.onAddOfficer,
    required this.onEditOfficer,
    required this.onArchiveOfficer,
    required this.onRestoreOfficer,
  });

  final OrganizationWorkspaceSnapshot snapshot;
  final OrganizationSection initialSection;
  final ValueChanged<OrganizationSection>? onSectionChanged;
  final VoidCallback onEditOrganization;
  final VoidCallback onAddOfficer;
  final ValueChanged<OfficerRowView> onEditOfficer;
  final ValueChanged<OfficerRowView> onArchiveOfficer;
  final ValueChanged<OfficerRowView> onRestoreOfficer;

  @override
  State<_OrganizationContent> createState() => _OrganizationContentState();
}

class _OrganizationContentState extends State<_OrganizationContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: OrganizationSection.values.length,
      initialIndex: widget.initialSection.index,
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    widget.onSectionChanged?.call(
      OrganizationSection.values[_tabController.index],
    );
  }

  @override
  void didUpdateWidget(_OrganizationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection &&
        _tabController.index != widget.initialSection.index) {
      _tabController.animateTo(widget.initialSection.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePageScaffold(
      children: [
        AppSlideFadeIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organization',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                tabs: const [
                  Tab(
                    key: Key('organizationProfileTab'),
                    icon: Icon(Icons.business_outlined),
                    text: 'Profile',
                  ),
                  Tab(
                    key: Key('organizationOfficersTab'),
                    icon: Icon(Icons.groups_outlined),
                    text: 'Officers',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final section = OrganizationSection.values[_tabController.index];
            return AppCrossfade(
              child: section == OrganizationSection.profile
                  ? _ProfileHeader(
                      key: const ValueKey('organizationProfileContent'),
                      snapshot: widget.snapshot,
                      onEditOrganization: widget.onEditOrganization,
                    )
                  : _OfficerRosterPanel(
                      key: const ValueKey('organizationOfficersContent'),
                      activeOfficers: widget.snapshot.activeOfficers,
                      archivedOfficers: widget.snapshot.archivedOfficers,
                      committeeSummaries: widget.snapshot.committeeSummaries,
                      onAddOfficer: widget.onAddOfficer,
                      onEditOfficer: widget.onEditOfficer,
                      onArchiveOfficer: widget.onArchiveOfficer,
                      onRestoreOfficer: widget.onRestoreOfficer,
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    super.key,
    required this.snapshot,
    required this.onEditOrganization,
  });

  final OrganizationWorkspaceSnapshot snapshot;
  final VoidCallback onEditOrganization;

  @override
  Widget build(BuildContext context) {
    final organization = snapshot.organization;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.organizationName,
                    key: const Key('profileOrganizationName'),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
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
              );
              final editButton = FilledButton.icon(
                key: const Key('profileEditOrganizationButton'),
                onPressed: onEditOrganization,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textBlock,
                    const SizedBox(height: AppSpacing.md),
                    editButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: textBlock),
                  const SizedBox(width: AppSpacing.lg),
                  editButton,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (organization == null)
            const Text(
              'Complete the organization profile for COA export.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: _InfoBlock(
                        label: 'Adviser',
                        value: organization.adviser.isNotEmpty
                            ? organization.adviser
                            : 'Not set',
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: _InfoBlock(
                        label: 'Signatories',
                        value: organization.signatoryNames.isNotEmpty
                            ? organization.signatoryNames.join(', ')
                            : 'Not set',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SignatureBlockPreview(
              treasurerName: organization.effectiveTreasurerSignatory,
              auditorName: organization.effectiveAuditorSignatory,
              headName: organization.effectiveHeadSignatory,
              adviserName: organization.adviser,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _OfficerRosterPanel extends StatelessWidget {
  const _OfficerRosterPanel({
    super.key,
    required this.activeOfficers,
    required this.archivedOfficers,
    required this.committeeSummaries,
    required this.onAddOfficer,
    required this.onEditOfficer,
    required this.onArchiveOfficer,
    required this.onRestoreOfficer,
  });

  final List<OfficerRowView> activeOfficers;
  final List<OfficerRowView> archivedOfficers;
  final List<CommitteeSummaryView> committeeSummaries;
  final VoidCallback onAddOfficer;
  final ValueChanged<OfficerRowView> onEditOfficer;
  final ValueChanged<OfficerRowView> onArchiveOfficer;
  final ValueChanged<OfficerRowView> onRestoreOfficer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roster header with Add Officer button
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(title: 'Officer Roster'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    children: [
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
                    ],
                  ),
                ],
              ),
              FilledButton.icon(
                key: const Key('profileAddOfficerButton'),
                onPressed: onAddOfficer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Officer'),
              ),
            ],
          ),
          // Committee summary inline
          if (committeeSummaries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final summary in committeeSummaries)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: _CommitteeChip(summary: summary),
                      ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.xs),
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
            const Divider(height: 28, color: AppColors.divider),
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
    );
  }
}

class _CommitteeChip extends StatelessWidget {
  const _CommitteeChip({required this.summary});

  final CommitteeSummaryView summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary.committeeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.headName != null
                ? 'Head: ${summary.headName}'
                : '${summary.memberCount} member${summary.memberCount == 1 ? '' : 's'} · No head assigned',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    officer.isArchived
                        ? Icons.inventory_2_outlined
                        : Icons.badge_outlined,
                    color: officer.isArchived
                        ? const Color(0xFF64748B)
                        : const Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      officer.fullName,
                      key: Key('profileOfficerName${officer.id}'),
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    key: Key('profileOfficerEdit${officer.id}'),
                    tooltip: 'Edit officer',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
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
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    label: officer.isArchived ? 'Archived' : 'Active',
                    icon: officer.isArchived
                        ? Icons.inventory_2_outlined
                        : Icons.check_circle_outline,
                    tone: officer.isArchived
                        ? InlineStatusTone.warning
                        : InlineStatusTone.success,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
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
  late final TextEditingController _treasurerController;
  late final TextEditingController _auditorController;
  late final TextEditingController _headController;
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
    _treasurerController = TextEditingController(
      text: organization?.effectiveTreasurerSignatory ?? '',
    );
    _auditorController = TextEditingController(
      text: organization?.effectiveAuditorSignatory ?? '',
    );
    _headController = TextEditingController(
      text: organization?.effectiveHeadSignatory ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _adviserController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _treasurerController.dispose();
    _auditorController.dispose();
    _headController.dispose();
    super.dispose();
  }

  Future<void> _autoFillFromOfficers() async {
    final snapshot = await widget.service.loadSnapshot();
    final officers = snapshot.activeOfficers;
    if (officers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active officers found in roster to auto-fill.'),
          ),
        );
      }
      return;
    }

    final financeHeads = officers.where(
      (o) =>
          o.committee == Committee.finance &&
          o.position == OfficerPosition.head,
    );
    final financeMembers = officers.where(
      (o) => o.committee == Committee.finance,
    );
    final treasurer = financeHeads.isNotEmpty
        ? financeHeads.first.fullName
        : (financeMembers.isNotEmpty ? financeMembers.first.fullName : '');

    final auditHeads = officers.where(
      (o) =>
          o.committee == Committee.audit && o.position == OfficerPosition.head,
    );
    final auditMembers = officers.where((o) => o.committee == Committee.audit);
    final auditor = auditHeads.isNotEmpty
        ? auditHeads.first.fullName
        : (auditMembers.isNotEmpty ? auditMembers.first.fullName : '');

    final otherOfficers = officers.where(
      (o) => o.fullName != treasurer && o.fullName != auditor,
    );
    final head = otherOfficers.isNotEmpty ? otherOfficers.first.fullName : '';

    var filledCount = 0;
    if (treasurer.isNotEmpty) {
      _treasurerController.text = treasurer;
      filledCount++;
    }
    if (auditor.isNotEmpty) {
      _auditorController.text = auditor;
      filledCount++;
    }
    if (head.isNotEmpty && _headController.text.trim().isEmpty) {
      _headController.text = head;
      filledCount++;
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            filledCount > 0
                ? 'Auto-filled $filledCount signatory field(s) from officer roster.'
                : 'No matching committee heads found to auto-fill.',
          ),
        ),
      );
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    'Official Signatories',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _autoFillFromOfficers,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Auto-fill from Roster'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _LabeledTextField(
                key: const Key('profileTreasurerField'),
                controller: _treasurerController,
                label: 'Organization Treasurer',
                helperText: 'Signatory for "Prepared by"',
              ),
              _LabeledTextField(
                key: const Key('profileAuditorField'),
                controller: _auditorController,
                label: 'Organization Auditor',
                helperText: 'Signatory for "Audited by"',
              ),
              _LabeledTextField(
                key: const Key('profileHeadField'),
                controller: _headController,
                label: 'Organization Head / President',
                helperText: 'Signatory for "Submitted by"',
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedBuilder(
                animation: Listenable.merge([
                  _treasurerController,
                  _auditorController,
                  _headController,
                  _adviserController,
                ]),
                builder: (context, _) {
                  return SignatureBlockPreview(
                    treasurerName: _treasurerController.text,
                    auditorName: _auditorController.text,
                    headName: _headController.text,
                    adviserName: _adviserController.text,
                    compact: true,
                  );
                },
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
        treasurerSignatory: _treasurerController.text.trim(),
        auditorSignatory: _auditorController.text.trim(),
        headSignatory: _headController.text.trim(),
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
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
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
