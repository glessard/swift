//===--- RawSpanIndex.swift -----------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if hasFeature(NonescapableTypes) && hasFeature(BitwiseCopyable)

extension RawSpan /*where Element: ~Copyable & ~Escapable*/ {
  @frozen
  public struct Index {
    @usableFromInline let _allocation: UnsafeRawPointer
    @usableFromInline let _rawValue: UnsafeRawPointer

    @inlinable @inline(__always)
    internal init(allocation: UnsafeRawPointer, rawValue: UnsafeRawPointer) {
      (_allocation, _rawValue) = (allocation, rawValue)
    }

    @inlinable @inline(__always)
    internal init(_rawStart: UnsafeRawPointer) {
      self.init(allocation: _rawStart, rawValue: _rawStart)
    }

    @inlinable @inline(__always)
    internal init<T: _BitwiseCopyable>(_ index: StorageView<T>.Index) {
      self.init(allocation: index._allocation, rawValue: index._rawValue)
    }
  }
}

@available(*, unavailable)
extension RawSpan.Index: Sendable {}

extension RawSpan.Index: Equatable /*where Element: ~Copyable & ~Escapable*/ {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    // note: if we don't define this function, then `Strideable` will define it.
    (lhs._allocation == rhs._allocation) && (lhs._rawValue == rhs._rawValue)
  }
}

extension RawSpan.Index: Hashable /*where Element: ~Copyable & ~Escapable*/ {}

extension RawSpan.Index: Strideable /*where Element: ~Copyable*/ /*& ~Escapable*/ {
  public typealias Stride = Int

  @inlinable @inline(__always)
  public func distance(to other: Self) -> Int {
    precondition(_allocation == other._allocation)
    return _rawValue.distance(to: other._rawValue)
  }

  @inlinable @inline(__always)
  public func advanced(by n: Int) -> Self {
    .init(allocation: _allocation, rawValue: _rawValue.advanced(by: n))
  }
}

extension RawSpan.Index: Comparable /*where Element: ~Copyable*/ /*& ~Escapable*/ {
  @inlinable @inline(__always)
  public static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs._rawValue < rhs._rawValue
  }
}

#endif
