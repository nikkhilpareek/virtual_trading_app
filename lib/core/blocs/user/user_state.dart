import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// User States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserInitial extends UserState {
  const UserInitial();
}

/// Loading state
class UserLoading extends UserState {
  const UserLoading();
}

/// Loaded state with user profile
class UserLoaded extends UserState {
  final UserProfile profile;

  const UserLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Error state
class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Uploading avatar state
class UserUploadingAvatar extends UserState {
  const UserUploadingAvatar();
}
