# Swift Tracing

A lightweight, protocol-oriented tracing package for Swift, focused on instrumenting client libraries without the complexity of distributed system concerns.

## Overview

Swift Tracing provides the core abstractions needed for tracing operations in your Swift applications:
- **Protocol-oriented design** with `Tracer` and `Span` protocols
- **Automatic context propagation** using task-local values
- **Zero-overhead** when tracing is disabled (via `NoOpTracer`)
- **Thread-safe** in-memory implementation for testing and development
- **No external dependencies** - pure Swift package

## Installation

Add Swift Tracing to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/grdsdev/swift-tracing.git", from: "1.0.0")
]
```

Then add the modules you need to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Tracing", package: "swift-tracing"),
        .product(name: "InMemoryTracing", package: "swift-tracing"),
        .product(name: "TracingInstrumentation", package: "swift-tracing"),
    ]
)
```

## Quick Start

### Basic Usage

```swift
import Tracing
import InMemoryTracing
import TracingInstrumentation

// Bootstrap with an in-memory tracer
InstrumentationSystem.bootstrap(InMemoryTracer())

// Use the global tracer
func fetchUser(id: String) async throws -> User {
    try await InstrumentationSystem.tracer.withSpan("fetch_user", ofKind: .client) { span in
        span.attributes["user.id"] = .string(id)
        span.addEvent(SpanEvent(name: "fetching"))

        let user = try await httpClient.get("/users/\(id)")

        span.addEvent(SpanEvent(name: "fetched"))
        return user
    }
}
```

### Manual Span Management

For more control, you can manage spans manually:

```swift
let tracer = InMemoryTracer()
let span = tracer.startSpan("database.query", ofKind: .client)
span.attributes["db.system"] = .string("postgresql")
span.attributes["db.statement"] = .string("SELECT * FROM users")
defer { span.end() }

do {
    let result = try await database.query("SELECT * FROM users")
    span.setStatus(.ok)
} catch {
    span.recordError(error)
    throw error
}
```

### Nested Spans

Spans automatically propagate context to child operations:

```swift
func processRequest() async throws {
    try await tracer.withSpan("process_request") { span in
        // This creates a child span automatically
        let user = try await fetchUser(id: "123")

        // This also creates a child span
        try await updateDatabase(user)
    }
}
```

## Core Concepts

### Spans

A span represents a single operation within a trace. It has:
- **Operation name**: A human-readable name for the operation
- **Context**: Trace and span identifiers for correlation
- **Kind**: The type of operation (client, server, internal, producer, consumer)
- **Attributes**: Key-value metadata about the operation
- **Events**: Timestamped events that occurred during the operation
- **Status**: Success or failure state
- **Duration**: Start and end times

### Attributes

Attributes are type-safe key-value pairs that describe a span:

```swift
span.attributes["http.method"] = .string("GET")
span.attributes["http.status_code"] = .int64(200)
span.attributes["cache.hit"] = .bool(true)
span.attributes["response.headers"] = .stringArray(["Content-Type", "Authorization"])
```

Attributes support:
- `Int32`, `Int64`, `Double`, `String`, `Bool`
- Arrays of the above types
- Dynamic member lookup for ergonomic access

### Events

Events mark significant points during a span's lifetime:

```swift
span.addEvent(SpanEvent(name: "cache.miss"))
span.addEvent(SpanEvent(
    name: "query.executed",
    attributes: ["query.duration_ms": .int64(42)]
))
```

### Status

Spans have a status indicating success or failure:

```swift
span.setStatus(.ok)
span.setStatus(.error(message: "Connection timeout"))

// Or use recordError for automatic error handling
span.recordError(error)
```

## Modules

### Tracing

The core module containing all protocols and types:
- `Tracer` and `SpanProtocol` protocols
- `SpanContext` and `TraceContext` for context management
- `SpanAttribute`, `SpanEvent`, `SpanStatus`, `SpanKind`
- `NoOpTracer` for zero-overhead disabled tracing

### InMemoryTracing

An in-memory tracer implementation for testing and development:
- `InMemoryTracer`: Thread-safe tracer that stores spans in memory
- `InMemorySpan`: Full-featured span implementation
- `FinishedInMemorySpan`: Immutable completed span

Query spans after execution:

```swift
let tracer = InMemoryTracer()

tracer.withSpan("operation") { span in
    span.attributes["key"] = .string("value")
}

// Query finished spans
let spans = tracer.finishedSpans
XCTAssertEqual(spans.count, 1)
XCTAssertEqual(spans[0].operationName, "operation")

// Query by name
let operationSpans = tracer.spans(withName: "operation")
```

### TracingInstrumentation

Optional global instrumentation system:
- `InstrumentationSystem.bootstrap(_:)` to configure the global tracer
- `InstrumentationSystem.tracer` to access the global tracer
- Thread-safe singleton pattern

## Client Library Instrumentation Patterns

### HTTP Client

```swift
struct HTTPClient {
    let tracer: any Tracer

    func get(_ url: String) async throws -> Data {
        try await tracer.withSpan("http.request", ofKind: .client) { span in
            span.attributes["http.method"] = .string("GET")
            span.attributes["http.url"] = .string(url)

            let (data, response) = try await URLSession.shared.data(from: URL(string: url)!)

            if let httpResponse = response as? HTTPURLResponse {
                span.attributes["http.status_code"] = .int64(Int64(httpResponse.statusCode))
            }

            return data
        }
    }
}
```

### Database Client

```swift
struct DatabaseClient {
    let tracer: any Tracer

    func query(_ sql: String) async throws -> [Row] {
        try await tracer.withSpan("db.query", ofKind: .client) { span in
            span.attributes["db.system"] = .string("postgresql")
            span.attributes["db.statement"] = .string(sql)

            span.addEvent(SpanEvent(name: "query.start"))

            let rows = try await executeQuery(sql)

            span.addEvent(SpanEvent(
                name: "query.complete",
                attributes: ["db.rows_affected": .int64(Int64(rows.count))]
            ))

            return rows
        }
    }
}
```

### Cache Client

```swift
struct CacheClient {
    let tracer: any Tracer

    func get(_ key: String) async -> String? {
        await tracer.withSpan("cache.get", ofKind: .client) { span in
            span.attributes["cache.key"] = .string(key)

            if let value = await cache.get(key) {
                span.addEvent(SpanEvent(name: "cache.hit"))
                span.attributes["cache.hit"] = .bool(true)
                return value
            } else {
                span.addEvent(SpanEvent(name: "cache.miss"))
                span.attributes["cache.hit"] = .bool(false)
                return nil
            }
        }
    }
}
```

## Migration from swift-distributed-tracing

If you're migrating from Apple's swift-distributed-tracing package:

### What's Different

| swift-distributed-tracing | swift-tracing |
|----------------------------|---------------|
| `ServiceContext` | `SpanContext` |
| Requires explicit context passing | Automatic task-local propagation |
| `Instrument`/`Extractor`/`Injector` protocols | Removed (not needed for local tracing) |
| W3C Baggage support | Removed (not needed for local tracing) |
| Carrier-agnostic serialization | Removed (not needed for local tracing) |
| `Span` protocol | `SpanProtocol` (renamed to avoid naming conflicts) |

### Migration Example

**Before (swift-distributed-tracing):**

```swift
func fetchUser(id: String, context: ServiceContext) async throws -> User {
    var span = InstrumentationSystem.tracer.startSpan("fetch_user", context: context)
    defer { span.end() }

    span.attributes["user.id"] = id
    return try await httpClient.get("/users/\(id)")
}
```

**After (swift-tracing):**

```swift
func fetchUser(id: String) async throws -> User {
    try await InstrumentationSystem.tracer.withSpan("fetch_user", ofKind: .client) { span in
        span.attributes["user.id"] = .string(id)
        return try await httpClient.get("/users/\(id)")
    }
}
```

Key changes:
1. No manual `ServiceContext` parameter needed
2. Context propagates automatically via task-local values
3. `withSpan` handles span lifecycle automatically
4. Attributes require explicit type wrapping (`.string()`, `.int64()`, etc.)

## Design Philosophy

Swift Tracing is designed specifically for **client library instrumentation** rather than distributed systems. This means:

- ✅ Local span hierarchy and context propagation
- ✅ Automatic parent-child relationships via task-local values
- ✅ Zero dependencies and minimal API surface
- ✅ Thread-safe, concurrent-ready design
- ❌ No cross-process context propagation (W3C Trace Context, Baggage)
- ❌ No carrier injection/extraction
- ❌ No distributed system concerns

This focused scope makes the package simpler to understand and use for the common case of instrumenting client libraries like HTTP clients, database clients, and cache clients.

## Platform Support

Swift Tracing supports:
- macOS 10.15+
- iOS 13+
- tvOS 13+
- watchOS 6+
- Linux
- Windows

Requires Swift 5.9+ for task-local values and strict concurrency support.

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request on GitHub.
