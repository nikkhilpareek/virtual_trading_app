import 'package:flutter_bloc/flutter_bloc.dart';
import 'holding_lot_event.dart';
import 'holding_lot_state.dart';
import 'dart:developer' as developer;

/// Holding Lot BLoC
/// DEPRECATED - Lot system removed, use HoldingsRepository instead
class HoldingLotBloc extends Bloc<HoldingLotEvent, HoldingLotState> {
  // Deprecated - HoldingLotRepository removed

  HoldingLotBloc() : super(const HoldingLotInitial()) {
    on<LoadLotsBySymbol>(_onLoadLotsBySymbol);
    on<LoadAllLots>(_onLoadAllLots);
    on<LoadLotsByType>(_onLoadLotsByType);
    on<UpdateLotsPrices>(_onUpdateLotsPrices);
    on<RefreshLots>(_onRefreshLots);
  }

  Future<void> _onLoadLotsBySymbol(
    LoadLotsBySymbol event,
    Emitter<HoldingLotState> emit,
  ) async {
    try {
      emit(const HoldingLotLoading());
      // Deprecated - no lots to load
      emit(const HoldingLotsEmpty());
    } catch (e, st) {
      developer.log(
        'Error loading lots by symbol',
        name: 'HoldingLotBloc',
        error: e,
        stackTrace: st,
      );
      emit(HoldingLotError(e.toString()));
    }
  }

  Future<void> _onLoadAllLots(
    LoadAllLots event,
    Emitter<HoldingLotState> emit,
  ) async {
    try {
      emit(const HoldingLotLoading());
      // Deprecated - no lots to load
      emit(const HoldingLotsEmpty());
    } catch (e, st) {
      developer.log(
        'Error loading all lots',
        name: 'HoldingLotBloc',
        error: e,
        stackTrace: st,
      );
      emit(HoldingLotError(e.toString()));
    }
  }

  Future<void> _onLoadLotsByType(
    LoadLotsByType event,
    Emitter<HoldingLotState> emit,
  ) async {
    try {
      emit(const HoldingLotLoading());
      // Deprecated - no lots to load
      emit(const HoldingLotsEmpty());
    } catch (e, st) {
      developer.log(
        'Error loading lots by type',
        name: 'HoldingLotBloc',
        error: e,
        stackTrace: st,
      );
      emit(HoldingLotError(e.toString()));
    }
  }

  Future<void> _onUpdateLotsPrices(
    UpdateLotsPrices event,
    Emitter<HoldingLotState> emit,
  ) async {
    try {
      // Deprecated - no lots to update
      emit(const HoldingLotsEmpty());
    } catch (e, st) {
      developer.log(
        'Error updating lot prices',
        name: 'HoldingLotBloc',
        error: e,
        stackTrace: st,
      );
      emit(HoldingLotError(e.toString()));
    }
  }

  Future<void> _onRefreshLots(
    RefreshLots event,
    Emitter<HoldingLotState> emit,
  ) async {
    // Deprecated
    emit(const HoldingLotsEmpty());
  }
}
