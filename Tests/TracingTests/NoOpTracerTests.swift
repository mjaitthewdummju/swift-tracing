import Testing

@testable import Tracing

@Suite struct NoOpTracerTests {
  @Test func noOpSpanIsNotRecording() {
    let tracer = NoOpTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    #expect(!span.isRecording)
  }

  @Test func noOpSpanOperationsAreNoOps() {
    let tracer = NoOpTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    span.attributes["key"] = .string("value")
    span.setStatus(.ok)
    span.addEvent(SpanEvent(name: "event"))
    span.end()

    // Should not crash and should have no effect
    #expect(!span.isRecording)
  }

  @Test func withSpanNoOp() {
    let tracer = NoOpTracer()

    let result = tracer.withSpan("test") { span in
      #expect(!span.isRecording)
      return 42
    }

    #expect(result == 42)
  }
}
