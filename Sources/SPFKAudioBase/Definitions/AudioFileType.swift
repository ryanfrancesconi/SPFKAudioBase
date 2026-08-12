// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import CoreAudio
import Foundation

// swiftformat:disable consecutiveSpaces

/// Common audio formats used by the SPFK system
public enum AudioFileType: String, Hashable, CaseIterable, Sendable, Codable {
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
    case mka
    case mkv
    case mov
    case mp3
    case mp4
    case opus
    case snd
    case ts
    case wav
    case w64
    case webm

    /// File types that are commonly used for metadata storage.
    ///
    /// `mov`/`m4v` belong here for the same reason `mp4` does — TagLib's MP4 handler reads and
    /// writes them, including a QuickTime chapter track for markers. Their earlier absence made
    /// `AudioFormatConverter.copyMetadata()` skip a `.mov` output wholesale, dropping tags,
    /// markers, artwork and Finder tags in one step.
    ///
    /// `mkv`/`webm` likewise: TagLib 2.x ships a full Matroska implementation and `FileRef`
    /// dispatches both by extension, so reads and writes work without a format-specific path.
    /// AVFoundation cannot open either — that limits playback and thumbnails, not metadata.
    public static let metadataTypes: [AudioFileType] = [
        .aac,
        .aiff,
        .m4a,
        .m4b,
        .m4v,
        .mka,
        .mkv,
        .mov,
        .mp3,
        .mp4,
        .wav,
        .webm,
        .flac,
        .ogg,
        .opus,
    ]

    public var supportsMetadata: Bool {
        Self.metadataTypes.contains(self)
    }

    /// Matroska-family containers. WebM is a Matroska profile, so one parser covers both and
    /// nothing downstream needs to tell them apart.
    ///
    /// **AVFoundation cannot open either** — they are absent from `AVURLAsset.audiovisualTypes()`,
    /// and `AVAudioFile(forReading:)` throws `'fmt?'`. So any AV-backed read returns nothing for
    /// them and a caller has to route to the demuxer instead, which is what this answers.
    public static let matroskaTypes: [AudioFileType] = [.mka, .mkv, .webm]

    public var isMatroska: Bool {
        Self.matroskaTypes.contains(self)
    }

    /// Containers that can hold more than one audio track, and so can present a choice of which
    /// one to play.
    ///
    /// **A superset of the `isVideo` types**, deliberately: `.mka` and `.m4a`/`.m4b` are audio
    /// containers built on formats that carry alternate tracks as readily as their video siblings,
    /// so a UTType-driven video test answers the wrong question here. Everything else in this enum
    /// carries exactly one stream, where listing tracks costs an asset open per imported file and
    /// can only ever name the track that would have played anyway.
    public static let multiAudioTrackTypes: [AudioFileType] = [
        .m4a, .m4b, .m4v, .mka, .mkv, .mov, .mp4, .ts, .webm,
    ]

    public var supportsMultipleAudioTracks: Bool {
        Self.multiAudioTrackTypes.contains(self)
    }

    /// File types with reliable XMP support via the Adobe XMP SDK smart handler.
    /// Formats not listed here either lack a smart handler or have no standard XMP embedding.
    public static let xmpTypes: [AudioFileType] = [
        .aiff, .aifc, .m4a, .m4b, .m4v, .mov, .mp3, .mp4, .wav, .w64,
    ]

    public var supportsXMP: Bool {
        Self.xmpTypes.contains(self)
    }

    /// RIFF-based formats that support native chunk metadata (BEXT and iXML).
    public static let riffTypes: [AudioFileType] = [.wav, .w64]

    /// Whether this format supports BEXT metadata chunks.
    /// Includes RIFF-based formats (WAV, AIFF) and FLAC (via APPLICATION blocks).
    public var supportsBEXT: Bool { Self.riffTypes.contains(self) || self == .flac }

    /// Whether this format supports iXML metadata chunks.
    /// Includes RIFF-based formats (WAV, AIFF) and FLAC (via APPLICATION blocks).
    public var supportsIXML: Bool { Self.riffTypes.contains(self) || self == .flac }

    public var stringValue: String {
        fileTypeName ?? rawValue
    }

    /// See getFileTypeName() for lookup version
    public var fileTypeName: String? {
        switch self {
        case .aac:  "Advanced Audio Coding"
        case .aiff: "Audio Interchange File Format"
        case .caf:  "Core Audio Format"
        case .flac: "Free Lossless Audio Codec"
        case .m4a:  "Apple MPEG-4 Audio"
        case .m4b:  "Apple MPEG-4 AudioBooks"
        case .mp3:  "MPEG Layer 3"
        case .mp4:  "MPEG-4"
        case .m4v:  "Apple MPEG-4 Video"
        case .mka:  "Matroska Audio"
        case .mkv:  "Matroska Video"
        case .mov:  "Apple QuickTime"
        case .webm: "WebM Video"
        case .ogg:  "Ogg Vorbis"
        case .opus: "Ogg Opus"
        case .wav:  "Waveform Audio"
        case .w64:  "Sony Wave64"
        default:
            nil
        }
    }

    /// Returns a descriptive UI facing string suitable for display
    public var fileTypeNameAndExtension: String {
        let ext = pathExtension.uppercased()

        guard let fileTypeName else { return ext }
        return "\(ext) (\(fileTypeName))"
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

    /// Whether this format uses bit depth for encoding (PCM and lossless formats like FLAC).
    /// Formats that return `false` use bit rate instead (MP3, M4A, OGG Vorbis).
    public var usesBitDepth: Bool {
        switch self {
        case .wav, .aiff, .caf, .flac:
            true
        default:
            false
        }
    }

    /// Whether `AVAudioFile` can write this format directly (PCM and AAC containers).
    /// Formats that return `false` require an intermediate converter (e.g. MP3, FLAC, OGG, Opus).
    /// Unknown formats not represented by this enum default to `true` — AVAudioFile will throw
    /// if the format is actually unsupported.
    public var isAVAudioFileWritable: Bool {
        switch self {
        case .aac, .aiff, .aifc, .au, .caf, .m4a, .mp4, .wav:
            true
        default:
            false
        }
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
