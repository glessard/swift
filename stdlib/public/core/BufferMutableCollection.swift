//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

public protocol _BufferMutableCollection: MutableCollection
{
  override subscript(position: Index) -> Element { get nonmutating set }

  subscript(bounds: Range<Index>) -> Slice<Self> { get nonmutating set }
  
  override nonmutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index
  
  override nonmutating func swapAt(_ i: Index, _ j: Index)

  nonmutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

extension _BufferMutableCollection
{
  @inlinable
  public nonmutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return nil
  }
}

/* From CollectionAlgorithms.swift.gyb */

extension _BufferMutableCollection
  where Self: BidirectionalCollection {
  @inlinable
  public nonmutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index {
    var ref = self
    return try ref._partition(by: belongsInSecondPartition)
  }
}

extension _BufferMutableCollection
  where Self: RandomAccessCollection {
  @inlinable
  public nonmutating func shuffle<T: RandomNumberGenerator>(
    using generator: inout T
  ) {
    var ref = self
    ref._shuffle(using: &generator)
  }

  @inlinable
  public mutating func shuffle() {
    var g = SystemRandomNumberGenerator()
    shuffle(using: &g)
  }
}

/* Adapted from Sort.swift */

extension _BufferMutableCollection
  where Self: RandomAccessCollection,
        Element: Comparable {
  @inlinable
  public nonmutating func sort() {
    sort(by: <)
  }
}

/* Adapted from Sort.swift */

extension _BufferMutableCollection
  where Self: RandomAccessCollection {
  @inlinable
  public nonmutating func sort(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows {
    var ref = self
    try ref._introSort(
      within: startIndex..<endIndex,
      by: areInIncreasingOrder
    )
  }
}

/* From Reverse.swift */

extension _BufferMutableCollection
  where Self: BidirectionalCollection {
  @inlinable
  public nonmutating func reverse() {
    var ref = self
    ref._reverse()
  }
}

/* From Range.swift */

extension _BufferMutableCollection {
  public subscript<R: RangeExpression>(r: R) -> Slice<Self>
    where R.Bound == Index {
    get {
      return self[r.relative(to: self)]
    }
    nonmutating set {
      self[r.relative(to: self)] = newValue
    }
  }

  public subscript(x: UnboundedRange) -> Slice<Self> {
    get {
      return self[startIndex...]
    }
    nonmutating set {
      self[startIndex...] = newValue
    }
  }
}
