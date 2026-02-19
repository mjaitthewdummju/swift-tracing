import XCTest
@testable import Tracing
@testable import InMemoryTracing

final class TraceContextTests: XCTestCase {
    func testTraceContextPropagation() async {
        let tracer = InMemoryTracer()

        await tracer.withSpan("parent") { parentSpan in
            // TraceContext should be set
            XCTAssertNotNil(TraceContext.current)
            XCTAssertEqual(TraceContext.current?.traceID, parentSpan.context.traceID)
            XCTAssertEqual(TraceContext.current?.spanID, parentSpan.context.spanID)

            await tracer.withSpan("child") { childSpan in
                // Child should have same trace ID but different span ID
                XCTAssertEqual(childSpan.context.traceID, parentSpan.context.traceID)
                XCTAssertNotEqual(childSpan.context.spanID, parentSpan.context.spanID)
                XCTAssertEqual(childSpan.context.parentSpanID, parentSpan.context.spanID)
            }
        }

        // Context should be cleared after withSpan completes
        XCTAssertNil(TraceContext.current)

        // Verify span hierarchy
        let spans = tracer.finishedSpans
        XCTAssertEqual(spans.count, 2)

        let parentSpan = spans.first { $0.operationName == "parent" }!
        let childSpan = spans.first { $0.operationName == "child" }!

        XCTAssertEqual(childSpan.context.traceID, parentSpan.context.traceID)
        XCTAssertEqual(childSpan.context.parentSpanID, parentSpan.context.spanID)
    }

    func testManualContextPropagation() {
        let tracer = InMemoryTracer()

        let parentSpan = tracer.startSpan("parent", context: nil, ofKind: .internal, at: nil)
        let childSpan = tracer.startSpan("child", context: parentSpan.context, ofKind: .internal, at: nil)

        XCTAssertEqual(childSpan.context.traceID, parentSpan.context.traceID)
        XCTAssertEqual(childSpan.context.parentSpanID, parentSpan.context.spanID)

        parentSpan.end()
        childSpan.end()
    }

    func testMultipleRootSpans() async {
        let tracer = InMemoryTracer()

        await tracer.withSpan("root1") { span1 in
            XCTAssertNil(span1.context.parentSpanID)
        }

        await tracer.withSpan("root2") { span2 in
            XCTAssertNil(span2.context.parentSpanID)
        }

        let spans = tracer.finishedSpans
        XCTAssertEqual(spans.count, 2)

        // Each should have different trace IDs
        XCTAssertNotEqual(spans[0].context.traceID, spans[1].context.traceID)
    }
}
