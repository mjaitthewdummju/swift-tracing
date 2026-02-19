/// A protocol representing a span in a trace.
///
/// A span represents a single operation within a trace. It has a start time, end time,
/// and can contain attributes, events, and links to other spans.
///
/// Spans must have reference semantics to allow mutation after creation.
///
/// Example:
/// ```swift
/// let span = tracer.startSpan("database.query")
/// span.attributes["db.system"] = "postgresql"
/// span.attributes["db.statement"] = "SELECT * FROM users"
/// defer { span.end() }
///
/// do {
///     let result = try await database.query("SELECT * FROM users")
///     span.setStatus(.ok)
/// } catch {
///     span.recordError(error)
/// }
/// ```
public protocol SpanProtocol: AnyObject, Sendable {
  /// The context information for this span.
  var context: SpanContext { get }

  /// The name of the operation this span represents.
  var operationName: String { get }

  /// The attributes attached to this span.
  var attributes: SpanAttributes { get set }

  /// Whether this span is recording.
  ///
  /// Non-recording spans (like NoOpSpan) return false and ignore all operations.
  var isRecording: Bool { get }

  /// Sets the status of this span.
  ///
  /// - Parameter status: The status to set.
  func setStatus(_ status: SpanStatus)

  /// Adds an event to this span.
  ///
  /// - Parameter event: The event to add.
  func addEvent(_ event: SpanEvent)

  /// Records an error on this span.
  ///
  /// This is a convenience method that:
  /// 1. Adds an error event with the error details
  /// 2. Sets the span status to error
  /// 3. Adds error-related attributes
  ///
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - attributes: Additional attributes to attach to the error event.
  ///   - instant: The time when the error occurred. Defaults to now.
  func recordError(
    _ error: Error,
    attributes: SpanAttributes,
    at instant: (any TracerInstant)?
  )

  /// Adds a link to another span.
  ///
  /// Links allow associating a span with other spans that are causally related
  /// but not in a strict parent-child relationship.
  ///
  /// - Parameter context: The context of the span to link to.
  func addLink(_ context: SpanContext)

  /// Ends this span.
  ///
  /// After calling end, no further modifications to the span should be made.
  ///
  /// - Parameter instant: The time when the span ended. Defaults to now.
  func end(at instant: (any TracerInstant)?)
}

extension SpanProtocol {
  /// Records an error on this span with default parameters.
  public func recordError(_ error: Error) {
    recordError(error, attributes: SpanAttributes(), at: nil)
  }

  /// Ends this span at the current time.
  public func end() {
    end(at: nil)
  }
}
