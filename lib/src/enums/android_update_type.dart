/// Update type for Android In-App Updates via Google Play Core.
///
/// - [immediate] — Fullscreen blocking UI; user must update before continuing.
///   Suitable for critical fixes or breaking changes.
/// - [flexible] — Update downloads in the background while user keeps using
///   the app. A completion prompt is shown when download finishes.
enum AndroidUpdateType {
  immediate,
  flexible,
}
