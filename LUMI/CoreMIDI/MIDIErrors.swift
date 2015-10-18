import CoreMIDI

enum Error: String, ErrorType {
  case invalidClient
  case invalidPort
  case wrongEndpointType
  case noConnection
  case unknownEndpoint
  case unknownProperty
  case wrongPropertyType
  case noCurrentSetup
  case messageSendErr
  case serverStartErr
  case setupFormatErr
  case wrongThread
  case objectNotFound
  case IDNotUnique
  case notPermitted

  private static var map = ErrorMap()

  init(_ status: OSStatus) {
    self = Error(rawValue: Error.map.statusToLabel[status]!)!
  }
}

private struct ErrorMap {
  let invalidClient = kMIDIInvalidClient
  let invalidPort = kMIDIInvalidPort
  let wrongEndpointType = kMIDIWrongEndpointType
  let noConnection = kMIDINoConnection
  let unknownEndpoint = kMIDIUnknownEndpoint
  let unknownProperty = kMIDIUnknownProperty
  let wrongPropertyType = kMIDIWrongPropertyType
  let noCurrentSetup = kMIDINoCurrentSetup
  let messageSendErr = kMIDIMessageSendErr
  let serverStartErr = kMIDIServerStartErr
  let setupFormatErr = kMIDISetupFormatErr
  let wrongThread = kMIDIWrongThread
  let objectNotFound = kMIDIObjectNotFound
  let IDNotUnique = kMIDIIDNotUnique
  let notPermitted = kMIDINotPermitted

  var statusToLabel: [OSStatus: String] = [:]

  init() {
    for child in Mirror(reflecting: self).children {
      guard let value = child.value as? OSStatus else { continue }
      self.statusToLabel[value] = child.label!
    }
  }
}
