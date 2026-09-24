import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_repository_provider.dart';
import '../../domain/models/customer_ledger_models.dart';
import '../providers/khata_providers.dart';
import '../widgets/add_edit_customer_sheet.dart';
import '../widgets/customer_card.dart';
import '../widgets/khata_summary_card.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerSheet() {
    final profile = ref.read(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddEditCustomerSheet(currencySymbol: currencySymbol),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overallSummary = ref.watch(khataOverallSummaryProvider);
    final filteredSummaries = ref.watch(filteredCustomerSummariesProvider);
    final customersAsync = ref.watch(khataCustomersProvider);
    final entriesAsync = ref.watch(khataAllEntriesProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';

    final statusFilter = ref.watch(khataStatusFilterProvider);
    final allCustomers = customersAsync.value ?? [];

    final isLoading = customersAsync.isLoading || entriesAsync.isLoading;
    final hasError = customersAsync.hasError || entriesAsync.hasError;
    final errorMessage = customersAsync.error ?? entriesAsync.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata / Customer Ledger'),
        actions: [
          IconButton(
            key: const Key('add_customer_appbar_button'),
            icon: const Icon(LucideIcons.userPlus, size: 20),
            tooltip: 'Add Customer',
            onPressed: _showAddCustomerSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_customer_fab'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddCustomerSheet,
        icon: const Icon(LucideIcons.userPlus, size: 18),
        label: const Text('Add Customer'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(khataCustomersProvider);
          ref.invalidate(khataAllEntriesProvider);
        },
        child: isLoading && !customersAsync.hasValue
            ? const Center(child: CircularProgressIndicator())
            : hasError && !customersAsync.hasValue
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load Khata ledger',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$errorMessage',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              ref.invalidate(khataCustomersProvider);
                              ref.invalidate(khataAllEntriesProvider);
                            },
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // 1. Overall Summary Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: KhataSummaryCard(
                            summary: overallSummary,
                            currencySymbol: currencySymbol,
                          ),
                        ),
                      ),

                // 2. Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: [
                        // Search text field
                        TextField(
                          key: const Key('khata_search_field'),
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search customer by name or phone...',
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(khataSearchQueryProvider.notifier).state = '';
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            ref.read(khataSearchQueryProvider.notifier).state = val;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 10),

                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Customers'),
                                selected: statusFilter == null,
                                onSelected: (_) {
                                  ref.read(khataStatusFilterProvider.notifier).state = null;
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text('Due Pending (${overallSummary.activeCustomersWithDue})'),
                                selected: statusFilter == CustomerBalanceStatus.due,
                                selectedColor: AppColors.error.withValues(alpha: 0.15),
                                onSelected: (_) {
                                  ref.read(khataStatusFilterProvider.notifier).state =
                                      statusFilter == CustomerBalanceStatus.due
                                          ? null
                                          : CustomerBalanceStatus.due;
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text('Settled (${overallSummary.settledCustomersCount})'),
                                selected: statusFilter == CustomerBalanceStatus.settled,
                                selectedColor: AppColors.credit.withValues(alpha: 0.15),
                                onSelected: (_) {
                                  ref.read(khataStatusFilterProvider.notifier).state =
                                      statusFilter == CustomerBalanceStatus.settled
                                          ? null
                                          : CustomerBalanceStatus.settled;
                                },
                              ),
                              if (overallSummary.advanceCustomersCount > 0) ...[
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text('Advance (${overallSummary.advanceCustomersCount})'),
                                  selected: statusFilter == CustomerBalanceStatus.advance,
                                  onSelected: (_) {
                                    ref.read(khataStatusFilterProvider.notifier).state =
                                        statusFilter == CustomerBalanceStatus.advance
                                            ? null
                                            : CustomerBalanceStatus.advance;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Customer List
                if (filteredSummaries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(
                                LucideIcons.users,
                                size: 40,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allCustomers.isEmpty
                                  ? 'No customers in Khata yet'
                                  : 'No customers match your filter',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              allCustomers.isEmpty
                                  ? 'Add your first customer to start tracking credit sales and payments.'
                                  : 'Try adjusting your search query or status filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                            if (allCustomers.isEmpty) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                key: const Key('empty_state_add_customer_button'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: _showAddCustomerSheet,
                                icon: const Icon(LucideIcons.userPlus, size: 16),
                                label: const Text('Add Customer'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final summary = filteredSummaries[index];
                          return CustomerCard(
                            key: ValueKey('customer_card_${summary.customer.id}'),
                            summary: summary,
                            currencySymbol: currencySymbol,
                            onTap: () {
                              context.push('/khata/customer/${summary.customer.id}');
                            },
                          );
                        },
                        childCount: filteredSummaries.length,
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

