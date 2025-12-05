import 'package:equatable/equatable.dart';
import 'asset_type.dart';
import '../utils/currency_formatter.dart';

/// Holding Model
/// Represents a user's holding of a specific asset (stock/crypto/mutual fund)
class Holding extends Equatable {
  final String id;
  final String userId;
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final double quantity;
  final double averagePrice;
  final double? currentPrice;
  // Risk management (optional)
  final double? stopLoss; // Sell all if price <= stopLoss
  final double? bracketLower; // Lower bound; sell if price < bracketLower
  final double? bracketUpper; // Upper bound; sell if price > bracketUpper
  final DateTime createdAt;
  final DateTime updatedAt;

  const Holding({
    required this.id,
    required this.userId,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.quantity,
    required this.averagePrice,
    this.currentPrice,
    this.stopLoss,
    this.bracketLower,
    this.bracketUpper,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Holding from Supabase JSON
  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetSymbol: json['asset_symbol'] as String,
      assetName: json['asset_name'] as String,
      assetType: AssetType.fromJson(json['asset_type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      averagePrice: (json['average_price'] as num).toDouble(),
      currentPrice: json['current_price'] != null
          ? (json['current_price'] as num).toDouble()
          : null,
      stopLoss: json['stop_loss'] != null
          ? (json['stop_loss'] as num).toDouble()
          : null,
      bracketLower: json['bracket_lower'] != null
          ? (json['bracket_lower'] as num).toDouble()
          : null,
      bracketUpper: json['bracket_upper'] != null
          ? (json['bracket_upper'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Holding to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'quantity': quantity,
      'average_price': averagePrice,
      'current_price': currentPrice,
      'stop_loss': stopLoss,
      'bracket_lower': bracketLower,
      'bracket_upper': bracketUpper,
      'total_invested': totalInvested,
      'current_value': currentValue,
      'profit_loss': profitLoss,
      'profit_loss_percentage': profitLossPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Holding copyWith({
    String? id,
    String? userId,
    String? assetSymbol,
    String? assetName,
    AssetType? assetType,
    double? quantity,
    double? averagePrice,
    double? currentPrice,
    double? stopLoss,
    double? bracketLower,
    double? bracketUpper,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Holding(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      bracketLower: bracketLower ?? this.bracketLower,
      bracketUpper: bracketUpper ?? this.bracketUpper,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculated fields

  /// Total amount invested (quantity × average price)
  double get totalInvested => quantity * averagePrice;

  /// Current value of holding (quantity × current price)
  double get currentValue =>
      currentPrice != null ? quantity * currentPrice! : totalInvested;

  /// Profit or loss amount
  double get profitLoss => currentValue - totalInvested;

  /// Profit or loss percentage
  double get profitLossPercentage {
    if (totalInvested == 0) return 0;
    return (profitLoss / totalInvested) * 100;
  }

  /// Is this holding profitable?
  bool get isProfitable => profitLoss > 0;

  /// Is this holding at a loss?
  bool get isLoss => profitLoss < 0;

  /// Formatted strings for display

  String get formattedQuantity => quantity.toStringAsFixed(6);

  String get formattedAveragePrice => CurrencyFormatter.formatINR(averagePrice);

  String get formattedCurrentPrice =>
      currentPrice != null ? CurrencyFormatter.formatINR(currentPrice!) : '--';

  String get formattedTotalInvested =>
      CurrencyFormatter.formatINR(totalInvested);

  String get formattedCurrentValue => CurrencyFormatter.formatINR(currentValue);

  String get formattedProfitLoss {
    final sign = profitLoss >= 0 ? '+' : '';
    return '$sign${CurrencyFormatter.formatINR(profitLoss).replaceAll('₹', '')}';
  }

  String get formattedProfitLossPercentage =>
      CurrencyFormatter.formatPercentage(profitLossPercentage);

  @override
  List<Object?> get props => [
    id,
    userId,
    assetSymbol,
    assetName,
    assetType,
    quantity,
    averagePrice,
    currentPrice,
    stopLoss,
    bracketLower,
    bracketUpper,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Holding(symbol: $assetSymbol, quantity: $quantity, P&L: $formattedProfitLoss)';
  }
}
