import Foundation

protocol LockType {
  mutating func withLock<T>(@noescape body: () -> T) -> T
}

// objc_sync_enter

/// A non-recursive spin lock. Designed for fast, repeated read/write critical sections.
struct SpinLock: LockType {
  mutating func withLock<T>(@noescape body: () -> T) -> T {
    OSSpinLockLock(&spinLock)
    let result = body()
    OSSpinLockUnlock(&spinLock)
    return result
  }

  private var spinLock = OS_SPINLOCK_INIT
}

protocol ReadWriteLockType {
  mutating func withReadLock<T>(@noescape body: () -> T) -> T
  mutating func withWriteLock<T>(@noescape body: () -> T) -> T
}

/// A read-write lock that gives preference to readers.
struct ReadersReadWriteLock: ReadWriteLockType {
  mutating func withReadLock<T>(@noescape body: () -> T) -> T {
    dispatch_semaphore_wait(readerCountMutex, DISPATCH_TIME_FOREVER)
    self.readerCount++
    if self.readerCount == 1 {
      dispatch_semaphore_wait(resource, DISPATCH_TIME_FOREVER)
    }
    dispatch_semaphore_signal(readerCountMutex)

    let result = body()

    dispatch_semaphore_wait(readerCountMutex, DISPATCH_TIME_FOREVER)
    self.readerCount--
    if self.readerCount == 0 {
      dispatch_semaphore_signal(resource)
    }
    dispatch_semaphore_signal(readerCountMutex)
    return result
  }

  mutating func withWriteLock<T>(@noescape body: () -> T) -> T {
    dispatch_semaphore_wait(resource, DISPATCH_TIME_FOREVER)
    let result = body()
    dispatch_semaphore_signal(resource)
    return result
  }

  private let resource = dispatch_semaphore_create(1)
  private let readerCountMutex = dispatch_semaphore_create(1)
  private var readerCount = 0
}

final class LockProtector<T> {
  typealias Type = T

  init(lock: LockType, _ item: T) {
    self.item = item
    self.lock = lock
  }

  convenience init(_ item: T) {
    self.init(lock: SpinLock(), item)
  }

  func withLock<U>(block: (inout T) -> U) -> U {
    return self.lock.withLock { [unowned self] in
      return block(&self.item)
    }
  }

  private var item: T
  private var lock: LockType
}

final class ReadWriteLockProtector<T> {
  init(lock: ReadWriteLockType, _ item: T) {
    self.item = item
    self.lock = lock
  }

  convenience init(_ item: T) {
    self.init(lock: ReadersReadWriteLock(), item)
  }

  func withReadLock<U>(block: (T) -> U) -> U {
    return self.lock.withReadLock { [unowned self] in
      return block(self.item)
    }
  }

  func withWriteLock<U>(block: (inout T) -> U) -> U {
    return self.lock.withWriteLock { [unowned self] in
      return block(&self.item)
    }
  }

  private var item: T
  private var lock: ReadWriteLockType
}
