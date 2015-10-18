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
    var generator = generatorForTuple(self.data)
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

      let byte = pop()
      if (byte & 0x80) == 0x80 { // Status byte
        let message = byte & 0xF0
        let channel = byte & 0x0F
        switch message {
        case 0x80: return .NoteOff(channel: channel, key: pop(), velocity: pop())
        case 0x90: return .NoteOn(channel: channel, key: pop(), velocity: pop())
        case 0xA0: return .Aftertouch(channel: channel, key: pop(), pressure: pop())
        case 0xB0: return .ControlChange(channel: channel, controller: pop(), value: pop())
        case 0xC0: return .ProgramChange(channel: channel, programNumber: pop())
        case 0xD0: return .ChannelPressure(channel: channel, pressure: pop())
        case 0xE0:
          // From http://www.midi.org/techspecs/Messages.php
          // The pitch bender is measured by a fourteen bit value. The first data byte contains the
          // least significant 7 bits. The second data bytes contains the most significant 7 bits.
          let low = UInt16(pop() & 0x7F)
          let high = UInt16(pop() & 0x7F)
          return .PitchBend(channel: channel, pitch: (high << 7) | low)
        default:
          assert(false, "Unimplemented message \(byte)")
          return nil
        }
      }

      assert(false, "Unimplemented message \(byte)")
      return nil
    }
  }
}
