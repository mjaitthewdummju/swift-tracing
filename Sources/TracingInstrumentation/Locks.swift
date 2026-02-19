import Foundation

/// A read-write lock implementation using NSLock.
final class ReadWriteLock: @unchecked Sendable {
    private let lock = NSLock()

    func withWriterLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    func withReaderLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
