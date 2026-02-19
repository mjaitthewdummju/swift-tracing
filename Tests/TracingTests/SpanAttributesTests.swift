import Testing

@testable import Tracing

@Suite struct SpanAttributesTests {
  @Test func subscriptAccess() {
    var attributes = SpanAttributes()
    attributes["key"] = .string("value")

    #expect(attributes["key"] == .string("value"))
  }

  @Test func dynamicMemberAccess() {
    var attributes = SpanAttributes()
    attributes.httpMethod = .string("GET")

    #expect(attributes["http_method"] == .string("GET"))
  }

  @Test func expressibleByDictionaryLiteral() {
    let attributes: SpanAttributes = [
      "key1": .string("value1"),
      "key2": .int64(42),
    ]

    #expect(attributes["key1"] == .string("value1"))
    #expect(attributes["key2"] == .int64(42))
  }

  @Test func merge() {
    var attributes1: SpanAttributes = ["key1": .string("value1")]
    let attributes2: SpanAttributes = ["key2": .string("value2")]

    attributes1.merge(attributes2)

    #expect(attributes1["key1"] == .string("value1"))
    #expect(attributes1["key2"] == .string("value2"))
  }
}
