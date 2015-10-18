import Foundation

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
}
