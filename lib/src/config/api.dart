/// Describes which API to use when operating
enum API_MODE {
  /// Live API
  live,

  /// Sandbox API
  test,

  /// Mocked API (Avoid using this, use [API_MODE.test] instead)
  local
}
