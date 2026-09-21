import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/presentation/providers/account_providers.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../domain/models/transaction_model.dart';
import '../domain/models/transaction_type.dart';
import 'providers/data_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  TransactionType? _selectedType;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedType = null;
      _selectedCategoryId = null;
      _selectedAccountId = null;
      _selectedDateRange = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};

    for (final tx in transactions) {
      final key = _formatDateHeader(tx.transactionDate);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allTransactionsAsync = ref.watch(allTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar, size: 20),
            tooltip: 'Filter by date',
            onPressed: _pickDateRange,
          ),
          if (_selectedType != null ||
              _selectedCategoryId != null ||
              _selectedAccountId != null ||
              _selectedDateRange != null ||
              _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.filterX, size: 20),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Chips Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search TextField
                TextField(
                  key: const Key('transaction_search_field'),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by note or description...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('filter_chip_all'),
                        label: const Text('All'),
                        selected: _selectedType == null,
                        labelStyle: TextStyle(
                          color: _selectedType == null
                              ? (isDark ? Colors.white : AppColors.primary)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          fontWeight: _selectedType == null ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_chip_expense'),
                        label: const Text('Expenses'),
                        selected: _selectedType == TransactionType.expense,
                        selectedColor: isDark ? AppColors.expenseContainerDark : AppColors.expenseContainerLight,
                        checkmarkColor: isDark ? const Color(0xFFF87171) : AppColors.expense,
                        labelStyle: TextStyle(
                          color: _selectedType == TransactionType.expense
                              ? (isDark ? const Color(0xFFF87171) : AppColors.expense)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          fontWeight: _selectedType == TransactionType.expense ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? TransactionType.expense : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_chip_credit'),
                        label: const Text('Credits'),
                        selected: _selectedType == TransactionType.credit,
                        selectedColor: isDark ? AppColors.creditContainerDark : AppColors.creditContainerLight,
                        checkmarkColor: isDark ? const Color(0xFF34D399) : AppColors.credit,
                        labelStyle: TextStyle(
                          color: _selectedType == TransactionType.credit
                              ? (isDark ? const Color(0xFF34D399) : AppColors.credit)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          fontWeight: _selectedType == TransactionType.credit ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? TransactionType.credit : null;
                          });
                        },
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            '${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM').format(_selectedDateRange!.end)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Transaction List with Date Grouping
          Expanded(
            child: allTransactionsAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading transactions...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 44, color: AppColors.error),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load transactions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Retry',
                        onPressed: () {
                          ref.invalidate(allTransactionsProvider);
                        },
                        type: AppButtonType.primary,
                      ),
                    ],
                  ),
                ),
              ),
              data: (transactions) {
                final categories = categoriesAsync.value ?? [];
                final accounts = accountsAsync.value ?? [];
                final categoryMap = {for (final c in categories) c.id: c};
                final accountMap = {for (final a in accounts) a.id: a};

                // Filter transactions locally
                final filtered = transactions.where((tx) {
                  // Type filter
                  if (_selectedType != null &&
                      tx.type.toUpperCase() != _selectedType!.value) {
                    return false;
                  }

                  // Category filter
                  if (_selectedCategoryId != null &&
                      tx.categoryId != _selectedCategoryId) {
                    return false;
                  }

                  // Account filter
                  if (_selectedAccountId != null &&
                      tx.accountId != _selectedAccountId) {
                    return false;
                  }

                  // Date range filter
                  if (_selectedDateRange != null) {
                    if (tx.transactionDate.isBefore(_selectedDateRange!.start) ||
                        tx.transactionDate.isAfter(
                          _selectedDateRange!.end.add(const Duration(days: 1)),
                        )) {
                      return false;
                    }
                  }

                  // Search query
                  if (_searchQuery.isNotEmpty) {
                    final category = categoryMap[tx.categoryId];
                    final catName = category?.name.toLowerCase() ?? '';
                    final desc = tx.description?.toLowerCase() ?? '';
                    if (!catName.contains(_searchQuery) &&
                        !desc.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.receiptText, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions recorded yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button below to log your first transaction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No matching transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try clearing filters or search terms.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = _groupTransactions(filtered);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allTransactionsProvider);
                    ref.invalidate(overallSummaryProvider);
                    ref.invalidate(currentMonthSummaryProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, groupIndex) {
                      final header = grouped.keys.elementAt(groupIndex);
                      final items = grouped[header]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Text(
                              header.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                          ...items.map((tx) {
                            final category = categoryMap[tx.categoryId];
                            final account = accountMap[tx.accountId];
                            final isCredit = tx.type.toUpperCase() == 'CREDIT';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: AppCard(
                                onTap: () {
                                  context.push('/add-transaction', extra: tx);
                                },
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                borderRadius: 14,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isCredit
                                            ? AppColors.creditContainerLight
                                            : AppColors.expenseContainerLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isCredit
                                            ? LucideIcons.arrowDownLeft
                                            : LucideIcons.arrowUpRight,
                                        size: 20,
                                        color: isCredit ? AppColors.credit : AppColors.expense,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category?.name ?? 'General',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (tx.description != null &&
                                                  tx.description!.trim().isNotEmpty)
                                                tx.description!.trim(),
                                              if (account != null) account.name,
                                              if (tx.paymentMethod != null &&
                                                  tx.paymentMethod!.isNotEmpty)
                                                tx.paymentMethod!,
                                            ].join(' • '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AmountDisplay(
                                      amount: tx.amount,
                                      currencySymbol: currencySymbol,
                                      isCredit: isCredit,
                                      isExpense: !isCredit,
                                      showSign: true,
                                      size: AmountSize.medium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
