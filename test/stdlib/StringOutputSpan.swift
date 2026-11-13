//===--- StringOutputSpan.swift -------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// RUN: %target-run-stdlib-swift

// REQUIRES: executable_test
// XFAIL: swift_test_mode_optimize_none_with_opaque_values

import StdlibUnittest
#if _runtime(_ObjC)
import Foundation
#endif

var suite = TestSuite("String OutputSpan Tests")
defer { runAllTests() }

enum MyTestError: Error, Equatable { case error }

// Strings around the small-string size limit of 15 UTF-8 code units.
let samples: [String] = [
  "",
  "abcdefg",
  "abéÏ𓀀",
  "012345678901234567890",
  "abéÏ012345678901234567890𓀀",
]

let replacement = "\u{FFFD}"

// A truncated scalar after "Caf", which is 4 code units long.
let truncated: [UInt8] = [0x43, 0x61, 0x66, 0xC3]

// The same, preceded by enough ASCII to be a large string.
let longTruncated: [UInt8] =
  [UInt8](repeating: 0x21, count: 20) + [0x43, 0x61, 0x66, 0xC3]

let illFormed: [[UInt8]] = [
  [0xC3],                    // truncated scalar
  [0xFF],                    // never valid
  [0xC0, 0x80],              // overlong encoding
  [0xED, 0xA0, 0x80],        // surrogate
  [0xF4, 0x90, 0x80, 0x80],  // beyond U+10FFFF
  truncated,
  longTruncated,
]

// MARK: String(validatingUTF8WithCapacity:initializingUTF8With:)

suite.test("String(validatingUTF8WithCapacity:) well-formed input")
.require(.minimumStdlib(.stdlib_6_2)).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  for sample in samples {
    for extra in [0, 1, 16] {
      let capacity = sample.utf8.count + extra
      let result = String(validatingUTF8WithCapacity: capacity) { span in
        expectEqual(span.capacity, capacity)
        expectEqual(span.count, 0)
        for byte in sample.utf8 { span.append(byte) }
      }
      expectEqual(result, sample)
    }
  }
}

suite.test("String(validatingUTF8WithCapacity:) empty")
.require(.minimumStdlib(.stdlib_6_2)).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  expectEqual(String(validatingUTF8WithCapacity: 0) { _ in }, "")
  expectEqual(String(validatingUTF8WithCapacity: 16) { _ in }, "")
}

suite.test("String(validatingUTF8WithCapacity:) ill-formed input")
.require(.minimumStdlib(.stdlib_6_2)).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  for bytes in illFormed {
    let result = String(validatingUTF8WithCapacity: bytes.count) { span in
      for byte in bytes { span.append(byte) }
    }
    expectNil(result, "\(bytes)")

    // Extra capacity doesn't change the verdict.
    let roomy = String(validatingUTF8WithCapacity: bytes.count + 16) { span in
      for byte in bytes { span.append(byte) }
    }
    expectNil(roomy, "\(bytes)")
  }
}

suite.test("String(validatingUTF8WithCapacity:) throws")
.require(.minimumStdlib(.stdlib_6_2)).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  for capacity in [8, 32] {
    do throws(MyTestError) {
      _ = try String(validatingUTF8WithCapacity: capacity) {
        span throws(MyTestError) in
        span.append(0x61)
        throw MyTestError.error
      }
      expectUnreachable("String initializer should have thrown.")
    } catch {
      expectEqual(error, MyTestError.error)
    }
  }
}

suite.test("String(validatingUTF8WithCapacity:) overflow")
.require(.minimumStdlib(.stdlib_6_2))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  expectCrashLater()
  _ = String(validatingUTF8WithCapacity: 1) { span in
    span.append(0x61)
    span.append(0x62)
  }
  expectUnreachable("String initializer should have trapped.")
}

suite.test("String(validatingUTF8WithCapacity:) negative capacity")
.require(.minimumStdlib(.stdlib_6_2))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  expectCrashLater()
  _ = String(validatingUTF8WithCapacity: -1) { _ in }
  expectUnreachable("String initializer should have trapped.")
}

// MARK: String.append(addingUTF8Capacity:initializingUTF8With:)

suite.test("String.append(addingUTF8Capacity:) well-formed input")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for base in samples {
    for addition in samples {
      var result = base
      result.append(addingUTF8Capacity: addition.utf8.count) { span in
        expectEqual(span.capacity, addition.utf8.count)
        expectEqual(span.count, 0)
        for byte in addition.utf8 { span.append(byte) }
      }
      expectEqual(result, base + addition)
      expectEqual(result.utf8.count, base.utf8.count + addition.utf8.count)
    }
  }
}

suite.test("String.append(addingUTF8Capacity:) unused capacity")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  var result = "Hello"
  result.append(addingUTF8Capacity: 64) { span in
    for byte in ", world".utf8 { span.append(byte) }
  }
  expectEqual(result, "Hello, world")
  expectEqual(result.utf8.count, 12)

  result.append(addingUTF8Capacity: 0) { _ in }
  expectEqual(result, "Hello, world")
}

suite.test("String.append(addingUTF8Capacity:) leaves copies unchanged")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for original in ["abc", String(repeating: "x", count: 40)] {
    var copy = original
    copy.append(addingUTF8Capacity: 2) { span in
      span.append(0x79)
      span.append(0x7A)
    }
    expectEqual(copy, original + "yz")
    expectEqual(original.utf8.count, copy.utf8.count - 2)
    expectTrue(copy.hasPrefix(original))
  }
}

suite.test("String.append(addingUTF8Capacity:) ill-formed input")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  var small = "Caf"
  small.append(addingUTF8Capacity: 1) { span in span.append(0xC3) }
  expectEqual(small, "Caf" + replacement)

  let prefix = String(repeating: "x", count: 40)
  var large = prefix
  large.append(addingUTF8Capacity: 3) { span in
    span.append(0x61)
    span.append(0xFF)
    span.append(0x62)
  }
  expectEqual(large, prefix + "a" + replacement + "b")

  // Repair can make the appended text longer than the requested capacity.
  var grown = "ab"
  grown.append(addingUTF8Capacity: 3) { span in
    for _ in 0..<3 { span.append(0xFF) }
  }
  expectEqual(grown, "ab" + String(repeating: replacement, count: 3))

  // A scalar split across the existing and the new code units is ill-formed.
  var split = "é"
  split.append(addingUTF8Capacity: 1) { span in span.append(0xA9) }
  expectEqual(split, "é" + replacement)
}

suite.test("String.append(addingUTF8Capacity:) throws")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for base in ["abc", String(repeating: "x", count: 40)] {
    var result = base
    do throws(MyTestError) {
      try result.append(addingUTF8Capacity: 8) {
        span throws(MyTestError) in
        span.append(0x64)
        span.append(0x65)
        throw MyTestError.error
      }
      expectUnreachable("String.append should have thrown.")
    } catch {
      expectEqual(error, MyTestError.error)
    }
    // Code units appended until the error remain.
    expectEqual(result, base + "de")
  }
}

#if _runtime(_ObjC)
suite.test("String.append(addingUTF8Capacity:) bridged string")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  let nsString = NSString(string: "Café, see you later")
  var result = nsString as String
  result.append(addingUTF8Capacity: 8) { span in
    for byte in " 🌍".utf8 { span.append(byte) }
  }
  expectEqual(result, "Café, see you later 🌍")
  expectEqual(nsString as String, "Café, see you later")
}
#endif

suite.test("String.append(addingUTF8Capacity:) overflow")
.require(.minimumStdlib(.stdlib_5_3))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  expectCrashLater()
  var s = "abc"
  s.append(addingUTF8Capacity: 1) { span in
    span.append(0x61)
    span.append(0x62)
  }
  expectUnreachable("String.append should have trapped.")
}

suite.test("String.append(addingUTF8Capacity:) negative capacity")
.require(.minimumStdlib(.stdlib_5_3))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  expectCrashLater()
  var s = "abc"
  s.append(addingUTF8Capacity: -1) { _ in }
  expectUnreachable("String.append should have trapped.")
}

// MARK: String.UnicodeScalarView

suite.test("String.UnicodeScalarView(repairingUTF8WithCapacity:)")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for sample in samples {
    let view = String.UnicodeScalarView(
      repairingUTF8WithCapacity: sample.utf8.count
    ) { span in
      for byte in sample.utf8 { span.append(byte) }
    }
    expectEqual(String(view), sample)
    expectEqual(view.count, sample.unicodeScalars.count)
  }

  let repaired = String.UnicodeScalarView(
    repairingUTF8WithCapacity: truncated.count
  ) { span in
    for byte in truncated { span.append(byte) }
  }
  expectEqual(String(repaired), "Caf" + replacement)

  do throws(MyTestError) {
    _ = try String.UnicodeScalarView(repairingUTF8WithCapacity: 8) {
      span throws(MyTestError) in
      span.append(0x61)
      throw MyTestError.error
    }
    expectUnreachable("View initializer should have thrown.")
  } catch {
    expectEqual(error, MyTestError.error)
  }
}

suite.test("String.UnicodeScalarView(validatingUTF8WithCapacity:)")
.require(.minimumStdlib(.stdlib_6_2)).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  for sample in samples {
    let view = String.UnicodeScalarView(
      validatingUTF8WithCapacity: sample.utf8.count
    ) { span in
      for byte in sample.utf8 { span.append(byte) }
    }
    expectNotNil(view)
    expectEqual(view.map { String($0) }, sample)
  }

  for bytes in illFormed {
    let view = String.UnicodeScalarView(
      validatingUTF8WithCapacity: bytes.count
    ) { span in
      for byte in bytes { span.append(byte) }
    }
    expectNil(view, "\(bytes)")
  }

  do throws(MyTestError) {
    _ = try String.UnicodeScalarView(validatingUTF8WithCapacity: 8) {
      span throws(MyTestError) in
      span.append(0x61)
      throw MyTestError.error
    }
    expectUnreachable("View initializer should have thrown.")
  } catch {
    expectEqual(error, MyTestError.error)
  }
}

suite.test("String.UnicodeScalarView.append(addingUTF8Capacity:)")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for base in samples {
    for addition in samples {
      var view = base.unicodeScalars
      view.append(addingUTF8Capacity: addition.utf8.count) { span in
        for byte in addition.utf8 { span.append(byte) }
      }
      expectEqual(String(view), base + addition)
    }
  }

  var repaired = "Caf".unicodeScalars
  repaired.append(addingUTF8Capacity: 1) { span in span.append(0xC3) }
  expectEqual(String(repaired), "Caf" + replacement)
}

suite.test(
  "String.UnicodeScalarView.append(addingUTF8Capacity:) leaves copies unchanged"
)
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  for original in ["abc", String(repeating: "x", count: 40)] {
    let base = original.unicodeScalars
    var copy = base
    copy.append(addingUTF8Capacity: 2) { span in
      span.append(0x79)
      span.append(0x7A)
    }
    expectEqual(String(copy), original + "yz")
    expectEqual(String(base), original)
  }
}

suite.test("String.UnicodeScalarView.append(addingUTF8Capacity:) throws")
.require(.minimumStdlib(.stdlib_5_3)).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  var view = "abc".unicodeScalars
  do throws(MyTestError) {
    try view.append(addingUTF8Capacity: 8) {
      span throws(MyTestError) in
      span.append(0x64)
      throw MyTestError.error
    }
    expectUnreachable("View append should have thrown.")
  } catch {
    expectEqual(error, MyTestError.error)
  }
  // Code units appended until the error remain.
  expectEqual(String(view), "abcd")
}

suite.test("String.UnicodeScalarView negative capacity (repairing)")
.require(.minimumStdlib(.stdlib_5_3))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  expectCrashLater()
  _ = String.UnicodeScalarView(repairingUTF8WithCapacity: -1) { _ in }
  expectUnreachable("View initializer should have trapped.")
}

suite.test("String.UnicodeScalarView negative capacity (validating)")
.require(.minimumStdlib(.stdlib_6_2))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 6.2, *) else { return }

  expectCrashLater()
  _ = String.UnicodeScalarView(validatingUTF8WithCapacity: -1) { _ in }
  expectUnreachable("View initializer should have trapped.")
}

suite.test("String.UnicodeScalarView negative capacity (append)")
.require(.minimumStdlib(.stdlib_5_3))
.require(.crashTesting).code {
  guard #available(SwiftStdlib 5.3, *) else { return }

  expectCrashLater()
  var view = "abc".unicodeScalars
  view.append(addingUTF8Capacity: -1) { _ in }
  expectUnreachable("View append should have trapped.")
}
