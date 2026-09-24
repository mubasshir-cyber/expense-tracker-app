import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/khata_customer_model.dart';
import '../../data/models/khata_entry_model.dart';
import '../../domain/models/customer_ledger_models.dart';
import '../../domain/models/khata_entry_type.dart';
import '../providers/khata_providers.dart';
import '../widgets/add_edit_customer_sheet.dart';
import '../widgets/customer_balance_card.dart';
import '../widgets/khata_entry_sheet.dart';
import '../widgets/ledger_entry_tile.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  KhataEntryType? _typeFilter;

  void _showAddEntrySheet({
    required BuildContext context,
    required KhataCustomerModel customer,
    required KhataEntryType initialType,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KhataEntrySheet(
        customerId: customer.id,
        initialType: initialType,
      ),
    );
  }

  void _showEditEntrySheet({
    required BuildContext context,
    required KhataCustomerModel customer,
    required KhataEntryModel entry,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KhataEntrySheet(
        customerId: customer.id,
        entryToEdit: entry,
      ),
    );
  }

  void _showEditCustomerSheet({
    required BuildContext context,
    required KhataCustomerModel customer,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditCustomerSheet(customerToEdit: customer),
    );
  }

  Future<void> _confirmDeleteCustomer(KhataCustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.name}"?\n\n'
          'This will safely archive the customer and preserve historical entries for audit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(khataControllerProvider.notifier).deleteCustomer(customer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer "${customer.name}" deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _confirmDeleteEntry(KhataEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          entry.isOpeningBalance
              ? 'Are you sure you want to delete this opening balance entry?'
              : 'Are you sure you want to delete this ${entry.type.displayName} entry of ₹${entry.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(khataControllerProvider.notifier).deleteEntry(
            entryId: entry.id,
            customerId: entry.customerId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ledger entry deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final balanceSummary = ref.watch(customerBalanceProvider(widget.customerId));
    final ledgerItems = ref.watch(customerLedgerProvider(widget.customerId));

    return customerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.expense),
              const SizedBox(height: 16),
              Text('Error loading customer: $err'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(customerProvider(widget.customerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.userX, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Customer does not exist or was deleted.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = balanceSummary ??
            CustomerBalanceSummary(
              customer: customer,
              totalGiven: 0.0,
              totalReceived: 0.0,
              currentBalance: 0.0,
              status: CustomerBalanceStatus.settled,
              lastEntryDate: null,
              entriesCount: 0,
            );

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.fileText),
                tooltip: 'Customer Statement',
                onPressed: () => context.push('/khata/customer/${customer.id}/statement'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCustomerSheet(context: context, customer: customer);
                  } else if (value == 'statement') {
                    context.push('/khata/customer/${customer.id}/statement');
                  } else if (value == 'delete') {
                    _confirmDeleteCustomer(customer);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.pencil, size: 18),
                        SizedBox(width: 12),
                        Text('Edit Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'statement',
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileSpreadsheet, size: 18),
                        SizedBox(width: 12),
                        Text('View Statement'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 18, color: AppColors.expense),
                        SizedBox(width: 12),
                        Text('Delete Customer', style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerProvider(widget.customerId));
              ref.invalidate(customerEntriesProvider(widget.customerId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ── 1. Customer Contact & Info Header ────────────────────────
                _buildCustomerHeaderCard(context, customer),
                const SizedBox(height: 16),

                // ── 2. Customer Balance Card & Quick Actions ─────────────────
                CustomerBalanceCard(
                  summary: summary,
                  onAddGiven: () => _showAddEntrySheet(
                    context: context,
                    customer: customer,
                    initialType: KhataEntryType.given,
                  ),
                  onAddReceived: () => _showAddEntrySheet(
                    context: context,
                    customer: customer,
                    initialType: KhataEntryType.received,
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3. Ledger Section Header & Statement Button ──────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRANSACTION LEDGER',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/khata/customer/${customer.id}/statement'),
                      icon: const Icon(LucideIcons.externalLink, size: 14),
                      label: const Text('Full Statement', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── 4. Ledger Filters ────────────────────────────────────────
                _buildFilterChips(theme),
                const SizedBox(height: 12),

                // ── 5. Ledger Entries List (Reverse-Chronological display for log view) ──
                Builder(
                  builder: (ctx) {
                    var filteredItems = ledgerItems;

                    // Filter by type if set
                    if (_typeFilter != null) {
                      filteredItems = filteredItems
                          .where((item) => item.entry.type == _typeFilter)
                          .toList();
                    }

                    if (filteredItems.isEmpty) {
                      return _buildEmptyLedgerState(context, customer);
                    }

                    // Display newest entries on top for easy review
                    final displayList = filteredItems.reversed.toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (sepCtx, index) => const SizedBox(height: 10),
                      itemBuilder: (itemCtx, index) {
                        final item = displayList[index];
                        return LedgerEntryTile(
                          item: item,
                          onEdit: () => _showEditEntrySheet(
                            context: context,
                            customer: customer,
                            entry: item.entry,
                          ),
                          onDelete: () => _confirmDeleteEntry(item.entry),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerHeaderCard(BuildContext context, KhataCustomerModel customer) {
    final theme = Theme.of(context);
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            customer.phone,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Entries'),
            selected: _typeFilter == null,
            onSelected: (_) => setState(() => _typeFilter = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Given / Credit'),
            avatar: const Icon(LucideIcons.arrowUpRight, size: 14, color: AppColors.expense),
            selected: _typeFilter == KhataEntryType.given,
            onSelected: (_) => setState(() => _typeFilter = KhataEntryType.given),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Received / Payment'),
            avatar: const Icon(LucideIcons.arrowDownLeft, size: 14, color: AppColors.credit),
            selected: _typeFilter == KhataEntryType.received,
            onSelected: (_) => setState(() => _typeFilter = KhataEntryType.received),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLedgerState(BuildContext context, KhataCustomerModel customer) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.receipt,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ledger entries found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record credit given or payment received to start this khata.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAddEntrySheet(
                    context: context,
                    customer: customer,
                    initialType: KhataEntryType.given,
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Give Credit'),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddEntrySheet(
                    context: context,
                    customer: customer,
                    initialType: KhataEntryType.received,
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Receive Payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
