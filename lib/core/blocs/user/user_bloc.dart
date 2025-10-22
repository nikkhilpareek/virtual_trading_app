import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/repositories.dart';
import 'user_event.dart';
import 'user_state.dart';

/// User BLoC
/// Manages user profile state and operations
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(),
        super(const UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<UploadUserAvatar>(_onUploadUserAvatar);
    on<RefreshUserProfile>(_onRefreshUserProfile);
  }

  /// Load user profile
  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final profile = await _userRepository.getUserProfile();
      if (profile != null) {
        emit(UserLoaded(profile));
      } else {
        emit(const UserError('Failed to load profile'));
      }
    } catch (e) {
      emit(UserError('Error loading profile: ${e.toString()}'));
    }
  }

  /// Update user profile
  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      emit(const UserLoading());
      try {
        final profile = await _userRepository.updateProfile(
          fullName: event.fullName,
          avatarUrl: event.avatarUrl,
        );
        if (profile != null) {
          emit(UserLoaded(profile));
        } else {
          emit(const UserError('Failed to update profile'));
        }
      } catch (e) {
        emit(UserError('Error updating profile: ${e.toString()}'));
      }
    }
  }

  /// Upload user avatar
  Future<void> _onUploadUserAvatar(
    UploadUserAvatar event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      emit(const UserUploadingAvatar());
      try {
        final avatarUrl = await _userRepository.uploadAvatar(event.filePath);
        if (avatarUrl != null) {
          // Reload profile to get updated avatar
          final profile = await _userRepository.getUserProfile();
          if (profile != null) {
            emit(UserLoaded(profile));
          } else {
            emit(const UserError('Failed to load updated profile'));
          }
        } else {
          emit(const UserError('Failed to upload avatar'));
        }
      } catch (e) {
        emit(UserError('Error uploading avatar: ${e.toString()}'));
      }
    }
  }

  /// Refresh user profile
  Future<void> _onRefreshUserProfile(
    RefreshUserProfile event,
    Emitter<UserState> emit,
  ) async {
    try {
      final profile = await _userRepository.getUserProfile();
      if (profile != null) {
        emit(UserLoaded(profile));
      } else {
        emit(const UserError('Failed to refresh profile'));
      }
    } catch (e) {
      emit(UserError('Error refreshing profile: ${e.toString()}'));
    }
  }
}
