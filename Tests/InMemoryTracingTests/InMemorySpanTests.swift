import XCTest
@testable import InMemoryTracing
@testable import Tracing

final class InMemorySpanTests: XCTestCase {
    func testSpanAttributes() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .client, at: nil)

        span.attributes["http.method"] = .string("GET")
        span.attributes["http.status_code"] = .int64(200)

        XCTAssertEqual(span.attributes["http.method"], .string("GET"))
        XCTAssertEqual(span.attributes["http.status_code"], .int64(200))

        span.end()

        let finished = tracer.finishedSpans[0]
        XCTAssertEqual(finished.attributes["http.method"], .string("GET"))
        XCTAssertEqual(finished.attributes["http.status_code"], .int64(200))
    }

    func testSpanStatus() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        span.setStatus(.ok)
        span.end()

        let finished = tracer.finishedSpans[0]
        XCTAssertEqual(finished.status?.code, .ok)
    }

    func testSpanEvents() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        span.addEvent(SpanEvent(name: "cache.hit"))
        span.addEvent(SpanEvent(name: "cache.miss"))
        span.end()

        let finished = tracer.finishedSpans[0]
        XCTAssertEqual(finished.events.count, 2)
        XCTAssertEqual(finished.events[0].name, "cache.hit")
        XCTAssertEqual(finished.events[1].name, "cache.miss")
    }

    func testRecordError() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        struct TestError: Error {}
        span.recordError(TestError())
        span.end()

        let finished = tracer.finishedSpans[0]
        XCTAssertEqual(finished.status?.code, .error)
        XCTAssertEqual(finished.events.count, 1)
        XCTAssertEqual(finished.events[0].name, "exception")
    }

    func testSpanNotRecordingAfterEnd() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        XCTAssertTrue(span.isRecording)

        span.end()

        XCTAssertFalse(span.isRecording)
    }

    func testWithSpan() {
        let tracer = InMemoryTracer()

        let result = tracer.withSpan("operation") { span in
            span.attributes["key"] = .string("value")
            return 42
        }

        XCTAssertEqual(result, 42)
        XCTAssertEqual(tracer.finishedSpans.count, 1)
        XCTAssertEqual(tracer.finishedSpans[0].operationName, "operation")
        XCTAssertEqual(tracer.finishedSpans[0].attributes["key"], .string("value"))
        XCTAssertEqual(tracer.finishedSpans[0].status?.code, .ok)
    }

    func testWithSpanError() {
        let tracer = InMemoryTracer()

        struct TestError: Error {}

        do {
            try tracer.withSpan("operation") { _ in
                throw TestError()
            }
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }

        XCTAssertEqual(tracer.finishedSpans.count, 1)
        XCTAssertEqual(tracer.finishedSpans[0].status?.code, .error)
    }

    func testWithSpanAsync() async {
        let tracer = InMemoryTracer()

        let result = await tracer.withSpan("async_operation") { span in
            span.attributes["key"] = .string("value")
            return 42
        }

        XCTAssertEqual(result, 42)
        XCTAssertEqual(tracer.finishedSpans.count, 1)
        XCTAssertEqual(tracer.finishedSpans[0].operationName, "async_operation")
    }
}
