import Tracing

/// A global singleton for managing the tracer instance.
///
/// InstrumentationSystem provides a centralized way to configure tracing for your application.
/// It must be bootstrapped with a tracer implementation before use.
///
/// Example:
/// ```swift
/// // Bootstrap with in-memory tracer
/// InstrumentationSystem.bootstrap(InMemoryTracer())
///
/// // Use the global tracer
/// InstrumentationSystem.tracer.withSpan("operation") { span in
///     span.attributes["key"] = "value"
/// }
/// ```
public enum InstrumentationSystem {
    private static let lock = ReadWriteLock()
    private nonisolated(unsafe) static var _tracer: (any Tracer)?

    /// Bootstraps the instrumentation system with the given tracer.
    ///
    /// This should be called once at application startup.
    ///
    /// - Parameter tracer: The tracer to use for creating spans.
    /// - Warning: Calling this method multiple times will replace the existing tracer.
    public static func bootstrap<T: Tracer>(_ tracer: T) {
        lock.withWriterLock {
            _tracer = tracer
        }
    }

    /// The current tracer instance.
    ///
    /// If no tracer has been bootstrapped, returns a NoOpTracer.
    public static var tracer: any Tracer {
        lock.withReaderLock {
            _tracer ?? NoOpTracer()
        }
    }
}
