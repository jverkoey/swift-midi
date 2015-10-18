import CoreMIDI

/** Returns a PropertyReader for the given MIDIObjectRef. */
func propertyOf(objectRef: MIDIObjectRef) -> PropertyReader? {
  if objectRef == 0 {
    return nil
  }
  return PropertyReader(objectRef)
}

/**
 PropertyReader exposes type-safe property values for CoreMIDI's MIDIObjectRef. Use the propertyOf
 method to create a property reader for a MIDIObjectRef.

 Example usage:

 propertyOf(endpointRef).displayName
 propertyOf(deviceRef).uniqueID
 */
class PropertyReader {
  private init(_ objectRef: MIDIObjectRef) {
    self.objectRef = objectRef
  }
  private let objectRef: MIDIObjectRef
}

extension PropertyReader {
  // Strings
  var name: String { return self[kMIDIPropertyName] }
  var manufacturer: String { return self[kMIDIPropertyManufacturer] }
  var model: String { return self[kMIDIPropertyModel] }
  var driverOwner: String { return self[kMIDIPropertyDriverOwner] }
  var image: String { return self[kMIDIPropertyImage] }
  var driverDeviceEditorApp: String { return self[kMIDIPropertyDriverDeviceEditorApp] }
  var displayName: String { return self[kMIDIPropertyDisplayName] }

  // Dictionaries
  var nameConfiguration: DictionaryProperty { return self[kMIDIPropertyNameConfiguration] }

  // Integers
  var uniqueID: Int32 { return self[kMIDIPropertyUniqueID] }
  var deviceID: Int32 { return self[kMIDIPropertyDeviceID] }
  var receiveChannels: Int32 { return self[kMIDIPropertyReceiveChannels] }
  var transmitChannels: Int32 { return self[kMIDIPropertyTransmitChannels] }
  var maxSysExSpeed: Int32 { return self[kMIDIPropertyMaxSysExSpeed] }
  var advanceScheduleTimeMuSec: Int32 { return self[kMIDIPropertyAdvanceScheduleTimeMuSec] }
  var isEmbeddedEntity: Int32 { return self[kMIDIPropertyIsEmbeddedEntity] }
  var isBroadcast: Int32 { return self[kMIDIPropertyIsBroadcast] }
  var singleRealtimeEntity: Int32 { return self[kMIDIPropertySingleRealtimeEntity] }
  var connectionUniqueID: Int32 { return self[kMIDIPropertyConnectionUniqueID] }
  var offline: Int32 { return self[kMIDIPropertyOffline] }
  var isPrivate: Int32 { return self[kMIDIPropertyPrivate] }
  var driverVersion: Int32 { return self[kMIDIPropertyDriverVersion] }
  var supportsGeneralMIDI: Int32 { return self[kMIDIPropertySupportsGeneralMIDI] }
  var supportsMMC: Int32 { return self[kMIDIPropertySupportsMMC] }
  var canRoute: Int32 { return self[kMIDIPropertyCanRoute] }
  var receivesClock: Int32 { return self[kMIDIPropertyReceivesClock] }
  var receivesMTC: Int32 { return self[kMIDIPropertyReceivesMTC] }
  var receivesNotes: Int32 { return self[kMIDIPropertyReceivesNotes] }
  var receivesProgramChanges: Int32 { return self[kMIDIPropertyReceivesProgramChanges] }
  var receivesBankSelectMSB: Int32 { return self[kMIDIPropertyReceivesBankSelectMSB] }
  var receivesBankSelectLSB: Int32 { return self[kMIDIPropertyReceivesBankSelectLSB] }
  var transmitsClock: Int32 { return self[kMIDIPropertyTransmitsClock] }
  var transmitsMTC: Int32 { return self[kMIDIPropertyTransmitsMTC] }
  var transmitsNotes: Int32 { return self[kMIDIPropertyTransmitsNotes] }
  var transmitsProgramChanges: Int32 { return self[kMIDIPropertyTransmitsProgramChanges] }
  var transmitsBankSelectMSB: Int32 { return self[kMIDIPropertyTransmitsBankSelectMSB] }
  var transmitsBankSelectLSB: Int32 { return self[kMIDIPropertyTransmitsBankSelectLSB] }
  var panDisruptsStereo: Int32 { return self[kMIDIPropertyPanDisruptsStereo] }
  var isSampler: Int32 { return self[kMIDIPropertyIsSampler] }
  var isDrumMachine: Int32 { return self[kMIDIPropertyIsDrumMachine] }
  var isMixer: Int32 { return self[kMIDIPropertyIsMixer] }
  var isEffectUnit: Int32 { return self[kMIDIPropertyIsEffectUnit] }
  var maxReceiveChannels: Int32 { return self[kMIDIPropertyMaxReceiveChannels] }
  var maxTransmitChannels: Int32 { return self[kMIDIPropertyMaxTransmitChannels] }
  var supportsShowControl: Int32 { return self[kMIDIPropertySupportsShowControl] }
}

// Private subscript API
extension PropertyReader {
  private subscript(propertyID: CFString) -> String {
    var value: Unmanaged<CFString>?
    let result = MIDIObjectGetStringProperty(self.objectRef, propertyID, &value)
    assert(result == noErr, "Failure with error \(Error(result))")
    return value!.takeRetainedValue() as String
  }

  private subscript(propertyID: CFString) -> Int32 {
    var value: Int32 = 0
    let result = MIDIObjectGetIntegerProperty(self.objectRef, propertyID, &value)
    assert(result == noErr, "Failure with error \(Error(result))")
    return value
  }

  typealias DictionaryProperty = Dictionary<String, AnyObject>
  private subscript(propertyID: CFString) -> DictionaryProperty {
    var value: Unmanaged<CFDictionary>?
    let result = MIDIObjectGetDictionaryProperty(self.objectRef, propertyID, &value)
    assert(result == noErr, "Failure with error \(Error(result))")
    return value!.takeRetainedValue() as! DictionaryProperty
  }
}
