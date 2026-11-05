abstract class SafetyService {
  Future<void> blockProfile(String blockerProfileId, String blockedProfileId);
  Future<void> unblockProfile(String blockerProfileId, String blockedProfileId);
  Future<void> reportProfile(
    String reporterProfileId,
    String reportedProfileId,
    String reason, {
    String? details,
  });
  Future<bool> isBlocked(String currentProfileId, String otherProfileId);
}
