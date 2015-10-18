import CoreMIDI

/**
 Allows a MIDIPacketList to be iterated through with a for statement.

 Example usage:

     let packetList: MIDIPacketList
     for packet in packetList {
       // packet is a MIDIPacket
     }
 */
extension MIDIPacketList: SequenceType {
  public func generate() -> AnyGenerator<MIDIPacket> {
    var iterator: MIDIPacket?
    var nextIndex: UInt32 = 0

    return anyGenerator {
      if nextIndex++ >= self.numPackets { return nil }
      if iterator == nil {
        iterator = self.packet
      } else {
        iterator = withUnsafePointer(&iterator!) { MIDIPacketNext($0).memory }
      }
      return iterator
    }
  }
}

// Blogged at http://softwaredesign.jeffverkoeyen.com/midi-packet-sequences-in-swift-part-1/
