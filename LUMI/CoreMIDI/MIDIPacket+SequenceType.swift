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
  public func generate() -> AnyGenerator<Event> {
    let generator = generatorForTuple(self.data)
    var index: UInt16 = 0

    return anyGenerator {
      if index >= self.length {
        return nil
      }

      func pop() -> UInt8 {
        assert(index < self.length)
        index++
        return generator.next() as! UInt8
      }

      let status = pop()
      if Message.isStatusByte(status) {
        var data1: UInt8 = 0
        var data2: UInt8 = 0

        switch Message.statusMessage(status) {
        case .NoteOff: data1 = pop(); data2 = pop();
        case .NoteOn: data1 = pop(); data2 = pop();
        case .Aftertouch: data1 = pop(); data2 = pop();
        case .ControlChange: data1 = pop(); data2 = pop();
        case .ProgramChange: data1 = pop()
        case .ChannelPressure:data1 = pop()
        case .PitchBend: data1 = pop(); data2 = pop();
        }

        return Event(timeStamp: self.timeStamp, status: status, data1: data1, data2: data2)
      }

      return nil
    }
  }
}
