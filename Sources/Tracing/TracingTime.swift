import Foundation

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#elseif os(Windows)
  import ucrt
#endif

/// A protocol representing an instant in time, used for span timestamps.
///
/// TracerInstant allows different tracing implementations to use their preferred
/// time representation while maintaining a common interface.
public protocol TracerInstant: Sendable {
  /// The elapsed time since a reference point, in nanoseconds.
  var nanosecondsSinceEpoch: UInt64 { get }
}

/// A clock that provides the current time for tracing operations.
///
/// DefaultTracerClock uses high-precision system clocks appropriate for each platform.
public struct DefaultTracerClock: Sendable {
  /// Returns the current time as a TracerInstant.
  public static func now() -> any TracerInstant {
    DefaultTracerInstant(nanosecondsSinceEpoch: Self.currentTimeNanoseconds())
  }

  private static func currentTimeNanoseconds() -> UInt64 {
    #if canImport(Darwin)
      var tv = timeval()
      gettimeofday(&tv, nil)
      return UInt64(tv.tv_sec) * 1_000_000_000 + UInt64(tv.tv_usec) * 1_000
    #elseif os(Windows)
      var ft = FILETIME()
      GetSystemTimeAsFileTime(&ft)
      let intervals = (UInt64(ft.dwHighDateTime) << 32) | UInt64(ft.dwLowDateTime)
      return intervals * 100
    #else
      var ts = timespec()
      clock_gettime(CLOCK_REALTIME, &ts)
      return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
    #endif
  }
}

/// The default implementation of TracerInstant.
public struct DefaultTracerInstant: TracerInstant {
  public let nanosecondsSinceEpoch: UInt64

  public init(nanosecondsSinceEpoch: UInt64) {
    self.nanosecondsSinceEpoch = nanosecondsSinceEpoch
  }
}

extension Date {
  /// Creates a Date from a TracerInstant.
  public init(tracerInstant: any TracerInstant) {
    let seconds = Double(tracerInstant.nanosecondsSinceEpoch) / 1_000_000_000.0
    self.init(timeIntervalSince1970: seconds)
  }
}

extension TracerInstant where Self == DefaultTracerInstant {
  /// Creates a TracerInstant from a Date.
  public static func from(_ date: Date) -> Self {
    let nanoseconds = UInt64(date.timeIntervalSince1970 * 1_000_000_000)
    return DefaultTracerInstant(nanosecondsSinceEpoch: nanoseconds)
  }
}
