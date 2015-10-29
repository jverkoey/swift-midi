import CoreMIDI

public struct Event {
  let timeStamp: MIDITimeStamp
  let status: UInt8
  let data1: UInt8
  let data2: UInt8
}

/// An individual message sent to or from a MIDI endpoint.
/// For the complete specification, visit http://www.midi.org/techspecs/Messages.php
enum Message {

  // Channel voice messages
  case NoteOff(channel: UInt8, key: UInt8, velocity: UInt8)
  case NoteOn(channel: UInt8, key: UInt8, velocity: UInt8)
  case Aftertouch(channel: UInt8, key: UInt8, pressure: UInt8)
  case ControlChange(channel: UInt8, controller: UInt8, value: UInt8)
  case ProgramChange(channel: UInt8, programNumber: UInt8)
  case ChannelPressure(channel: UInt8, pressure: UInt8)
  case PitchBend(channel: UInt8, pitch: UInt16)

  // TODO: We need to store the data in raw form and convert it to the nicer enum on demand. This
  // implementation is overly-complicated because it's trying to store the data in the nicer enum first.

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

  func statusByte() -> UInt8 {
    switch self {
    case .NoteOff(let data): return (MessageValue.NoteOff.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .NoteOn(let data): return (MessageValue.NoteOn.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .Aftertouch(let data): return (MessageValue.Aftertouch.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .ControlChange(let data): return (MessageValue.ControlChange.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .ProgramChange(let data): return (MessageValue.ProgramChange.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .ChannelPressure(let data): return (MessageValue.ChannelPressure.rawValue << UInt8(4)) | data.channel | Message.statusBit
    case .PitchBend(let data): return (MessageValue.PitchBend.rawValue << UInt8(4)) | data.channel | Message.statusBit
    }
  }

  func data1Byte() -> UInt8 {
    switch self {
    case .NoteOff(let data): return data.1
    case .NoteOn(let data): return data.1
    case .Aftertouch(let data): return data.1
    case .ControlChange(let data): return data.1
    case .ProgramChange(let data): return data.1
    case .ChannelPressure(let data): return data.1
    case .PitchBend(let data): return UInt8(data.pitch & 0x7F)
    }
  }

  func data2Byte() -> UInt8 {
    switch self {
    case .NoteOff(let data): return data.2
    case .NoteOn(let data): return data.2
    case .Aftertouch(let data): return data.2
    case .ControlChange(let data): return data.2
    case .ProgramChange: return 0
    case .ChannelPressure: return 0
    case .PitchBend(let data): return UInt8((data.pitch >> 7) & 0x7F)
    }
  }

  static private let statusBit: UInt8 = 0b10000000
  static private let dataMask: UInt8 = 0b01111111
  static private let messageMask: UInt8 = 0b01110000
  static private let channelMask: UInt8 = 0b00001111

  enum MessageValue : UInt8 {
    case NoteOff = 0
    case NoteOn
    case Aftertouch
    case ControlChange
    case ProgramChange
    case ChannelPressure
    case PitchBend
  }

  static func isStatusByte(byte: UInt8) -> Bool {
    return (byte & Message.statusBit) == Message.statusBit
  }
  static func isDataByte(byte: UInt8) -> Bool {
    return (byte & Message.statusBit) == 0
  }

  static func statusMessage(byte: UInt8) -> MessageValue {
    return MessageValue(rawValue: (byte & Message.messageMask) >> UInt8(4))!
  }
  static func statusChannel(byte: UInt8) -> UInt8 {
    return byte & Message.channelMask
  }
}
