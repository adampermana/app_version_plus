/// Represents the availability status of an app update
enum UpdateAvailability {
  /// No update is available
  none,

  /// An update is available but not required (user can skip)
  optional,

  /// An update is required (force update scenario)
  required,
}
