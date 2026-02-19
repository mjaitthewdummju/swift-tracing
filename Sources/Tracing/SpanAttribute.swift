/// A type-safe value that can be attached to a ``Span`` as metadata.
///
/// SpanAttribute supports common value types and their array variants:
/// - Numeric values: Int32, Int64, Double
/// - Text values: String
/// - Boolean values: Bool
/// - Arrays of the above types
///
/// Example:
/// ```swift
/// span.attributes["http.status_code"] = 200
/// span.attributes["http.method"] = "GET"
/// span.attributes["cache.hit"] = true
/// span.attributes["response.headers"] = ["Content-Type", "Authorization"]
/// ```
public enum SpanAttribute: Sendable, Hashable {
  case int32(Int32)
  case int64(Int64)
  case double(Double)
  case string(String)
  case bool(Bool)

  case int32Array([Int32])
  case int64Array([Int64])
  case doubleArray([Double])
  case stringArray([String])
  case boolArray([Bool])
}

extension SpanAttribute: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .int64(Int64(value))
  }
}

extension SpanAttribute: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .double(value)
  }
}

extension SpanAttribute: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension SpanAttribute: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension SpanAttribute: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: String...) {
    self = .stringArray(elements)
  }
}
