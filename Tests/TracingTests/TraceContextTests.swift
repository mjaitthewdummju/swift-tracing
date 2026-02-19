import Testing

@testable import InMemoryTracing
@testable import Tracing

@Suite struct TraceContextTests {
  @Test func traceContextPropagation() async {
    let tracer = InMemoryTracer()

    await tracer.withSpan("parent") { parentSpan in
      // TraceContext should be set
      #expect(TraceContext.current != nil)
      #expect(TraceContext.current?.traceID == parentSpan.context.traceID)
      #expect(TraceContext.current?.spanID == parentSpan.context.spanID)

      await tracer.withSpan("child") { childSpan in
        // Child should have same trace ID but different span ID
        #expect(childSpan.context.traceID == parentSpan.context.traceID)
        #expect(childSpan.context.spanID != parentSpan.context.spanID)
        #expect(childSpan.context.parentSpanID == parentSpan.context.spanID)
      }
    }

    // Context should be cleared after withSpan completes
    #expect(TraceContext.current == nil)

    // Verify span hierarchy
    let spans = tracer.finishedSpans
    #expect(spans.count == 2)

    let parentSpan = spans.first { $0.operationName == "parent" }!
    let childSpan = spans.first { $0.operationName == "child" }!

    #expect(childSpan.context.traceID == parentSpan.context.traceID)
    #expect(childSpan.context.parentSpanID == parentSpan.context.spanID)
  }

  @Test func manualContextPropagation() {
    let tracer = InMemoryTracer()

    let parentSpan = tracer.startSpan("parent", context: nil, ofKind: .internal, at: nil)
    let childSpan = tracer.startSpan(
      "child", context: parentSpan.context, ofKind: .internal, at: nil)

    #expect(childSpan.context.traceID == parentSpan.context.traceID)
    #expect(childSpan.context.parentSpanID == parentSpan.context.spanID)

    parentSpan.end()
    childSpan.end()
  }

  @Test func multipleRootSpans() async {
    let tracer = InMemoryTracer()

    await tracer.withSpan("root1") { span1 in
      #expect(span1.context.parentSpanID == nil)
    }

    await tracer.withSpan("root2") { span2 in
      #expect(span2.context.parentSpanID == nil)
    }

    let spans = tracer.finishedSpans
    #expect(spans.count == 2)

    // Each should have different trace IDs
    #expect(spans[0].context.traceID != spans[1].context.traceID)
  }
}
