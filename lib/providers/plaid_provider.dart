import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/plaid_item.dart';
import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/prefs.dart';
import 'auth_provider.dart';
import 'data_provider.dart';

/// Plaid linking + sync state, ported from PlaidContext.jsx. Also folds the
/// PlaidSyncBridge behaviour in directly: synced transactions are pushed into
/// [DataProvider] so the rest of the app sees them.
class PlaidProvider extends ChangeNotifier {
  static const _key = 'bb-plaid';

  final ApiClient _api;
  AuthProvider _auth;
  DataProvider _data;

  List<PlaidItem> _items = [];
  List<TransactionModel> _plaidTransactions = [];
  bool _loading = false;
  String? _error;
  String? _lastToken;

  PlaidProvider({
    required ApiClient api,
    required AuthProvider auth,
    required DataProvider data,
  })  : _api = api,
        _auth = auth,
        _data = data {
    _loadCached();
    _maybeReload();
  }

  List<PlaidItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  /// Flattened accounts across all linked institutions.
  List<PlaidAccount> get allAccounts =>
      _items.expand((item) => item.accounts).toList();

  double get totalBankBalance =>
      allAccounts.fold(0.0, (sum, a) => sum + (a.balances.current ?? 0));

  String? get _token => _auth.token;

  /// Called by the proxy provider whenever Auth/Data change. Reloads items when
  /// the access token changes (login/logout), mirroring the React useEffect.
  void updateDependencies(AuthProvider auth, DataProvider data) {
    _auth = auth;
    _data = data;
    _maybeReload();
  }

  void _maybeReload() {
    final token = _token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null) {
        loadItems();
      } else {
        _items = [];
        _plaidTransactions = [];
        notifyListeners();
      }
    }
  }

  void _loadCached() {
    final raw = Prefs.instance.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _items = ((map['items'] as List?) ?? const [])
          .map((e) => PlaidItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _plaidTransactions = ((map['plaidTransactions'] as List?) ?? const [])
          .map((e) => TransactionModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  void _persist() {
    Prefs.instance.setString(
      _key,
      jsonEncode({
        'items': _items
            .map((i) => {
                  'itemId': i.itemId,
                  'institutionId': i.institutionId,
                  'institutionName': i.institutionName,
                  'lastRefreshed': i.lastRefreshed?.toIso8601String(),
                  'accounts': i.accounts
                      .map((a) => {
                            'account_id': a.accountId,
                            'name': a.name,
                            'mask': a.mask,
                            'type': a.type,
                            'subtype': a.subtype,
                            'balances': {
                              'current': a.balances.current,
                              'available': a.balances.available,
                              'iso_currency_code': a.balances.isoCurrencyCode,
                            },
                          })
                      .toList(),
                })
            .toList(),
        'plaidTransactions': _plaidTransactions.map((t) => t.toJson()).toList(),
      }),
    );
  }

  Future<void> loadItems() async {
    final token = _token;
    if (token == null) return;
    try {
      final data = await _api.get('/plaid/items', token: token) as List;
      _items = data.map((e) => PlaidItem.fromJson((e as Map).cast<String, dynamic>())).toList();
      _persist();
      notifyListeners();
    } catch (_) {
      // User may not have any items yet.
    }
  }

  Future<String> getLinkToken() async {
    final token = _token;
    if (token == null) {
      throw const ApiException('Please sign out and sign back in to connect your bank.');
    }
    _setLoading(true);
    try {
      final data = await _api.post('/plaid/link-token', token: token) as Map;
      return data['linkToken'].toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Called after Plaid Link succeeds. Exchanges the public token, triggers a
  /// sync, then reloads items + transactions.
  Future<void> onPlaidSuccess(String publicToken) async {
    final token = _token;
    if (token == null) throw const ApiException('Not authenticated');
    _setLoading(true);
    _error = null;
    try {
      await _api.post('/plaid/exchange', body: {'publicToken': publicToken}, token: token);
      await _api.post('/plaid/transactions/sync', token: token);
      await _reloadAll(token);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _reloadAll(String token) async {
    final results = await Future.wait([
      _api.get('/plaid/items', token: token),
      _api.get('/plaid/transactions', token: token),
    ]);
    _items = (results[0] as List)
        .map((e) => PlaidItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final txData = (results[1] as Map).cast<String, dynamic>();
    _setTransactions(((txData['transactions'] as List?) ?? const [])
        .map((e) => TransactionModel.fromPlaid((e as Map).cast<String, dynamic>()))
        .toList());
  }

  /// Manual sync for the linked-accounts screen. Returns the synced list.
  Future<List<TransactionModel>> syncTransactions() async {
    final token = _token;
    if (token == null) return [];
    try {
      await _api.post('/plaid/transactions/sync', token: token);
      final txData = (await _api.get('/plaid/transactions', token: token) as Map).cast<String, dynamic>();
      final mapped = ((txData['transactions'] as List?) ?? const [])
          .map((e) => TransactionModel.fromPlaid((e as Map).cast<String, dynamic>()))
          .toList();
      _setTransactions(mapped);
      return mapped;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return [];
    }
  }

  Future<void> refreshAccounts() async {
    final token = _token;
    if (token == null) return;
    try {
      final data = await _api.get('/plaid/items', token: token) as List;
      _items = data.map((e) => PlaidItem.fromJson((e as Map).cast<String, dynamic>())).toList();
      _persist();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    final token = _token;
    try {
      if (token != null) await _api.delete('/plaid/items/$itemId', token: token);
    } catch (_) {
      // Optimistic — remove locally regardless.
    }
    _items = _items.where((i) => i.itemId != itemId).toList();
    _persist();
    notifyListeners();
  }

  void _setTransactions(List<TransactionModel> incoming) {
    final incomingIds = incoming.map((t) => t.id).toSet();
    final kept = _plaidTransactions.where((t) => !incomingIds.contains(t.id)).toList();
    _plaidTransactions = [...incoming, ...kept];
    _persist();
    // Push into DataProvider (replaces PlaidSyncBridge).
    if (_plaidTransactions.isNotEmpty) {
      _data.importTransactions(_plaidTransactions);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
