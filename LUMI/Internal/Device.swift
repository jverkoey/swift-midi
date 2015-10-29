import CoreMIDI

protocol DeviceEventReceiver: class {
  func device(device: Device, didSendEvents: AnyGenerator<Event>)
}

/**
 A Device tracks a collection of source and destination MIDI endpoints, faciliting the delivery
 of messages to and from a given device.

 TODO: Consider grouping endpoints by their parent entities.
 */
class Device {
  deinit {
    // Tear down open ports so that our callbacks are no longer called.
    for endpoint in self.sourceEndpoints {
      if endpoint.portRef == nil { continue }
      MIDIPortDisconnectSource(endpoint.portRef!, endpoint.ref)
      MIDIPortDispose(endpoint.portRef!)
    }
    for endpoint in self.destinationEndpoints {
      if endpoint.portRef == nil { continue }
      MIDIPortDispose(endpoint.portRef!)
    }
  }

  init(_ clientRef: MIDIClientRef) {
    self.clientRef = clientRef
  }

  /// May represent either a source or destination endpoint.
  private struct Endpoint {
    let ref: MIDIEntityRef
    var portRef: MIDIPortRef? = 0

    init(_ ref: MIDIEntityRef) {
      self.ref = ref
    }
  }

  weak var eventReceiver: DeviceEventReceiver?

  private let clientRef: MIDIClientRef
  private var deviceRef: MIDIDeviceRef = 0
  private var sourceEndpoints: [Endpoint] = []
  private var destinationEndpoints: [Endpoint] = []
  private var messageObservers: [(Message) -> Void] = []
}

// Internal API
extension Device {
  func name() -> String {
    return propertyOf(self.deviceRef)!.name
  }

  func addMessageObserver(observer: (Message) -> Void) {
    self.messageObservers.append(observer)
  }
}

// Communication with the device
extension Device {
  func addSourceEndpoint(endpointRef: MIDIEndpointRef) throws {
    let name = propertyOf(endpointRef)!.name
    let portName = "\(name) to Swift"
    var portRef: MIDIPortRef = 0

    if self.deviceRef == 0 {
      if let error = Error(MIDIEndpointGetDevice(endpointRef, &self.deviceRef)) {
        throw error
      }
    }

    var status: OSStatus

    if #available(iOS 9.0, OSX 10.11, *) {
      status = MIDIInputPortCreateWithBlock(self.clientRef, portName, &portRef)
        { [weak self] (packetList, srcConnRefCon) -> Void in
          self?.didReceivePacketList(packetList)
      }
    } else {
      status = MIDIInputPortCreate(self.clientRef, portName,
        { (packetList, readProcRefCon, srcConnRefCon) -> Void in
          let device = unsafeBitCast(readProcRefCon, Device.self)
          device.didReceivePacketList(packetList)
        }, unsafeBitCast(self, UnsafeMutablePointer<Void>.self), &portRef)
    }

    if let error = Error(status) {
      throw error
    }

    if let error = Error(MIDIPortConnectSource(portRef, endpointRef, nil)) {
      MIDIPortDispose(portRef)
      throw error
    }

    var endpoint = Endpoint(endpointRef)
    endpoint.portRef = portRef
    self.sourceEndpoints.append(endpoint)
  }

  func addDestinationEndpoint(endpointRef: MIDIEndpointRef) throws {
    let endpoint = Endpoint(endpointRef)
    self.destinationEndpoints.append(endpoint)

    if self.deviceRef == 0 {
      if let error = Error(MIDIEndpointGetDevice(endpointRef, &self.deviceRef)) {
        throw error
      }
    }
  }

  private func didReceivePacketList(packetList: UnsafePointer<MIDIPacketList>) {
    guard let eventReceiver = self.eventReceiver else { return }

    let events = anyGenerator(FlattenGenerator(packetList.memory.generate()))
    eventReceiver.device(self, didSendEvents: events)
  }
}
