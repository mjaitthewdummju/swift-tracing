import Testing

@testable import InMemoryTracing
@testable import Tracing

@Suite struct InMemoryTracerTests {
  @Test func startSpanCreatesRootSpan() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    #expect(span.isRecording)
    #expect(span.operationName == "test")
    #expect(span.context.parentSpanID == nil)
  }

  @Test func startSpanCreatesChildSpan() {
    let tracer = InMemoryTracer()
    let parentSpan = tracer.startSpan("parent", context: nil, ofKind: .internal, at: nil)
    let childSpan = tracer.startSpan(
      "child", context: parentSpan.context, ofKind: .internal, at: nil)

    #expect(childSpan.context.traceID == parentSpan.context.traceID)
    #expect(childSpan.context.parentSpanID == parentSpan.context.spanID)
  }

  @Test func finishedSpansAreRecorded() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    #expect(tracer.finishedSpans.count == 0)

    span.end()

    #expect(tracer.finishedSpans.count == 1)
    #expect(tracer.finishedSpans[0].operationName == "test")
  }

  @Test func spansWithName() {
    let tracer = InMemoryTracer()

    let span1 = tracer.startSpan("operation1", context: nil, ofKind: .internal, at: nil)
    let span2 = tracer.startSpan("operation2", context: nil, ofKind: .internal, at: nil)
    let span3 = tracer.startSpan("operation1", context: nil, ofKind: .internal, at: nil)

    span1.end()
    span2.end()
    span3.end()

    let operation1Spans = tracer.spans(withName: "operation1")
    #expect(operation1Spans.count == 2)

    let operation2Spans = tracer.spans(withName: "operation2")
    #expect(operation2Spans.count == 1)
  }

  @Test func clearFinishedSpans() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)
    span.end()

    #expect(tracer.finishedSpans.count == 1)

    tracer.clearFinishedSpans()

    #expect(tracer.finishedSpans.count == 0)
  }
}
