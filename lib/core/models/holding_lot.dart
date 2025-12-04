import 'package:equatable/equatable.dart';
import 'asset_type.dart';
import '../utils/currency_formatter.dart';

/// Holding Lot Model
/// Represents a single purchase batch/lot of an asset at a specific price
/// This allows tracking multiple purchases of the same asset separately
/// for individual stop-loss management and tax lot accounting
class HoldingLot extends Equatable {
  final String id;
  final String userId;
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final double quantity;
  final double purchasePrice;
  final double? currentPrice;
  final DateTime purchaseDate;
  final DateTime updatedAt;
  final String? transactionId; // Link to the buy transaction

  const HoldingLot({
    required this.id,
    required this.userId,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.quantity,
    required this.purchasePrice,
    this.currentPrice,
    required this.purchaseDate,
    required this.updatedAt,
    this.transactionId,
  });

  /// Create HoldingLot from Supabase JSON
  factory HoldingLot.fromJson(Map<String, dynamic> json) {
    return HoldingLot(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetSymbol: json['asset_symbol'] as String,
      assetName: json['asset_name'] as String,
      assetType: AssetType.fromJson(json['asset_type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      currentPrice: json['current_price'] != null
          ? (json['current_price'] as num).toDouble()
          : null,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      transactionId: json['transaction_id'] as String?,
    );
  }

  /// Convert HoldingLot to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'current_price': currentPrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'transaction_id': transactionId,
    };
  }

  /// Create a copy with updated fields
  HoldingLot copyWith({
    String? id,
    String? userId,
    String? assetSymbol,
    String? assetName,
    AssetType? assetType,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    DateTime? purchaseDate,
    DateTime? updatedAt,
    String? transactionId,
  }) {
    return HoldingLot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  // Calculated fields

  /// Total amount invested in this lot
  double get totalInvested => quantity * purchasePrice;

  /// Current value of this lot
  double get currentValue =>
      currentPrice != null ? quantity * currentPrice! : totalInvested;

  /// Profit or loss amount for this lot
  double get profitLoss => currentValue - totalInvested;

  /// Profit or loss percentage for this lot
  double get profitLossPercentage {
    if (totalInvested == 0) return 0;
    return (profitLoss / totalInvested) * 100;
  }

  /// Is this lot profitable?
  bool get isProfitable => profitLoss > 0;

  /// Is this lot at a loss?
  bool get isLoss => profitLoss < 0;

  // Formatted strings for display

  String get formattedQuantity => quantity.toStringAsFixed(6);

  String get formattedPurchasePrice =>
      CurrencyFormatter.formatINR(purchasePrice);

  String get formattedCurrentPrice =>
      currentPrice != null ? CurrencyFormatter.formatINR(currentPrice!) : '--';

  String get formattedTotalInvested =>
      CurrencyFormatter.formatINR(totalInvested);

  String get formattedCurrentValue => CurrencyFormatter.formatINR(currentValue);

  String get formattedProfitLoss {
    final formatted = CurrencyFormatter.formatINR(profitLoss.abs());
    return profitLoss >= 0 ? '+$formatted' : '-$formatted';
  }

  String get formattedProfitLossPercentage {
    final formatted = profitLossPercentage.abs().toStringAsFixed(2);
    return profitLossPercentage >= 0 ? '+$formatted%' : '-$formatted%';
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    assetSymbol,
    assetName,
    assetType,
    quantity,
    purchasePrice,
    currentPrice,
    purchaseDate,
    updatedAt,
    transactionId,
  ];

  @override
  String toString() {
    return 'HoldingLot(symbol: $assetSymbol, quantity: $quantity, price: ${CurrencyFormatter.formatINR(purchasePrice)}, P&L: $formattedProfitLoss)';
  }
}
