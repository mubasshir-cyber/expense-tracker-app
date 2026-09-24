import 'package:expense_tracker/features/khata/data/models/khata_customer_model.dart';
import 'package:expense_tracker/features/khata/data/models/khata_entry_model.dart';
import 'package:expense_tracker/features/khata/domain/models/khata_entry_type.dart';
import 'package:expense_tracker/features/khata/presentation/providers/khata_providers.dart';
import 'package:expense_tracker/features/khata/presentation/screens/khata_screen.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final customer1 = KhataCustomerModel(
    id: 'cust-1',
    userId: 'user-1',
    name: 'Ahmed',
    phone: '9876543210',
    createdAt: DateTime(2026, 9, 1),
  );

  final customer2 = KhataCustomerModel(
    id: 'cust-2',
    userId: 'user-1',
    name: 'Rahim',
    phone: '9123456780',
    createdAt: DateTime(2026, 9, 2),
  );

  final entry1 = KhataEntryModel(
    id: 'e1',
    userId: 'user-1',
    customerId: 'cust-1',
    type: KhataEntryType.given,
    amount: 900.0,
    isOpeningBalance: true,
    entryDate: DateTime(2026, 9, 20),
    createdAt: DateTime(2026, 9, 20),
  );

  final entry2 = KhataEntryModel(
    id: 'e2',
    userId: 'user-1',
    customerId: 'cust-2',
    type: KhataEntryType.given,
    amount: 500.0,
    entryDate: DateTime(2026, 9, 21),
    createdAt: DateTime(2026, 9, 21),
  );

  final entry3 = KhataEntryModel(
    id: 'e3',
    userId: 'user-1',
    customerId: 'cust-2',
    type: KhataEntryType.received,
    amount: 500.0,
    entryDate: DateTime(2026, 9, 22),
    createdAt: DateTime(2026, 9, 22),
  );

  Widget createWidgetUnderTest({
    List<KhataCustomerModel> customers = const [],
    List<KhataEntryModel> entries = const [],
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'user-1',
            email: 'test@example.com',
            currencyCode: 'INR',
            currencySymbol: '₹',
          ),
        ),
        khataCustomersProvider.overrideWith((ref) async => customers),
        khataAllEntriesProvider.overrideWith((ref) async => entries),
      ],
      child: const MaterialApp(
        home: KhataScreen(),
      ),
    );
  }

  testWidgets('Renders empty state when no customers exist', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(customers: [], entries: []));
    await tester.pumpAndSettle();

    expect(find.text('Khata / Customer Ledger'), findsOneWidget);
    expect(find.text('No customers in Khata yet'), findsOneWidget);
    expect(find.text('Add your first customer to start tracking credit sales and payments.'), findsOneWidget);
    expect(find.byKey(const Key('empty_state_add_customer_button')), findsOneWidget);
  });

  testWidgets('Renders Khata Summary Card and Customer List correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      customers: [customer1, customer2],
      entries: [entry1, entry2, entry3],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Khata / Customer Ledger'), findsOneWidget);
    expect(find.text('TOTAL RECEIVABLE'), findsOneWidget);
    expect(find.text('₹ 900.00'), findsAtLeastNWidgets(1)); // Summary & Ahmed due
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('Settled'), findsAtLeastNWidgets(1));
  });

  testWidgets('Opens Add Customer sheet when FAB is pressed', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      customers: [customer1],
      entries: [entry1],
    ));
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Customer Name *'), findsOneWidget);
    expect(find.text('Mobile Number *'), findsOneWidget);
    expect(find.text('Previous Pending / Opening Due (Optional)'), findsOneWidget);
  });
}
