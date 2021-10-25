abstract class GetReady {
  late Future<void> _ready;
  Future<void> get ready => _ready;

  GetReady() {
    _ready = setup();
  }

  Future<void> setup();
}