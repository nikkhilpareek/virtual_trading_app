import 'package:equatable/equatable.dart';

/// User Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile
class LoadUserProfile extends UserEvent {
  const LoadUserProfile();
}

/// Update user profile
class UpdateUserProfile extends UserEvent {
  final String? fullName;
  final String? avatarUrl;

  const UpdateUserProfile({this.fullName, this.avatarUrl});

  @override
  List<Object?> get props => [fullName, avatarUrl];
}

/// Upload avatar
class UploadUserAvatar extends UserEvent {
  final String filePath;

  const UploadUserAvatar(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Refresh user profile
class RefreshUserProfile extends UserEvent {
  const RefreshUserProfile();
}
