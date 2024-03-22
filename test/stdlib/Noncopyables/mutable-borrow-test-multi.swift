// RUN: %empty-directory(%t)
// RUN: %target-run-simple-swift(-enable-experimental-feature NoncopyableGenerics -enable-experimental-feature NonescapableTypes -Xfrontend -enable-experimental-associated-type-inference -Xfrontend -disable-experimental-parser-round-trip -Xllvm -enable-lifetime-dependence-diagnostics)
// REQUIRES: executable_test

struct A: ~Copyable {
  var values: (Int, Int, Int, Int, Int, Int, Int, Int)

  init(_ i: Int) {
    values = (i+0,i+1,i+2,i+3,i+4,i+5,i+6,i+7)
  }
}

struct B: ~Escapable {
  let p: UnsafePointer<Int>
  let c: Int

  init(_ borrowed: borrowing A) -> _borrow(borrowed) Self {
    p = withUnsafePointer(to: borrowed.values) {
      $0.withMemoryRebound(to: Int.self, capacity: 5) { $0 }
    }
    c = MemoryLayout.stride(ofValue: borrowed.values)/MemoryLayout<Int>.stride
    return self
  }

  subscript(_ i: Int) -> Int {
    get {
      precondition(0 <= i && i < c)
      return p[i]
    }
  }
}

extension A {
  var b: B {
    borrowing get { B(self) }
  }
}

func test(a: borrowing A) {
  let b = a.b
  print((b[0], b[5]))
}

var a = A(42)
test(a: a)
