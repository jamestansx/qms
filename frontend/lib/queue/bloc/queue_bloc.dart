import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part "queue_state.dart";
part "queue_event.dart";

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  QueueBloc() : super(const QueueState()) {
    on<AddQueue>(_onAddQueue);
    on<Dequeue>(_onDequeue);
  }

  void _onDequeue(
    Dequeue event,
    Emitter<QueueState> emit,
  ) {
    emit(
      state.copyWith(
        status: QueueStatus.unqueued,
        queueNo: null,
      ),
    );
  }

  void _onAddQueue(
    AddQueue event,
    Emitter<QueueState> emit,
  ) {
    emit(
      state.copyWith(
        status: QueueStatus.queued,
        queueNo: event.queueNo,
      ),
    );
  }
}
