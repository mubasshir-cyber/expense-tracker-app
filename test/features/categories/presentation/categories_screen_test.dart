import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/categories/presentation/categories_screen.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_repository_provider.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';

class FakeCategoryRepository extends Fake implements CategoryRepository {
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;

  String? lastCreatedName;
  String? lastCreatedType;
  String? lastCreatedIcon;
  String? lastDeletedId;

  @override
  Future<List<CategoryModel>> getCategories({String? type}) async {
    return [];
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    createCalled = true;
    lastCreatedName = name;
    lastCreatedType = type;
    lastCreatedIcon = icon;
    return CategoryModel(
      id: 'cat-new',
      userId: 'user-1',
      name: name,
      type: type,
      icon: icon,
      isActive: true,
    );
  }

  @override
  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
  }) async {
    updateCalled = true;
    return CategoryModel(
      id: categoryId,
      userId: 'user-1',
      name: name ?? 'Category',
      type: 'EXPENSE',
      icon: icon,
      isActive: true,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    deleteCalled = true;
    lastDeletedId = categoryId;
  }
}

void main() {
  const testExpenseCategories = [
    CategoryModel(
      id: 'cat-sys-1',
      userId: '', // System default
      name: 'Food & Dining',
      type: 'EXPENSE',
      icon: 'food',
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-usr-1',
      userId: 'user-1', // Custom user category
      name: 'Gym & Fitness',
      type: 'EXPENSE',
      icon: 'health',
      isActive: true,
    ),
  ];

  const testCreditCategories = [
    CategoryModel(
      id: 'cat-sys-2',
      userId: '', // System default
      name: 'Salary',
      type: 'CREDIT',
      icon: 'salary',
      isActive: true,
    ),
  ];

  late FakeCategoryRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeCategoryRepository();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(fakeRepo),
        expenseCategoriesProvider.overrideWith((ref) => Future.value(testExpenseCategories)),
        incomeCategoriesProvider.overrideWith((ref) => Future.value(testCreditCategories)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const CategoriesScreen(),
      ),
    );
  }

  group('CategoriesScreen — 5.6 Categories Management', () {
    testWidgets('renders expense and credit tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income / Credit'), findsOneWidget);

      // On expenses tab initially
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Gym & Fitness'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget); // System badge
    });

    testWidgets('switches to Income tab and shows credit categories', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income / Credit'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('creates new custom category via bottom sheet', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name *'),
        'Books',
      );

      // Save
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      expect(fakeRepo.createCalled, isTrue);
      expect(fakeRepo.lastCreatedName, 'Books');
      expect(fakeRepo.lastCreatedType, 'EXPENSE');
    });

    testWidgets('deletes custom category after confirmation', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap popup menu on user custom category (the only more_vert icon because system has lock icon)
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Category?'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deleteCalled, isTrue);
      expect(fakeRepo.lastDeletedId, 'cat-usr-1');
    });
  });
}
