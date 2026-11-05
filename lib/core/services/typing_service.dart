abstract class TypingService {
  /// Signal that user is typing in a thread between [myProfileId] and [otherProfileId]
  /// for approximately [ttlSeconds]. Server may clamp TTL.
  Future<void> sendTyping({
    required String myProfileId,
    required String otherProfileId,
    int ttlSeconds = 7,
  });

  /// Poll to check if other user is typing in the thread.
  Future<bool> isTyping({
    required String myProfileId,
    required String otherProfileId,
  });
}
