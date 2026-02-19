/// Describes the relationship between the span, its parent, and its children in a trace.
///
/// SpanKind helps categorize spans based on their role in a distributed system:
/// - Client spans represent outgoing requests
/// - Server spans represent incoming requests
/// - Producer spans represent messages being sent to a broker
/// - Consumer spans represent messages being received from a broker
/// - Internal spans represent internal operations
public enum SpanKind: Sendable, Hashable {
    /// Indicates that the span represents a request to a remote service.
    case client

    /// Indicates that the span represents the handling of an incoming request.
    case server

    /// Indicates that the span represents the creation of a message to be sent to a broker.
    case producer

    /// Indicates that the span represents the processing of a message from a broker.
    case consumer

    /// Indicates that the span represents an internal operation within an application.
    case `internal`
}
