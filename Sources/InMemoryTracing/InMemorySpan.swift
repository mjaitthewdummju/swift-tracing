import Foundation
import Tracing

/// An in-memory span implementation for testing and development.
///
/// InMemorySpan stores all span data in memory and is thread-safe for concurrent access.
public final class InMemorySpan: SpanProtocol, @unchecked Sendable {
    private let lock = NSLock()

    public let context: SpanContext
    public let operationName: String
    public let kind: SpanKind
    public let startTime: Date

    private var _attributes: SpanAttributes
    private var _status: SpanStatus?
    private var _events: [SpanEvent]
    private var _links: [SpanContext]
    private var _endTime: Date?

    private let onEnd: (FinishedInMemorySpan) -> Void

    public var isRecording: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _endTime == nil
    }

    public var attributes: SpanAttributes {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _attributes
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _attributes = newValue
        }
    }

    init(
        context: SpanContext,
        operationName: String,
        kind: SpanKind,
        startTime: Date,
        onEnd: @escaping (FinishedInMemorySpan) -> Void
    ) {
        self.context = context
        self.operationName = operationName
        self.kind = kind
        self.startTime = startTime
        self._attributes = SpanAttributes()
        self._status = nil
        self._events = []
        self._links = []
        self._endTime = nil
        self.onEnd = onEnd
    }

    public func setStatus(_ status: SpanStatus) {
        lock.lock()
        defer { lock.unlock() }
        guard _endTime == nil else { return }
        _status = status
    }

    public func addEvent(_ event: SpanEvent) {
        lock.lock()
        defer { lock.unlock() }
        guard _endTime == nil else { return }
        _events.append(event)
    }

    public func recordError(
        _ error: Error,
        attributes: SpanAttributes,
        at instant: (any TracerInstant)?
    ) {
        lock.lock()
        defer { lock.unlock() }
        guard _endTime == nil else { return }

        var eventAttributes = attributes
        eventAttributes["error.type"] = .string(String(describing: type(of: error)))
        eventAttributes["error.message"] = .string(error.localizedDescription)

        let timestamp = instant.map { Date(tracerInstant: $0) } ?? Date()
        let event = SpanEvent(
            name: "exception",
            timestamp: timestamp,
            attributes: eventAttributes
        )
        _events.append(event)
        _status = .error(message: error.localizedDescription)
    }

    public func addLink(_ context: SpanContext) {
        lock.lock()
        defer { lock.unlock() }
        guard _endTime == nil else { return }
        _links.append(context)
    }

    public func end(at instant: (any TracerInstant)?) {
        lock.lock()
        let endTime = instant.map { Date(tracerInstant: $0) } ?? Date()

        guard _endTime == nil else {
            lock.unlock()
            return
        }

        _endTime = endTime

        let finished = FinishedInMemorySpan(
            context: context,
            operationName: operationName,
            kind: kind,
            startTime: startTime,
            endTime: endTime,
            attributes: _attributes,
            status: _status,
            events: _events,
            links: _links
        )
        lock.unlock()

        onEnd(finished)
    }
}

/// An immutable snapshot of a completed span.
///
/// FinishedInMemorySpan is created when a span ends and provides read-only access
/// to all span data.
public struct FinishedInMemorySpan: Sendable, Hashable {
    public let context: SpanContext
    public let operationName: String
    public let kind: SpanKind
    public let startTime: Date
    public let endTime: Date
    public let attributes: SpanAttributes
    public let status: SpanStatus?
    public let events: [SpanEvent]
    public let links: [SpanContext]

    /// The duration of the span.
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
