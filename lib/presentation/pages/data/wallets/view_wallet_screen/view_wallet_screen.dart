// lib/presentation/pages/extra/wallet_screen/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/presentation/pages/data/transactions/create_transaction_screen/create_transaction_screen.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/transaction_list.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/transaction_tabs.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/wallet_card.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_modal.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/services/category_service.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/wallet_service.dart';
import 'package:wallet_app/providers/wallet_provider.dart'; // Necesario para refresh

class ViewWalletScreen extends ConsumerStatefulWidget {
  final int walletId;

  const ViewWalletScreen({super.key, required this.walletId});

  @override
  ConsumerState<ViewWalletScreen> createState() => _ViewWalletScreenState();
}

class _ViewWalletScreenState extends ConsumerState<ViewWalletScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  Wallet? _wallet;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _filterType = 'all';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _filterType = ['all', 'income', 'expense'][_tabController.index]);
    _loadTransactions();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadWallet(), _loadCategories(), _loadTransactions()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWallet() async {
    final wallets = await _walletService.getWallets(includeArchived: true);
    _wallet = wallets.firstWhere((w) => w.id == widget.walletId, orElse: () => _wallet!);
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getCategories();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactionsByWallet(
      widget.walletId,
      type: _filterType == 'all' ? null : _filterType,
    );
    if (mounted) setState(() => _transactions = transactions);
  }

  void _goToCreateTransaction() async {
    if (_wallet == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTransactionScreen(
          initialWalletId: _wallet!.id!,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // === ACCIONES DEL MENÚ ===

  void _toggleArchive() async {
    if (_wallet == null) return;
    final updated = _wallet!.copyWith(isArchived: !_wallet!.isArchived);
    await _walletService.updateWallet(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updated.isArchived ? 'Cartera archivada' : 'Cartera desarchivada')),
      );
      ref.read(walletsProvider.notifier).refresh();
      _loadWallet();
    }
  }

  void _toggleFavorite() async {
    if (_wallet == null) return;
    final updated = _wallet!.copyWith(isFavorite: !_wallet!.isFavorite);
    await _walletService.updateWallet(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updated.isFavorite ? 'Añadida a favoritos' : 'Quitada de favoritos')),
      );
      ref.read(walletsProvider.notifier).refresh();
      _loadWallet();
    }
  }

  void _createExpense() {
    if (_wallet == null) return;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showCustomModal(
      context: context,
      title: 'Nuevo gasto',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Desde: ${_wallet!.name}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            CustomNumberField(currency: _wallet!.currency, controller: amountCtrl, hintText: '0.00'),
            const SizedBox(height: 16),
            CustomTextField(controller: descCtrl, hintText: 'Descripción (opcional)', icon: Icons.note),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
            if (amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido')));
              return;
            }
            final updated = _wallet!.copyWith(balance: _wallet!.balance - amount);
            await _walletService.updateWallet(updated);
            Navigator.pop(context);
            _loadWallet();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gasto de ${_wallet!.currency} $amount registrado')));
          },
          child: const Text('Crear gasto', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _deleteWallet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cartera'),
        content: Text('¿Seguro que quieres eliminar "${_wallet?.name}"? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && _wallet != null) {
      await _walletService.deleteWallet(_wallet!.id!);
      if (mounted) {
        ref.read(walletsProvider.notifier).refresh();
        Navigator.of(context).pop(); // Vuelve a la lista de carteras
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cartera eliminada')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = <PopupMenuEntry<dynamic>>[
      PopupMenuItem(
        child: Row(children: [
          Icon(_wallet?.isArchived == true ? Icons.unarchive : Icons.archive),
          const SizedBox(width: 12),
          Text(_wallet?.isArchived == true ? 'Desarchivar' : 'Archivar'),
        ]),
        onTap: _toggleArchive,
      ),
      PopupMenuItem(
        child: Row(children: [
          Icon(_wallet?.isFavorite == true ? Icons.star : Icons.star_border, color: _wallet?.isFavorite == true ? Colors.amber : null),
          const SizedBox(width: 12),
          Text(_wallet?.isFavorite == true ? 'Quitar de favoritos' : 'Añadir a favoritos'),
        ]),
        onTap: _toggleFavorite,
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        child: const Row(children: [Icon(Icons.remove_circle_outline, color: Colors.red), SizedBox(width: 12), Text('Crear gasto')]),
        onTap: _createExpense,
      ),
      PopupMenuItem(
        child: const Row(children: [Icon(Icons.swap_horiz, color: Colors.blue), SizedBox(width: 12), Text('Crear transacción')]),
        onTap: _goToCreateTransaction,
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        child: const Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 12), Text('Eliminar cartera', style: TextStyle(color: Colors.red))]),
        onTap: _deleteWallet,
      ),
    ];

    return Scaffold(
      appBar: CustomHeader(
        menuItems: _wallet == null ? [] : menuItems,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        onPressed: _goToCreateTransaction,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva transacción', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
              ? const Center(child: Text('Cartera no encontrada'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      WalletCard(wallet: _wallet!),
                      TransactionTabs(controller: _tabController),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TransactionList(
                          transactions: _transactions,
                          categories: _categories,
                          currency: _wallet!.currency,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}