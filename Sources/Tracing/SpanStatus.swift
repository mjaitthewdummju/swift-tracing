/// The status of a span, indicating whether the operation succeeded or failed.
///
/// Example:
/// ```swift
/// span.setStatus(.ok)
/// span.setStatus(.error(message: "Connection timeout"))
/// ```
public struct SpanStatus: Sendable, Hashable {
  /// The status code.
  public let code: Code

  /// An optional description of the status.
  public let message: String?

  /// Creates a span status with the given code and optional message.
  public init(code: Code, message: String? = nil) {
    self.code = code
    self.message = message
  }

  /// The status code of a span.
  public enum Code: Sendable, Hashable {
    /// The operation completed successfully.
    case ok

    /// The operation failed.
    case error
  }

  /// A successful span status.
  public static let ok = SpanStatus(code: .ok)

  /// Creates an error span status with the given message.
  public static func error(message: String) -> SpanStatus {
    SpanStatus(code: .error, message: message)
  }
}
