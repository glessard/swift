// RUN: %empty-directory(%t)
// RUN: %target-run-simple-swift(-enable-experimental-feature NoncopyableGenerics -enable-experimental-feature NonescapableTypes -Xfrontend -enable-experimental-associated-type-inference -Xfrontend -disable-experimental-parser-round-trip -Xllvm -enable-lifetime-dependence-diagnostics)
// REQUIRES: executable_test

struct A: ~Copyable {
  var value: Int

  init(_ value: Int) { self.value = value }
}

struct B: ~Escapable {
  let p: UnsafePointer<Int>

  init(_ borrowed: borrowing A) -> _borrow(borrowed) Self {
    p = withUnsafePointer(to: borrowed.value) { $0 }
    return self
  }

  var value: Int { p.pointee }
}

extension A {
  var b: B {
    borrowing _read {
      yield B(self)
    }
  }
}

func test(a: inout A) {
  let b = a.b
//  a.value = 1
  print(b.value)
}

var a = A(42)
test(a: &a)
