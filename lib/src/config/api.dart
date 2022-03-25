/// Describes which API to use when operating
///
/// live - Live API
///
/// test - Sandbox API
///
/// local - Mocked API (Avoid using this, use [API_MODE.test] instead)
enum API_MODE { live, test, local }
