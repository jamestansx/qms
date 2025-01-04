import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qms_staff/queue/services/queue.dart';

part "queue_state.dart";
part "queue_event.dart";

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  QueueBloc({
    required QueueRepo queueRepo,
  })  : _queueRepo = queueRepo,
        super(const QueueState()) {
    on<NextQueue>(_onNextQueue);
  }

  final QueueRepo _queueRepo;

  void _onNextQueue(
    NextQueue event,
    Emitter<QueueState> emit,
  ) {
    _queueRepo.nextQueue();
  }
}
