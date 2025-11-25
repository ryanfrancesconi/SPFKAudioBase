import AVFoundation
import Foundation
import Numerics
@testable import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite(.tags(.file))
final class AudioToolsTests: BinTestCase {
    @Test func loopAudio() async throws {
        let url = TestBundleResources.shared.cowbell_wav
        let audioFile1 = try AVAudioFile(forReading: url)

        // original file duration
        #expect(audioFile1.duration == 2.0000226757369615)

        let output = bin.appendingPathComponent("cowbell_20.wav", conformingTo: .wav)

        // loop it for 20 seconds
        let tmpfile = try await AudioTools.createLoopedAudio(input: url, output: output, minimumDuration: 20)

        let audioFile2 = try AVAudioFile(forReading: tmpfile)

        #expect(audioFile2.duration.isApproximatelyEqual(to: 20, absoluteTolerance: 0.001))
    }
}
