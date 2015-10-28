import AudioToolbox

public struct AudioNode {
  public init?(graph: AudioGraph, type: UInt32, subType: UInt32, manufacturer: UInt32) {
    var cd = AudioComponentDescription(
      componentType: OSType(type),
      componentSubType: OSType(subType),
      componentManufacturer: OSType(manufacturer),
      componentFlags: 0,
      componentFlagsMask: 0)
    var node: AUNode = 0
    if AUGraphAddNode(graph.graph, &cd, &node) != noErr {
      return nil
    }
    self.graph = graph
    self.node = node

    var unit: AudioUnit = nil
    AUGraphNodeInfo(self.graph.graph, self.node, nil, &unit)
    self.unit = unit
  }

  public func connectTo(node: AudioNode) {
    AUGraphConnectNodeInput(self.graph.graph, self.node, 0, node.node, 0)
  }

  private let graph: AudioGraph
  private let node: AUNode
  public let unit: AudioUnit
}

public class AudioGraph {
  public init() {
    var graph: AUGraph = nil
    NewAUGraph(&graph)
    self.graph = graph

    AUGraphOpen(self.graph)
  }

  public func start() {
    AUGraphInitialize(self.graph)
    AUGraphStart(self.graph)
  }

  private var nodes: Set<AudioNode> = []
  private let graph: AUGraph
}

extension AudioGraph {
  public func createMusicDeviceNode() -> AudioNode {
    let node = AudioNode(
      graph: self,
      type: kAudioUnitType_MusicDevice,
      subType: kAudioUnitSubType_DLSSynth,
      manufacturer: kAudioUnitManufacturer_Apple
      )!
    self.nodes.insert(node)
    return node
  }

  public func createDefaultOutputNode() -> AudioNode {
    let node = AudioNode(
      graph: self,
      type: kAudioUnitType_Output,
      subType: kAudioUnitSubType_DefaultOutput,
      manufacturer: kAudioUnitManufacturer_Apple
      )!
    self.nodes.insert(node)
    return node
  }
}

extension AudioNode : Hashable {
  public var hashValue: Int {
    return Int(self.node)
  }
}

public func ==(lhs: AudioNode, rhs: AudioNode) -> Bool {
  return lhs.graph.graph == rhs.graph.graph && lhs.node == rhs.node
}
