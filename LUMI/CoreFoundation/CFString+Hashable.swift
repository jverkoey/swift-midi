import Foundation

// Allows Set<CFString> and switch statements of CFString values.
extension CFString: Hashable {
  public var hashValue: Int { return Int(CFHash(self)) }
}

// Second requirement of conforming to Hashable.
public func ==(lhs: CFString, rhs: CFString) -> Bool {
  return CFStringCompare(lhs, rhs, CFStringCompareFlags()) == .CompareEqualTo
}

// Blogged at http://softwaredesign.jeffverkoeyen.com/hashable-cfstring-in-swift
