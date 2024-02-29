// RUN: %empty-directory(%t)
// RUN: %target-run-simple-swift(-enable-experimental-feature BuiltinModule -enable-experimental-feature NoncopyableGenerics -enable-experimental-feature NonescapableTypes -Xfrontend -enable-experimental-associated-type-inference -Xfrontend -disable-experimental-parser-round-trip)
// REQUIRES: executable_test

let c = 10

func mutation() {
  var a = Array(0..<c)
  let span = a.storage
  a.append(c)
  print(span.count)
}

mutation()
