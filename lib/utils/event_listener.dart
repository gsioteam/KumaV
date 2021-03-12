
typedef EventAction<T> = void Function(T);

class EventListener<T> {
  final List<EventAction<T>> actions = [];

  void call([T data]) {
    actions.forEach((element) {
      element.call(data);
    });
  }

  void add(EventAction<T> action) {
    actions.add(action);
  }

  void remove(EventAction<T> action) {
    actions.remove(action);
  }
}