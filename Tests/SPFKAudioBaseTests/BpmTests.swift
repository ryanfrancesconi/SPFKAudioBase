import AVFoundation
import Numerics
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

final class BpmTests {
    @Test func isMultiple() async throws {
        let _80 = try #require(Bpm(80))
        #expect(_80.isMultiple(of: 20))
        #expect(_80.isMultiple(of: 40))
        #expect(_80.isMultiple(of: 80))
        #expect(_80.isMultiple(of: 160))
        #expect(_80.isMultiple(of: 320))
    }

    @Test func clamped() async throws {
        #expect(Bpm(2000)!.clamped(to: Bpm.tempoRange) == Bpm.tempoRange.upperBound)
        #expect(Bpm(0.5)!.clamped(to: Bpm.tempoRange) == Bpm.tempoRange.lowerBound)
    }
}
