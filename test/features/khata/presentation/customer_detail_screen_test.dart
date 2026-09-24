import 'package:expense_tracker/features/khata/data/models/khata_customer_model.dart';
import 'package:expense_tracker/features/khata/data/models/khata_entry_model.dart';
import 'package:expense_tracker/features/khata/domain/models/khata_entry_type.dart';
import 'package:expense_tracker/features/khata/presentation/providers/khata_providers.dart';
import 'package:expense_tracker/features/khata/presentation/screens/customer_detail_screen.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final customer = KhataCustomerModel(
    id: 'cust-ahmed',
    userId: 'user-1',
    name: 'Ahmed',
    phone: '9876543210',
    notes: 'Preferred client',
    createdAt: DateTime(2026, 9, 1),
  );

  final entryOpening = KhataEntryModel(
    id: 'e1',
    userId: 'user-1',
    customerId: 'cust-ahmed',
    type: KhataEntryType.given,
    amount: 800.0,
    isOpeningBalance: true,
    description: 'Initial Balance',
    entryDate: DateTime(2026, 9, 20),
    createdAt: DateTime(2026, 9, 20, 10, 0),
  );

  final entrySale = KhataEntryModel(
    id: 'e2',
    userId: 'user-1',
    customerId: 'cust-ahmed',
    type: KhataEntryType.given,
    amount: 150.0,
    isOpeningBalance: false,
    description: 'Goods credit',
    entryDate: DateTime(2026, 9, 24),
    createdAt: DateTime(2026, 9, 24, 11, 0),
  );

  final entryPayment = KhataEntryModel(
    id: 'e3',
    userId: 'user-1',
    customerId: 'cust-ahmed',
    type: KhataEntryType.received,
    amount: 50.0,
    isOpeningBalance: false,
    description: 'UPI Payment',
    entryDate: DateTime(2026, 9, 24),
    createdAt: DateTime(2026, 9, 24, 12, 0),
  );

  Widget createWidgetUnderTest({
    KhataCustomerModel? currentCustomer,
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
        customerProvider('cust-ahmed').overrideWith((ref) async => currentCustomer),
        customerEntriesProvider('cust-ahmed').overrideWith((ref) async => entries),
      ],
      child: const MaterialApp(
        home: CustomerDetailScreen(customerId: 'cust-ahmed'),
      ),
    );
  }

  testWidgets('Renders customer details, balance card, and ledger entries with correct running balance', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      currentCustomer: customer,
      entries: [entryOpening, entrySale, entryPayment],
    ));
    await tester.pumpAndSettle();

    // Verify Customer Info
    expect(find.text('Ahmed'), findsAtLeastNWidgets(1));
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Preferred client'), findsOneWidget);

    // Verify Balance Card
    expect(find.text('CURRENT DUE'), findsOneWidget);
    expect(find.text('₹ 900.00'), findsAtLeastNWidgets(1));
    expect(find.text('+ GIVEN'), findsOneWidget);
    expect(find.text('+ RECEIVED'), findsOneWidget);

    // Verify Ledger Entries
    expect(find.text('Initial Balance'), findsOneWidget);
    expect(find.text('Goods credit'), findsOneWidget);
    expect(find.text('UPI Payment'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
  });

  testWidgets('Opens Add Entry sheet when Give Credit button is tapped', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      currentCustomer: customer,
      entries: [entryOpening],
    ));
    await tester.pumpAndSettle();

    final giveCreditButton = find.text('+ GIVEN');
    expect(giveCreditButton, findsOneWidget);
    await tester.tap(giveCreditButton);
    await tester.pumpAndSettle();

    expect(find.text('You Gave (Credit)'), findsOneWidget);
    expect(find.text('Amount *'), findsOneWidget);
  });
}
