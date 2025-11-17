import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'dart:ui';

class TransactionsHomeSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback? onViewAllPressed;

  const TransactionsHomeSection({
    super.key,
    required this.transactions,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayTransactions = transactions.take(10).toList();
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: displayTransactions.length + 1,
        itemBuilder: (context, index) {
          // Última card con botón "Ver todas"
          if (index == displayTransactions.length) {
            return _buildViewAllCard(context);
          }

          final transaction = displayTransactions[index];
          final rotation = (index % 2 == 0) ? -0.02 : 0.02;
          
          return Transform.rotate(
            angle: rotation,
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: _buildTransactionCard(transaction),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final sign = isExpense ? '-' : '+';
    
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isExpense 
                    ? Colors.red.withValues(alpha: .15)
                    : Colors.green.withValues(alpha: .15),
                  Colors.white.withValues(alpha: .1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: .2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono y tipo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpense 
                          ? Colors.red.withValues(alpha: .2)
                          : Colors.green.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isExpense ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    Text(
                      transaction.currency ?? 'USD',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                // Comentario/Descripción
                Text(
                  transaction.comment ?? (isExpense ? 'Gasto' : 'Ingreso'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Monto y Fecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sign ${transaction.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ClashDisplay',
                        color: isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllCard(BuildContext context) {
    return Transform.rotate(
      angle: 0.02,
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.black.withValues(alpha: .7),
                    AppColors.black.withValues(alpha: .5),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .2),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewAllPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ver todas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'ClashDisplay',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'las transacciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}