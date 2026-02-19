import Foundation

/// A timestamped event that can be added to a span.
///
/// Span events represent significant points during a span's lifetime, such as:
/// - Cache hits or misses
/// - Query executions
/// - Network retries
/// - Internal state changes
///
/// Example:
/// ```swift
/// span.addEvent(SpanEvent(name: "cache.miss"))
/// span.addEvent(SpanEvent(
///     name: "query.executed",
///     attributes: ["query.duration_ms": 42]
/// ))
/// ```
public struct SpanEvent: Sendable, Hashable {
  /// The name of the event.
  public let name: String

  /// The timestamp when the event occurred.
  public let timestamp: Date

  /// Additional attributes describing the event.
  public let attributes: SpanAttributes

  /// Creates a span event with the given name and optional timestamp and attributes.
  ///
  /// - Parameters:
  ///   - name: The name of the event.
  ///   - timestamp: The timestamp when the event occurred. Defaults to the current time.
  ///   - attributes: Additional attributes describing the event. Defaults to empty.
  public init(
    name: String,
    timestamp: Date = Date(),
    attributes: SpanAttributes = SpanAttributes()
  ) {
    self.name = name
    self.timestamp = timestamp
    self.attributes = attributes
  }
}
