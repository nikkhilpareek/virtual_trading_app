import 'package:equatable/equatable.dart';
import '../utils/currency_formatter.dart';

/// User Profile Model
/// Represents a user's profile data stored in Supabase
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final double stonkBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.stonkBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserProfile from Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      stonkBalance: (json['stonk_balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert UserProfile to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'stonk_balance': stonkBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    double? stonkBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stonkBalance: stonkBalance ?? this.stonkBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (fallback to email if no full name)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email.split('@')[0];

  /// Check if user has avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Format balance with currency
  String get formattedBalance => CurrencyFormatter.formatINR(stonkBalance);

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        stonkBalance,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName, balance: $stonkBalance)';
  }
}
