import 'dart:convert';

import 'package:foreshore_core/foreshore_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PendingContribution {
  PendingContribution({
    required this.syncId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.collectedAt,
  });

  final String syncId;
  final String customerId;
  final String customerName;
  final int amount;
  final DateTime collectedAt;

  Map<String, dynamic> toJson() => {
        'sync_id': syncId,
        'customer_id': customerId,
        'customer_name': customerName,
        'amount': amount,
        'collected_at': collectedAt.toUtc().toIso8601String(),
      };

  factory PendingContribution.fromJson(Map<String, dynamic> json) =>
      PendingContribution(
        syncId: json['sync_id'] as String,
        customerId: json['customer_id'] as String,
        customerName: (json['customer_name'] as String?) ?? '',
        amount: (json['amount'] as num).toInt(),
        collectedAt: DateTime.parse(json['collected_at'] as String),
      );

  Map<String, dynamic> toApiItem() => {
        'customer_id': customerId,
        'amount': amount,
        'sync_id': syncId,
        'collected_at': collectedAt.toUtc().toIso8601String(),
      };
}

class OfflineQueue {
  static const _key = 'pending_contributions';
  final _uuid = const Uuid();
  List<PendingContribution> _pending = [];
  SharedPreferences? _prefs;

  List<PendingContribution> get pending => List.unmodifiable(_pending);
  int get pendingCount => _pending.length;
  int get pendingTotal =>
      _pending.fold<int>(0, (sum, p) => sum + p.amount);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    final list = jsonDecode(raw) as List<dynamic>;
    _pending = list
        .map((e) => PendingContribution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_pending.map((e) => e.toJson()).toList()),
    );
  }

  Future<PendingContribution> enqueue({
    required String customerId,
    required String customerName,
    required int amount,
    DateTime? collectedAt,
  }) async {
    final item = PendingContribution(
      syncId: _uuid.v4(),
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      collectedAt: collectedAt ?? DateTime.now(),
    );
    _pending.add(item);
    await _persist();
    return item;
  }

  Future<int> flush(ForeshoreApi api) async {
    if (_pending.isEmpty) return 0;
    final items = _pending.map((e) => e.toApiItem()).toList();
    await api.syncContributions(items);
    final n = _pending.length;
    _pending.clear();
    await _persist();
    return n;
  }

  /// Try online first; on failure queue offline.
  Future<void> collect({
    required ForeshoreApi api,
    required String customerId,
    required String customerName,
    required int amount,
  }) async {
    final syncId = _uuid.v4();
    final at = DateTime.now();
    try {
      await api.logContribution(
        customerId: customerId,
        amount: amount,
        syncId: syncId,
        collectedAt: at,
      );
    } catch (_) {
      _pending.add(
        PendingContribution(
          syncId: syncId,
          customerId: customerId,
          customerName: customerName,
          amount: amount,
          collectedAt: at,
        ),
      );
      await _persist();
    }
  }

  bool hasLocalCollection(String customerId) {
    final today = DateTime.now();
    return _pending.any(
      (p) =>
          p.customerId == customerId &&
          p.collectedAt.year == today.year &&
          p.collectedAt.month == today.month &&
          p.collectedAt.day == today.day,
    );
  }

  int localTotalForToday() {
    final today = DateTime.now();
    return _pending
        .where((p) =>
            p.collectedAt.year == today.year &&
            p.collectedAt.month == today.month &&
            p.collectedAt.day == today.day)
        .fold<int>(0, (s, p) => s + p.amount);
  }
}
