import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ForeshoreApi {
  ForeshoreApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _json(http.Response res) async {
    if (res.statusCode >= 400) {
      String detail = res.body;
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['detail'] != null) {
          detail = body['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(res.statusCode, detail);
    }
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _jsonList(http.Response res) async {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<AuthResponse> login(String phone, String password) async {
    final res = await _client.post(
      _u('/auth/login'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = await _json(res);
    final auth = AuthResponse.fromJson(data);
    _token = auth.token;
    return auth;
  }

  Future<List<Customer>> getRoute({String? agentId, String? date}) async {
    final res = await _client.get(
      _u('/agent/route', {
        if (agentId != null) 'agent_id': agentId,
        if (date != null) 'date': date,
      }),
      headers: _headers,
    );
    final list = await _jsonList(res);
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> createCustomer({
    required String name,
    required String phone,
    required String address,
    required int usualDailyAmount,
  }) async {
    final res = await _client.post(
      _u('/customers'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'address': address,
        'usual_daily_amount': usualDailyAmount,
      }),
    );
    return Customer.fromJson(await _json(res));
  }

  Future<Contribution> logContribution({
    required String customerId,
    required int amount,
    String? syncId,
    DateTime? collectedAt,
  }) async {
    final res = await _client.post(
      _u('/contributions'),
      headers: _headers,
      body: jsonEncode({
        'customer_id': customerId,
        'amount': amount,
        if (syncId != null) 'sync_id': syncId,
        if (collectedAt != null) 'collected_at': collectedAt.toUtc().toIso8601String(),
      }),
    );
    return Contribution.fromJson(await _json(res));
  }

  Future<List<Contribution>> syncContributions(
      List<Map<String, dynamic>> items) async {
    final res = await _client.post(
      _u('/contributions/sync'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    final data = await _json(res);
    final list = data['created'] as List<dynamic>? ?? [];
    return list
        .map((e) => Contribution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Contribution>> getContributions({
    String? customerId,
    String? agentId,
    String? date,
  }) async {
    final res = await _client.get(
      _u('/contributions', {
        if (customerId != null) 'customer_id': customerId,
        if (agentId != null) 'agent_id': agentId,
        if (date != null) 'date': date,
      }),
      headers: _headers,
    );
    final list = await _jsonList(res);
    return list
        .map((e) => Contribution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CollectionDay> getOrCreateToday({int? declaredCash}) async {
    final res = await _client.post(
      _u('/collection-days/today'),
      headers: _headers,
      body: jsonEncode({
        if (declaredCash != null) 'declared_cash': declaredCash,
      }),
    );
    return CollectionDay.fromJson(await _json(res));
  }

  Future<List<CollectionDay>> listCollectionDays({String? date}) async {
    final res = await _client.get(
      _u('/collection-days', {if (date != null) 'date': date}),
      headers: _headers,
    );
    final list = await _jsonList(res);
    return list
        .map((e) => CollectionDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CollectionDay> setDeclaredCash(String dayId, int declaredCash) async {
    final res = await _client.patch(
      _u('/collection-days/$dayId'),
      headers: _headers,
      body: jsonEncode({'declared_cash': declaredCash}),
    );
    return CollectionDay.fromJson(await _json(res));
  }

  Future<CollectionDay> signOffDay(String dayId) async {
    final res = await _client.post(
      _u('/collection-days/$dayId/signoff'),
      headers: _headers,
    );
    return CollectionDay.fromJson(await _json(res));
  }

  Future<Withdrawal> createWithdrawal({
    required String customerId,
    int? amount,
  }) async {
    final res = await _client.post(
      _u('/withdrawals'),
      headers: _headers,
      body: jsonEncode({
        'customer_id': customerId,
        if (amount != null) 'amount': amount,
      }),
    );
    return Withdrawal.fromJson(await _json(res));
  }

  Future<Map<String, dynamic>> previewWithdrawal(String customerId) async {
    final res = await _client.get(
      _u('/withdrawals/preview', {'customer_id': customerId}),
      headers: _headers,
    );
    return _json(res);
  }

  Future<List<Loan>> listLoans({String? status}) async {
    final res = await _client.get(
      _u('/loans', {if (status != null) 'status': status}),
      headers: _headers,
    );
    final list = await _jsonList(res);
    return list.map((e) => Loan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Loan> requestLoan({
    required String customerId,
    required int principal,
  }) async {
    final res = await _client.post(
      _u('/loans'),
      headers: _headers,
      body: jsonEncode({
        'customer_id': customerId,
        'principal': principal,
      }),
    );
    return Loan.fromJson(await _json(res));
  }

  Future<Loan> decideLoan(String loanId, {required bool approve}) async {
    final res = await _client.post(
      _u('/loans/$loanId/decide'),
      headers: _headers,
      body: jsonEncode({'approve': approve}),
    );
    return Loan.fromJson(await _json(res));
  }

  Future<Loan> repayLoan(String loanId, int amount) async {
    final res = await _client.post(
      _u('/loans/$loanId/repay'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return Loan.fromJson(await _json(res));
  }

  Future<DashboardStats> getStats() async {
    final res = await _client.get(_u('/reports/summary'), headers: _headers);
    return DashboardStats.fromJson(await _json(res));
  }

  Future<Map<String, dynamic>> customerStatement(String customerId) async {
    final res = await _client.get(
      _u('/reports/customer/$customerId'),
      headers: _headers,
    );
    return _json(res);
  }

  Future<List<Customer>> listCustomers() async {
    final res = await _client.get(_u('/customers'), headers: _headers);
    final list = await _jsonList(res);
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
