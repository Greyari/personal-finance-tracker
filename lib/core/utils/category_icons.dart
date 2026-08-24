import 'package:flutter/material.dart';

/// Categories store an icon as a short String key (Firestore can't
/// persist IconData), and this maps that key back to a real icon for
/// display. Add a new entry here whenever a new default category or
/// icon choice is introduced — the icon picker in the UI reads its
/// options straight from [allKeys], so nothing else needs updating.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _icons = {
    'salary': Icons.payments_outlined,
    'bonus': Icons.card_giftcard_outlined,
    'freelance': Icons.laptop_mac_outlined,
    'income_other': Icons.attach_money,
    'food': Icons.restaurant_outlined,
    'food_out': Icons.lunch_dining_outlined,
    'transport': Icons.directions_car_outlined,
    'internet': Icons.wifi,
    'phone_credit': Icons.smartphone_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'entertainment': Icons.movie_outlined,
    'hangout': Icons.local_cafe_outlined,
    'date': Icons.favorite_outline,
    'family': Icons.family_restroom_outlined,
    'health': Icons.local_hospital_outlined,
    'education': Icons.school_outlined,
    'bill': Icons.receipt_long_outlined,
    'installment': Icons.credit_card_outlined,
    'church': Icons.church_outlined,
    'other': Icons.category_outlined,
    'saving_main': Icons.savings_outlined,
    'emergency_fund': Icons.shield_outlined,
    'saving_goal': Icons.flag_outlined,
    'mutual_fund': Icons.pie_chart_outline,
    'bond': Icons.account_balance_outlined,
    'stock': Icons.show_chart,
    'gold': Icons.workspace_premium_outlined,
    'crypto': Icons.currency_bitcoin,
    'investment_other': Icons.trending_up,
  };

  static IconData resolve(String key) => _icons[key] ?? Icons.category_outlined;

  static List<String> get allKeys => _icons.keys.toList(growable: false);
}
