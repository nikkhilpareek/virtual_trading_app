import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/holding_lot_repository.dart';
import 'holding_lot_event.dart';
import 'holding_lot_state.dart';
import 'dart:developer' as developer;

/// Holding Lot BLoC
/// Manages lot-based position tracking
class HoldingLotBloc extends Bloc<HoldingLotEvent, HoldingLotState> {
  final HoldingLotRepository _repository;

  HoldingLotBloc(this._repository) : super(const HoldingLotInitial()) {
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

      final lots = await _repository.getLotsBySymbol(event.assetSymbol);

      if (lots.isEmpty) {
        emit(const HoldingLotsEmpty());
      } else {
        emit(HoldingLotsLoaded(lots: lots, assetSymbol: event.assetSymbol));
      }
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

      final lots = await _repository.getAllLots();

      if (lots.isEmpty) {
        emit(const HoldingLotsEmpty());
      } else {
        emit(HoldingLotsLoaded(lots: lots));

        developer.log(
          'Loaded ${lots.length} total lots',
          name: 'HoldingLotBloc',
        );
      }
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

      final lots = await _repository.getLotsByAssetType(event.assetType);

      if (lots.isEmpty) {
        emit(const HoldingLotsEmpty());
      } else {
        emit(HoldingLotsLoaded(lots: lots));

        developer.log(
          'Loaded ${lots.length} ${event.assetType} lots',
          name: 'HoldingLotBloc',
        );
      }
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
      await _repository.updateCurrentPrice(event.assetSymbol, event.newPrice);

      // Reload lots to show updated prices
      add(LoadLotsBySymbol(event.assetSymbol));

      developer.log(
        'Updated prices for ${event.assetSymbol}: ${event.newPrice}',
        name: 'HoldingLotBloc',
      );
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
    if (event.assetSymbol != null) {
      add(LoadLotsBySymbol(event.assetSymbol!));
    } else {
      add(const LoadAllLots());
    }
  }
}
