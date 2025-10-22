import 'package:equatable/equatable.dart';
import 'asset_type.dart';

/// Transaction Type Enum
enum TransactionType {
  buy,
  sell;

  String toJson() => name;

  static TransactionType fromJson(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid transaction type: $value'),
    );
  }

  String get displayName => name.toUpperCase();
}

/// Transaction Model
/// Represents a buy or sell transaction made by the user
class Transaction extends Equatable {
  final String id;
  final String userId;
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final TransactionType transactionType;
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final double balanceAfter;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.transactionType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.balanceAfter,
    required this.createdAt,
  });

  /// Create Transaction from Supabase JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetSymbol: json['asset_symbol'] as String,
      assetName: json['asset_name'] as String,
      assetType: AssetType.fromJson(json['asset_type'] as String),
      transactionType: TransactionType.fromJson(json['transaction_type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Transaction to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'transaction_type': transactionType.toJson(),
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_amount': totalAmount,
      'balance_after': balanceAfter,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    String? assetSymbol,
    String? assetName,
    AssetType? assetType,
    TransactionType? transactionType,
    double? quantity,
    double? pricePerUnit,
    double? totalAmount,
    double? balanceAfter,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Is this a buy transaction?
  bool get isBuy => transactionType == TransactionType.buy;

  /// Is this a sell transaction?
  bool get isSell => transactionType == TransactionType.sell;

  /// Formatted strings for display

  String get formattedQuantity => quantity.toStringAsFixed(6);
  
  String get formattedPricePerUnit => '${pricePerUnit.toStringAsFixed(2)} ST';
  
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(2)} ST';
  
  String get formattedBalanceAfter => '${balanceAfter.toStringAsFixed(2)} ST';
  
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get transactionDescription {
    final action = isBuy ? 'Bought' : 'Sold';
    return '$action $formattedQuantity $assetSymbol';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        assetSymbol,
        assetName,
        assetType,
        transactionType,
        quantity,
        pricePerUnit,
        totalAmount,
        balanceAfter,
        createdAt,
      ];

  @override
  String toString() {
    return 'Transaction(${transactionType.name.toUpperCase()}: $assetSymbol, qty: $quantity, total: $formattedTotalAmount)';
  }
}
