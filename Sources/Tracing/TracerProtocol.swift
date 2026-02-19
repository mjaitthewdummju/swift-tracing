/// A protocol for creating and managing spans.
///
/// Tracers are the entry point for creating new spans. They handle span lifecycle
/// management and automatic context propagation.
///
/// Example:
/// ```swift
/// let tracer = InMemoryTracer()
///
/// // Manual span management
/// let span = tracer.startSpan("http.request", ofKind: .client)
/// span.attributes["http.method"] = "GET"
/// defer { span.end() }
///
/// // Automatic span management with withSpan
/// try await tracer.withSpan("database.query", ofKind: .client) { span in
///     span.attributes["db.system"] = "postgresql"
///     return try await database.query("SELECT * FROM users")
/// }
/// ```
public protocol Tracer: Sendable {
  /// The span type created by this tracer.
  associatedtype Span: SpanProtocol

  /// Starts a new span with the given parameters.
  ///
  /// - Parameters:
  ///   - operationName: The name of the operation this span represents.
  ///   - context: The parent context, if any. If nil, creates a root span.
  ///   - kind: The kind of span. Defaults to .internal.
  ///   - instant: The time when the span started. Defaults to now.
  /// - Returns: A new span.
  func startSpan(
    _ operationName: String,
    context: SpanContext?,
    ofKind kind: SpanKind,
    at instant: (any TracerInstant)?
  ) -> Span
}

extension Tracer {
  /// Starts a new span with automatic context propagation from task-local storage.
  ///
  /// If a TraceContext is present in task-local storage, the new span will be a child
  /// of the current span. Otherwise, a new root span is created.
  public func startSpan(
    _ operationName: String,
    ofKind kind: SpanKind = .internal,
    at instant: (any TracerInstant)? = nil
  ) -> Span {
    let context: SpanContext?
    if let current = TraceContext.current {
      context = SpanContext(
        traceID: current.traceID,
        spanID: current.spanID
      )
    } else {
      context = nil
    }
    return startSpan(operationName, context: context, ofKind: kind, at: instant)
  }

  /// Executes a closure within a span, automatically managing its lifecycle.
  ///
  /// This method:
  /// 1. Creates a new span with automatic context propagation
  /// 2. Sets the span in task-local storage so child operations can access it
  /// 3. Executes the closure
  /// 4. Automatically ends the span when the closure completes
  /// 5. Records any errors thrown by the closure
  ///
  /// Example:
  /// ```swift
  /// let user = try await tracer.withSpan("fetch_user", ofKind: .client) { span in
  ///     span.attributes["user.id"] = userId
  ///     return try await httpClient.get("/users/\(userId)")
  /// }
  /// ```
  public func withSpan<T>(
    _ operationName: String,
    context: SpanContext? = nil,
    ofKind kind: SpanKind = .internal,
    at instant: (any TracerInstant)? = nil,
    _ operation: (Span) async throws -> T
  ) async rethrows -> T {
    let parentContext =
      context
      ?? TraceContext.current.map { current in
        SpanContext(traceID: current.traceID, spanID: current.spanID)
      }
    let span = startSpan(operationName, context: parentContext, ofKind: kind, at: instant)
    defer { span.end() }

    let traceContext = TraceContext(from: span.context)
    return try await TraceContext.$current.withValue(traceContext) {
      do {
        let result = try await operation(span)
        if span.isRecording {
          span.setStatus(.ok)
        }
        return result
      } catch {
        if span.isRecording {
          span.recordError(error)
        }
        throw error
      }
    }
  }

  /// Executes a closure within a span, automatically managing its lifecycle (synchronous version).
  ///
  /// This is the synchronous variant of withSpan for non-async operations.
  ///
  /// Example:
  /// ```swift
  /// let result = tracer.withSpan("compute") { span in
  ///     span.attributes["input.size"] = data.count
  ///     return processData(data)
  /// }
  /// ```
  public func withSpan<T>(
    _ operationName: String,
    context: SpanContext? = nil,
    ofKind kind: SpanKind = .internal,
    at instant: (any TracerInstant)? = nil,
    _ operation: (Span) throws -> T
  ) rethrows -> T {
    let parentContext =
      context
      ?? TraceContext.current.map { current in
        SpanContext(traceID: current.traceID, spanID: current.spanID)
      }
    let span = startSpan(operationName, context: parentContext, ofKind: kind, at: instant)
    defer { span.end() }

    let traceContext = TraceContext(from: span.context)
    return try TraceContext.$current.withValue(traceContext) {
      do {
        let result = try operation(span)
        if span.isRecording {
          span.setStatus(.ok)
        }
        return result
      } catch {
        if span.isRecording {
          span.recordError(error)
        }
        throw error
      }
    }
  }
}
