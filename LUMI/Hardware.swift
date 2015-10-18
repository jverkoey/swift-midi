import Foundation
import CoreMIDI

/**
 An instance of Hardware tracks all source and destination MIDI endpoints as a collection of
 MIDI devices.
 */
@objc(LUMIHardware) public class Hardware: NSObject {
  deinit {
    MIDIClientDispose(self.clientRef)
  }

  public override init() {
    super.init()

    var clientRef: MIDIClientRef = 0
    let result: OSStatus
    if #available(iOS 9.0, OSX 10.11, *) {
      result = MIDIClientCreateWithBlock(clientName, &clientRef)
        { [weak self] (notification) -> Void in
          self?.didReceiveNotification(notification)
      }

    } else {
      result = MIDIClientCreate(clientName,
        { (notification, refCon) -> Void in
          let hardware = unsafeBitCast(refCon, Hardware.self)
          hardware.didReceiveNotification(notification)
        }, unsafeBitCast(self, UnsafeMutablePointer<Void>.self), &clientRef)
    }

    self.clientRef = clientRef

    if result == noErr {
      // Immediately scan for devices because MIDIClientCreate only executes on changes (not on startup).
      self.scanForDevices()

    } else {
      print("Failed to create MIDI client. Error: \(result)")
    }

    self.addMessageObserver { message in
      print(message)
    }
  }

  private let clientName = "Swift MIDI"
  private var clientRef: MIDIClientRef = 0

  private typealias DeviceUniqueID = Int32
  private typealias DeviceName = String

  private var byUniqueID: [DeviceUniqueID:Device] = [:]
  private var byName: [DeviceName:[Device]] = [:]
  private let namedMessageObservers: ReadWriteLockProtector<[DeviceName: [(Message) -> Void]]> = ReadWriteLockProtector([:])
  private let messageObservers: ReadWriteLockProtector<[(Message) -> Void]> = ReadWriteLockProtector([])
  private let setupObserverMap = LockProtector<[() -> Void]>([])
}

// Public API
extension Hardware {
  public func connectedDeviceNames() -> [String] {
    return Array(self.byName.keys)
  }

  public func onSetupChanged(observer: () -> Void) {
    setupObserverMap.withLock { $0.append(observer); return }
    observer()
  }

  public func addMessageObserver(observer: (Message) -> Void) {
    self.messageObservers.withWriteLock { $0.append(observer); return }
  }

  public func addMessageObserverForDeviceNamed(deviceName: String, observer: (Message) -> Void) {
    self.namedMessageObservers.withWriteLock { $0[deviceName, withDefault: []].append(observer); return }
  }
}

// Device connectivity
extension Hardware {
  /// Callback for MIDIClient notifications.
  private func didReceiveNotification(notification: UnsafePointer<MIDINotification>) {
    // We don't attempt to handle add/remove messages, instead choosing to rescan for all
    // devices any time the setup changes.
    // TODO: Consider recycling device instances across setup changes.

    if notification.memory.messageID == .MsgSetupChanged {
      self.scanForDevices()
    }
  }

  /// Scans all connected MIDI devices. The results are stored in self.deviceMap.
  func scanForDevices() {
    var byUniqueID: [DeviceUniqueID:Device] = [:]

    func getDeviceForEndpoint(endpointRef: MIDIEndpointRef) -> Device {
      var deviceRef: MIDIDeviceRef = 0
      MIDIEndpointGetDevice(endpointRef, &deviceRef)
      let uniqueID = propertyOf(deviceRef)!.uniqueID
      let device = byUniqueID[uniqueID, withDefault: Device(self.clientRef)]
      device.messageReceiver = self
      return device
    }

    let numberOfSources = MIDIGetNumberOfSources()
    for index in 0..<numberOfSources {
      let endpointRef = MIDIGetSource(index)
      let device = getDeviceForEndpoint(endpointRef)
      do {
        try device.addSourceEndpoint(endpointRef)
      } catch {
        // TODO: What do we do when we fail?
        continue
      }
    }

    let numberOfDestinations = MIDIGetNumberOfDestinations()
    for index in 0..<numberOfDestinations {
      let endpointRef = MIDIGetDestination(index)
      let device = getDeviceForEndpoint(endpointRef)
      do {
        try device.addDestinationEndpoint(endpointRef)
      } catch {
        // TODO: What do we do when we fail?
        continue
      }
    }

    var byName: [DeviceName:[Device]] = [:]
    for (_, device) in byUniqueID {
      let name = device.name()
      if byName[name] == nil {
        byName[name] = [device]
      } else {
        byName[name]!.append(device)
      }
    }

    self.byName = byName
    self.byUniqueID = byUniqueID

    // Notify any setup change messageObservers
    setupObserverMap.withLock {
      for observer in $0 {
        observer()
      }
    }
  }
}

extension Hardware: DeviceMessageReceiver {

  func device(device: Device, didSendMessages messages: AnyGenerator<Message>) {
    let deviceName = device.name()

    // Gather all observers
    var observers: [(Message) -> Void] = []
    observers.appendContentsOf(self.namedMessageObservers.withReadLock { return $0[deviceName] } ?? [])
    observers.appendContentsOf(self.messageObservers.withReadLock { return $0 })

    if observers.count == 0 {
      return
    }

    // All observers receive events in lockstep.
    for message in messages {
      for observer in observers {
        observer(message)
      }
    }
  }
}

// MARK: Debugging
extension Hardware {
  private func logNotification(notification: UnsafePointer<MIDINotification>) {

    // Cast the notification based on its messageID because the MIDINotification sub-structures
    // aren't subclasses of MIDINotification.

    switch notification.memory.messageID {
    case .MsgIOError:
      let casted = UnsafeMutablePointer<MIDIIOErrorNotification>(notification)
      print(casted.memory)

    case .MsgObjectAdded: fallthrough
    case .MsgObjectRemoved:
      let casted = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(notification)
      print(casted.memory)

    case .MsgPropertyChanged:
      let casted = UnsafeMutablePointer<MIDIObjectPropertyChangeNotification>(notification)
      print(casted.memory)
      
    default:
      print(notification.memory)
    }
    
    print("----")
  }
}
