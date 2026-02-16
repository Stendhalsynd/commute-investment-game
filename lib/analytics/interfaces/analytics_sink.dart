abstract class IAnalyticsSink {
  void trackEvent(String name, Map<String, Object?> payload);
  void trackError(String code, Map<String, Object?> context);
}

class NoopAnalyticsSink implements IAnalyticsSink {
  const NoopAnalyticsSink();

  @override
  void trackEvent(String name, Map<String, Object?> payload) {
    // Intentionally no-op for MVP baseline.
  }

  @override
  void trackError(String code, Map<String, Object?> context) {
    // Intentionally no-op for MVP baseline.
  }
}
