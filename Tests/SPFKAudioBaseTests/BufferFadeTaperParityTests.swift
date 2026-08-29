// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

/// Pins the rendered fade envelope to ``AudioTaper/gain(at:)`` and ``AudioTaper/fadeOutGain(at:)``,
/// the same curve the transport plays and the fade overlay draws.
///
/// The failure this guards against is smooth, monotonic and exact at both endpoints, so every
/// cheap assertion passes while the middle of the curve is several dB off.
@Suite(.tags(.automation))
struct BufferFadeTaperParityTests {
    private let sampleRate: Double = 48000

    /// A one-channel buffer of `frames` samples at unity, so the output is the gain envelope itself.
    private func unityBuffer(frames: Int) throws -> AVAudioPCMBuffer {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        )
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = try #require(buffer.floatChannelData)
        for i in 0 ..< frames { data[0][i] = 1.0 }
        return buffer
    }

    @Test(arguments: AudioTaper.presets)
    func fadeInMatchesGainAt(taper: AudioTaper) throws {
        let fadeSamples = Int(sampleRate)
        let buffer = try unityBuffer(frames: fadeSamples * 2)
        let faded = try buffer.fade(inTime: 1.0, inTaper: taper)
        let out = try #require(faded.floatChannelData)

        for i in stride(from: 0, to: fadeSamples, by: 97) {
            // fade() evaluates at (i + 1) / fadeSamples so the region's last sample reaches unity
            let t = Double(i + 1) / Double(fadeSamples)
            #expect(abs(out[0][i] - Float(taper.gain(at: t))) < 1e-6, "fade-in diverges at frame \(i)")
        }
    }

    @Test(arguments: AudioTaper.presets)
    func fadeOutMatchesFadeOutGainAt(taper: AudioTaper) throws {
        let fadeSamples = Int(sampleRate)
        let frames = fadeSamples * 2
        let buffer = try unityBuffer(frames: frames)
        let faded = try buffer.fade(outTime: 1.0, outTaper: taper)
        let out = try #require(faded.floatChannelData)

        for i in stride(from: fadeSamples, to: frames, by: 97) {
            let s = Double(i - fadeSamples + 1) / Double(fadeSamples)
            #expect(abs(out[0][i] - Float(taper.fadeOutGain(at: s))) < 1e-6, "fade-out diverges at frame \(i)")
        }
    }

    /// The midpoints the fade editor's taper handles are calibrated on. A blend that reaches these
    /// is the auditioned curve; the linear blend the render used before reached 0.25 and 0.30.
    @Test func defaultTaperReachesTheAuditionedMidpoints() throws {
        let fadeSamples = Int(sampleRate)
        let buffer = try unityBuffer(frames: fadeSamples * 2)
        let faded = try buffer.fade(inTime: 1.0, outTime: 1.0, inTaper: .default, outTaper: .default)
        let out = try #require(faded.floatChannelData)

        #expect(abs(out[0][fadeSamples / 2] - 0.1521) < 1e-3)
        #expect(abs(out[0][fadeSamples + fadeSamples / 2] - 0.1792) < 1e-3)
    }

    /// `.linear` is the one preset both blends agreed on, so it must stay a straight line —
    /// which is what proves the change is confined to the skew term.
    @Test func linearTaperRendersAStraightLine() throws {
        let fadeSamples = Int(sampleRate)
        let buffer = try unityBuffer(frames: fadeSamples * 2)
        let faded = try buffer.fade(inTime: 1.0, outTime: 1.0, inTaper: .linear, outTaper: .linear)
        let out = try #require(faded.floatChannelData)

        for i in stride(from: 0, to: fadeSamples, by: 97) {
            #expect(abs(out[0][i] - Float(Double(i + 1) / Double(fadeSamples))) < 1e-6)
        }
        for i in stride(from: fadeSamples, to: fadeSamples * 2, by: 97) {
            let s = Double(i - fadeSamples + 1) / Double(fadeSamples)
            #expect(abs(out[0][i] - Float(1.0 - s)) < 1e-6)
        }
    }

    @Test(arguments: AudioTaper.presets)
    func fadeReachesBothEndpoints(taper: AudioTaper) throws {
        let fadeSamples = Int(sampleRate)
        let frames = fadeSamples * 2
        let buffer = try unityBuffer(frames: frames)
        let faded = try buffer.fade(inTime: 1.0, outTime: 1.0, inTaper: taper, outTaper: taper)
        let out = try #require(faded.floatChannelData)

        // The render's first fade-in sample sits at t = 1/fadeSamples rather than 0, so silence
        // is a property of the formula; unity and silence at the region boundaries are the buffer's.
        // skew is a Float, so the fade-out's 1 is exact only to Float precision
        #expect(taper.gain(at: 0) == 0)
        #expect(abs(taper.fadeOutGain(at: 0) - 1) < 1e-6)
        #expect(abs(out[0][fadeSamples - 1] - 1.0) < 1e-6, "fade-in does not reach unity")
        #expect(out[0][frames - 1] < 1e-6, "fade-out does not reach silence")
    }
}
