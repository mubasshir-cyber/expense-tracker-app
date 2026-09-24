import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/debt_installment_model.dart';
import '../../domain/models/debt_model.dart';
import '../../domain/models/debt_repayment_model.dart';
import '../../domain/models/debt_status.dart';
import '../../domain/models/debt_type.dart';
import '../../domain/services/debt_calculation_service.dart';

/// Data repository for debts, loans, installment schedules, and repayment ledgers.
class DebtRepository {
  const DebtRepository(
    this._client, {
    this.calculationService = const DebtCalculationService(),
  });

  final SupabaseClient _client;
  final DebtCalculationService calculationService;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Fetches debts for the current authenticated user with calculated paid balance.
  Future<List<DebtModel>> getDebts({
    bool activeOnly = false,
    DebtType? type,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    var query = _client
        .from('debts')
        .select('*, debt_repayments(*), debt_installments(*)')
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null);

    if (type != null) {
      query = query.eq('type', type.dbValue);
    }

    final response = await query.order('created_at', ascending: false);
    final list = (response as List).cast<Map<String, dynamic>>();

    final debts = <DebtModel>[];
    for (final map in list) {
      final repaymentsRaw = (map['debt_repayments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final activeRepayments = repaymentsRaw.where((r) => r['deleted_at'] == null).toList();
      final repayments = activeRepayments.map((r) => DebtRepaymentModel.fromMap(r)).toList()
        ..sort((a, b) => b.repaymentDate.compareTo(a.repaymentDate));

      final totalPaid = repayments.fold<double>(0.0, (sum, r) => sum + r.amount);

      final installmentsRaw = (map['debt_installments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final activeInstallments = installmentsRaw.where((i) => i['deleted_at'] == null).toList();
      final installments = activeInstallments.map((i) => DebtInstallmentModel.fromMap(i)).toList()
        ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));

      final debt = DebtModel.fromMap(
        map,
        totalPaid: totalPaid,
        installments: installments,
        repayments: repayments,
      );

      if (activeOnly && debt.isSettled) {
        continue;
      }
      debts.add(debt);
    }

    return debts;
  }

  /// Fetches a single debt by ID with its installments and repayment ledger.
  Future<DebtModel?> getDebt(String id) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('debts')
        .select('*, debt_repayments(*), debt_installments(*)')
        .eq('id', id)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    final map = response;

    final repaymentsRaw = (map['debt_repayments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final activeRepayments = repaymentsRaw.where((r) => r['deleted_at'] == null).toList();
    final repayments = activeRepayments.map((r) => DebtRepaymentModel.fromMap(r)).toList()
      ..sort((a, b) => b.repaymentDate.compareTo(a.repaymentDate));

    final totalPaid = repayments.fold<double>(0.0, (sum, r) => sum + r.amount);

    final installmentsRaw = (map['debt_installments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final activeInstallments = installmentsRaw.where((i) => i['deleted_at'] == null).toList();
    final installments = activeInstallments.map((i) => DebtInstallmentModel.fromMap(i)).toList()
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));

    return DebtModel.fromMap(
      map,
      totalPaid: totalPaid,
      installments: installments,
      repayments: repayments,
    );
  }

  /// Creates a new debt/loan and optionally persists its installment schedule.
  Future<DebtModel> createDebt({
    required DebtModel debt,
    List<DebtInstallmentModel> installments = const [],
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User must be logged in to create a debt');

    final debtMap = debt.toMap()..['user_id'] = userId;
    if (debt.id.isEmpty) {
      debtMap.remove('id');
    }

    final createdDebtRaw = await _client
        .from('debts')
        .insert(debtMap)
        .select()
        .single();

    final createdDebtId = createdDebtRaw['id'] as String;

    final createdInstallments = <DebtInstallmentModel>[];
    if (installments.isNotEmpty) {
      final installmentMaps = installments.map((inst) {
        final map = inst.toMap()
          ..['debt_id'] = createdDebtId
          ..['user_id'] = userId;
        // Strip temporary non-UUID client ID so Postgres generates valid UUID
        if (inst.id.isEmpty || inst.id.contains('_inst_')) {
          map.remove('id');
        }
        return map;
      }).toList();

      final response = await _client
          .from('debt_installments')
          .insert(installmentMaps)
          .select();

      final list = (response as List).cast<Map<String, dynamic>>();
      createdInstallments.addAll(list.map((m) => DebtInstallmentModel.fromMap(m)));
    }

    return DebtModel.fromMap(
      createdDebtRaw,
      totalPaid: 0.0,
      installments: createdInstallments,
      repayments: const [],
    );
  }

  /// Updates debt metadata (name, notes, due date, etc.).
  Future<void> updateDebt(DebtModel debt) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User must be logged in to update a debt');

    final debtMap = debt.toMap()..remove('id');
    await _client
        .from('debts')
        .update(debtMap)
        .eq('id', debt.id)
        .eq('user_id', userId);
  }

  /// Soft deletes a debt and cascades soft deletion to installments and repayments.
  Future<void> deleteDebt(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User must be logged in to delete a debt');

    final now = DateTime.now().toIso8601String();

    await _client.from('debts').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('id', id).eq('user_id', userId);

    await _client.from('debt_installments').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('debt_id', id).eq('user_id', userId);

    await _client.from('debt_repayments').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('debt_id', id).eq('user_id', userId);
  }

  /// Fetches installments for a debt.
  Future<List<DebtInstallmentModel>> getInstallments(String debtId) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('debt_installments')
        .select()
        .eq('debt_id', debtId)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('installment_number', ascending: true);

    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map((m) => DebtInstallmentModel.fromMap(m)).toList();
  }

  /// Fetches repayments for a debt.
  Future<List<DebtRepaymentModel>> getRepayments(String debtId) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('debt_repayments')
        .select()
        .eq('debt_id', debtId)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('repayment_date', ascending: false);

    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map((m) => DebtRepaymentModel.fromMap(m)).toList();
  }

  /// Logs a repayment, validates overpayment limits, allocates across installments,
  /// and updates debt status if settled.
  Future<DebtRepaymentModel> addRepayment({
    required String debtId,
    required double amount,
    required DateTime repaymentDate,
    String? accountId,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User must be logged in to record repayment');

    if (amount <= 0) {
      throw ArgumentError('Repayment amount must be strictly greater than 0');
    }

    // 1. Fetch debt to verify remaining balance
    final debt = await getDebt(debtId);
    if (debt == null) throw ArgumentError('Debt not found');

    if (amount > debt.remainingAmount + 0.01) {
      throw ArgumentError(
        'Repayment amount (₹$amount) cannot exceed outstanding balance (₹${debt.remainingAmount})',
      );
    }

    // 2. Insert repayment record
    final repaymentMap = <String, dynamic>{
      'debt_id': debtId,
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'repayment_date': '${repaymentDate.year.toString().padLeft(4, '0')}-${repaymentDate.month.toString().padLeft(2, '0')}-${repaymentDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
    };

    final createdRaw = await _client
        .from('debt_repayments')
        .insert(repaymentMap)
        .select()
        .single();

    final createdRepayment = DebtRepaymentModel.fromMap(createdRaw);

    // 3. Sequentially allocate to installments if installments exist
    if (debt.installments.isNotEmpty) {
      final updatedInstallments = calculationService.allocateRepaymentToInstallments(
        debt.installments,
        amount,
      );

      for (final inst in updatedInstallments) {
        await _client.from('debt_installments').update({
          'paid_amount': inst.paidAmount,
          'status': inst.status.dbValue,
        }).eq('id', inst.id).eq('user_id', userId);
      }
    }

    // 4. Mark debt settled if remaining balance is cleared
    final newRemaining = debt.remainingAmount - amount;
    if (newRemaining <= 0.01 && debt.status != DebtStatus.settled) {
      await _client.from('debts').update({
        'status': DebtStatus.settled.dbValue,
      }).eq('id', debtId).eq('user_id', userId);
    }

    return createdRepayment;
  }

  /// Soft deletes a repayment entry and recalculates installment status.
  Future<void> deleteRepayment(String repaymentId, String debtId) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User must be logged in to delete repayment');

    final now = DateTime.now().toIso8601String();
    await _client.from('debt_repayments').update({
      'deleted_at': now,
      'deleted_by': userId,
    }).eq('id', repaymentId).eq('user_id', userId);

    // Re-sync installments and debt status
    final remainingRepayments = await getRepayments(debtId);
    final totalPaid = remainingRepayments.fold<double>(0.0, (sum, r) => sum + r.amount);

    final debt = await getDebt(debtId);
    if (debt != null) {
      if (debt.installments.isNotEmpty) {
        // Reset all installments to 0 then re-allocate total paid
        final resetInstallments = debt.installments.map((i) => i.copyWith(
          paidAmount: 0.0,
          status: InstallmentStatus.pending,
        )).toList();

        final reallocated = calculationService.allocateRepaymentToInstallments(
          resetInstallments,
          totalPaid,
        );

        for (final inst in reallocated) {
          await _client.from('debt_installments').update({
            'paid_amount': inst.paidAmount,
            'status': inst.status.dbValue,
          }).eq('id', inst.id).eq('user_id', userId);
        }
      }

      final isSettled = totalPaid >= debt.totalRepaymentAmount;
      await _client.from('debts').update({
        'status': isSettled ? DebtStatus.settled.dbValue : DebtStatus.active.dbValue,
      }).eq('id', debtId).eq('user_id', userId);
    }
  }
}
