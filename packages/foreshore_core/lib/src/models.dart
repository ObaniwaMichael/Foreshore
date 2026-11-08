import 'money.dart';

enum UserRole { agent, admin, management }

UserRole userRoleFromString(String v) {
  switch (v) {
    case 'agent':
      return UserRole.agent;
    case 'admin':
      return UserRole.admin;
    case 'management':
      return UserRole.management;
    default:
      throw ArgumentError('Unknown role: $v');
  }
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: userRoleFromString(json['role'] as String),
      );
}

class Customer {
  Customer({
    required this.id,
    required this.cardId,
    required this.name,
    required this.phone,
    required this.address,
    required this.agentId,
    required this.usualDailyAmount,
    this.savingsBalance = 0,
    this.tenureDays = 0,
    this.collectedToday = false,
  });

  final String id;
  final String cardId;
  final String name;
  final String phone;
  final String address;
  final String agentId;
  final int usualDailyAmount;
  final int savingsBalance;
  final int tenureDays;
  final bool collectedToday;

  Money get usualMoney => Money(usualDailyAmount);
  Money get balanceMoney => Money(savingsBalance);

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        cardId: json['card_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        address: (json['address'] as String?) ?? '',
        agentId: json['agent_id'] as String,
        usualDailyAmount: (json['usual_daily_amount'] as num).toInt(),
        savingsBalance: (json['savings_balance'] as num?)?.toInt() ?? 0,
        tenureDays: (json['tenure_days'] as num?)?.toInt() ?? 0,
        collectedToday: json['collected_today'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'card_id': cardId,
        'name': name,
        'phone': phone,
        'address': address,
        'agent_id': agentId,
        'usual_daily_amount': usualDailyAmount,
        'savings_balance': savingsBalance,
        'tenure_days': tenureDays,
        'collected_today': collectedToday,
      };
}

class Contribution {
  Contribution({
    required this.id,
    required this.customerId,
    required this.agentId,
    required this.amount,
    required this.collectedAt,
    this.syncId,
    this.customerName,
  });

  final String id;
  final String customerId;
  final String agentId;
  final int amount;
  final DateTime collectedAt;
  final String? syncId;
  final String? customerName;

  Money get money => Money(amount);

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        agentId: json['agent_id'] as String,
        amount: (json['amount'] as num).toInt(),
        collectedAt: DateTime.parse(json['collected_at'] as String),
        syncId: json['sync_id'] as String?,
        customerName: json['customer_name'] as String?,
      );
}

enum CollectionDayStatus { open, mismatched, closed }

CollectionDayStatus dayStatusFromString(String v) {
  switch (v) {
    case 'open':
      return CollectionDayStatus.open;
    case 'mismatched':
      return CollectionDayStatus.mismatched;
    case 'closed':
      return CollectionDayStatus.closed;
    default:
      return CollectionDayStatus.open;
  }
}

class CollectionDay {
  CollectionDay({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.businessDate,
    required this.systemTotal,
    this.declaredCash,
    required this.status,
    this.signedOffAt,
  });

  final String id;
  final String agentId;
  final String agentName;
  final String businessDate;
  final int systemTotal;
  final int? declaredCash;
  final CollectionDayStatus status;
  final DateTime? signedOffAt;

  bool get hasMismatch =>
      declaredCash != null && declaredCash != systemTotal;

  factory CollectionDay.fromJson(Map<String, dynamic> json) => CollectionDay(
        id: json['id'] as String,
        agentId: json['agent_id'] as String,
        agentName: (json['agent_name'] as String?) ?? '',
        businessDate: json['business_date'] as String,
        systemTotal: (json['system_total'] as num).toInt(),
        declaredCash: (json['declared_cash'] as num?)?.toInt(),
        status: dayStatusFromString(json['status'] as String),
        signedOffAt: json['signed_off_at'] != null
            ? DateTime.parse(json['signed_off_at'] as String)
            : null,
      );
}

enum LoanStatus { pending, approved, declined, active, repaid, overdue }

LoanStatus loanStatusFromString(String v) {
  switch (v) {
    case 'pending':
      return LoanStatus.pending;
    case 'approved':
    case 'active':
      return LoanStatus.active;
    case 'declined':
      return LoanStatus.declined;
    case 'repaid':
      return LoanStatus.repaid;
    case 'overdue':
      return LoanStatus.overdue;
    default:
      return LoanStatus.pending;
  }
}

class Loan {
  Loan({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.principal,
    required this.interestRate,
    required this.interestAmount,
    required this.totalRepayable,
    required this.outstanding,
    required this.disbursedAt,
    required this.dueDate,
    required this.status,
    this.tenureDays = 0,
    this.dailyAverage = 0,
  });

  final String id;
  final String customerId;
  final String customerName;
  final int principal;
  final double interestRate;
  final int interestAmount;
  final int totalRepayable;
  final int outstanding;
  final DateTime? disbursedAt;
  final String dueDate;
  final LoanStatus status;
  final int tenureDays;
  final int dailyAverage;

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: (json['customer_name'] as String?) ?? '',
        principal: (json['principal'] as num).toInt(),
        interestRate: (json['interest_rate'] as num).toDouble(),
        interestAmount: (json['interest_amount'] as num).toInt(),
        totalRepayable: (json['total_repayable'] as num).toInt(),
        outstanding: (json['outstanding'] as num).toInt(),
        disbursedAt: json['disbursed_at'] != null
            ? DateTime.parse(json['disbursed_at'] as String)
            : null,
        dueDate: json['due_date'] as String,
        status: loanStatusFromString(json['status'] as String),
        tenureDays: (json['tenure_days'] as num?)?.toInt() ?? 0,
        dailyAverage: (json['daily_average'] as num?)?.toInt() ?? 0,
      );
}

class Withdrawal {
  Withdrawal({
    required this.id,
    required this.customerId,
    required this.gross,
    required this.charge,
    required this.net,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final int gross;
  final int charge;
  final int net;
  final DateTime createdAt;

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        gross: (json['gross'] as num).toInt(),
        charge: (json['charge'] as num).toInt(),
        net: (json['net'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class DashboardStats {
  DashboardStats({
    required this.totalSavings,
    required this.totalLoansOutstanding,
    required this.totalInterestEarned,
    required this.todayCollections,
  });

  final int totalSavings;
  final int totalLoansOutstanding;
  final int totalInterestEarned;
  final int todayCollections;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalSavings: (json['total_savings'] as num).toInt(),
        totalLoansOutstanding: (json['total_loans_outstanding'] as num).toInt(),
        totalInterestEarned: (json['total_interest_earned'] as num).toInt(),
        todayCollections: (json['today_collections'] as num).toInt(),
      );
}

class AuthResponse {
  AuthResponse({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['access_token'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
