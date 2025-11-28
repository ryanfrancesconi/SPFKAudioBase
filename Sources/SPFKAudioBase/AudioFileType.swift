// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKMetadata

import AVFoundation
import CoreAudio
import Foundation

// swiftformat:disable consecutiveSpaces

/// Common audio formats used by the SPFK system
public enum AudioFileType: String, Hashable, Codable, CaseIterable, Sendable {
    case aac
    case aifc
    case aiff
    case au
    case caf
    case flac
    case ogg
    case m4a
    case m4b
    case m4v
    case mov
    case mp3
    case mp4
    case opus
    case snd
    case ts
    case wav
    case w64

    /// File types that are commonly used for metadata storage
    public var metadataTypes: [AudioFileType] { [
        .aac,
        .aiff,
        .m4a,
        .m4b,
        .mp3,
        .mp4,
        .wav,
        .flac,
        .ogg,
        .opus,
    ] }

    public var supportsMetadata: Bool {
        metadataTypes.contains(self)
    }

    public var stringValue: String {
        fileTypeName ?? rawValue
    }

    /// See getFileTypeName() for lookup version
    public var fileTypeName: String? {
        switch self {
        case .aac:  "AAC"
        case .aiff: "AIFF"
        case .caf:  "CAF"
        case .flac: "FLAC"
        case .m4a:  "Apple MPEG-4 Audio"
        case .m4b:  "Apple MPEG-4 AudioBooks"
        case .mp3:  "MPEG Layer 3"
        case .mp4:  "MPEG-4"
        case .m4v:  "Apple MPEG-4 Video"
        case .mov:  "Apple QuickTime"
        case .ogg:  "Ogg Vorbis"
        case .opus: "Ogg Opus"
        case .wav:  "Waveform Audio"
        case .w64:  "Wave (BW64 for length over 4 GB)"
        default:
            nil
        }
    }

    public var pathExtension: String { rawValue }

    /// Create an `AudioFileType` from a URL pathExtension
    /// - Parameter pathExtension: pathExtension to parse.
    public init?(pathExtension: String) {
        let rawValue = pathExtension.lowercased()

        if rawValue == "aif" {
            self = .aiff
            return

        } else if rawValue == "wave" || rawValue == "bwf" {
            self = .wav
            return
        }

        guard let value = AudioFileType(rawValue: rawValue) else {
            return nil
        }

        self = value
    }

    // MARK: - Convenience mappings to CoreAudio and AVFoundation types when possible

    /// AVFoundation: File format UTIs
    public var avFileType: AVFileType? {
        switch self {
        case .aac:  .mp4
        case .aiff: .aiff
        case .aifc: .aifc
        case .au:   .au
        case .caf:  .caf
        case .m4a:  .m4a
        case .mov:  .mov
        case .mp3:  .mp3
        case .mp4:  .mp4
        case .wav:  .wav
        default:
            nil
        }
    }

    public var utType: UTType? {
        UTType(filenameExtension: pathExtension)
    }

    public var isVideo: Bool {
        guard let utType else { return false }
        return utType.conforms(to: .video) || utType.conforms(to: .movie)
    }

    public var isAudio: Bool {
        guard let utType else { return false }
        return utType.conforms(to: .audio)
    }

    public var isPCM: Bool {
        audioFormatID == kAudioFormatLinearPCM
    }

    public var mimeType: String? {
        switch self {
        case .aac:  "audio/aac"
        case .aiff: "audio/aiff"
        case .caf:  "audio/x-caf"
        case .m4a:  "audio/x-m4a"
        case .mov:  "video/mov"
        case .mp3:  "audio/mpeg"
        case .mp4:  "video/mp4"
        case .wav:  "audio/wav"
        default:
            utType?.preferredMIMEType
        }
    }

    /// CoreAudio: A four char code indicating the general kind of data in the stream.
    public var audioFormatID: AudioFormatID? {
        switch self {
        case .wav, .aiff, .caf:
            kAudioFormatLinearPCM
        case .m4a, .mp4:
            kAudioFormatMPEG4AAC
        case .mp3:
            kAudioFormatMPEGLayer3
        case .aac:
            kAudioFormatMPEG4AAC
        default:
            nil
        }
    }

    /// CoreAudio: Hardcoded CoreAudio identifier for an AudioFileType.
    public var audioFileTypeID: AudioFileTypeID? {
        switch self {
        case .aac:  kAudioFileAAC_ADTSType
        case .aifc: kAudioFileAIFCType
        case .aiff: kAudioFileAIFFType
        case .caf:  kAudioFileCAFType
        case .flac: kAudioFileFLACType
        case .m4a:  kAudioFileM4AType
        case .mp3:  kAudioFileMP3Type
        case .mp4:  kAudioFileMPEG4Type
        case .w64:  kAudioFileWave64Type
        case .wav:  kAudioFileWAVEType
        default:
            nil
        }
    }
}

// swiftformat:enable consecutiveSpaces
