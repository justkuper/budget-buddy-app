import 'package:flutter/material.dart';

/// A spending/income category, ported from DataContext.CATEGORIES.
/// `label` is an i18n key; `icon` is an emoji; `color` matches the React palette.
class TxCategory {
  final String key;
  final String icon;
  final Color color;

  const TxCategory({required this.key, required this.icon, required this.color});
}

class Categories {
  const Categories._();

  static const Map<String, TxCategory> all = {
    'food': TxCategory(key: 'food', icon: '🍔', color: Color(0xFFFF6B6B)),
    'transport': TxCategory(key: 'transport', icon: '🚗', color: Color(0xFF4ECDC4)),
    'shopping': TxCategory(key: 'shopping', icon: '🛍️', color: Color(0xFFFFB347)),
    'health': TxCategory(key: 'health', icon: '💊', color: Color(0xFF95E1D3)),
    'entertainment': TxCategory(key: 'entertainment', icon: '🎬', color: Color(0xFFF38181)),
    'housing': TxCategory(key: 'housing', icon: '🏠', color: Color(0xFF6C63FF)),
    'salary': TxCategory(key: 'salary', icon: '💼', color: Color(0xFF00C896)),
    'freelance': TxCategory(key: 'freelance', icon: '💻', color: Color(0xFF00C896)),
    'investment': TxCategory(key: 'investment', icon: '📈', color: Color(0xFF00C896)),
    'other': TxCategory(key: 'other', icon: '📦', color: Color(0xFFA8A4CE)),
  };

  static const List<String> expense = [
    'food', 'transport', 'shopping', 'health', 'entertainment', 'housing', 'other',
  ];
  static const List<String> income = ['salary', 'freelance', 'investment', 'other'];

  static TxCategory? of(String key) => all[key];
  static const TxCategory fallback = TxCategory(key: 'other', icon: '📦', color: Color(0xFFA8A4CE));
}
