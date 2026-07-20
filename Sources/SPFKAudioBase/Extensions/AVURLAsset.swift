// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation

extension AVURLAsset {
    public var audioFormat: AVAudioFormat? {
        get async {
            // pull the input format out of the audio file...
            if let source = try? AVAudioFile(forReading: url) {
                return source.fileFormat

                // if that fails it might be a video, so check the tracks for audio
            } else {
                guard let audioTracks = try? await loadTracks(withMediaType: .audio),
                      !audioTracks.isEmpty else { return nil }

                var allDescriptions: [CMFormatDescription] = []
                for track in audioTracks {
                    if let descriptions = try? await track.load(.formatDescriptions) {
                        allDescriptions.append(contentsOf: descriptions)
                    }
                }

                let audioFormats: [AVAudioFormat] = allDescriptions.compactMap {
                    AVAudioFormat(cmAudioFormatDescription: $0)
                }
                return audioFormats.first
            }
        }
    }

    public func hasTimecode() async -> Bool {
        guard let tracks = try? await loadTracks(withMediaType: .timecode) else { return false }
        return !tracks.isEmpty
    }

    public func hasAudio() async -> Bool {
        guard let tracks = try? await loadTracks(withMediaType: .audio) else { return false }
        return !tracks.isEmpty
    }

    public func hasVideo() async -> Bool {
        guard let tracks = try? await loadTracks(withMediaType: .video) else { return false }
        return !tracks.isEmpty
    }
}
