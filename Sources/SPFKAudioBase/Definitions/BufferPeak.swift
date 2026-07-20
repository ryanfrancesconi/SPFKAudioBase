// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Accelerate
import AVFoundation
import Foundation
import SPFKBase

public struct BufferPeak: Equatable {
    internal static let min: Float = -10000.0

    /// Time of the peak
    public var time: TimeInterval? {
        guard let sampleRate, sampleRate > 0 else { return nil }

        return Double(framePosition) / sampleRate
    }

    public var sampleRate: Double?

    /// Frame position of the peak
    public var framePosition: Int = 0

    /// Peak amplitude
    public var amplitude: Float = 1

    public init() {}

    public init(sampleRate: Double, framePosition: Int, amplitude: Float) {
        self.sampleRate = sampleRate
        self.framePosition = framePosition
        self.amplitude = amplitude
    }

    public init(url: URL) async throws {
        let avfile = try AVAudioFile(forReading: url)
        let format = avfile.processingFormat
        let totalFrames = AVAudioFrameCount(avfile.length)
        let channelCount = Int(format.channelCount)

        guard totalFrames > 0, channelCount > 0 else { return }

        let chunkSize: AVAudioFrameCount = 4096
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else { return }

        sampleRate = format.sampleRate

        var position: AVAudioFrameCount = 0
        var runningMax: Float = 0
        var peakFrame: Int = 0

        while position < totalFrames {
            try Task.checkCancellation()
            let framesToRead = Swift.min(chunkSize, totalFrames - position)
            avfile.framePosition = AVAudioFramePosition(position)
            try avfile.read(into: buffer, frameCount: framesToRead)

            guard let data = buffer.floatChannelData else { break }
            let frameLength = vDSP_Length(buffer.frameLength)

            for ch in 0 ..< channelCount {
                var chMax: Float = 0
                var chMaxIdx: vDSP_Length = 0
                vDSP_maxmgvi(data[ch], 1, &chMax, &chMaxIdx, frameLength)

                if chMax > runningMax {
                    runningMax = chMax
                    peakFrame = Int(position) + Int(chMaxIdx)
                }
            }

            position += AVAudioFrameCount(buffer.frameLength)
        }

        amplitude = runningMax
        framePosition = peakFrame
    }
}
