import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/khata_customer_model.dart';
import '../../data/models/khata_entry_model.dart';
import '../../data/repositories/khata_repository.dart';
import '../../domain/models/customer_ledger_models.dart';
import '../../domain/models/khata_entry_type.dart';
import '../../domain/services/khata_calculation_service.dart';

final khataCalculationServiceProvider = Provider<KhataCalculationService>((ref) {
  return const KhataCalculationService();
});

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  final client = Supabase.instance.client;
  final calculationService = ref.watch(khataCalculationServiceProvider);
  return KhataRepository(client, calculationService: calculationService);
});

/// Fetches all active customers.
final khataCustomersProvider = FutureProvider<List<KhataCustomerModel>>((ref) async {
  final repo = ref.watch(khataRepositoryProvider);
  return repo.getCustomers();
});

/// Fetches all active entries for portfolio summary calculations.
final khataAllEntriesProvider = FutureProvider<List<KhataEntryModel>>((ref) async {
  final repo = ref.watch(khataRepositoryProvider);
  return repo.getAllEntries();
});

/// Fetches entries for a specific customer.
final customerEntriesProvider =
    FutureProvider.family<List<KhataEntryModel>, String>((ref, customerId) async {
  final repo = ref.watch(khataRepositoryProvider);
  return repo.getEntriesForCustomer(customerId);
});

/// Fetches a specific customer by ID.
final customerProvider =
    FutureProvider.family<KhataCustomerModel?, String>((ref, customerId) async {
  final repo = ref.watch(khataRepositoryProvider);
  return repo.getCustomerById(customerId);
});

/// Computes the chronological ledger items with running balances for a specific customer.
final customerLedgerProvider =
    Provider.family<List<CustomerLedgerItem>, String>((ref, customerId) {
  final entriesAsync = ref.watch(customerEntriesProvider(customerId));
  final calcService = ref.watch(khataCalculationServiceProvider);
  final entries = entriesAsync.value ?? [];
  return calcService.computeLedgerWithRunningBalances(entries);
});

/// Computes the balance summary for a single customer.
final customerSummaryProvider =
    Provider.family<CustomerBalanceSummary?, String>((ref, customerId) {
  final customerAsync = ref.watch(customerProvider(customerId));
  final entriesAsync = ref.watch(customerEntriesProvider(customerId));
  final calcService = ref.watch(khataCalculationServiceProvider);

  final customer = customerAsync.value;
  if (customer == null) return null;
  final entries = entriesAsync.value ?? [];
  return calcService.calculateCustomerSummary(customer, entries);
});

/// Alias for customerSummaryProvider.
final customerBalanceProvider = customerSummaryProvider;

/// Computes balance summaries for all active customers.
final allCustomersSummaryProvider = Provider<List<CustomerBalanceSummary>>((ref) {
  final customersAsync = ref.watch(khataCustomersProvider);
  final entriesAsync = ref.watch(khataAllEntriesProvider);
  final calcService = ref.watch(khataCalculationServiceProvider);

  final customers = customersAsync.value ?? [];
  final entries = entriesAsync.value ?? [];

  return customers.map((c) => calcService.calculateCustomerSummary(c, entries)).toList();
});

/// Computes overall portfolio summary (total receivables, advances, counts).
final khataOverallSummaryProvider = Provider<KhataOverallSummary>((ref) {
  final customersAsync = ref.watch(khataCustomersProvider);
  final entriesAsync = ref.watch(khataAllEntriesProvider);
  final calcService = ref.watch(khataCalculationServiceProvider);

  final customers = customersAsync.value ?? [];
  final entries = entriesAsync.value ?? [];

  return calcService.calculateOverallSummary(customers, entries);
});

/// Search text query state for filtering customer list.
final khataSearchQueryProvider = StateProvider<String>((ref) => '');

/// Balance status filter state (all, due, settled, advance).
final khataStatusFilterProvider = StateProvider<CustomerBalanceStatus?>((ref) => null);

/// Filtered customer summaries based on query and status filter.
final filteredCustomerSummariesProvider = Provider<List<CustomerBalanceSummary>>((ref) {
  final allSummaries = ref.watch(allCustomersSummaryProvider);
  final query = ref.watch(khataSearchQueryProvider);
  final filterStatus = ref.watch(khataStatusFilterProvider);
  final calcService = ref.watch(khataCalculationServiceProvider);

  return calcService.filterCustomers(
    allSummaries,
    query: query,
    filterStatus: filterStatus,
  );
});

/// Controller for Khata operations and state invalidation.
class KhataController extends StateNotifier<AsyncValue<void>> {
  KhataController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  KhataRepository get _repository => _ref.read(khataRepositoryProvider);

  void _invalidateAll([String? customerId]) {
    _ref.invalidate(khataCustomersProvider);
    _ref.invalidate(khataAllEntriesProvider);
    if (customerId != null) {
      _ref.invalidate(customerEntriesProvider(customerId));
    }
  }

  Future<KhataCustomerModel?> createCustomer({
    required String name,
    required String phone,
    String? address,
    String? notes,
    double? openingBalance,
    String? openingBalanceDescription,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newCustomer = KhataCustomerModel(
        id: '',
        userId: '',
        name: name.trim(),
        phone: phone.trim(),
        address: address?.trim().isNotEmpty == true ? address!.trim() : null,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createCustomer(
        newCustomer,
        openingBalance: openingBalance,
        openingBalanceDescription: openingBalanceDescription,
      );

      _invalidateAll();
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateCustomer(KhataCustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCustomer(customer);
      _invalidateAll(customer.id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCustomer(customerId);
      _invalidateAll(customerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addEntry({
    required String customerId,
    required KhataEntryType type,
    required double amount,
    required DateTime entryDate,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entry = KhataEntryModel(
        id: '',
        userId: '',
        customerId: customerId,
        type: type,
        amount: amount,
        description: description?.trim().isNotEmpty == true ? description!.trim() : null,
        entryDate: entryDate,
        createdAt: DateTime.now(),
      );

      await _repository.createEntry(entry);
      _invalidateAll(customerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateEntry(KhataEntryModel entry) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateEntry(entry);
      _invalidateAll(entry.customerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteEntry({required String entryId, required String customerId}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteEntry(entryId);
      _invalidateAll(customerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final khataControllerProvider =
    StateNotifierProvider<KhataController, AsyncValue<void>>((ref) {
  return KhataController(ref);
});
