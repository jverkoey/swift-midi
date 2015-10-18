import Foundation

extension Dictionary {

  /**
   Returns the value for the given key if it exists, otherwise stores and returns the result of
   withDefault.
   
   Example usage:
   
       var dictionary: [String:[String]] = [:]
       dictionary["foo", withDefault: []].append("bar")
   */
  subscript(key: Key, @autoclosure withDefault value: Void -> Value) -> Value {
    mutating get {
      if self[key] == nil {
        self[key] = value()
      }
      return self[key]!
    }
    set {
      self[key] = newValue
    }
  }
}

// Blogged at http://softwaredesign.jeffverkoeyen.com/swift-dictionary-get-with-default
