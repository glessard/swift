//===--- RawSpan.swift ----------------------------------------------------===//
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

@frozen
public struct RawSpan: Copyable, ~Escapable {
  @usableFromInline let _start: Index
  @usableFromInline let _count: Int

  @inlinable @inline(__always)
  internal init<Owner: ~Copyable & ~Escapable>(
    _unchecked start: Index,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self._start = start
    self._count = count
  }

  @inlinable @inline(__always)
  internal init<Owner: ~Copyable & ~Escapable>(
    _unchecked start: Index,
    count: Int,
    consuming owner: consuming Owner
  ) -> dependsOn(owner) Self {
    self._start = start
    self._count = count
  }
}

@available(*, unavailable)
extension RawSpan: Sendable {}

extension RawSpan {

  @inlinable @inline(__always)
  internal init<Owner: ~Copyable & ~Escapable>(
    start: Index,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    precondition(count >= 0, "Count must not be negative")
    self.init(_unchecked: start, count: count, owner: owner)
  }

#if hasFeature(BitwiseCopyable)
  @inlinable @inline(__always)
  internal init<T: _BitwiseCopyable>(
    _ owner: borrowing StorageView<T>
  ) -> dependsOn(owner) Self {
    let start = Index(
      allocation: owner.startIndex._allocation,
      rawValue: owner.startIndex._rawValue
    )
    self.init(
      _unchecked: start, count: owner.count*MemoryLayout<T>.stride, owner: owner
    )
  }
#endif
}

extension RawSpan {
  @inlinable @inline(__always)
  func boundsCheckPrecondition(_ position: Index) {
    precondition(
      startIndex._allocation == position._allocation &&
      distance(from: startIndex, to: position) >= 0 &&
      distance(from: position, to: endIndex) > 0,
      "Index out of bounds"
    )
  }

  @inlinable @inline(__always)
  func boundsCheckPrecondition(_ bounds: Range<Index>) {
    precondition(
      startIndex._allocation == bounds.lowerBound._allocation &&
      startIndex._allocation == bounds.upperBound._allocation &&
      startIndex._rawValue.distance(to: bounds.lowerBound._rawValue) >= 0 &&
      bounds.lowerBound._rawValue.distance(to: bounds.upperBound._rawValue) >= 0 &&
      bounds.upperBound._rawValue.distance(to: endIndex._rawValue) >= 0,
      "Range of indices out of bounds"
    )
  }
}

//MARK: Index Manipulation
extension RawSpan {
  //  Collection,
  //  BidirectionalCollection,
  //  RandomAccessCollection

  @inlinable @inline(__always)
  public var startIndex: Index { _start }

  @inlinable @inline(__always)
  public var endIndex: Index { _start.advanced(by: _count) }

  @inlinable @inline(__always)
  public var count: Int {
    borrowing get { self._count }
  }

  @inlinable @inline(__always)
  public var isEmpty: Bool { count == 0 }

  @inlinable @inline(__always)
  public var indices: Range<Index> {
    .init(uncheckedBounds: (startIndex, endIndex))
  }

  @inlinable @inline(__always)
  public func index(after i: Index) -> Index {
    i.advanced(by: +1)
  }

  @inlinable @inline(__always)
  public func index(before i: Index) -> Index {
    i.advanced(by: -1)
  }

  @inlinable @inline(__always)
  public func formIndex(after i: inout Index) {
    i = index(after: i)
  }

  @inlinable @inline(__always)
  public func formIndex(before i: inout Index) {
    i = index(before: i)
  }

  @inlinable @inline(__always)
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    i.advanced(by: distance)
  }

  @inlinable @inline(__always)
  public func formIndex(_ i: inout Index, offsetBy distance: Int) {
    i = index(i, offsetBy: distance)
  }

  @inlinable @inline(__always)
  public func distance(from start: Index, to end: Index) -> Int {
    start.distance(to: end)
  }
}

//MARK: index-based slicing subscripts
extension RawSpan {

  //FIXME: lifetime-dependent on self
  @inlinable @inline(__always)
  public subscript(bounds: Range<Index>) -> Self {
    consuming get {
      boundsCheckPrecondition(bounds)
      return (copy self)[unchecked: bounds]
    }
  }

  //FIXME: lifetime-dependent on self
  @inlinable @inline(__always)
  public subscript(unchecked bounds: Range<Index>) -> Self {
    consuming get {
      RawSpan(
        start: bounds.lowerBound,
        count: bounds.count,
        owner: self
      )
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(bounds: some RangeExpression<Index>) -> Self {
    consuming get {
      (copy self)[bounds.relative(to: indices)]
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(unchecked bounds: some RangeExpression<Index>) -> Self {
    consuming get {
      (copy self)[unchecked: bounds.relative(to: indices)]
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(x: UnboundedRange) -> Self {
    consuming get {
      (copy self)[unchecked: indices]
    }
  }
}

//MARK: integer offset subscripts
extension RawSpan {

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(offsets: Range<Int>) -> Self {
    borrowing get {
      precondition(0 <= offsets.lowerBound && offsets.upperBound <= count)
      return RawSpan(
        _unchecked: index(startIndex, offsetBy: offsets.lowerBound),
        count: offsets.count,
        owner: self
      )
//      return (copy self)[uncheckedOffsets: offsets]
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(uncheckedOffsets offsets: Range<Int>) -> Self {
    borrowing get {
      RawSpan(
        _unchecked: index(startIndex, offsetBy: offsets.lowerBound),
        count: offsets.count,
        owner: self
      )
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(offsets: some RangeExpression<Int>) -> Self {
    borrowing get {
      self[offsets.relative(to: 0..<count)]
    }
  }

  //FIXME: lifetime-dependent on self
  @_alwaysEmitIntoClient
  public subscript(uncheckedOffsets offsets: some RangeExpression<Int>) -> Self {
    borrowing get {
      self[uncheckedOffsets: offsets.relative(to: 0..<count)]
    }
  }
}

//MARK: withUnsafeBytes
extension RawSpan {

  //FIXME: mark closure parameter as non-escaping
  @_alwaysEmitIntoClient
  borrowing public func withUnsafeBytes<E: Error, R: ~Copyable/*& ~Escapable*/>(
    _ body: (_ buffer: UnsafeRawBufferPointer) throws(E) -> R
  ) throws(E) -> /*dependsOn(self)*/ R {
    let rawBuffer = UnsafeRawBufferPointer(
      start: count==0 ? nil : _start._rawValue,
      count: count
    )
    return try body(rawBuffer)
  }

  //FIXME: mark closure parameter as non-escaping
//  @_alwaysEmitIntoClient
//  public func withContiguousStorageIfAvailable<E: Error, R/*: ~Copyable & ~Escapable*/>(
//    _ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R
//  ) throws(E) -> R? {
//    try withUnsafeBytes {
//      bytes throws(E) -> R in
//      try bytes.withMemoryRebound(to: UInt8.self, body)
//    }
//  }

#if hasFeature(BitwiseCopyable)
  consuming public func view<T: _BitwiseCopyable>(
    as: T.Type
  ) -> dependsOn(self) StorageView<T> {
    let (c, r) = count.quotientAndRemainder(dividingBy: MemoryLayout<T>.stride)
    precondition(r == 0, "Returned span must contain whole number of T")
    return StorageView(
      unsafeRawPointer: _start._rawValue, as: T.self, count: c, owner: self
    )
  }
#endif
}

//MARK: load

extension RawSpan {

  public func load<T>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    boundsCheckPrecondition(
      Range(uncheckedBounds: (
        .init(
          allocation: startIndex._allocation,
          rawValue: _start._rawValue.advanced(by: offset)
        ),
        .init(
          allocation: startIndex._allocation,
          rawValue: _start._rawValue.advanced(by: offset+MemoryLayout<T>.size)
        )
      ))
    )
    return load(fromUncheckedByteOffset: offset, as: T.self)
  }

  public func load<T>(
    fromUncheckedByteOffset offset: Int, as: T.Type
  ) -> T {
    _start._rawValue.load(fromByteOffset: offset, as: T.self)
  }

  public func load<T>(from index: Index, as: T.Type) -> T {
    load(
      fromByteOffset: distance(from: startIndex, to: index), as: T.self
    )
  }

  public func load<T>(fromUnchecked index: Index, as: T.Type) -> T {
    load(
      fromUncheckedByteOffset: distance(from: startIndex, to: index), as: T.self
    )
  }

#if hasFeature(BitwiseCopyable)
  public func loadUnaligned<T: _BitwiseCopyable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    boundsCheckPrecondition(
      Range(uncheckedBounds: (
        .init(
          allocation: startIndex._allocation,
          rawValue: _start._rawValue.advanced(by: offset)
        ),
        .init(
          allocation: startIndex._allocation,
          rawValue: _start._rawValue.advanced(by: offset+MemoryLayout<T>.size)
        )
      ))
    )
    return loadUnaligned(fromUncheckedByteOffset: offset, as: T.self)
  }

  public func loadUnaligned<T: _BitwiseCopyable>(
    fromUncheckedByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    _start._rawValue.loadUnaligned(fromByteOffset: offset, as: T.self)
  }

  public func loadUnaligned<T: _BitwiseCopyable>(
    from index: Index, as: T.Type
  ) -> T {
    loadUnaligned(
      fromByteOffset: distance(from: startIndex, to: index), as: T.self
    )
  }

  public func loadUnaligned<T: _BitwiseCopyable>(
    fromUnchecked index: Index, as: T.Type
  ) -> T {
    loadUnaligned(
      fromUncheckedByteOffset: distance(from: startIndex, to: index), as: T.self
    )
  }
#endif
}

//MARK: one-sided slicing operations
extension RawSpan {

  consuming public func prefix(upTo index: Index) -> dependsOn(self) Self {
    index == startIndex
    ? Self(_unchecked: _start, count: 0, owner: self)
    : prefix(through: index.advanced(by: -1))
  }

  consuming public func prefix(through index: Index) -> dependsOn(self) Self {
    boundsCheckPrecondition(index)
    let nc = distance(from: startIndex, to: index) &+ 1
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  consuming public func prefix(_ maxLength: Int) -> dependsOn(self) Self {
    precondition(maxLength >= 0, "Can't have a prefix of negative length.")
    let nc = maxLength < count ? maxLength : count
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  consuming public func dropLast(_ k: Int = 1) -> dependsOn(self) Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let nc = k < count ? count&-k : 0
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  consuming public func suffix(from index: Index) -> dependsOn(self) Self {
    if index == endIndex {
      return Self(_unchecked: index, count: 0, owner: self )
    }
    boundsCheckPrecondition(index)
    let nc = distance(from: index, to: endIndex)
    return Self(_unchecked: index, count: nc, owner: self)
  }

  consuming public func suffix(_ maxLength: Int) -> dependsOn(self) Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length.")
    let nc = maxLength < count ? maxLength : count
    let newStart = _start.advanced(by: count&-nc)
    return Self(_unchecked: newStart, count: nc, owner: self)
  }

  consuming public func dropFirst(_ k: Int = 1) -> dependsOn(self) Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let dc = k < count ? k : count
    let newStart = _start.advanced(by: dc)
    return Self(_unchecked: newStart, count: count&-dc, owner: self)
  }
}

#endif
