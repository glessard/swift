// RUN: %target-run-simple-swift
// REQUIRES: executable_test

import StdlibUnittest

var SpanContainmentTestSuite = TestSuite("SpanContainment")

class C: @unchecked Sendable {
  let id: Int
  init(_ i: Int) { id = i }
}

let limit = 1000
let arrayOfBitwiseCopyable = Array(0..<limit).map({ ($0, $0, $0) })
let arrayOfArbitraryValue = Array(0..<limit).map({ (C($0), $0, $0) })

let sliceBounds = 0..<limit//50..<950

let clk = ContinuousClock()

var ranges: [Range<Int>] = []
for _ in 0..<4 {
  let a = Int.random(in: 0..<limit)
  let b = Int.random(in: a..<limit)
  ranges.append(a..<b)
}

SpanContainmentTestSuite.test("yes-or-no-bc") {
  arrayOfBitwiseCopyable.withSpan {
    span in
    for _ in 0..<10 {
      var count = 0
      let sliced = span._extracting(unchecked: sliceBounds)
      let tic = clk.now
      for _ in 0..<5_000_000 {
        for r in ranges {
          let subspan = span._extracting(unchecked: r)
          if subspan.isWithin(sliced) {
            _blackHole(true)
            count += 1
          }
        }
      }
      print(clk.now - tic, count)
    }
  }
}

SpanContainmentTestSuite.test("actual-bounds-bc") {
  arrayOfBitwiseCopyable.withSpan {
    span in
    for _ in 0..<10 {
      var count = 0
      let sliced = span._extracting(unchecked: sliceBounds)
      let tic = clk.now
      for _ in 0..<5_000_000 {
        for r in ranges {
          let subspan = span._extracting(unchecked: r)
          if let bounds = subspan.indicesWithin(sliced) {
            _blackHole(bounds)
            count += 1
          }
        }
      }
      print(clk.now - tic, count)
    }
  }
}

SpanContainmentTestSuite.test("yes-or-no-any") {
  arrayOfArbitraryValue.withSpan {
    span in
    for _ in 0..<10 {
      var count = 0
      let sliced = span._extracting(unchecked: sliceBounds)
      let tic = clk.now
      for _ in 0..<5_000_000 {
        for r in ranges {
          let subspan = span._extracting(unchecked: r)
          if subspan.isWithin(sliced) {
            _blackHole(true)
            count += 1
          }
        }
      }
      print(clk.now - tic, count)
    }
  }
}

SpanContainmentTestSuite.test("actual-bounds-any") {
  arrayOfArbitraryValue.withSpan {
    span in
    for _ in 0..<10 {
      var count = 0
      let sliced = span._extracting(unchecked: sliceBounds)
      let tic = clk.now
      for _ in 0..<5_000_000 {
        for r in ranges {
          let subspan = span._extracting(unchecked: r)
          if let bounds = subspan.indicesWithin(sliced) {
            _blackHole(bounds)
            count += 1
          }
        }
      }
      print(clk.now - tic, count)
    }
  }
}

runAllTests()
