// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite
class AVAudioPCMBufferProcessingTests {
    // MARK: - Helpers

    /// Build a buffer from per-channel sample arrays.
    private func makeBuffer(channels: [[Float]], sampleRate: Double = 44100) -> AVAudioPCMBuffer {
        let frameCount = channels[0].count
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: AVAudioChannelCount(channels.count)
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        for (ch, samples) in channels.enumerated() {
            for (i, sample) in samples.enumerated() {
                buffer.floatChannelData![ch][i] = sample
            }
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer, channel: Int = 0) -> [Float] {
        guard let data = buffer.floatChannelData else { return [] }
        return (0 ..< Int(buffer.frameLength)).map { data[channel][$0] }
    }

    // MARK: - peak()

    @Test func peakFindsCorrectFramePosition() throws {
        // peak is at frame 2 (value -0.9, absolute 0.9)
        let buffer = makeBuffer(channels: [[0.1, 0.5, -0.9, 0.2]])
        let result = try buffer.peak()
        #expect(result.framePosition == 2)
        #expect(abs(result.amplitude - 0.9) < 1e-5)
    }

    @Test func peakStereoPicksHighestAcrossChannels() throws {
        // ch0 peak = 0.5 at frame 1; ch1 peak = 0.9 at frame 2 — result should come from ch1
        let buffer = makeBuffer(channels: [
            [0.1, 0.5, 0.2],
            [0.1, 0.1, -0.9],
        ])
        let result = try buffer.peak()
        #expect(result.framePosition == 2)
        #expect(abs(result.amplitude - 0.9) < 1e-5)
    }

    @Test func peakThrowsOnEmptyBuffer() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)!
        // frameLength defaults to 0
        #expect(throws: (any Error).self) {
            try buffer.peak()
        }
    }

    // MARK: - normalize()

    @Test func normalizeProducesPeakOfOne() throws {
        let buffer = makeBuffer(channels: [[0.1, 0.4, -0.2, 0.05]])
        let result = try buffer.normalize()
        let peak = try result.peak()
        #expect(abs(peak.amplitude - 1.0) < 1e-5)
    }

    @Test func normalizePreservesRelativeAmplitudes() throws {
        let buffer = makeBuffer(channels: [[0.2, 0.4, -0.4]])
        let result = try buffer.normalize()
        let out = samples(result)
        // 0.2 / 0.4 == 0.5 — ratio between first and second sample must be preserved
        #expect(abs(out[0] / out[1] - 0.5) < 1e-5)
    }

    @Test func normalizePreservesFrameLength() throws {
        let buffer = makeBuffer(channels: [[0.1, 0.5, -0.9, 0.2]])
        let result = try buffer.normalize()
        #expect(result.frameLength == buffer.frameLength)
    }

    // MARK: - reverse()

    @Test func reverseSwapsFirstAndLastSamples() throws {
        let input: [Float] = [1, 2, 3, 4, 5]
        let buffer = makeBuffer(channels: [input])
        let result = try buffer.reverse()
        let out = samples(result)
        #expect(out.first == input.last)
        #expect(out.last == input.first)
        #expect(out == [5, 4, 3, 2, 1])
    }

    @Test func reverseStereoEachChannelIndependent() throws {
        let buffer = makeBuffer(channels: [
            [1, 2, 3],
            [4, 5, 6],
        ])
        let result = try buffer.reverse()
        #expect(samples(result, channel: 0) == [3, 2, 1])
        #expect(samples(result, channel: 1) == [6, 5, 4])
    }

    @Test func reversePreservesFrameLength() throws {
        let buffer = makeBuffer(channels: [[0.1, 0.5, -0.9, 0.2]])
        let result = try buffer.reverse()
        #expect(result.frameLength == buffer.frameLength)
    }

    // MARK: - fade()

    @Test func fadeThrowsWhenBothTimesAreZero() throws {
        let buffer = makeBuffer(channels: [Array(repeating: Float(1.0), count: 4410)])
        #expect(throws: (any Error).self) {
            try buffer.fade(inTime: 0, outTime: 0)
        }
    }

    @Test func fadeThrowsWhenInOutExceedsBufferDuration() throws {
        // 0.5 s buffer at 44100 Hz. inTime + outTime = 0.6 s > 0.5 s.
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: Int(44100 * 0.5))],
            sampleRate: 44100
        )
        #expect(throws: (any Error).self) {
            try buffer.fade(inTime: 0.3, outTime: 0.3)
        }
    }

    @Test func fadeInGainIncreasesMonotonically() throws {
        // All-ones input: output values directly reflect the gain envelope.
        let sampleRate: Double = 44100
        let fadeInTime: TimeInterval = 0.1
        let fadeInSamples = Int(sampleRate * fadeInTime)
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: fadeInSamples * 2)],
            sampleRate: sampleRate
        )
        let result = try buffer.fade(inTime: fadeInTime)
        let out = samples(result)
        for i in 1 ..< fadeInSamples {
            #expect(out[i] >= out[i - 1], "gain decreased at frame \(i)")
        }
    }

    @Test func fadeOutGainDecreasesMonotonically() throws {
        let sampleRate: Double = 44100
        let fadeOutTime: TimeInterval = 0.1
        let fadeOutSamples = Int(sampleRate * fadeOutTime)
        let frameCount = fadeOutSamples * 2
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: frameCount)],
            sampleRate: sampleRate
        )
        let result = try buffer.fade(outTime: fadeOutTime)
        let out = samples(result)
        let fadeOutStart = frameCount - fadeOutSamples
        for i in (fadeOutStart + 1) ..< frameCount {
            #expect(out[i] <= out[i - 1], "gain increased at frame \(i)")
        }
    }

    @Test func fadeInStereoChannelsReceiveIdenticalGain() throws {
        // Regression: the old code updated `gain` inside the channel loop, so ch0 and ch1
        // got different gain values at the same sample position. This verifies the fix.
        let frameCount = 4410
        let ones = Array(repeating: Float(1.0), count: frameCount)
        let buffer = makeBuffer(channels: [ones, ones])
        let result = try buffer.fade(inTime: 0.1)
        guard let data = result.floatChannelData else {
            Issue.record("floatChannelData is nil")
            return
        }
        for i in 0 ..< frameCount {
            #expect(data[0][i] == data[1][i], "channels diverge at frame \(i)")
        }
    }

    @Test func fadeMiddleRegionIsUnmodified() throws {
        // Samples between the fade regions should pass through at gain = 1.
        // 44100 Hz, 3 s buffer, 0.5 s fade in + 0.5 s fade out → middle 2 s untouched.
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * 3)
        let input = Array(repeating: Float(0.5), count: frameCount)
        let buffer = makeBuffer(channels: [input], sampleRate: sampleRate)
        let result = try buffer.fade(inTime: 0.5, outTime: 0.5)
        let out = samples(result)
        // Sample at 1.5 s is in the untouched middle region
        let midFrame = Int(sampleRate * 1.5)
        #expect(abs(out[midFrame] - 0.5) < 1e-5)
    }

    // MARK: - extract()

    @Test func extractProducesCorrectFrameCount() throws {
        // 10 frames at 10 Hz = 1 second total. Extract 0.2 s – 0.7 s = 5 frames.
        let buffer = makeBuffer(channels: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]], sampleRate: 10)
        let result = try buffer.extract(from: 0.2, to: 0.7)
        #expect(result.frameLength == 5)
    }

    @Test func extractSampleValuesMatchSource() throws {
        // Extract frames 2–4 (0.2 s – 0.5 s at 10 Hz). Values should be [2, 3, 4].
        let buffer = makeBuffer(channels: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]], sampleRate: 10)
        let result = try buffer.extract(from: 0.2, to: 0.5)
        #expect(samples(result) == [2, 3, 4])
    }

    @Test func extractClampsEndBeyondBufferToFrameLength() throws {
        // 5-frame buffer at 10 Hz = 0.5 s. Requesting end at 9999 s should clamp to the buffer end.
        let buffer = makeBuffer(channels: [[1, 2, 3, 4, 5]], sampleRate: 10)
        let result = try buffer.extract(from: 0, to: 9999)
        #expect(result.frameLength == 5)
        #expect(samples(result) == [1, 2, 3, 4, 5])
    }

    // MARK: - applying(_:)

    @Test func applyingEmptyEditReturnsSelf() throws {
        let buffer = makeBuffer(channels: [[0.1, 0.2, 0.3]])
        let result = try buffer.applying(AudioEditDescription())
        #expect(result === buffer)
    }

    @Test func applyingInOutPointReducesFrameLength() throws {
        // 10 frames at 10 Hz. inPoint=0.2, outPoint=0.7 → frames [2,3,4,5,6] = 5 frames.
        let buffer = makeBuffer(channels: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]], sampleRate: 10)
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 0.2, outPoint: 0.7))
        let result = try buffer.applying(edit)
        #expect(result.frameLength == 5)
        #expect(samples(result) == [2, 3, 4, 5, 6])
    }

    @Test func applyingInPointOnlyTrimsHead() throws {
        // 10 frames at 10 Hz. inPoint=0.6 → frames [6,7,8,9] = 4 frames.
        let buffer = makeBuffer(channels: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]], sampleRate: 10)
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 0.6))
        let result = try buffer.applying(edit)
        #expect(result.frameLength == 4)
        #expect(samples(result) == [6, 7, 8, 9])
    }

    @Test func applyingFadeInOnConstantSignal() throws {
        // All-ones, fade in 0.1 s. First output sample must be near 0, last of fade near 1.
        let sampleRate: Double = 44100
        let fadeInSamples = Int(sampleRate * 0.1)
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: fadeInSamples * 2)],
            sampleRate: sampleRate
        )
        let edit = AudioEditDescription(fade: FadeDescription(inTime: 0.1))
        let result = try buffer.applying(edit)
        let out = samples(result)
        #expect(out[0] < 0.1)
        #expect(out[fadeInSamples - 1] > 0.9)
    }

    // MARK: - applying(_:) de-click fades

    @Test func applyingTrimDeClicksStartAndEnd() throws {
        // All-ones at 44100 Hz, 1 s total. Trim to 0–0.5 s.
        // No explicit fade, so the 5 ms de-click must attenuate the first and last samples.
        let sampleRate: Double = 44100
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: Int(sampleRate))],
            sampleRate: sampleRate
        )
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 0, outPoint: 0.5))
        let result = try buffer.applying(edit)
        let out = samples(result)
        // First sample is inside the 5 ms fade-in — must be well below 1.
        #expect(out[0] < 0.1)
        // Last sample is in the final frame of the 5 ms fade-out — gain is near 0.
        #expect(out[out.count - 1] < 1e-5)
    }

    @Test func applyingTrimExplicitFadeLongerThanDeClickWins() throws {
        // Explicit 0.1 s fade-in is longer than the 5 ms de-click; it should take effect.
        // At 0.05 s into a 0.1 s fade the gain is still rising, so the sample is < 1.
        // Past 0.1 s the gain is 1 and the all-ones input passes through unmodified.
        let sampleRate: Double = 44100
        let buffer = makeBuffer(
            channels: [Array(repeating: Float(1.0), count: Int(sampleRate))],
            sampleRate: sampleRate
        )
        let edit = AudioEditDescription(
            trim: TrimDescription(inPoint: 0, outPoint: 0.5),
            fade: FadeDescription(inTime: 0.1)
        )
        let result = try buffer.applying(edit)
        let out = samples(result)
        // Mid-way through the 0.1 s fade — still rising.
        #expect(out[Int(sampleRate * 0.05)] < 1.0)
        // Just past the 0.1 s fade boundary — at full gain.
        #expect(out[Int(sampleRate * 0.11)] > 0.99)
    }

    // MARK: - loop()

    @Test func loopTotalFrameCountIsMultiple() throws {
        let buffer = makeBuffer(channels: [[0.1, 0.2, 0.3]])
        let result = try buffer.loop(numberOfDuplicates: 3)
        #expect(result.frameLength == buffer.frameLength * 3)
    }

    @Test func loopSecondCopyStartsWithFirstSample() throws {
        let input: [Float] = [0.1, 0.2, 0.3]
        let buffer = makeBuffer(channels: [input])
        let result = try buffer.loop(numberOfDuplicates: 2)
        let out = samples(result)
        // Second copy starts at frame 3 — must equal frame 0 of the original
        #expect(out[3] == out[0])
    }
}
