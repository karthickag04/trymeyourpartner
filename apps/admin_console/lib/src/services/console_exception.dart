/// An error with a message that can be shown to staff. lib/data/
/// implementations turn provider errors into this type.
class ConsoleException implements Exception {
  const ConsoleException(this.message);

  final String message;

  @override
  String toString() => message;
}
