@testable import LUMI
import AudioToolbox
import XCPlayground

let hardware = Hardware()

var instrument: UInt8 = 0

var processingGraph: AUGraph = nil
if let error = Error(NewAUGraph(&processingGraph)) {
  error
}

var cd = AudioComponentDescription(
  componentType: OSType(kAudioUnitType_MusicDevice),
  componentSubType: OSType(kAudioUnitSubType_DLSSynth),
  componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
  componentFlags: 0,
  componentFlagsMask: 0)
var samplerNode: AUNode = 0
withUnsafeMutablePointer(&samplerNode) { AUGraphAddNode(processingGraph, &cd, $0) }

var ioUnitDescription = AudioComponentDescription(
  componentType: OSType(kAudioUnitType_Output),
  componentSubType: OSType(kAudioUnitSubType_DefaultOutput),
  componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
  componentFlags: 0,
  componentFlagsMask: 0)
var ioNode: AUNode = 0
withUnsafeMutablePointer(&ioNode) { AUGraphAddNode(processingGraph, &ioUnitDescription, $0) }

AUGraphOpen(processingGraph)

var samplerUnit = UnsafeMutablePointer<AudioUnit>.alloc(1)
AUGraphNodeInfo(processingGraph, samplerNode, nil, samplerUnit)

var ioUnit = UnsafeMutablePointer<AudioUnit>.alloc(1)
AUGraphNodeInfo(processingGraph, ioNode, nil, ioUnit)

var ioUnitOutputElement:AudioUnitElement = 0
var samplerOutputElement:AudioUnitElement = 0
AUGraphConnectNodeInput(processingGraph, samplerNode, samplerOutputElement, ioNode, ioUnitOutputElement)

AUGraphInitialize(processingGraph)
AUGraphStart(processingGraph)

hardware.addMessageObserverForDeviceNamed("Samson Carbon49 ") { (message: Message) -> Void in
  switch message {
  case .NoteOn(let channel, let key, let velocity):
    XCPlaygroundPage.currentPage.captureValue(key, withIdentifier: "key")
    XCPlaygroundPage.currentPage.captureValue(velocity, withIdentifier: "velocity")
    key

    MusicDeviceMIDIEvent(samplerUnit.memory, UInt32(0x90 | channel), UInt32(key), UInt32(velocity), 0)

    /*
    var channel = UnsafeMutablePointer<MIDIChannelMessage>.alloc(1)
    channel.initialize(MIDIChannelMessage(status: 0xC0, data1: instrument, data2: 0, reserved: 0))
    MusicTrackNewMIDIChannelEvent(chordsTrack.memory, 0, channel)

    var message = UnsafeMutablePointer<MIDINoteMessage>.alloc(1)
    message.initialize(MIDINoteMessage(channel: 0, note: key, velocity: 127, releaseVelocity: 0, duration: 1))
    MusicTrackNewMIDINoteEvent(chordsTrack.memory, 0, message)

    MusicPlayerStart(musicPlayer.memory)
*/
  case .NoteOff(let channel, let key, let velocity):
    key

    MusicDeviceMIDIEvent(samplerUnit.memory, UInt32(0x80 | channel), UInt32(key), UInt32(velocity), 0)

  case .ControlChange(let channel, let controller, let value):

    if controller == 10 {
      // Instrument change.
      MusicDeviceMIDIEvent(samplerUnit.memory, UInt32(0xC0 | channel), UInt32(value), 0, 0)
    } else if controller == 7 {
      // Volume
      MusicDeviceMIDIEvent(samplerUnit.memory, UInt32(0xB0 | channel), UInt32(0x07), UInt32(value), 0)
    }
    instrument = value
    controller
    channel
  case .PitchBend(let channel, let pitch):
    pitch
  default:
    print("bob")
    break
  }
}


XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
