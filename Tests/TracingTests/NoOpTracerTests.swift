import XCTest

@testable import Tracing

final class NoOpTracerTests: XCTestCase {
  func testNoOpSpanIsNotRecording() {
    let tracer = NoOpTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    XCTAssertFalse(span.isRecording)
  }

  func testNoOpSpanOperationsAreNoOps() {
    let tracer = NoOpTracer()
    let span = tracer.startSpan("test", context: nil, ofKind: .internal, at: nil)

    span.attributes["key"] = .string("value")
    span.setStatus(.ok)
    span.addEvent(SpanEvent(name: "event"))
    span.end()

    // Should not crash and should have no effect
    XCTAssertFalse(span.isRecording)
  }

  func testWithSpanNoOp() {
    let tracer = NoOpTracer()

    let result = tracer.withSpan("test") { span in
      XCTAssertFalse(span.isRecording)
      return 42
    }

    XCTAssertEqual(result, 42)
  }
}
