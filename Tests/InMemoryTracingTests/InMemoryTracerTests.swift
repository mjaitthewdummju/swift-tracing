import XCTest
@testable import InMemoryTracing
@testable import Tracing

final class InMemoryTracerTests: XCTestCase {
    func testStartSpanCreatesRootSpan() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        XCTAssertTrue(span.isRecording)
        XCTAssertEqual(span.operationName, "test")
        XCTAssertNil(span.context.parentSpanID)
    }

    func testStartSpanCreatesChildSpan() {
        let tracer = InMemoryTracer()
        let parentSpan = tracer.startSpan("parent", context: nil, ofKind: .internal, at: nil)
        let childSpan = tracer.startSpan("child", context: parentSpan.context, ofKind: .internal, at: nil)

        XCTAssertEqual(childSpan.context.traceID, parentSpan.context.traceID)
        XCTAssertEqual(childSpan.context.parentSpanID, parentSpan.context.spanID)
    }

    func testFinishedSpansAreRecorded() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

        XCTAssertEqual(tracer.finishedSpans.count, 0)

        span.end()

        XCTAssertEqual(tracer.finishedSpans.count, 1)
        XCTAssertEqual(tracer.finishedSpans[0].operationName, "test")
    }

    func testSpansWithName() {
        let tracer = InMemoryTracer()

        let span1 = tracer.startSpan("operation1", context: nil, ofKind: .internal, at: nil)
        let span2 = tracer.startSpan("operation2", context: nil, ofKind: .internal, at: nil)
        let span3 = tracer.startSpan("operation1", context: nil, ofKind: .internal, at: nil)

        span1.end()
        span2.end()
        span3.end()

        let operation1Spans = tracer.spans(withName: "operation1")
        XCTAssertEqual(operation1Spans.count, 2)

        let operation2Spans = tracer.spans(withName: "operation2")
        XCTAssertEqual(operation2Spans.count, 1)
    }

    func testClearFinishedSpans() {
        let tracer = InMemoryTracer()
        let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)
        span.end()

        XCTAssertEqual(tracer.finishedSpans.count, 1)

        tracer.clearFinishedSpans()

        XCTAssertEqual(tracer.finishedSpans.count, 0)
    }
}
