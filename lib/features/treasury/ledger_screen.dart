import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../audit/domain/audit_models.dart';
import 'treasury_formatters.dart';
import 'treasury_service.dart';

enum LedgerTypeFilter { all, systemGenerated, manual }

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key, required this.service, this.initialRows});

  final TreasuryService service;
  final List<TreasuryLedgerRow>? initialRows;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late Future<TreasurySnapshot> _snapshotFuture;
  LedgerTypeFilter _typeFilter = LedgerTypeFilter.all;
  FundMovementType? _specificType;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.service.loadSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = widget.service.loadSnapshot();
    });
  }

  bool get _hasActiveFilters =>
      _typeFilter != LedgerTypeFilter.all ||
      _specificType != null ||
      _dateRange != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _typeFilter = LedgerTypeFilter.all;
      _specificType = null;
      _dateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<TreasuryLedgerRow> _applyFilters(List<TreasuryLedgerRow> rows) {
    return rows
        .where((row) {
          // Type filter
          if (_typeFilter == LedgerTypeFilter.systemGenerated &&
              !row.isSystemGenerated) {
            return false;
          }
          if (_typeFilter == LedgerTypeFilter.manual && row.isSystemGenerated) {
            return false;
          }
          if (_specificType != null && row.type != _specificType) {
            return false;
          }

          // Date range filter
          if (_dateRange != null) {
            final rowDate = DateTime(
              row.date.year,
              row.date.month,
              row.date.day,
            );
            final start = DateTime(
              _dateRange!.start.year,
              _dateRange!.start.month,
              _dateRange!.start.day,
            );
            final end = DateTime(
              _dateRange!.end.year,
              _dateRange!.end.month,
              _dateRange!.end.day,
            );
            if (rowDate.isBefore(start) || rowDate.isAfter(end)) {
              return false;
            }
          }

          // Search query filter
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchPurpose = row.purpose.toLowerCase().contains(q);
            final matchRef = row.reference.toLowerCase().contains(q);
            final matchType = row.typeLabel.toLowerCase().contains(q);
            final matchRemarks =
                row.remarks != null && row.remarks!.toLowerCase().contains(q);
            if (!matchPurpose && !matchRef && !matchType && !matchRemarks) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treasury Ledger'),
        actions: [
          IconButton(
            key: const Key('ledgerFilterButton'),
            tooltip: 'Filter ledger',
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilterSheet,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<TreasurySnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppStateView.loading(
              title: 'Loading Ledger',
              message: 'Reading all treasury fund movements.',
            );
          }
          if (snapshot.hasError) {
            return AppStateView.error(
              title: 'Ledger could not be loaded',
              message: snapshot.error.toString(),
              onAction: _refresh,
            );
          }

          final allRows = snapshot.data?.ledgerRows ?? widget.initialRows ?? [];
          final filteredRows = _applyFilters(allRows);

          return Column(
            children: [
              // Search and Quick filter bar
              _buildSearchBar(),
              if (_hasActiveFilters)
                _buildActiveFilterChips(allRows.length, filteredRows.length),
              Expanded(
                child: filteredRows.isEmpty
                    ? (allRows.isEmpty
                          ? const AppStateView.empty(
                              title: 'No Ledger Entries',
                              message: 'Fund movements will appear here once funds are added or allocated.',
                            )
                          : AppStateView.empty(
                              title: 'No Matching Movements',
                              message: 'No fund movements match your selected filters.',
                              actionLabel: 'Clear Filters',
                              onAction: _clearFilters,
                            ))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filteredRows.length,
                        itemBuilder: (context, index) {
                          final row = filteredRows[index];
                          return _buildLedgerItem(
                            row,
                            index == filteredRows.length - 1,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('ledgerSearchField'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by purpose, reference, or type...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildActiveFilterChips(int totalCount, int filteredCount) {
    return AnimatedSize(
      duration: AppMotion.durationFast,
      curve: AppMotion.curveStandard,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 6,
        ),
        color: AppColors.surfaceSubtle,
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$filteredCount of $totalCount rows',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_typeFilter != LedgerTypeFilter.all)
                    Chip(
                      label: Text(
                        _typeFilter == LedgerTypeFilter.systemGenerated
                            ? 'System-generated'
                            : 'Manual',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onDeleted: () {
                        setState(() {
                          _typeFilter = LedgerTypeFilter.all;
                        });
                      },
                    ),
                  if (_specificType != null)
                    Chip(
                      label: Text(
                        fundMovementTypeLabel(_specificType!),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onDeleted: () {
                        setState(() {
                          _specificType = null;
                        });
                      },
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${formatDate(_dateRange!.start)} – ${formatDate(_dateRange!.end)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onDeleted: () {
                        setState(() {
                          _dateRange = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(0, 28),
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerItem(TreasuryLedgerRow row, bool isLast) {
    return ExpandableListRow(
      key: Key('ledgerRow${row.id}'),
      leading: Icon(
        row.isSystemGenerated ? Icons.lock_outline : Icons.edit_note,
        color: row.isSystemGenerated ? AppColors.info : AppColors.warning,
        size: 20,
      ),
      title: Text(
        row.purpose,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${row.reference} · ${row.typeLabel} · ${row.dateLabel}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
      ),
      trailing: Text(
        row.amountLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: AppColors.textPrimary,
        ),
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
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
            ],
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

  void _openFilterSheet() {
    var tempTypeFilter = _typeFilter;
    var tempSpecificType = _specificType;
    var tempDateRange = _dateRange;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Ledger',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempTypeFilter = LedgerTypeFilter.all;
                              tempSpecificType = null;
                              tempDateRange = null;
                            });
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Origin Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<LedgerTypeFilter>(
                      segments: const [
                        ButtonSegment(
                          value: LedgerTypeFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: LedgerTypeFilter.systemGenerated,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: LedgerTypeFilter.manual,
                          label: Text('Manual'),
                        ),
                      ],
                      selected: {tempTypeFilter},
                      onSelectionChanged: (selection) {
                        setSheetState(() {
                          tempTypeFilter = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Movement Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FundMovementType?>(
                      initialValue: tempSpecificType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'All movement types',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<FundMovementType?>(
                          value: null,
                          child: Text('All movement types'),
                        ),
                        ...FundMovementType.values.map(
                          (type) => DropdownMenuItem<FundMovementType?>(
                            value: type,
                            child: Text(
                              fundMovementTypeLabel(type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          tempSpecificType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        tempDateRange == null
                            ? 'Any Date'
                            : '${formatDate(tempDateRange!.start)} – ${formatDate(tempDateRange!.end)}',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: tempDateRange,
                        );
                        if (picked != null) {
                          setSheetState(() {
                            tempDateRange = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('applyLedgerFilterButton'),
                      onPressed: () {
                        setState(() {
                          _typeFilter = tempTypeFilter;
                          _specificType = tempSpecificType;
                          _dateRange = tempDateRange;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
