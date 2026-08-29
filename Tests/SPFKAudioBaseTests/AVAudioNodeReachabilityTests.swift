// Copyright Ryan Francesconi. All Rights Reserved.

import AVFoundation
import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite(.serialized, .tags(.engine))
final class AVAudioNodeReachabilityTests {
    private let engine = AVAudioEngine()
    private let format: AVAudioFormat

    init() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2))
        self.format = format

        // Offline rendering keeps the graph off the HAL. `mainMixerNode` is never touched: reading it
        // would connect a mixer to the output node and give every attached node a path there.
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
    }

    @Test func playerThroughMixerReachesOutput() {
        let player = AVAudioPlayerNode()
        let mixer = AVAudioMixerNode()
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: format)
        engine.connect(mixer, to: engine.outputNode, format: format)

        #expect(player.reachesOutput)
        #expect(mixer.reachesOutput)
        #expect(player.hasOutputConnection)
    }

    @Test func danglingMixerHasAnOutputConnectionWithoutReachingOutput() {
        let player = AVAudioPlayerNode()
        let mixer = AVAudioMixerNode()
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: format)

        #expect(player.hasOutputConnection)
        #expect(player.reachesOutput == false)
        #expect(mixer.reachesOutput == false)
    }

    @Test func unconnectedNodeReachesNothing() {
        let player = AVAudioPlayerNode()
        engine.attach(player)

        #expect(player.hasOutputConnection == false)
        #expect(player.reachesOutput == false)
    }

    @Test func unattachedNodeReachesNothing() {
        let player = AVAudioPlayerNode()

        #expect(player.engine == nil)
        #expect(player.hasOutputConnection == false)
        #expect(player.reachesOutput == false)
    }

    @Test(.timeLimit(.minutes(1))) func cycleTerminates() {
        // `AVAudioEngine.connect` crashes with SIGSEGV when the connection would close a loop, so a
        // cycle can only be presented to the walk by an engine that reports one.
        let engine = StubConnectionEngine()
        let a = AVAudioMixerNode()
        let b = AVAudioMixerNode()
        engine.attach(a)
        engine.attach(b)
        engine.links[ObjectIdentifier(a)] = [b]
        engine.links[ObjectIdentifier(b)] = [a]

        #expect(a.reachesOutput == false)
        #expect(b.reachesOutput == false)
    }
}

private final class StubConnectionEngine: AVAudioEngine {
    var links: [ObjectIdentifier: [AVAudioNode]] = [:]

    override func outputConnectionPoints(for node: AVAudioNode, outputBus bus: AVAudioNodeBus) -> [AVAudioConnectionPoint] {
        (links[ObjectIdentifier(node)] ?? []).map { AVAudioConnectionPoint(node: $0, bus: 0) }
    }
}
