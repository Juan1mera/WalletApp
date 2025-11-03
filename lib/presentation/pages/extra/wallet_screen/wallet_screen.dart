// lib/presentation/pages/extra/wallet_screen/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_modal.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  final int walletId;

  const WalletScreen({
    super.key,
    required this.walletId,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();

  Wallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _filterType = 'all';

  late TabController _tabController;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _transactionDescController = TextEditingController();
  final TextEditingController _transactionNoteController = TextEditingController();
  
  get selectedCurrency => null;
  
  get selectedType => null;
  
  get selectedColor => null;
  
  get isFavorite => null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _nameController.dispose();
    _transactionDescController.dispose();
    _transactionNoteController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _filterType = ['all', 'income', 'expense'][_tabController.index];
    });
    _loadTransactions();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    try {
      final wallets = await _walletService.getWallets(includeArchived: true);
      _wallet = wallets.firstWhere((w) => w.id == widget.walletId);
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _walletService.getTransactionsByWallet(
        widget.walletId,
        type: _filterType == 'all' ? null : _filterType,
      );
      if (mounted) {
        setState(() => _transactions = transactions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar transacciones: $e')),
        );
      }
    }
  }

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
    };
    return symbols[currency] ?? currency;
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      default:
        return Icons.swap_horiz;
    }
  }

  // MODAL: Editar Wallet
  void _showEditWalletModal() {
    if (_wallet == null) return;

    _nameController.text = _wallet!.name;

    showCustomModal(
      context: context,
      title: 'Editar Cartera',
      heightFactor: 0.85,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          String selectedCurrency = _wallet!.currency;
          String selectedType = _wallet!.type;
          String selectedColor = _wallet!.color;
          bool isFavorite = _wallet!.isFavorite;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  hintText: 'Ej: Efectivo, Banco Santander',
                ),
                CustomSelect<String>(
                  label: 'Moneda',
                  items: ['USD', 'COP', 'EUR', 'GBP', 'MXN', 'BRL', 'JPY', 'INR'],
                  selectedItem: selectedCurrency,
                  getDisplayText: (c) => c,
                  onChanged: (val) => setModalState(() => selectedCurrency = val!),
                  color: Color(int.parse(selectedColor.replaceFirst('#', '0xFF'))),
                  dynamicIcon: (c) => {
                    'USD': Icons.attach_money,
                    'EUR': Icons.euro,
                    'GBP': Icons.currency_pound,
                    'MXN': Icons.money,
                    'JPY': Icons.currency_yen,
                    'INR': Icons.currency_rupee,
                  }[c] ?? Icons.attach_money,
                ),
                const SizedBox(height: 20),
                _buildTypeSelector(setModalState, selectedType, (val) => selectedType = val),
                const SizedBox(height: 20),
                _buildColorSelector(setModalState, selectedColor, (val) => selectedColor = val),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Marcar como favorita'),
                  value: isFavorite,
                  onChanged: (val) => setModalState(() => isFavorite = val),
                  activeColor: AppColors.verde,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        CustomButton(
          text: 'Cancelar',
          bgColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        CustomButton(
          text: 'Guardar',
          onPressed: () async {
            if (_nameController.text.trim().isEmpty) return;

            final updatedWallet = _wallet!.copyWith(
              name: _nameController.text.trim(),
              currency: selectedCurrency,
              type: selectedType,
              color: selectedColor,
              isFavorite: isFavorite,
            );

            try {
              await _walletService.updateWallet(updatedWallet);
              if (mounted) Navigator.pop(context);
              _loadWalletData();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
        ),
      ],
    );
  }

  // MODAL: Crear Transacción
  void _showCreateTransactionModal() {
    if (_wallet == null) return;

    _transactionDescController.clear();
    _transactionNoteController.clear();

    String type = 'expense';
    double amount = 0.0;

    showCustomModal(
      context: context,
      title: 'Nueva Transacción',
      heightFactor: 0.85,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _transactionDescController,
                  label: 'Descripción',
                  hintText: 'Ej: Supermercado, Salario',
                ),
                CustomNumberField(
                  currency: _wallet!.currency,
                  onChanged: (val) => amount = val,
                ),
                const SizedBox(height: 20),
                _buildTransactionTypeSelector(setModalState, type, (val) => type = val),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _transactionNoteController,
                  label: 'Nota (opcional)',
                  hintText: 'Ej: Pago en efectivo',
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        CustomButton(
          text: 'Cancelar',
          bgColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        CustomButton(
          text: 'Crear',
          onPressed: () async {
            if (_transactionDescController.text.trim().isEmpty || amount <= 0) return;

            final transaction = Transaction(
              walletId: _wallet!.id!,
              type: type,
              amount: amount,
              description: _transactionDescController.text.trim(),
              note: _transactionNoteController.text.isEmpty ? null : _transactionNoteController.text.trim(),
              date: DateTime.now(),
              createdAt: DateTime.now(),
            );

            try {
              await _walletService.createTransaction(transaction);
              if (mounted) Navigator.pop(context);
              await _loadTransactions();
              setState(() {
                _wallet = _wallet!.copyWith(
                  balance: type == 'income'
                      ? _wallet!.balance + amount
                      : _wallet!.balance - amount,
                );
              });
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
        ),
      ],
    );
  }

  // Selectores reutilizados
  Widget _buildTypeSelector(StateSetter setModalState, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tipo de cartera',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verde),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.payments, size: 20, color: selected == 'cash' ? AppColors.verde : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Efectivo'),
                  ],
                ),
                value: 'cash',
                groupValue: selected,
                onChanged: (val) => setModalState(() => onChanged(val!)),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.account_balance, size: 20, color: selected == 'bank' ? AppColors.verde : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Banco'),
                  ],
                ),
                value: 'bank',
                groupValue: selected,
                onChanged: (val) => setModalState(() => onChanged(val!)),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector(StateSetter setModalState, String selected, Function(String) onChanged) {
    final colors = ['#4CAF50', '#2196F3', '#FF9800', '#F44336', '#9C27B0', '#00BCD4', '#FFC107', '#795548'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verde)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = selected == color;
              return GestureDetector(
                onTap: () => setModalState(() => onChanged(color)),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeSelector(StateSetter setState, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verde)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: selected == 'income' ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Ingreso'),
                  ],
                ),
                value: 'income',
                groupValue: selected,
                onChanged: (val) => setState(() => onChanged(val!)),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20, color: selected == 'expense' ? Colors.red : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Gasto'),
                  ],
                ),
                value: 'expense',
                groupValue: selected,
                onChanged: (val) => setState(() => onChanged(val!)),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // UI: Header de la cartera
  Widget _buildWalletHeader() {
    if (_wallet == null) return const SizedBox.shrink();

    final currencySymbol = _getCurrencySymbol(_wallet!.currency);
    final walletColor = Color(int.parse(_wallet!.color.replaceFirst('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [walletColor, walletColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: walletColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(_wallet!.iconBank ?? Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_wallet!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_wallet!.type == 'bank' ? 'Banco' : 'Efectivo'} • ${_wallet!.currency}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                  ],
                ),
              ),
              if (_wallet!.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Saldo actual', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currencySymbol, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(_wallet!.balance.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: AppColors.verde, borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [Tab(text: 'Todas'), Tab(text: 'Ingresos'), Tab(text: 'Gastos')],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay transacciones', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Las transacciones aparecerán aquí', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final Map<String, List<Transaction>> grouped = {};
    final dateFormat = DateFormat('dd MMM yyyy', 'es_ES');
    for (var t in _transactions) {
      final key = dateFormat.format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ),
            ...items.map(_buildTransactionCard),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction t) {
    final symbol = _getCurrencySymbol(_wallet?.currency ?? 'USD');
    final color = _getTransactionColor(t.type);
    final icon = _getTransactionIcon(t.type);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(timeFormat.format(t.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (t.note != null && t.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.note!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        trailing: Text(
          '${t.type == 'expense' ? '-' : '+'}$symbol${t.amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Detalle de Cartera',
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditWalletModal),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.verde,
        onPressed: _showCreateTransactionModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva transacción', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
              ? const Center(child: Text('Cartera no encontrada'))
              : RefreshIndicator(
                  onRefresh: _loadWalletData,
                  child: Column(
                    children: [
                      _buildWalletHeader(),
                      _buildTabBar(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTransactionsList()),
                    ],
                  ),
                ),
    );
  }
}