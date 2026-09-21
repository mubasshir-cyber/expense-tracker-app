import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../transactions/presentation/providers/data_providers.dart';
import '../domain/models/category_model.dart';
import 'providers/category_repository_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog({CategoryModel? category, String? defaultType}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AddEditCategorySheet(
        category: category,
        defaultType: defaultType ?? (_tabController.index == 0 ? 'EXPENSE' : 'CREDIT'),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Existing transactions with this category will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(categoryRepositoryProvider);
        await repo.deleteCategory(category.id);

        ref.invalidate(categoriesProvider);
        ref.invalidate(expenseCategoriesProvider);
        ref.invalidate(incomeCategoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete category: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income / Credit'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryListView(
            categoriesAsync: ref.watch(expenseCategoriesProvider),
            onRefresh: () async => ref.invalidate(expenseCategoriesProvider),
            onEdit: (cat) => _showAddEditCategoryDialog(category: cat),
            onDelete: (cat) => _confirmDeleteCategory(cat),
            emptyLabel: 'No expense categories found',
          ),
          _CategoryListView(
            categoriesAsync: ref.watch(incomeCategoriesProvider),
            onRefresh: () async => ref.invalidate(incomeCategoriesProvider),
            onEdit: (cat) => _showAddEditCategoryDialog(category: cat),
            onDelete: (cat) => _confirmDeleteCategory(cat),
            emptyLabel: 'No income categories found',
          ),
        ],
      ),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  const _CategoryListView({
    required this.categoriesAsync,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.emptyLabel,
  });

  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final Future<void> Function() onRefresh;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;
  final String emptyLabel;

  IconData _getCategoryIcon(String? iconName, String type) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'food':
        case 'dining':
        case 'restaurant':
          return Icons.restaurant_rounded;
        case 'transport':
        case 'commute':
        case 'travel':
          return Icons.directions_car_rounded;
        case 'shopping':
          return Icons.shopping_bag_rounded;
        case 'bills':
        case 'utilities':
          return Icons.receipt_long_rounded;
        case 'entertainment':
          return Icons.movie_rounded;
        case 'salary':
          return Icons.account_balance_wallet_rounded;
        case 'freelance':
        case 'business':
          return Icons.work_outline_rounded;
        case 'investment':
          return Icons.trending_up_rounded;
        case 'gift':
          return Icons.card_giftcard_rounded;
        case 'health':
        case 'medical':
          return Icons.local_hospital_rounded;
        case 'education':
          return Icons.school_rounded;
      }
    }
    return type.toUpperCase() == 'CREDIT'
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRefresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSystem = cat.userId.isEmpty || cat.userId == 'system';
              final iconData = _getCategoryIcon(cat.icon, cat.type);
              final isCredit = cat.type.toUpperCase() == 'CREDIT';

              return AppCard(
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isCredit
                          ? AppColors.credit.withValues(alpha: 0.12)
                          : AppColors.expense.withValues(alpha: 0.12),
                      child: Icon(
                        iconData,
                        color: isCredit ? AppColors.credit : AppColors.expense,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (isSystem)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    trailing: isSystem
                        ? const Tooltip(
                            message: 'System categories cannot be modified',
                            child: Icon(Icons.lock_outline_rounded, size: 20, color: Colors.grey),
                          )
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(cat);
                              } else if (value == 'delete') {
                                onDelete(cat);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 20, color: Theme.of(context).colorScheme.error),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AddEditCategorySheet extends ConsumerStatefulWidget {
  const _AddEditCategorySheet({
    this.category,
    this.defaultType = 'EXPENSE',
  });

  final CategoryModel? category;
  final String defaultType;

  @override
  ConsumerState<_AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<_AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  late String _selectedIcon;
  bool _isSaving = false;

  final List<String> _availableIcons = [
    'food',
    'transport',
    'shopping',
    'bills',
    'entertainment',
    'salary',
    'freelance',
    'investment',
    'gift',
    'health',
    'education',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type.toUpperCase() ?? widget.defaultType.toUpperCase();
    if (_selectedType != 'CREDIT' && _selectedType != 'EXPENSE') {
      _selectedType = 'EXPENSE';
    }
    _selectedIcon = widget.category?.icon ?? (_selectedType == 'CREDIT' ? 'salary' : 'food');
    if (!_availableIcons.contains(_selectedIcon)) {
      _selectedIcon = _availableIcons.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(categoryRepositoryProvider);

      if (widget.category == null) {
        await repo.createCategory(
          name: _nameController.text.trim(),
          type: _selectedType,
          icon: _selectedIcon,
        );
      } else {
        await repo.updateCategory(
          categoryId: widget.category!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
        );
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(incomeCategoriesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Category created successfully.'
                  : 'Category updated successfully.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save category: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Category' : 'New Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'EXPENSE',
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward_rounded),
                    ),
                    ButtonSegment(
                      value: 'CREDIT',
                      label: Text('Income / Credit'),
                      icon: Icon(Icons.arrow_downward_rounded),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedType = set.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. Groceries, Bonus, Fuel',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedIcon,
                decoration: const InputDecoration(
                  labelText: 'Icon Preset',
                  prefixIcon: Icon(Icons.emoji_symbols_rounded),
                ),
                items: _availableIcons
                    .map(
                      (icon) => DropdownMenuItem(
                        value: icon,
                        child: Row(
                          children: [
                            Text(icon.toUpperCase()),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedIcon = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
