// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase

public struct AudioFileScanner: Sendable {
    private let bufferDuration: TimeInterval
    private var sendPeriodicProgressEvery: UInt32
    private let eventHandler: AudioFileScannerEventHandler

    /// Prepare to scan a file
    /// - Parameters:
    ///   - bufferDuration: The duration of each buffer returned
    ///   - sendPeriodicProgressEvery: Sends this event after this time in samples has been processed.
    ///   not the amount of time elapsed processing.
    ///   - eventHandler: Events will be send async
    public init(
        bufferDuration: TimeInterval = 0.2,
        sendPeriodicProgressEvery: TimeInterval = 4,
        eventHandler: @escaping AudioFileScannerEventHandler
    ) {
        self.bufferDuration = max(0.1, bufferDuration)
        self.sendPeriodicProgressEvery = UInt32(max(1, sendPeriodicProgressEvery))
        self.eventHandler = eventHandler
    }

    public func process(url: URL) async throws {
        try await process(audioFile: AVAudioFile(forReading: url))
    }

    public func process(audioFile: AVAudioFile) async throws {
        Log.debug(audioFile.url.lastPathComponent, audioFile.duration, "seconds", "bufferDuration", bufferDuration)

        // store the current frame before scanning the file
        let currentFrame = audioFile.framePosition

        defer {
            // return the file to frame is was on previously
            audioFile.framePosition = currentFrame
        }

        try await _process(audioFile: audioFile)

        await eventHandler(.complete(url: audioFile.url))
    }

    private func _process(audioFile: AVAudioFile) async throws {
        let url = audioFile.url
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let totalFramesDouble = Double(totalFrames)
        let pcmFormat: AVAudioFormat = audioFile.processingFormat

        guard totalFrames > 0 else {
            throw NSError(description: "No audio was found in \(audioFile.url.path)")
        }

        // analysis buffer size
        var framesPerBuffer = AVAudioFrameCount(bufferDuration * pcmFormat.sampleRate)

        if framesPerBuffer > totalFrames {
            framesPerBuffer = totalFrames
        }

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: pcmFormat,
                frameCapacity: framesPerBuffer
            )
        else {
            throw NSError(description: "Unable to create buffer")
        }

        var currentFrame: AVAudioFramePosition = 0

        // check for rolling bpm every 4 seconds
        let performCheckAt: AVAudioFrameCount = AVAudioFrameCount(pcmFormat.sampleRate) * sendPeriodicProgressEvery
        var framesSinceLastDetect: AVAudioFrameCount = 0

        func send(progress: UnitInterval) async {
            await eventHandler(.progress(url: url, value: progress))
        }

        func send(samples: UnsafePointer<UnsafeMutablePointer<Float>>) async {
            await eventHandler(.data(format: pcmFormat, length: framesPerBuffer, samples: samples))
        }

        while currentFrame < totalFrames {
            try Task.checkCancellation()

            audioFile.framePosition = currentFrame

            let progress: UnitInterval = Double(currentFrame) / totalFramesDouble
            await send(progress: progress)

            try audioFile.read(into: buffer, frameCount: framesPerBuffer)

            if let rawData = buffer.floatChannelData {
                await send(samples: rawData)
            }

            currentFrame += AVAudioFramePosition(framesPerBuffer)

            // buffer has reached end of file, trim it
            if currentFrame + AVAudioFramePosition(framesPerBuffer) > totalFrames {
                framesPerBuffer = totalFrames - AVAudioFrameCount(currentFrame)

                guard framesPerBuffer > 0 else { break }
            }

            framesSinceLastDetect += framesPerBuffer

            if framesSinceLastDetect > performCheckAt {
                await eventHandler(.periodicProgress(url: url, value: progress))

                framesSinceLastDetect = 0
            }
        }
    }
}

/// Event handler for scanning audio data
public typealias AudioFileScannerEventHandler = @Sendable (AudioFileScannerEvent) async -> Void

/// Note: This event can't be Sendable due to the raw samples in the .data() case
public enum AudioFileScannerEvent {
    case progress(url: URL, value: UnitInterval)
    case periodicProgress(url: URL, value: UnitInterval)
    case data(format: AVAudioFormat, length: AVAudioFrameCount, samples: UnsafePointer<UnsafeMutablePointer<Float>>)
    case complete(url: URL)
}
