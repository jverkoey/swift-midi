import CoreMIDI

/// An individual message sent to or from a MIDI endpoint.
/// For the complete specification, visit http://www.midi.org/techspecs/Messages.php
public enum Message {

  // Channel voice messages
  case NoteOff(channel: UInt8, key: UInt8, velocity: UInt8)
  case NoteOn(channel: UInt8, key: UInt8, velocity: UInt8)
  case Aftertouch(channel: UInt8, key: UInt8, pressure: UInt8)
  case ControlChange(channel: UInt8, controller: UInt8, value: UInt8)
  case ProgramChange(channel: UInt8, programNumber: UInt8)
  case ChannelPressure(channel: UInt8, pressure: UInt8)
  case PitchBend(channel: UInt8, pitch: UInt16)

  init?(byteGenerator pop: () -> UInt8) {
    let byte = pop()
    if (byte & 0x80) == 0x80 { // Status byte
      let message = byte & 0xF0
      let channel = byte & 0x0F
      switch message {
      case 0x80: self = .NoteOff(channel: channel, key: pop(), velocity: pop())
      case 0x90: self = .NoteOn(channel: channel, key: pop(), velocity: pop())
      case 0xA0: self = .Aftertouch(channel: channel, key: pop(), pressure: pop())
      case 0xB0: self = .ControlChange(channel: channel, controller: pop(), value: pop())
      case 0xC0: self = .ProgramChange(channel: channel, programNumber: pop())
      case 0xD0: self = .ChannelPressure(channel: channel, pressure: pop())
      case 0xE0:
        // From http://www.midi.org/techspecs/Messages.php
        // The pitch bender is measured by a fourteen bit value. The first data byte contains the
        // least significant 7 bits. The second data bytes contains the most significant 7 bits.
        let low = UInt16(pop() & 0x7F)
        let high = UInt16(pop() & 0x7F)
        self = .PitchBend(channel: channel, pitch: (high << 7) | low)
      default:
        assert(false, "Unimplemented message \(byte)")
        return nil
      }
      return
    }
    return nil
  }
}
