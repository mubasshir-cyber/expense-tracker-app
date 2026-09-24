import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/khata_entry_type.dart';
import '../../domain/services/khata_calculation_service.dart';
import '../models/khata_customer_model.dart';
import '../models/khata_entry_model.dart';

/// Data repository for Khata Customers and Ledger Entries with soft deletion and user isolation.
class KhataRepository {
  const KhataRepository(
    this._client, {
    this.calculationService = const KhataCalculationService(),
  });

  final SupabaseClient _client;
  final KhataCalculationService calculationService;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Fetches all active customers for current user.
  Future<List<KhataCustomerModel>> getCustomers({bool activeOnly = true}) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    var query = _client.from('khata_customers').select().eq('user_id', userId);

    if (activeOnly) {
      query = query.filter('deleted_at', 'is', null);
    }

    final response = await query.order('name', ascending: true);
    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map((m) => KhataCustomerModel.fromMap(m)).toList();
  }

  /// Fetches a single customer by ID.
  Future<KhataCustomerModel?> getCustomerById(String customerId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('khata_customers')
        .select()
        .eq('id', customerId)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return KhataCustomerModel.fromMap(response);
  }

  /// Creates a new customer and optionally initializes an Opening Balance GIVEN entry.
  Future<KhataCustomerModel> createCustomer(
    KhataCustomerModel customer, {
    double? openingBalance,
    String? openingBalanceDescription,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User must be authenticated to create a customer.');
    }

    // 1. Try atomic RPC if opening balance is provided
    if (openingBalance != null && openingBalance > 0) {
      try {
        final rpcResult = await _client.rpc(
          'create_khata_customer_with_opening',
          params: {
            'p_name': customer.name,
            'p_phone': customer.phone,
            'p_address': customer.address,
            'p_notes': customer.notes,
            'p_opening_balance': openingBalance,
            'p_opening_description': openingBalanceDescription?.trim().isNotEmpty == true
                ? openingBalanceDescription!.trim()
                : 'Opening Balance',
          },
        );
        if (rpcResult != null && rpcResult is Map<String, dynamic>) {
          return KhataCustomerModel.fromMap(rpcResult);
        }
      } catch (_) {
        // Fall back to direct multi-step insert with cleanup
      }
    }

    final customerData = customer.toMap();
    customerData['user_id'] = userId;
    customerData['created_by'] = userId;
    customerData.remove('deleted_at');

    final response = await _client
        .from('khata_customers')
        .insert(customerData)
        .select()
        .single();

    final createdCustomer = KhataCustomerModel.fromMap(response);

    // If opening balance is specified (>0), create an initial GIVEN ledger entry
    if (openingBalance != null && openingBalance > 0) {
      try {
        final openingEntry = KhataEntryModel(
          id: '',
          userId: userId,
          customerId: createdCustomer.id,
          type: KhataEntryType.given,
          amount: openingBalance,
          description: openingBalanceDescription?.trim().isNotEmpty == true
              ? openingBalanceDescription!.trim()
              : 'Opening Balance',
          entryDate: customer.createdAt,
          isOpeningBalance: true,
          createdAt: customer.createdAt,
        );

        await createEntry(openingEntry);
      } catch (e) {
        // In case entry fails, clean up created customer to avoid inconsistent state
        await _client.from('khata_customers').delete().eq('id', createdCustomer.id);
        rethrow;
      }
    }

    return createdCustomer;
  }

  /// Updates customer details (name, phone, address, notes).
  Future<KhataCustomerModel> updateCustomer(KhataCustomerModel customer) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User must be authenticated to update customer.');
    }

    final updateData = {
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'notes': customer.notes,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': userId,
    };

    final response = await _client
        .from('khata_customers')
        .update(updateData)
        .eq('id', customer.id)
        .eq('user_id', userId)
        .select()
        .single();

    return KhataCustomerModel.fromMap(response);
  }

  /// Soft deletes a customer and all their ledger entries.
  Future<void> deleteCustomer(String customerId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now().toIso8601String();

    // 1. Soft delete customer
    await _client.from('khata_customers').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('id', customerId).eq('user_id', userId);

    // 2. Soft delete all associated entries
    await _client.from('khata_entries').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('customer_id', customerId).eq('user_id', userId);
  }

  /// Fetches all active entries for a specific customer.
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('khata_entries')
        .select()
        .eq('customer_id', customerId)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('entry_date', ascending: true)
        .order('created_at', ascending: true);

    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map((m) => KhataEntryModel.fromMap(m)).toList();
  }

  /// Fetches all active ledger entries across all customers for summary computations.
  Future<List<KhataEntryModel>> getAllEntries() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('khata_entries')
        .select()
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null);

    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map((m) => KhataEntryModel.fromMap(m)).toList();
  }

  /// Creates a new ledger entry.
  Future<KhataEntryModel> createEntry(KhataEntryModel entry) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User must be authenticated to create a ledger entry.');
    }

    final entryData = entry.toMap();
    if (entry.id.isEmpty) {
      entryData.remove('id');
    }
    entryData['user_id'] = userId;
    entryData['created_by'] = userId;
    entryData.remove('deleted_at');

    final response = await _client
        .from('khata_entries')
        .insert(entryData)
        .select()
        .single();

    return KhataEntryModel.fromMap(response);
  }

  /// Updates an existing ledger entry.
  Future<KhataEntryModel> updateEntry(KhataEntryModel entry) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User must be authenticated to update entry.');
    }

    final updateData = {
      'type': entry.type.value,
      'amount': entry.amount,
      'description': entry.description,
      'entry_date': entry.entryDate.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': userId,
    };

    final response = await _client
        .from('khata_entries')
        .update(updateData)
        .eq('id', entry.id)
        .eq('user_id', userId)
        .select()
        .single();

    return KhataEntryModel.fromMap(response);
  }

  /// Soft deletes a ledger entry.
  Future<void> deleteEntry(String entryId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now().toIso8601String();
    await _client.from('khata_entries').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('id', entryId).eq('user_id', userId);
  }
}
