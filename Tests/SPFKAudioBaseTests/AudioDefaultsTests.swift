
import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

// Note, more tests in SPFKMetadataTests

@Suite(.serialized, .tags(.file))
class AudioDefaultsTests {
    @Test func setters() async throws {
        #expect(await AudioDefaults2.shared.sampleRate == 48000)

        await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!)
        #expect(await AudioDefaults2.shared.sampleRate == 44100)

        await AudioDefaults2.shared.update(enforceMinimumSamplateRate: true)
        await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 11025, channels: 2)!)
        #expect(await AudioDefaults2.shared.sampleRate == 44100)

        await AudioDefaults2.shared.update(enforceMinimumSamplateRate: false)
        await AudioDefaults2.shared.update(minimumSampleRateSupported: 11025)
        await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 11025, channels: 2)!)
        #expect(await AudioDefaults2.shared.sampleRate == 11025)
        
        await AudioDefaults2.shared.update(enforceMinimumSamplateRate: true)
        await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: AudioDefaults2.defaultSampleRate, channels: 2)!)
        #expect(await AudioDefaults2.shared.sampleRate == 48000)

    }
    
    // just watching how it plays outF
    @Test func sharedState() async throws {
        let task1 = Task {
            for _ in 0 ... 10 {
                Log.debug("🟡 enter 11k")
                await AudioDefaults2.shared.update(enforceMinimumSamplateRate: false)
                await AudioDefaults2.shared.update(minimumSampleRateSupported: 11025)
                await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 11025, channels: 2)!)
                #expect(await AudioDefaults2.shared.sampleRate == 11025)
                Log.debug("🟡 set 11k")

            }
        }
        
        let task2 = Task {
            for _ in 0 ... 10 {
                Log.debug("🟠 enter 48k")
                await AudioDefaults2.shared.update(enforceMinimumSamplateRate: true)
                await AudioDefaults2.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: AudioDefaults2.defaultSampleRate, channels: 2)!)
                #expect(await AudioDefaults2.shared.sampleRate == 48000)
                Log.debug("🟠 set 48k")
            }
        }
        
        _ = await task1.result
        _ = await task2.result
        
        Log.debug(await AudioDefaults2.shared.sampleRate)
    }
}
