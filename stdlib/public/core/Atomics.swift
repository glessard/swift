public enum Atomic {}

extension Atomic {
  public enum MemoryOrder {
    case relaxed, /* consume, */ acquire, release, acqrel, sequential
  }

  public enum LoadMemoryOrder {
    case relaxed, /* consume, */ acquire, sequential
  }

  public enum StoreMemoryOrder {
    case relaxed, release, sequential
  }
}

@_versioned internal func __unsafe_address<T>(_ v: UnsafeMutablePointer<T>) -> Builtin.RawPointer {
  return v._rawValue
}
