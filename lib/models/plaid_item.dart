/// Account balances, as returned by Plaid via the backend.
class PlaidBalances {
  final double? current;
  final double? available;
  final String isoCurrencyCode;

  const PlaidBalances({this.current, this.available, this.isoCurrencyCode = 'USD'});

  factory PlaidBalances.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlaidBalances();
    return PlaidBalances(
      current: (json['current'] as num?)?.toDouble(),
      available: (json['available'] as num?)?.toDouble(),
      isoCurrencyCode: (json['iso_currency_code'] as String?) ?? 'USD',
    );
  }
}

/// A single bank account within a linked institution (Plaid item).
class PlaidAccount {
  final String accountId;
  final String name;
  final String? mask;
  final String type; // depository | credit | investment | loan
  final String? subtype;
  final PlaidBalances balances;
  final String? institutionName;

  const PlaidAccount({
    required this.accountId,
    required this.name,
    this.mask,
    required this.type,
    this.subtype,
    required this.balances,
    this.institutionName,
  });

  bool get isCredit => type == 'credit';

  factory PlaidAccount.fromJson(Map<String, dynamic> json, {String? institutionName}) {
    return PlaidAccount(
      accountId: (json['account_id'] ?? json['accountId'] ?? '') as String,
      name: (json['name'] as String?) ?? 'Account',
      mask: json['mask'] as String?,
      type: (json['type'] as String?) ?? 'depository',
      subtype: json['subtype'] as String?,
      balances: PlaidBalances.fromJson((json['balances'] as Map?)?.cast<String, dynamic>()),
      institutionName: institutionName ?? json['institutionName'] as String?,
    );
  }
}

/// A linked institution (one Plaid item = one bank login).
class PlaidItem {
  final String itemId;
  final String? institutionId;
  final String? institutionName;
  final List<PlaidAccount> accounts;
  final DateTime? lastRefreshed;

  const PlaidItem({
    required this.itemId,
    this.institutionId,
    this.institutionName,
    this.accounts = const [],
    this.lastRefreshed,
  });

  factory PlaidItem.fromJson(Map<String, dynamic> json) {
    final inst = json['institutionName'] as String?;
    final rawAccounts = (json['accounts'] as List?) ?? const [];
    DateTime? refreshed;
    final lr = json['lastRefreshed'];
    if (lr != null) {
      refreshed = DateTime.tryParse(lr.toString());
    }
    return PlaidItem(
      itemId: json['itemId'] as String,
      institutionId: json['institutionId'] as String?,
      institutionName: inst,
      accounts: rawAccounts
          .map((a) => PlaidAccount.fromJson((a as Map).cast<String, dynamic>(), institutionName: inst))
          .toList(),
      lastRefreshed: refreshed,
    );
  }
}
