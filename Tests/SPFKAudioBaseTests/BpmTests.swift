import AVFoundation
import Numerics
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

final class BpmTests {
    @Test func isMultiple() {
        let _80 = Bpm(80)
        #expect(_80.isMultiple(of: 20))
        #expect(_80.isMultiple(of: 40))
        #expect(_80.isMultiple(of: 80))
        #expect(_80.isMultiple(of: 160))
        #expect(_80.isMultiple(of: 320))
    }
}
