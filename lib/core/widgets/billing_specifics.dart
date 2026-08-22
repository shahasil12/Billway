import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.p8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      if (onDiscountTap != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  Text(
                    '-$currency${discountAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.financialMicro.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
        _buildLine('Tax', taxTotal),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
          child: Divider(thickness: 1.5),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('TOTAL', style: AppTextStyles.h2.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            Text(
              '$currency${grandTotal.toStringAsFixed(2)}',
              style: AppTextStyles.financialTotal.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: AppTextStyles.financialMicro,
          ),
        ],
      ),
    );
  }
}

// Spec: large 2x2 grid payment method tiles, 80px+ tall, icon + label
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onSelected;
  final bool gridLayout;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
    this.gridLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      ('CASH', Icons.payments_outlined, 'Cash'),
      ('UPI', Icons.qr_code_scanner, 'UPI'),
      ('CARD', Icons.credit_card_outlined, 'Card'),
      ('CREDIT', Icons.account_balance_wallet_outlined, 'Credit'),
    ];

    if (gridLayout) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: methods.map((m) => _buildTile(m.$1, m.$2, m.$3)).toList(),
      );
    }

    return Row(
      children: methods.map((m) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildTile(m.$1, m.$2, m.$3),
        ),
      )).toList(),
    );
  }

  Widget _buildTile(String method, IconData icon, String label) {
    final isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () => onSelected(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Spec: quantity stepper — each button 48x48px minimum, number 22px bold
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          isDestructive: value <= 1,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: AppTextStyles.h3.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _StepperButton({
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? AppColors.textDisabled
        : isDestructive
            ? AppColors.error
            : AppColors.primary;
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

// Stock badge per spec: In Stock (green), Low Stock (orange), Out of Stock (red)
class StockBadge extends StatelessWidget {
  final int stock;
  final int minStock;

  const StockBadge({super.key, required this.stock, required this.minStock});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    if (stock <= 0) {
      color = AppColors.error;
      label = 'Out of Stock';
    } else if (stock <= minStock || stock <= 5) {
      color = AppColors.warning;
      label = 'Low Stock';
    } else {
      color = AppColors.success;
      label = 'In Stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
