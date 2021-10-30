

class MessageException with Exception {
  final String message;

  MessageException(this.message);

  @override
  String toString() => message;
}