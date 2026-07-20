// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Accelerate
import AVFoundation
import Foundation

/// Scans an AVAudioFile in fixed-size chunks to locate silence boundaries and non-silent regions.
///
/// Uses a vDSP peak-magnitude fast path to skip silent chunks without per-frame inspection,
/// keeping memory usage constant regardless of file length.
public struct AudioSilenceScanner: Sendable {
    public static let defaultChunkSize: AVAudioFrameCount = 4096

    /// Silence threshold in linear amplitude. Samples at or below this level are treated as silence.
    public let silenceThreshold: Float

    /// Number of frames per read chunk.
    public let chunkSize: AVAudioFrameCount

    public init(silenceThreshold: Float, chunkSize: AVAudioFrameCount = defaultChunkSize) {
        self.silenceThreshold = silenceThreshold
        self.chunkSize = chunkSize
    }

    // MARK: - Public API

    /// Returns the frame index of the first sample above the silence threshold, scanning forward
    /// from the start. Returns `nil` if the entire file is at or below the threshold.
    public func leadingSilenceEnd(in audioFile: AVAudioFile) async throws -> AVAudioFrameCount? {
        let format = audioFile.processingFormat
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let channelCount = Int(format.channelCount)

        guard totalFrames > 0, channelCount > 0 else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else { return nil }

        var position: AVAudioFrameCount = 0

        while position < totalFrames {
            try Task.checkCancellation()
            let framesToRead = min(chunkSize, totalFrames - position)
            audioFile.framePosition = AVAudioFramePosition(position)
            try audioFile.read(into: buffer, frameCount: framesToRead)

            guard let data = buffer.floatChannelData else { break }
            let frameLength = Int(buffer.frameLength)

            if hasAudio(data: data, frameLength: frameLength, channelCount: channelCount) {
                for i in 0 ..< frameLength {
                    for ch in 0 ..< channelCount {
                        if abs(data[ch][i]) > silenceThreshold {
                            return position + AVAudioFrameCount(i)
                        }
                    }
                }
            }

            position += AVAudioFrameCount(frameLength)
        }

        return nil
    }

    /// Returns the frame index of the last sample above the silence threshold, scanning backward
    /// from the end. Returns `nil` if the entire file is at or below the threshold.
    public func trailingSilenceStart(in audioFile: AVAudioFile) async throws -> AVAudioFrameCount? {
        let format = audioFile.processingFormat
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let channelCount = Int(format.channelCount)

        guard totalFrames > 0, channelCount > 0 else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else { return nil }

        var endPosition = totalFrames

        while endPosition > 0 {
            try Task.checkCancellation()
            let chunkStart = endPosition > chunkSize ? endPosition - chunkSize : 0
            let framesToRead = endPosition - chunkStart
            audioFile.framePosition = AVAudioFramePosition(chunkStart)
            try audioFile.read(into: buffer, frameCount: framesToRead)

            guard let data = buffer.floatChannelData else { break }
            let frameLength = Int(buffer.frameLength)

            if hasAudio(data: data, frameLength: frameLength, channelCount: channelCount) {
                for i in stride(from: frameLength - 1, through: 0, by: -1) {
                    for ch in 0 ..< channelCount {
                        if abs(data[ch][i]) > silenceThreshold {
                            return chunkStart + AVAudioFrameCount(i)
                        }
                    }
                }
            }

            endPosition = chunkStart
        }

        return nil
    }

    /// Returns all contiguous non-silent regions in the file as inclusive frame ranges.
    ///
    /// Silent gaps shorter than `minimumSilenceDuration` are bridged so that transient quiet
    /// moments within a sound do not split a region. Intended for stem extraction and region
    /// detection workflows.
    public func nonSilentRegions(
        in audioFile: AVAudioFile,
        minimumSilenceDuration: TimeInterval = 0.1
    ) async throws -> [ClosedRange<AVAudioFrameCount>] {
        let format = audioFile.processingFormat
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let channelCount = Int(format.channelCount)
        let minimumSilenceFrames = AVAudioFrameCount(minimumSilenceDuration * format.sampleRate)

        guard totalFrames > 0, channelCount > 0 else { return [] }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else { return [] }

        var regions: [ClosedRange<AVAudioFrameCount>] = []
        var regionStart: AVAudioFrameCount? = nil
        var silenceRunStart: AVAudioFrameCount? = nil
        var position: AVAudioFrameCount = 0

        while position < totalFrames {
            try Task.checkCancellation()
            let framesToRead = min(chunkSize, totalFrames - position)
            audioFile.framePosition = AVAudioFramePosition(position)
            try audioFile.read(into: buffer, frameCount: framesToRead)

            guard let data = buffer.floatChannelData else { break }
            let frameLength = Int(buffer.frameLength)

            // Fast path: entire chunk is silent — extend any open silence run without per-frame work.
            if !hasAudio(data: data, frameLength: frameLength, channelCount: channelCount) {
                if regionStart != nil, silenceRunStart == nil {
                    silenceRunStart = position
                }
                if let silStart = silenceRunStart,
                   position + AVAudioFrameCount(frameLength) - silStart >= minimumSilenceFrames,
                   let regStart = regionStart
                {
                    regions.append(regStart ... (silStart - 1))
                    regionStart = nil
                    silenceRunStart = nil
                }
                position += AVAudioFrameCount(frameLength)
                continue
            }

            // Slow path: chunk contains audio — scan per-frame for precise boundary detection.
            for i in 0 ..< frameLength {
                var frameHasAudio = false
                for ch in 0 ..< channelCount {
                    if abs(data[ch][i]) > silenceThreshold {
                        frameHasAudio = true
                        break
                    }
                }

                let frame = position + AVAudioFrameCount(i)

                if frameHasAudio {
                    if regionStart == nil { regionStart = frame }
                    silenceRunStart = nil
                } else {
                    if regionStart != nil, silenceRunStart == nil {
                        silenceRunStart = frame
                    }
                    if let silStart = silenceRunStart,
                       frame - silStart >= minimumSilenceFrames,
                       let regStart = regionStart
                    {
                        regions.append(regStart ... (silStart - 1))
                        regionStart = nil
                        silenceRunStart = nil
                    }
                }
            }

            position += AVAudioFrameCount(frameLength)
        }

        // Close any still-open region at EOF.
        if let regStart = regionStart {
            let lastNonSilent = silenceRunStart.map { $0 - 1 } ?? (totalFrames > 0 ? totalFrames - 1 : 0)
            regions.append(regStart ... lastNonSilent)
        }

        return regions
    }

    // MARK: - Private

    private func hasAudio(
        data: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameLength: Int,
        channelCount: Int
    ) -> Bool {
        for ch in 0 ..< channelCount {
            var maxMag: Float = 0
            vDSP_maxmgv(data[ch], 1, &maxMag, vDSP_Length(frameLength))
            if maxMag > silenceThreshold { return true }
        }
        return false
    }
}
