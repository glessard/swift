// RUN: rm -rf %t
// RUN: mkdir -p %t
//
// RUN: %target-build-swift -module-name a %s -o %t.out -O
// RUN: %target-run %t.out
// REQUIRES: executable_test

import SwiftPrivate
import StdlibUnittest

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

var AtomicIntTestSuite = TestSuite("AtomicInt")

AtomicIntTestSuite.test("Basic Atomics, Int") {
  var i = Atomic.Int64()

  let r1 = Int64(bitPattern: rand64())
  let r2 = Int64(bitPattern: rand64())
  let r3 = Int64(bitPattern: rand64())

  i.store(r1)
  expectEqual(r1, i.load())

  var j = r2
  j = i.swap(r2)
  expectEqual(r1, j)
  expectEqual(r2, i.load())

  j = i.add(r1)
  expectEqual(r2, j)
  expectEqual(r1 &+ r2, i.load())

  j = i.subtract(r2)
  expectEqual(r1 &+ r2, j)
  expectEqual(r1, i.load())

  j = i.increment()
  expectEqual(r1, j)
  expectEqual(r1 &+ 1, i.load())

  j = i.decrement()
  expectEqual(r1 &+ 1, j)
  expectEqual(r1, i.load())

  i.store(r1)
  j = i.bitwiseOr(r2)
  expectEqual(r1, j)
  expectEqual(r1 | r2, i.load())

  i.store(r2)
  j = i.bitwiseXor(r1)
  expectEqual(r2, j)
  expectEqual(r1 ^ r2, i.load())

  i.store(r1)
  j = i.bitwiseAnd(r2)
  expectEqual(r1, j)
  expectEqual(r1 & r2, i.load())

  i.store(r1)
  j = i.bitwiseNand(r2)
  expectEqual(r1, j)
  expectEqual(~(r1 & r2), i.load())

  i.store(r1)
  j = i.min(r2)
  expectEqual(r1, j)
  expectEqual(min(r1,r2), i.load())

  i.store(r1)
  j = i.max(r2)
  expectEqual(r1, j)
  expectEqual(max(r1,r2), i.load())

  i.store(r1)
  expectFalse(i.compareAndSwap(current: r2, future: r1))
  expectTrue(i.compareAndSwap(current: r1, future: r2))
  expectEqual(r2, i.load())

  i.store(r1)
  j = r2
  expectFalse(i.compareAndSwap(current: &j, future: r3))
  expectEqual(r1, j)
  expectEqual(r1, i.load())
  i.store(r2)
  j = i.load()
  expectTrue(i.compareAndSwap(current: &j, future: r3))
  expectEqual(r2, j)
  expectEqual(r3, i.load())
}

runAllTests()

