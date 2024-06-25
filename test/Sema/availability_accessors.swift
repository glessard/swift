// RUN: %target-typecheck-verify-swift -parse-as-library -module-name MyModule

struct Nested {
  var b: Int

  @discardableResult
  mutating func setToZero() -> Int {
    let prev = b
    b = 0
    return prev
  }
}

protocol ValueProto {
  static var defaultValue: Self { get }

  var a: Nested { get set }

  subscript(_ i: Int) -> Nested { get set }

  @discardableResult mutating func setToZero() -> Int
}

struct StructValue: ValueProto {
  static var defaultValue: Self { .init(a: Nested(b: 1)) }

  var a: Nested

  subscript(_ i: Int) -> Nested {
    get { a }
    set { a = newValue }
  }

  @discardableResult
  mutating func setToZero() -> Int {
    let prev = a.b
    a.setToZero()
    return prev
  }
}

class ClassValue: ValueProto {
  static var defaultValue: Self { .init(a: Nested(b: 1)) }

  var a: Nested

  required init(a: Nested) {
    self.a = a
  }

  subscript(_ i: Int) -> Nested {
    get { a }
    set { a = newValue }
  }

  @discardableResult func setToZero() -> Int {
    let prev = a.b
    a.setToZero()
    return prev
  }
}

struct BaseStruct<T: ValueProto> {
  var available: T = .defaultValue

  var unavailableGetter: T {
    @available(*, unavailable)
    get { fatalError() } // expected-note 46 {{getter for 'unavailableGetter' has been explicitly marked unavailable here}}
    set {}
  }

  var unavailableSetter: T {
    get { .defaultValue }
    @available(*, unavailable)
    set { fatalError() } // expected-note 27 {{setter for 'unavailableSetter' has been explicitly marked unavailable here}}
  }

  var unavailableGetterAndSetter: T {
    @available(*, unavailable)
    get { fatalError() } // expected-note 46 {{getter for 'unavailableGetterAndSetter' has been explicitly marked unavailable here}}
    @available(*, unavailable)
    set { fatalError() } // expected-note 27 {{setter for 'unavailableGetterAndSetter' has been explicitly marked unavailable here}}
  }
}

@discardableResult func takesInOut<T>(_ t: inout T) -> T {
  return t
}

func testDiscardedRValueLoads_Struct() {
  var x = BaseStruct<StructValue>() // expected-warning {{variable 'x' was never mutated; consider changing to 'let' constant}}

  _ = x.available
  _ = x.available.a
  _ = x.available[0]
  _ = x.available[0].b

  _ = x.unavailableGetter // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter[0] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter[0].b // expected-error {{getter for 'unavailableGetter' is unavailable}}

  _ = x.unavailableSetter
  _ = x.unavailableSetter.a
  _ = x.unavailableSetter[0]
  _ = x.unavailableSetter[0].b

  _ = x.unavailableGetterAndSetter // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter[0] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter[0].b // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

func testDiscardedRValueLoads_Class() {
  var x = BaseStruct<ClassValue>() // expected-warning {{variable 'x' was never mutated; consider changing to 'let' constant}}

  _ = x.available
  _ = x.available.a
  _ = x.available[0]
  _ = x.available[0].b

  _ = x.unavailableGetter // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter[0] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x.unavailableGetter[0].b // expected-error {{getter for 'unavailableGetter' is unavailable}}

  _ = x.unavailableSetter
  _ = x.unavailableSetter.a
  _ = x.unavailableSetter[0]
  _ = x.unavailableSetter[0].b

  _ = x.unavailableGetterAndSetter // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter[0] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x.unavailableGetterAndSetter[0].b // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

func testLValueAssignments_Struct(_ someValue: StructValue) {
  var x = BaseStruct<StructValue>()

  x.available = someValue
  x.available.a = someValue.a
  x.available[0] = someValue.a
  x.available[0].b = 1

  x.unavailableGetter = someValue
  x.unavailableGetter.a = someValue.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  x.unavailableGetter[0] = someValue.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  x.unavailableGetter[0].b = 1 // expected-error {{getter for 'unavailableGetter' is unavailable}}

  x.unavailableSetter = someValue // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x.unavailableSetter.a = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x.unavailableSetter[0] = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x.unavailableSetter[0].b = 1 // expected-error {{setter for 'unavailableSetter' is unavailable}}

  x.unavailableGetterAndSetter = someValue // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x.unavailableGetterAndSetter.a = someValue.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x.unavailableGetterAndSetter[0] = someValue.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x.unavailableGetterAndSetter[0].b = 1 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
}

func testLValueAssignments_Class(_ someValue: ClassValue) {
  var x = BaseStruct<ClassValue>()

  x.available = someValue
  x.available.a = someValue.a
  x.available[0] = someValue.a
  x.available[0].b = 1

  x.unavailableGetter = someValue
  x.unavailableGetter.a = someValue.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  x.unavailableGetter[0] = someValue.a // FIXME: missing diagnostic for getter
  x.unavailableGetter[0].b = 1 // expected-error {{getter for 'unavailableGetter' is unavailable}}

  x.unavailableSetter = someValue // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x.unavailableSetter.a = someValue.a
  x.unavailableSetter[0] = someValue.a
  x.unavailableSetter[0].b = 1

  x.unavailableGetterAndSetter = someValue // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x.unavailableGetterAndSetter.a = someValue.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  // FIXME: missing diagnostic for getter
  x.unavailableGetterAndSetter[0] = someValue.a
  x.unavailableGetterAndSetter[0].b = 1 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

func testDiscardedKeyPathLoads_Struct() {
  let a = [0]
  var x = BaseStruct<StructValue>()

  _ = x[keyPath: \.available]
  _ = x[keyPath: \.available.a]
  _ = x[keyPath: \.available[0]]
  _ = x[keyPath: \.available[0].b]
  _ = a[keyPath: \.[takesInOut(&x.available.a.b)]]
  _ = a[keyPath: \.[takesInOut(&x.available[0].b)]]

  _ = x[keyPath: \.unavailableGetter] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter.a] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter[0]] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter[0].b] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetter.a.b)]] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetter[0].b)]] // expected-error {{getter for 'unavailableGetter' is unavailable}}

  _ = x[keyPath: \.unavailableSetter]
  _ = x[keyPath: \.unavailableSetter.a]
  _ = x[keyPath: \.unavailableSetter[0]]
  _ = x[keyPath: \.unavailableSetter[0].b]
  _ = a[keyPath: \.[takesInOut(&x.unavailableSetter.a.b)]] // expected-error {{setter for 'unavailableSetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableSetter[0].b)]] // expected-error {{setter for 'unavailableSetter' is unavailable}}

  _ = x[keyPath: \.unavailableGetterAndSetter] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter.a] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter[0]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter[0].b] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter.a.b)]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter[0].b)]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
}

func testDiscardedKeyPathLoads_Class() {
  let a = [0]
  var x = BaseStruct<ClassValue>() // expected-warning {{variable 'x' was never mutated; consider changing to 'let' constant}}

  _ = x[keyPath: \.available]
  _ = x[keyPath: \.available.a]
  _ = x[keyPath: \.available[0]]
  _ = x[keyPath: \.available[0].b]
  _ = a[keyPath: \.[takesInOut(&x.available.a.b)]]
  _ = a[keyPath: \.[takesInOut(&x.available[0].b)]]

  _ = x[keyPath: \.unavailableGetter] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter.a] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter[0]] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetter[0].b] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetter.a.b)]] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetter[0].b)]] // expected-error {{getter for 'unavailableGetter' is unavailable}}

  _ = x[keyPath: \.unavailableSetter]
  _ = x[keyPath: \.unavailableSetter.a]
  _ = x[keyPath: \.unavailableSetter[0]]
  _ = x[keyPath: \.unavailableSetter[0].b]
  _ = a[keyPath: \.[takesInOut(&x.unavailableSetter.a.b)]]
  _ = a[keyPath: \.[takesInOut(&x.unavailableSetter[0].b)]]

  _ = x[keyPath: \.unavailableGetterAndSetter] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter.a] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter[0]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = x[keyPath: \.unavailableGetterAndSetter[0].b] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter.a.b)]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter[0].b)]] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

func testKeyPathAssignments_Struct(_ someValue: StructValue) {
  var a = [0]
  var x = BaseStruct<StructValue>()

  x[keyPath: \.available] = someValue
  x[keyPath: \.available.a] = someValue.a
  x[keyPath: \.available[0]] = someValue.a
  x[keyPath: \.available[0].b] = 1
  x[keyPath: \.available] = someValue
  a[keyPath: \.[takesInOut(&x.available.a.b)]] = 0
  a[keyPath: \.[takesInOut(&x.available[0].b)]] = 0

  x[keyPath: \.unavailableGetter] = someValue
  x[keyPath: \.unavailableGetter.a] = someValue.a // FIXME: missing diagnostic for getter
  x[keyPath: \.unavailableGetter[0]] = someValue.a // FIXME: missing diagnostic for getter
  x[keyPath: \.unavailableGetter[0].b] = 1 // FIXME: missing diagnostic for getter
  a[keyPath: \.[takesInOut(&x.unavailableGetter.a.b)]] = 0 // expected-error {{getter for 'unavailableGetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetter[0].b)]] = 0 // expected-error {{getter for 'unavailableGetter' is unavailable}}

  x[keyPath: \.unavailableSetter] = someValue // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x[keyPath: \.unavailableSetter.a] = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x[keyPath: \.unavailableSetter[0]] = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x[keyPath: \.unavailableSetter[0].b] = 1 // expected-error {{setter for 'unavailableSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableSetter.a.b)]] = 0 // expected-error {{setter for 'unavailableSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableSetter[0].b)]] = 0 // expected-error {{setter for 'unavailableSetter' is unavailable}}

  x[keyPath: \.unavailableGetterAndSetter] = someValue // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x[keyPath: \.unavailableGetterAndSetter.a] = someValue.a // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x[keyPath: \.unavailableGetterAndSetter[0]] = someValue.a // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x[keyPath: \.unavailableGetterAndSetter[0].b] = 1 // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter.a.b)]] = 0 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter[0].b)]] = 0 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
}

func testKeyPathAssignments_Class(_ someValue: ClassValue) {
  var a = [0]
  var x = BaseStruct<ClassValue>()

  x[keyPath: \.available] = someValue
  x[keyPath: \.available.a] = someValue.a
  x[keyPath: \.available[0]] = someValue.a
  x[keyPath: \.available[0].b] = 1
  x[keyPath: \.available] = someValue
  a[keyPath: \.[takesInOut(&x.available.a.b)]] = 0
  a[keyPath: \.[takesInOut(&x.available[0].b)]] = 0

  x[keyPath: \.unavailableGetter] = someValue
  x[keyPath: \.unavailableGetter.a] = someValue.a // FIXME: missing diagnostic for getter
  x[keyPath: \.unavailableGetter[0]] = someValue.a // FIXME: missing diagnostic for getter
  x[keyPath: \.unavailableGetter[0].b] = 1 // FIXME: missing diagnostic for getter
  a[keyPath: \.[takesInOut(&x.unavailableGetter.a.b)]] = 0 // expected-error {{getter for 'unavailableGetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetter[0].b)]] = 0 // expected-error {{getter for 'unavailableGetter' is unavailable}}

  x[keyPath: \.unavailableSetter] = someValue // expected-error {{setter for 'unavailableSetter' is unavailable}}
  // FIXME: spurious unavailable setter error
  x[keyPath: \.unavailableSetter.a] = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  // FIXME: spurious unavailable setter error
  x[keyPath: \.unavailableSetter[0]] = someValue.a // expected-error {{setter for 'unavailableSetter' is unavailable}}
  // FIXME: spurious unavailable setter error
  x[keyPath: \.unavailableSetter[0].b] = 1 // expected-error {{setter for 'unavailableSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableSetter.a.b)]] = 0
  a[keyPath: \.[takesInOut(&x.unavailableSetter[0].b)]] = 0

  x[keyPath: \.unavailableGetterAndSetter] = someValue // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x[keyPath: \.unavailableGetterAndSetter.a] = someValue.a // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x[keyPath: \.unavailableGetterAndSetter[0]] = someValue.a // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  // FIXME: spurious unavailable setter error
  x[keyPath: \.unavailableGetterAndSetter[0].b] = 1 // expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter.a.b)]] = 0 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  a[keyPath: \.[takesInOut(&x.unavailableGetterAndSetter[0].b)]] = 0 // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

func testMutatingStructMember() {
  var x = BaseStruct<StructValue>()
  let a = [0]

  x.available.setToZero()
  x.available[0].setToZero()
  _ = a[x.available.setToZero()]
  _ = a[x.available.a.setToZero()]
  _ = a[x.available[0].setToZero()]

  x.unavailableGetter.setToZero() // expected-error {{getter for 'unavailableGetter' is unavailable}}
  x.unavailableGetter[0].setToZero() // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[x.unavailableGetter.setToZero()] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[x.unavailableGetter.a.setToZero()] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  _ = a[x.unavailableGetter[0].setToZero()] // expected-error {{getter for 'unavailableGetter' is unavailable}}

  x.unavailableSetter.setToZero() // expected-error {{setter for 'unavailableSetter' is unavailable}}
  x.unavailableSetter[0].setToZero() // expected-error {{setter for 'unavailableSetter' is unavailable}}
  _ = a[x.unavailableSetter.setToZero()] // expected-error {{setter for 'unavailableSetter' is unavailable}}
  _ = a[x.unavailableSetter.a.setToZero()] // expected-error {{setter for 'unavailableSetter' is unavailable}}
  _ = a[x.unavailableSetter[0].setToZero()] // expected-error {{setter for 'unavailableSetter' is unavailable}}

  x.unavailableGetterAndSetter.setToZero() // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  x.unavailableGetterAndSetter[0].setToZero() // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[x.unavailableGetterAndSetter.setToZero()] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[x.unavailableGetterAndSetter.a.setToZero()] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  _ = a[x.unavailableGetterAndSetter[0].setToZero()] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
}

func testIgnoredApplyOfFuncWithInOutParam_Struct() {
  var x = BaseStruct<StructValue>()

  takesInOut(&x.available)
  takesInOut(&x.available.a)
  takesInOut(&x.available[0])
  takesInOut(&x.available[0].b)

  takesInOut(&x.unavailableGetter) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter.a) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter[0]) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter[0].b) // expected-error {{getter for 'unavailableGetter' is unavailable}}

  takesInOut(&x.unavailableSetter) // expected-error {{setter for 'unavailableSetter' is unavailable}}
  takesInOut(&x.unavailableSetter.a) // expected-error {{setter for 'unavailableSetter' is unavailable}}
  takesInOut(&x.unavailableSetter[0]) // expected-error {{setter for 'unavailableSetter' is unavailable}}
  takesInOut(&x.unavailableSetter[0].b) // expected-error {{setter for 'unavailableSetter' is unavailable}}

  takesInOut(&x.unavailableGetterAndSetter) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter.a) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter[0]) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter[0].b) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
}

func testIgnoredApplyOfFuncWithInOutParam_Class() {
  var x = BaseStruct<ClassValue>()

  takesInOut(&x.available)
  takesInOut(&x.available.a)
  takesInOut(&x.available[0])
  takesInOut(&x.available[0].b)

  takesInOut(&x.unavailableGetter) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter.a) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter[0]) // expected-error {{getter for 'unavailableGetter' is unavailable}}
  takesInOut(&x.unavailableGetter[0].b) // expected-error {{getter for 'unavailableGetter' is unavailable}}

  takesInOut(&x.unavailableSetter) // expected-error {{setter for 'unavailableSetter' is unavailable}}
  takesInOut(&x.unavailableSetter.a)
  takesInOut(&x.unavailableSetter[0])
  takesInOut(&x.unavailableSetter[0].b)

  takesInOut(&x.unavailableGetterAndSetter) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}} expected-error {{setter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter.a) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter[0]) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  takesInOut(&x.unavailableGetterAndSetter[0].b) // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}

var global = BaseStruct<StructValue>()

struct TestPatternBindingInitExprs {
  var available = global.available
  var available_a = global.available.a
  var available_0 = global.available[0]
  var available_0_b = global.available[0].b

  var unavailableGetter = global.unavailableGetter // expected-error {{getter for 'unavailableGetter' is unavailable}}
  var unavailableGetter_a = global.unavailableGetter.a // expected-error {{getter for 'unavailableGetter' is unavailable}}
  var unavailableGetter_0 = global.unavailableGetter[0] // expected-error {{getter for 'unavailableGetter' is unavailable}}
  var unavailableGetter_0_b = global.unavailableGetter[0].b // expected-error {{getter for 'unavailableGetter' is unavailable}}

  var unavailableSetter = global.unavailableSetter
  var unavailableSetter_a = global.unavailableSetter.a
  var unavailableSetter_0 = global.unavailableSetter[0]
  var unavailableSetter_0_b = global.unavailableSetter[0].b

  var unavailableGetterAndSetter = global.unavailableGetterAndSetter // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  var unavailableGetterAndSetter_a = global.unavailableGetterAndSetter.a // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  var unavailableGetterAndSetter_0 = global.unavailableGetterAndSetter[0] // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
  var unavailableGetterAndSetter_0_b = global.unavailableGetterAndSetter[0].b // expected-error {{getter for 'unavailableGetterAndSetter' is unavailable}}
}
