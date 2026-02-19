import Testing

@testable import InMemoryTracing
@testable import Tracing

@Suite struct InMemorySpanTests {
  @Test func spanAttributes() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .client, at: nil)

    span.attributes["http.method"] = .string("GET")
    span.attributes["http.status_code"] = .int64(200)

    #expect(span.attributes["http.method"] == .string("GET"))
    #expect(span.attributes["http.status_code"] == .int64(200))

    span.end()

    let finished = tracer.finishedSpans[0]
    #expect(finished.attributes["http.method"] == .string("GET"))
    #expect(finished.attributes["http.status_code"] == .int64(200))
  }

  @Test func spanStatus() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    span.setStatus(.ok)
    span.end()

    let finished = tracer.finishedSpans[0]
    #expect(finished.status?.code == .ok)
  }

  @Test func spanEvents() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    span.addEvent(SpanEvent(name: "cache.hit"))
    span.addEvent(SpanEvent(name: "cache.miss"))
    span.end()

    let finished = tracer.finishedSpans[0]
    #expect(finished.events.count == 2)
    #expect(finished.events[0].name == "cache.hit")
    #expect(finished.events[1].name == "cache.miss")
  }

  @Test func recordError() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    struct TestError: Error {}
    span.recordError(TestError())
    span.end()

    let finished = tracer.finishedSpans[0]
    #expect(finished.status?.code == .error)
    #expect(finished.events.count == 1)
    #expect(finished.events[0].name == "exception")
  }

  @Test func spanNotRecordingAfterEnd() {
    let tracer = InMemoryTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    #expect(span.isRecording)

    span.end()

    #expect(!span.isRecording)
  }

  @Test func withSpan() {
    let tracer = InMemoryTracer()

    let result = tracer.withSpan("operation") { span in
      span.attributes["key"] = .string("value")
      return 42
    }

    #expect(result == 42)
    #expect(tracer.finishedSpans.count == 1)
    #expect(tracer.finishedSpans[0].operationName == "operation")
    #expect(tracer.finishedSpans[0].attributes["key"] == .string("value"))
    #expect(tracer.finishedSpans[0].status?.code == .ok)
  }

  @Test func withSpanError() {
    let tracer = InMemoryTracer()

    struct TestError: Error {}

    do {
      try tracer.withSpan("operation") { _ in
        throw TestError()
      }
      Issue.record("Should have thrown")
    } catch {
      // Expected
    }

    #expect(tracer.finishedSpans.count == 1)
    #expect(tracer.finishedSpans[0].status?.code == .error)
  }

  @Test func withSpanAsync() async {
    let tracer = InMemoryTracer()

    let result = await tracer.withSpan("async_operation") { span in
      span.attributes["key"] = .string("value")
      return 42
    }

    #expect(result == 42)
    #expect(tracer.finishedSpans.count == 1)
    #expect(tracer.finishedSpans[0].operationName == "async_operation")
  }
}
