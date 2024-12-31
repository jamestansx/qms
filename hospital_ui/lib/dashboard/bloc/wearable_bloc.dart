import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:qms_staff/dashboard/model/wearable.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';

part "wearable_state.dart";
part "wearable_event.dart";

class WearableBloc extends Bloc<WearableEvent, WearableState> {
  WearableBloc({
    required WearablesRepo wearableRepo,
  })  : _wearableRepo = wearableRepo,
        super(const WearableState()) {
    on<WearablesFetched>(_onFetch);
    on<SelectWearable>(_onSelectWearable);
  }

  final WearablesRepo _wearableRepo;

  Future<void> _onFetch(
    WearablesFetched event,
    Emitter<WearableState> emit,
  ) async {
    try {
      final wearables = await _wearableRepo.fetchList();
      emit(
        state.copyWith(
          status: WearableStatus.success,
          wearables: wearables,
        ),
      );
    } catch (_) {
      emit(state.copyWith(
        status: WearableStatus.failure,
        selectedItem: () => null,
      ));
    }
  }

  Future<void> _onSelectWearable(
    SelectWearable event,
    Emitter<WearableState> emit,
  ) async {
    try {
      if (state.response != null) {
        state.response!.cancel();
      }

      final response = await _wearableRepo.monitor();

      emit(state.copyWith(
        selectedItem: () => event.wearable,
        response: response,
      ));
    } catch (_) {
      emit(state.copyWith(
        selectedItem: () => null,
      ));
    }
  }
}
