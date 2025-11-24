// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKAudio

import Accelerate
import AVFoundation
import SPFKBase

extension AVAudioPCMBuffer {
    public var duration: TimeInterval {
        TimeInterval(frameLength) / format.sampleRate
    }

    public var rmsValue: Float {
        guard let data = floatChannelData else { return 0 }

        var rms: Float = 0.0

        for i in 0 ..< Int(format.channelCount) {
            var channelRms: Float = 0.0
            vDSP_rmsqv(data[i], 1, &channelRms, vDSP_Length(frameLength))
            rms += abs(channelRms)
        }

        let value = rms / Float(format.channelCount)

        return value
    }

    /// Returns internal buffer as an `Array` of swift `Float` Arrays.
    ///
    /// - `floatData?[X]` will contain an Array of channel length samples as `Float`
    public var floatData: FloatChannelData? {
        // Do we have PCM channel data?
        guard let floatChannelData else { return nil }

        let channelCount = Int(format.channelCount)
        let length = Int(frameLength)
        var result = newFloatChannelData(channelCount: channelCount, length: length)

        for n in 0 ..< channelCount {
            for i in 0 ..< length {
                result[n][i] = floatChannelData[n][i * stride]
            }
        }

        return result
    }
}

extension AVAudioPCMBuffer {
    /// Read the contents of the url into this buffer
    public convenience init?(url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        try self.init(audioFile: file)
    }

    /// Read entire file and return a new AVAudioPCMBuffer with its contents
    public convenience init?(audioFile: AVAudioFile) throws {
        audioFile.framePosition = 0

        self.init(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        )

        try audioFile.read(into: self)
    }

    /// Write this buffer with it's current format to file
    /// - Parameter url: URL to write to
    public func write(to url: URL) throws {
        var settings = format.settings
        settings[AVLinearPCMIsNonInterleaved] = false

        let output = try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )

        try output.write(from: self)
    }
}
