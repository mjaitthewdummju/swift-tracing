import Foundation
import Tracing

/// An in-memory tracer implementation for testing and development.
///
/// InMemoryTracer stores all spans in memory and provides methods to query them.
/// It's thread-safe and suitable for use in concurrent environments.
///
/// Example:
/// ```swift
/// let tracer = InMemoryTracer()
///
/// tracer.withSpan("operation") { span in
///     span.attributes["key"] = "value"
/// }
///
/// let spans = tracer.finishedSpans
/// XCTAssertEqual(spans.count, 1)
/// XCTAssertEqual(spans[0].operationName, "operation")
/// ```
public final class InMemoryTracer: Tracer, @unchecked Sendable {
    private let lock = NSLock()
    private var activeSpans: [String: InMemorySpan] = [:]
    private var finished: [FinishedInMemorySpan] = []

    /// Creates a new in-memory tracer.
    public init() {}

    public func startSpan(
        _ operationName: String,
        context: SpanContext?,
        ofKind kind: SpanKind,
        at instant: (any TracerInstant)?
    ) -> InMemorySpan {
        let spanContext: SpanContext
        if let parentContext = context {
            let spanID = generateSpanID()
            spanContext = parentContext.makeChild(spanID: spanID)
        } else {
            spanContext = SpanContext(
                traceID: generateTraceID(),
                spanID: generateSpanID()
            )
        }

        let startTime = instant.map { Date(tracerInstant: $0) } ?? Date()

        let span = InMemorySpan(
            context: spanContext,
            operationName: operationName,
            kind: kind,
            startTime: startTime,
            onEnd: { [weak self] finished in
                self?.handleSpanEnd(finished)
            }
        )

        lock.lock()
        activeSpans[spanContext.spanID] = span
        lock.unlock()

        return span
    }

    private func handleSpanEnd(_ span: FinishedInMemorySpan) {
        lock.lock()
        activeSpans.removeValue(forKey: span.context.spanID)
        finished.append(span)
        lock.unlock()
    }

    /// Returns all finished spans.
    public var finishedSpans: [FinishedInMemorySpan] {
        lock.lock()
        defer { lock.unlock() }
        return finished
    }

    /// Returns finished spans with the given operation name.
    public func spans(withName name: String) -> [FinishedInMemorySpan] {
        lock.lock()
        defer { lock.unlock() }
        return finished.filter { $0.operationName == name }
    }

    /// Clears all finished spans.
    public func clearFinishedSpans() {
        lock.lock()
        defer { lock.unlock() }
        finished.removeAll()
    }

    private func generateTraceID() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    private func generateSpanID() -> String {
        String(format: "%016llx", UInt64.random(in: 0...UInt64.max))
    }
}
