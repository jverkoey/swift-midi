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

  static private let statusBit: UInt8 = 0b10000000
  static private let dataMask: UInt8 = 0b01111111
  static private let messageMask: UInt8 = 0b01110000
  static private let channelMask: UInt8 = 0b00001111

  private enum MessageValue : UInt8 {
    case NoteOff
    case NoteOn
    case Aftertouch
    case ControlChange
    case ProgramChange
    case ChannelPressure
    case PitchBend
  }

  static private func isStatusByte(byte: UInt8) -> Bool {
    return (byte & Message.statusBit) == Message.statusBit
  }
  static private func isDataByte(byte: UInt8) -> Bool {
    return (byte & Message.statusBit) == 0
  }

  static private func statusMessage(byte: UInt8) -> MessageValue {
    return MessageValue(rawValue: (byte & Message.messageMask) >> UInt8(4))!
  }
  static private func statusChannel(byte: UInt8) -> UInt8 {
    return byte & Message.channelMask
  }

  init?(byteGenerator pop: () -> UInt8) {
    let byte = pop()
    if Message.isStatusByte(byte) {
      let channel = Message.statusChannel(byte)
      switch Message.statusMessage(byte) {
      case .NoteOff: self = .NoteOff(channel: channel, key: pop(), velocity: pop())
      case .NoteOn: self = .NoteOn(channel: channel, key: pop(), velocity: pop())
      case .Aftertouch: self = .Aftertouch(channel: channel, key: pop(), pressure: pop())
      case .ControlChange: self = .ControlChange(channel: channel, controller: pop(), value: pop())
      case .ProgramChange: self = .ProgramChange(channel: channel, programNumber: pop())
      case .ChannelPressure: self = .ChannelPressure(channel: channel, pressure: pop())
      case .PitchBend:
        // From http://midi.org/techspecs/midimessages.php
        // The pitch bender is measured by a fourteen bit value. The first data byte contains the
        // least significant 7 bits. The second data bytes contains the most significant 7 bits.
        let low = UInt16(pop())
        let high = UInt16(pop())
        self = .PitchBend(channel: channel, pitch: (high << 7) | low)
      }
      return
    }
    return nil
  }
}
