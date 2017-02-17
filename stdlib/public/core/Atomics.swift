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

@_versioned internal func _rawAddress<T>(_ v: UnsafeMutablePointer<T>) -> Builtin.RawPointer {
  return v._rawValue
}

extension Atomic {
  public struct Int64 {
    @_versioned internal var _value: Builtin.Int64

    public init(_ value: Swift.Int64 = 0) {
      _value = value._value
    }

    @inline(__always)
    public mutating func load(order: LoadMemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicload_monotonic_Int64(_rawAddress(&_value))
      case .acquire:
        v = Builtin.atomicload_acquire_Int64(_rawAddress(&_value))
      case .sequential:
        v = Builtin.atomicload_seqcst_Int64(_rawAddress(&_value))
      }
      return Swift.Int64(v)
    }

    @inline(__always)
    public mutating func store(_ value: Swift.Int64, order: StoreMemoryOrder = .relaxed) {
      switch order {
      case .relaxed:
        Builtin.atomicstore_monotonic_Int64(_rawAddress(&_value), value._value)
      case .release:
        Builtin.atomicstore_release_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        Builtin.atomicstore_seqcst_Int64(_rawAddress(&_value), value._value)
      }
    }

    @inline(__always) @discardableResult
    public mutating func swap(_ value: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_xchg_monotonic_Int64(_rawAddress(&_value), value._value)
      case .acquire:
        v = Builtin.atomicrmw_xchg_acquire_Int64(_rawAddress(&_value), value._value)
      case .release:
        v = Builtin.atomicrmw_xchg_release_Int64(_rawAddress(&_value), value._value)
      case .acqrel:
        v = Builtin.atomicrmw_xchg_acqrel_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        v = Builtin.atomicrmw_xchg_seqcst_Int64(_rawAddress(&_value), value._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func add(_ value: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_add_monotonic_Int64(_rawAddress(&_value), value._value)
      case .acquire:
        v = Builtin.atomicrmw_add_acquire_Int64(_rawAddress(&_value), value._value)
      case .release:
        v = Builtin.atomicrmw_add_release_Int64(_rawAddress(&_value), value._value)
      case .acqrel:
        v = Builtin.atomicrmw_add_acqrel_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        v = Builtin.atomicrmw_add_seqcst_Int64(_rawAddress(&_value), value._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func subtract(_ value: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_sub_monotonic_Int64(_rawAddress(&_value), value._value)
      case .acquire:
        v = Builtin.atomicrmw_sub_acquire_Int64(_rawAddress(&_value), value._value)
      case .release:
        v = Builtin.atomicrmw_sub_release_Int64(_rawAddress(&_value), value._value)
      case .acqrel:
        v = Builtin.atomicrmw_sub_acqrel_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        v = Builtin.atomicrmw_sub_seqcst_Int64(_rawAddress(&_value), value._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func increment(order: MemoryOrder = .relaxed) -> Swift.Int64 {
      return add(1, order: order)
    }

    @inline(__always) @discardableResult
    public mutating func decrement(order: MemoryOrder = .relaxed) -> Swift.Int64 {
      return subtract(1, order: order)
    }

    @inline(__always) @discardableResult
    public mutating func bitwiseOr(_ bits: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_or_monotonic_Int64(_rawAddress(&_value), bits._value)
      case .acquire:
        v = Builtin.atomicrmw_or_acquire_Int64(_rawAddress(&_value), bits._value)
      case .release:
        v = Builtin.atomicrmw_or_release_Int64(_rawAddress(&_value), bits._value)
      case .acqrel:
        v = Builtin.atomicrmw_or_acqrel_Int64(_rawAddress(&_value), bits._value)
      case .sequential:
        v = Builtin.atomicrmw_or_seqcst_Int64(_rawAddress(&_value), bits._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func bitwiseXor(_ bits: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_xor_monotonic_Int64(_rawAddress(&_value), bits._value)
      case .acquire:
        v = Builtin.atomicrmw_xor_acquire_Int64(_rawAddress(&_value), bits._value)
      case .release:
        v = Builtin.atomicrmw_xor_release_Int64(_rawAddress(&_value), bits._value)
      case .acqrel:
        v = Builtin.atomicrmw_xor_acqrel_Int64(_rawAddress(&_value), bits._value)
      case .sequential:
        v = Builtin.atomicrmw_xor_seqcst_Int64(_rawAddress(&_value), bits._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func bitwiseAnd(_ bits: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_and_monotonic_Int64(_rawAddress(&_value), bits._value)
      case .acquire:
        v = Builtin.atomicrmw_and_acquire_Int64(_rawAddress(&_value), bits._value)
      case .release:
        v = Builtin.atomicrmw_and_release_Int64(_rawAddress(&_value), bits._value)
      case .acqrel:
        v = Builtin.atomicrmw_and_acqrel_Int64(_rawAddress(&_value), bits._value)
      case .sequential:
        v = Builtin.atomicrmw_and_seqcst_Int64(_rawAddress(&_value), bits._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func bitwiseNand(_ bits: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_nand_monotonic_Int64(_rawAddress(&_value), bits._value)
      case .acquire:
        v = Builtin.atomicrmw_nand_acquire_Int64(_rawAddress(&_value), bits._value)
      case .release:
        v = Builtin.atomicrmw_nand_release_Int64(_rawAddress(&_value), bits._value)
      case .acqrel:
        v = Builtin.atomicrmw_nand_acqrel_Int64(_rawAddress(&_value), bits._value)
      case .sequential:
        v = Builtin.atomicrmw_nand_seqcst_Int64(_rawAddress(&_value), bits._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func min(_ value: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_min_monotonic_Int64(_rawAddress(&_value), value._value)
      case .acquire:
        v = Builtin.atomicrmw_min_acquire_Int64(_rawAddress(&_value), value._value)
      case .release:
        v = Builtin.atomicrmw_min_release_Int64(_rawAddress(&_value), value._value)
      case .acqrel:
        v = Builtin.atomicrmw_min_acqrel_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        v = Builtin.atomicrmw_min_seqcst_Int64(_rawAddress(&_value), value._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func max(_ value: Swift.Int64, order: MemoryOrder = .relaxed) -> Swift.Int64 {
      let v: Builtin.Int64
      switch order {
      case .relaxed:
        v = Builtin.atomicrmw_max_monotonic_Int64(_rawAddress(&_value), value._value)
      case .acquire:
        v = Builtin.atomicrmw_max_acquire_Int64(_rawAddress(&_value), value._value)
      case .release:
        v = Builtin.atomicrmw_max_release_Int64(_rawAddress(&_value), value._value)
      case .acqrel:
        v = Builtin.atomicrmw_max_acqrel_Int64(_rawAddress(&_value), value._value)
      case .sequential:
        v = Builtin.atomicrmw_max_seqcst_Int64(_rawAddress(&_value), value._value)
      }
      return Swift.Int64(v)
    }

    @inline(__always) @discardableResult
    public mutating func compareAndSwap(current: Swift.Int64, future: Swift.Int64,
                                        orderSuccess: MemoryOrder = .relaxed,
                                        orderFailure: LoadMemoryOrder = .relaxed) -> Bool {
      let s: Builtin.Int1
      let a = _rawAddress(&_value)
      let c = current._value
      let f = future._value
      switch (orderSuccess, orderFailure) {
      case (.relaxed, .relaxed):
        (_, s) = Builtin.cmpxchg_monotonic_monotonic_Int64(a, c, f)
      case (.acquire, .relaxed):
        (_, s) = Builtin.cmpxchg_acquire_monotonic_Int64(a, c, f)
      case (.acquire, .acquire):
        (_, s) = Builtin.cmpxchg_acquire_acquire_Int64(a, c, f)
      case (.release, .relaxed):
        (_, s) = Builtin.cmpxchg_release_monotonic_Int64(a, c, f)
      case (.acqrel, .relaxed):
        (_, s) = Builtin.cmpxchg_acqrel_monotonic_Int64(a, c, f)
      case (.acqrel, .acquire):
        (_, s) = Builtin.cmpxchg_acqrel_acquire_Int64(a, c, f)
      case (.sequential, .relaxed):
        (_, s) = Builtin.cmpxchg_seqcst_monotonic_Int64(a, c, f)
      case (.sequential, .acquire):
        (_, s) = Builtin.cmpxchg_seqcst_acquire_Int64(a, c, f)
      case (.sequential, .sequential):
        (_, s) = Builtin.cmpxchg_seqcst_seqcst_Int64(a, c, f)
      default:
        fatalError("memory order combination invalid in \(#function): \(orderSuccess), \(orderFailure)")
      }
      return Bool(s)
    }

    @inline(__always) @discardableResult
    public mutating func compareAndSwap(current: inout Swift.Int64, future: Swift.Int64,
                                        orderSuccess: MemoryOrder = .relaxed,
                                        orderFailure: LoadMemoryOrder = .relaxed) -> Bool {
      let r: Builtin.Int64
      let s: Builtin.Int1
      let a = _rawAddress(&_value)
      let c = current._value
      let f = future._value
      switch (orderSuccess, orderFailure) {
      case (.relaxed, .relaxed):
        (r, s) = Builtin.cmpxchg_monotonic_monotonic_Int64(a, c, f)
      case (.acquire, .relaxed):
        (r, s) = Builtin.cmpxchg_acquire_monotonic_Int64(a, c, f)
      case (.acquire, .acquire):
        (r, s) = Builtin.cmpxchg_acquire_acquire_Int64(a, c, f)
      case (.release, .relaxed):
        (r, s) = Builtin.cmpxchg_release_monotonic_Int64(a, c, f)
      case (.acqrel, .relaxed):
        (r, s) = Builtin.cmpxchg_acqrel_monotonic_Int64(a, c, f)
      case (.acqrel, .acquire):
        (r, s) = Builtin.cmpxchg_acqrel_acquire_Int64(a, c, f)
      case (.sequential, .relaxed):
        (r, s) = Builtin.cmpxchg_seqcst_monotonic_Int64(a, c, f)
      case (.sequential, .acquire):
        (r, s) = Builtin.cmpxchg_seqcst_acquire_Int64(a, c, f)
      case (.sequential, .sequential):
        (r, s) = Builtin.cmpxchg_seqcst_seqcst_Int64(a, c, f)
      default:
        fatalError("memory order combination invalid in \(#function): \(orderSuccess), \(orderFailure)")
      }
      current = Swift.Int64(r)
      return Bool(s)
    }
  }
}
