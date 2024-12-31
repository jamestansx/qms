part of "queue_bloc.dart";

enum QueueStatus {
  unqueued,
  queued,
  failure,
}

final class QueueState extends Equatable {
  const QueueState({
    this.status = QueueStatus.unqueued,
    this.queueNo,
    this.isLoading,
  });

  final QueueStatus status;
  final int? queueNo;
  final bool? isLoading;

  QueueState copyWith({
    QueueStatus? status,
    int? queueNo,
    bool? isLoading,
  }) {
    return QueueState(
      status: status ?? this.status,
      queueNo: queueNo ?? this.queueNo,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [status, queueNo, isLoading];
}
