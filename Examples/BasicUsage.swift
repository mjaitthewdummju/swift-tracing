import Foundation
import InMemoryTracing
import Tracing
import TracingInstrumentation

// Example: Basic tracing usage

// Bootstrap the instrumentation system
InstrumentationSystem.bootstrap(InMemoryTracer())

// Example 1: Simple synchronous operation
func computeSum(_ numbers: [Int]) -> Int {
  InstrumentationSystem.tracer.withSpan("compute_sum") { span in
    span.attributes["input.count"] = .int64(Int64(numbers.count))

    let sum = numbers.reduce(0, +)

    span.attributes["result"] = .int64(Int64(sum))
    return sum
  }
}

// Example 2: Async operation with automatic context propagation
func fetchData(id: String) async throws -> String {
  try await InstrumentationSystem.tracer.withSpan("fetch_data", ofKind: .client) { span in
    span.attributes["data.id"] = .string(id)
    span.addEvent(SpanEvent(name: "fetching"))

    // Simulate async work
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    span.addEvent(SpanEvent(name: "fetched"))
    return "Data for \(id)"
  }
}

// Example 3: Nested spans with automatic parent-child relationships
func processRequest() async throws {
  try await InstrumentationSystem.tracer.withSpan("process_request") { span in
    span.attributes["request.type"] = .string("user_data")

    // This creates a child span automatically
    let data = try await fetchData(id: "123")

    // Process the data
    let _ = computeSum([1, 2, 3, 4, 5])

    span.attributes["result.length"] = .int64(Int64(data.count))
  }
}

// Example 4: Error handling
func operationThatFails() throws {
  try InstrumentationSystem.tracer.withSpan("failing_operation") { span in
    span.attributes["will_fail"] = .bool(true)

    struct CustomError: Error, LocalizedError {
      var errorDescription: String? { "Something went wrong" }
    }

    throw CustomError()
  }
}

// Run examples
@main
struct Main {
  static func main() async {
    print("Running tracing examples...\n")

    // Get the in-memory tracer to inspect spans
    guard let tracer = InstrumentationSystem.tracer as? InMemoryTracer else {
      print("Expected InMemoryTracer")
      return
    }

    // Example 1
    print("Example 1: Simple synchronous operation")
    let sum = computeSum([1, 2, 3, 4, 5])
    print("Sum: \(sum)")
    print("Spans created: \(tracer.finishedSpans.count)")
    if let span = tracer.finishedSpans.last {
      print("  - Operation: \(span.operationName)")
      print("  - Duration: \(String(format: "%.3f", span.duration * 1000))ms")
    }
    print()

    tracer.clearFinishedSpans()

    // Example 2
    print("Example 2: Async operation")
    do {
      let data = try await fetchData(id: "123")
      print("Data: \(data)")
      print("Spans created: \(tracer.finishedSpans.count)")
      if let span = tracer.finishedSpans.last {
        print("  - Operation: \(span.operationName)")
        print("  - Events: \(span.events.count)")
        for event in span.events {
          print("    - \(event.name)")
        }
      }
    } catch {
      print("Error: \(error)")
    }
    print()

    tracer.clearFinishedSpans()

    // Example 3
    print("Example 3: Nested spans")
    do {
      try await processRequest()
      print("Spans created: \(tracer.finishedSpans.count)")
      for span in tracer.finishedSpans {
        print("  - Operation: \(span.operationName)")
        print("    Trace ID: \(span.context.traceID)")
        print("    Parent: \(span.context.parentSpanID ?? "none")")
      }
    } catch {
      print("Error: \(error)")
    }
    print()

    tracer.clearFinishedSpans()

    // Example 4
    print("Example 4: Error handling")
    do {
      try operationThatFails()
    } catch {
      print("Caught error (expected)")
    }
    if let span = tracer.finishedSpans.last {
      print("Spans created: \(tracer.finishedSpans.count)")
      print("  - Operation: \(span.operationName)")
      print("  - Status: \(span.status?.code == .error ? "error" : "ok")")
      print("  - Events: \(span.events.count)")
      if let errorEvent = span.events.first {
        print("    - \(errorEvent.name)")
      }
    }

    print("\nAll examples completed!")
  }
}
