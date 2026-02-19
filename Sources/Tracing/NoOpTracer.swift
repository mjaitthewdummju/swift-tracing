import Foundation

/// A tracer that performs no operations and has zero runtime overhead.
///
/// NoOpTracer is useful when tracing is disabled or not configured. All operations
/// are no-ops and the compiler can optimize away most of the code.
///
/// Example:
/// ```swift
/// let tracer = NoOpTracer()
/// tracer.withSpan("operation") { span in
///     // span.isRecording == false, so no work is done
///     span.attributes["key"] = "value"  // No-op
/// }
/// ```
public struct NoOpTracer: Tracer, Sendable {
    /// Creates a no-op tracer.
    public init() {}

    public func startSpan(
        _ operationName: String,
        context: SpanContext?,
        ofKind kind: SpanKind,
        at instant: (any TracerInstant)?
    ) -> NoOpSpan {
        NoOpSpan()
    }

    /// A span that performs no operations.
    public final class NoOpSpan: SpanProtocol, @unchecked Sendable {
        public let context: SpanContext = SpanContext(
            traceID: "00000000000000000000000000000000",
            spanID: "0000000000000000"
        )

        public let operationName: String = ""

        public var attributes: SpanAttributes {
            get { SpanAttributes() }
            set {}
        }

        public let isRecording: Bool = false

        public func setStatus(_ status: SpanStatus) {}

        public func addEvent(_ event: SpanEvent) {}

        public func recordError(
            _ error: Error,
            attributes: SpanAttributes,
            at instant: (any TracerInstant)?
        ) {}

        public func addLink(_ context: SpanContext) {}

        public func end(at instant: (any TracerInstant)?) {}

        init() {}
    }
}
