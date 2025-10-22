import 'package:equatable/equatable.dart';
import 'asset_type.dart';

/// WatchlistItem Model
/// Represents an asset saved in user's watchlist
class WatchlistItem extends Equatable {
  final String id;
  final String userId;
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final DateTime createdAt;

  const WatchlistItem({
    required this.id,
    required this.userId,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.createdAt,
  });

  /// Create WatchlistItem from Supabase JSON
  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetSymbol: json['asset_symbol'] as String,
      assetName: json['asset_name'] as String,
      assetType: AssetType.fromJson(json['asset_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert WatchlistItem to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  WatchlistItem copyWith({
    String? id,
    String? userId,
    String? assetSymbol,
    String? assetName,
    AssetType? assetType,
    DateTime? createdAt,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        assetSymbol,
        assetName,
        assetType,
        createdAt,
      ];

  @override
  String toString() {
    return 'WatchlistItem(symbol: $assetSymbol, name: $assetName, type: ${assetType.displayName})';
  }
}
