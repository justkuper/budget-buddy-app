import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Formats a USD amount. When [decimals] is false, drops cents (matches the
/// React `minimumFractionDigits: 0` variants).
String formatCurrency(num amount, {bool decimals = true, String currency = 'USD'}) {
  final symbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;
  final format = NumberFormat.currency(
    symbol: symbol,
    decimalDigits: decimals ? 2 : 0,
  );
  return format.format(amount);
}

/// Standard white/dark surface card (`.card`).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
    return Container(
      margin: margin,
      child: onTap == null
          ? card
          : InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: card),
    );
  }
}

/// Purple gradient hero card (`.card-gradient`).
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const GradientCard({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x596C63FF), blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

/// Income/expense pill badge (`.badge-income` / `.badge-expense`).
class StatusBadge extends StatelessWidget {
  final String label;
  final bool income;
  const StatusBadge({super.key, required this.label, required this.income});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = income
        ? (isDark ? const Color(0xFF0A2A20) : const Color(0xFFD4FAF0))
        : (isDark ? const Color(0xFF2A1515) : const Color(0xFFFFE8E8));
    final fg = income ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Horizontal filter pill (`.pill`).
class FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const FilterPill({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : p.bgCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? AppColors.primary : p.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : p.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Thin rounded progress bar (`.progress-track` / `.progress-fill`).
class ProgressBar extends StatelessWidget {
  final double fraction; // 0..1
  final Color? color;
  final Gradient? gradient;
  final double height;
  const ProgressBar({
    super.key,
    required this.fraction,
    this.color,
    this.gradient,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: height,
        color: p.bgInput,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? AppColors.primary) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered empty-state block (`.empty-state`).
class EmptyState extends StatelessWidget {
  final String icon;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: p.textMuted, fontSize: 15)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Full-width gradient primary button (`.btn-primary`).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          color: onPressed == null ? AppColors.primary.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x596C63FF), blurRadius: 15, offset: Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Floating action button (`.fab`) — gradient rounded square with a '+'.
class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  const AppFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x736C63FF), blurRadius: 20, offset: Offset(0, 6))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Helper that shows a bottom sheet styled like the React `.sheet` overlay.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  final p = AppPaletteScope.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bgCard,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: builder(ctx))),
            ],
          ),
        ),
      ),
    ),
  );
}
