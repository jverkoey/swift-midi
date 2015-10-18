//: Playground - noun: a place where people can play

protocol Imagable {
  var title:String { get }
}

struct Image: Imagable {
  let title: String
}

struct Artwork {
  var images: [Imagable]
}

Artwork(images: [Image(title: "bar")])

class Foo {
  var array: [String] = []
  subscript(name: String) -> [String] {
    get {
      print("get")
      return array
    }
    set {
      print("set")
      array = newValue
    }
  }
}

let f = Foo()
f["foo"].append("bar")
