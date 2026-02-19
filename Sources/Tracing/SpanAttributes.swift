/// A container for span attributes that provides convenient access via dynamic member lookup.
///
/// SpanAttributes allows setting attributes using subscript or dynamic member syntax:
///
/// ```swift
/// var attributes = SpanAttributes()
/// attributes["http.method"] = "GET"
/// attributes.httpStatusCode = 200
/// ```
@dynamicMemberLookup
public struct SpanAttributes: Sendable, Hashable {
  private var storage: [String: SpanAttribute]

  /// Creates an empty attributes container.
  public init() {
    self.storage = [:]
  }

  /// Creates an attributes container with the given dictionary.
  public init(_ attributes: [String: SpanAttribute]) {
    self.storage = attributes
  }

  /// Accesses the attribute value for the given key.
  public subscript(key: String) -> SpanAttribute? {
    get { storage[key] }
    set { storage[key] = newValue }
  }

  /// Accesses the attribute value using dynamic member lookup.
  ///
  /// The member name is converted from camelCase to snake_case for the key.
  /// For example, `attributes.httpMethod` becomes `attributes["http_method"]`.
  public subscript(dynamicMember member: String) -> SpanAttribute? {
    get { storage[toSnakeCase(member)] }
    set { storage[toSnakeCase(member)] = newValue }
  }

  /// Returns all attribute keys.
  public var keys: Dictionary<String, SpanAttribute>.Keys {
    storage.keys
  }

  /// Returns all attribute values.
  public var values: Dictionary<String, SpanAttribute>.Values {
    storage.values
  }

  /// Returns the number of attributes.
  public var count: Int {
    storage.count
  }

  /// Returns true if the container is empty.
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Merges the given attributes into this container.
  public mutating func merge(_ other: SpanAttributes) {
    storage.merge(other.storage) { _, new in new }
  }

  private func toSnakeCase(_ camelCase: String) -> String {
    var result = ""
    for (index, character) in camelCase.enumerated() {
      if character.isUppercase {
        if index > 0 {
          result.append("_")
        }
        result.append(character.lowercased())
      } else {
        result.append(character)
      }
    }
    return result
  }
}

extension SpanAttributes: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, SpanAttribute)...) {
    self.storage = Dictionary(uniqueKeysWithValues: elements)
  }
}

extension SpanAttributes: Sequence {
  public func makeIterator() -> Dictionary<String, SpanAttribute>.Iterator {
    storage.makeIterator()
  }
}
