import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

class TotalsBlock extends StatelessWidget {
  final double subtotal;
  final double taxTotal;
  final double discountAmount;
  final double grandTotal;
  final VoidCallback? onDiscountTap;
  final String currency;

  const TotalsBlock({
    super.key,
    required this.subtotal,
    required this.taxTotal,
    this.discountAmount = 0.0,
    required this.grandTotal,
    this.onDiscountTap,
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLine('Subtotal', subtotal),
        if (discountAmount > 0 || onDiscountTap != null)
          InkWell(
            onTap: onDiscountTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.p4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Discount', style: AppTextStyles.bodyMedium),
                      if (onDiscountTap != null)
                        const Icon(Icons.edit, size: 14, color: AppColors.primary),
                    ],
                  ),
                  Text('-$currency${discountAmount.toStringAsFixed(2)}', 
                    style: AppTextStyles.financialLine.copyWith(color: AppColors.success)),
                ],
              ),
            ),
          ),
        _buildLine('Tax', taxTotal),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.p8),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOTAL', style: AppTextStyles.h2),
            Text('$currency${grandTotal.toStringAsFixed(2)}', style: AppTextStyles.financialTotal),
          ],
        ),
      ],
    );
  }

  Widget _buildLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text('$currency${amount.toStringAsFixed(2)}', style: AppTextStyles.financialLine),
        ],
      ),
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildOption('CASH', Icons.money)),
        const SizedBox(width: AppSpacing.p4),
        Expanded(child: _buildOption('CARD', Icons.credit_card)),
        const SizedBox(width: AppSpacing.p4),
        Expanded(child: _buildOption('UPI', Icons.qr_code_scanner)),
        const SizedBox(width: AppSpacing.p4),
        Expanded(child: _buildOption('CREDIT', Icons.account_balance_wallet)),
      ],
    );
  }

  Widget _buildOption(String method, IconData icon) {
    final isSelected = selectedMethod == method;
    return InkWell(
      onTap: () => onSelected(method),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(height: 4),
            Text(
              method, 
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary
              ),
            ),
          ],
        ),
      ),
    );
  }
}
