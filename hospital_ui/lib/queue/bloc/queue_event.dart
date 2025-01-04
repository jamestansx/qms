part of "queue_bloc.dart";

sealed class QueueEvent {
  const QueueEvent();
}

final class NextQueue extends QueueEvent {}
