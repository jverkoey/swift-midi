import CoreMIDI

/** The returned generator will enumerate each value of the provided tuple. */
func generatorForTuple(tuple: Any) -> AnyGenerator<Any> {
  let children = Mirror(reflecting: tuple).children
  return anyGenerator(children.generate().lazy.map { $0.value }.generate())
}

/**
 Allows a MIDIPacket to be iterated through with a for statement.

 Example usage:

     let packet: MIDIPacket
     for message in packet {
       // message is a Message
     }
 */
extension MIDIPacket: SequenceType {
  public func generate() -> AnyGenerator<Message> {
    let generator = generatorForTuple(self.data)
    var index: UInt16 = 0

    return anyGenerator {
      if index >= self.length {
        return nil
      }

      return Message(byteGenerator: { () -> UInt8 in
        assert(index < self.length)
        index++
        return generator.next() as! UInt8
      })
    }
  }
}
