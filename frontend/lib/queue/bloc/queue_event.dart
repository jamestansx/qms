part of "queue_bloc.dart";

sealed class QueueEvent {
  const QueueEvent();
}

final class AddQueue extends QueueEvent {
  final int queueNo;

  AddQueue({required this.queueNo});
}

final class Dequeue extends QueueEvent {}
