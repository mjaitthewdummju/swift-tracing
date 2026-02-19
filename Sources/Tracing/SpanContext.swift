/// Context information for a span, including trace and span identifiers.
///
/// SpanContext provides the core identifiers needed to correlate spans within a trace:
/// - `traceID`: Unique identifier for the entire trace
/// - `spanID`: Unique identifier for this specific span
/// - `parentSpanID`: Identifier of the parent span (if any)
public struct SpanContext: Sendable, Hashable {
    /// The unique identifier for the trace this span belongs to.
    public let traceID: String

    /// The unique identifier for this span.
    public let spanID: String

    /// The identifier of the parent span, if any.
    public let parentSpanID: String?

    /// Creates a span context with the given identifiers.
    public init(
        traceID: String,
        spanID: String,
        parentSpanID: String? = nil
    ) {
        self.traceID = traceID
        self.spanID = spanID
        self.parentSpanID = parentSpanID
    }

    /// Creates a child context with a new span ID.
    ///
    /// The child context inherits the trace ID and uses the current span ID as its parent.
    public func makeChild(spanID: String) -> SpanContext {
        SpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: self.spanID
        )
    }
}

/// Task-local context for automatic span propagation.
///
/// TraceContext is stored in task-local storage and automatically propagates to child tasks.
/// This enables automatic parent-child relationships without manual context passing.
///
/// Example:
/// ```swift
/// TraceContext.$current.withValue(context) {
///     // This task and all child tasks inherit the context
///     await doWork()
/// }
/// ```
public struct TraceContext: Sendable, Hashable {
    /// The unique identifier for the trace.
    public let traceID: String

    /// The unique identifier for the current span.
    public let spanID: String

    /// Creates a trace context with the given identifiers.
    public init(traceID: String, spanID: String) {
        self.traceID = traceID
        self.spanID = spanID
    }

    /// Creates a trace context from a span context.
    public init(from spanContext: SpanContext) {
        self.traceID = spanContext.traceID
        self.spanID = spanContext.spanID
    }

    /// The current trace context, stored in task-local storage.
    @TaskLocal
    public static var current: TraceContext?
}
