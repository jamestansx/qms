import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qms_staff/dashboard/model/stream_data.dart';
import 'package:qms_staff/dashboard/model/wearable.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';
import 'package:qms_staff/main.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

part "wearable_event.dart";
part "wearable_state.dart";

class WearableBloc extends Bloc<WearableEvent, WearableState> {
  WearableBloc({
    required WearablesRepo wearableRepo,
  })  : _wearableRepo = wearableRepo,
        super(const WearableState()) {
    on<WearablesFetched>(_onFetch);
    on<SelectWearable>(_onSelectWearable);
    on<MonitorDashboard>(_onMonitorStarted);
    on<ResetAlert>(_onResetAlert);
  }

  final WearablesRepo _wearableRepo;

  Future<void> _onMonitorStarted(
    MonitorDashboard event,
    Emitter<WearableState> emit,
  ) async {
    await _wearableRepo.monitor();

    _wearableRepo.controller.stream.listen((ev) async {
      if (ev.topic == "accelerometer/fall") {
        await QuickAlert.show(
          context: navigatorKey.currentContext!,
          type: QuickAlertType.error,
          title: 'Fall Alert',
          text: 'Fall location: ${ev.data}',
        );
        await _wearableRepo.ackFall();
      }
      emit(state.copyWith(streamData: ev, isAlertDismissed: false));
    });

    return emit.onEach(
      _wearableRepo.controller.stream,
      onData: (status) async {
        return emit(
            state.copyWith(streamData: status, isAlertDismissed: false));
      },
    );
  }

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
          selectedIdx: 0,
        ),
      );
    } catch (_) {
      emit(state.copyWith(
        status: WearableStatus.failure,
      ));
    }
  }

  Future<void> _onSelectWearable(
    SelectWearable event,
    Emitter<WearableState> emit,
  ) async {
    emit(state.copyWith(
      selectedIdx: event.idx,
    ));
  }

  Future<void> _onResetAlert(
    ResetAlert event,
    Emitter<WearableState> emit,
  ) async {
    if (!(state.isAlertDismissed ?? true)) {
      emit(state.copyWith(
          isAlertDismissed: true, alertDevice: event.alertDevice));
    }
  }
}
