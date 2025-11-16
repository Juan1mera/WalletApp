import 'package:flutter/material.dart';
import 'package:wallet_app/models/wallet_model.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;

  const WalletCard({super.key, required this.wallet});

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
      'COP': 'COL',
    };
    return symbols[currency] ?? currency;
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _getCurrencySymbol(wallet.currency);
    final walletColor = Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));

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
                child: Icon(wallet.iconBank ?? Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${wallet.type == 'bank' ? 'Banco' : 'Efectivo'} • ${wallet.currency}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                  ],
                ),
              ),
              if (wallet.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 24),
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
              Text(wallet.balance.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}