import 'dart:async';

abstract class Event {
  const Event();
}

class ArbitraryEvent extends Event {
  final String namespace;
  final Map<String, dynamic> data;

  const ArbitraryEvent({required this.namespace, required this.data});
}

class EventBus {
  final StreamController _streamController;

  EventBus({bool sync = false, StreamController? controller}) : _streamController = controller ?? StreamController.broadcast(sync: sync);

  Stream<T> on<T extends Event>() => _streamController.stream.where((event) => event is T).cast<T>();

  void publish(Event event) => _streamController.add(event);

  void close() => _streamController.close();
}
