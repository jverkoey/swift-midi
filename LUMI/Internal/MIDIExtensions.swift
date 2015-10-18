import CoreMIDI

/// Convenience method for retrieving a MIDIEndpointRef's parent MIDIDeviceRef.
func MIDIEndpointGetDevice(inEndpoint: MIDIEndpointRef, _ outDevice: UnsafeMutablePointer<MIDIDeviceRef>) -> OSStatus {
  var entityRef: MIDIEntityRef = 0
  var status = MIDIEndpointGetEntity(inEndpoint, &entityRef)
  guard status == noErr else { return status }
  var deviceRef: MIDIDeviceRef = 0
  status = MIDIEntityGetDevice(entityRef, &deviceRef)
  guard status == noErr else { return status }
  outDevice.memory = deviceRef
  return noErr
}

extension MIDINotificationMessageID : CustomStringConvertible {
  public var description: String {
    switch self {
    case .MsgIOError: return "MsgIOError"
    case .MsgObjectAdded: return "MsgObjectAdded"
    case .MsgObjectRemoved: return "MsgObjectRemoved"
    case .MsgPropertyChanged: return "MsgPropertyChanged"
    case .MsgSerialPortOwnerChanged: return "MsgSerialPortOwnerChanged"
    case .MsgSetupChanged: return "MsgSetupChanged"
    case .MsgThruConnectionsChanged: return "MsgThruConnectionsChanged"
    }
  }
}
