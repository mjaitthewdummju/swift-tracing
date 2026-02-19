import XCTest

@testable import Tracing

final class SpanAttributesTests: XCTestCase {
  func testSubscriptAccess() {
    var attributes = SpanAttributes()
    attributes["key"] = .string("value")

    XCTAssertEqual(attributes["key"], .string("value"))
  }

  func testDynamicMemberAccess() {
    var attributes = SpanAttributes()
    attributes.httpMethod = .string("GET")

    XCTAssertEqual(attributes["http_method"], .string("GET"))
  }

  func testExpressibleByDictionaryLiteral() {
    let attributes: SpanAttributes = [
      "key1": .string("value1"),
      "key2": .int64(42),
    ]

    XCTAssertEqual(attributes["key1"], .string("value1"))
    XCTAssertEqual(attributes["key2"], .int64(42))
  }

  func testMerge() {
    var attributes1: SpanAttributes = ["key1": .string("value1")]
    let attributes2: SpanAttributes = ["key2": .string("value2")]

    attributes1.merge(attributes2)

    XCTAssertEqual(attributes1["key1"], .string("value1"))
    XCTAssertEqual(attributes1["key2"], .string("value2"))
  }
}
