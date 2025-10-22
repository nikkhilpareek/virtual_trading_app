/// Asset Type Enum
/// Represents the different types of assets that can be traded
enum AssetType {
  stock,
  crypto,
  mutualFund;

  /// Convert enum to string for database storage
  String toJson() {
    switch (this) {
      case AssetType.stock:
        return 'stock';
      case AssetType.crypto:
        return 'crypto';
      case AssetType.mutualFund:
        return 'mutual_fund';
    }
  }

  /// Create enum from string (database value)
  static AssetType fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'stock':
        return AssetType.stock;
      case 'crypto':
        return AssetType.crypto;
      case 'mutual_fund':
        return AssetType.mutualFund;
      default:
        throw ArgumentError('Invalid asset type: $value');
    }
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case AssetType.stock:
        return 'Stock';
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.mutualFund:
        return 'Mutual Fund';
    }
  }

  /// Get icon representation
  String get icon {
    switch (this) {
      case AssetType.stock:
        return '📈';
      case AssetType.crypto:
        return '₿';
      case AssetType.mutualFund:
        return '📊';
    }
  }
}
