
import 'package:wallet_app/core/database/db.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/services/auth_service.dart';

class WalletService {
  final Db _db = Db();
  final AuthService _authService = AuthService();

  // -------------------- Wallets --------------------

  Future<int> createWallet(Wallet wallet) async {
    final userEmail = _authService.getCurrentUserEmail();
    if (userEmail == null) throw Exception('User not authenticated');

    final db = await _db.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getWallets({
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    final userEmail = _authService.getCurrentUserEmail();
    if (userEmail == null) return [];

    final db = await _db.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: onlyFavorites
          ? 'is_favorite = 1'
          : includeArchived
              ? null
              : 'is_archived = 0',
      orderBy: 'created_at DESC',
    );

    return maps.map(Wallet.fromMap).toList();
  }

  Future<bool> updateWallet(Wallet wallet) async {
    if (wallet.id == null) throw Exception('Wallet ID required');

    final db = await _db.database;
    final result = await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    return result > 0;
  }

  Future<bool> deleteWallet(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // -------------------- Categories --------------------

  Future<int> createCategory(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<bool> updateCategory(Category category) async {
    if (category.id == null) throw Exception('Category ID required');

    final db = await _db.database;
    final result = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return result > 0;
  }

  Future<bool> deleteCategory(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // -------------------- Transactions --------------------

  Future<int> createTransaction(Transaction transaction) async {
    final userEmail = _authService.getCurrentUserEmail();
    if (userEmail == null) throw Exception('User not authenticated');

    final db = await _db.database;

    // Verificar que la wallet pertenece al usuario (opcional, según tu modelo de seguridad)
    final walletCheck = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [transaction.walletId],
    );
    if (walletCheck.isEmpty) throw Exception('Wallet not found');

    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getTransactionsByWallet(
    int walletId, {
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    final whereParts = <String>['wallet_id = ?'];
    final whereArgs = <Object>[walletId];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getAllTransactions({
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    final whereParts = <String>[];
    final whereArgs = <Object>[];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList();
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction ID required');

    final db = await _db.database;
    final result = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return result > 0;
  }

  Future<bool> deleteTransaction(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }
}