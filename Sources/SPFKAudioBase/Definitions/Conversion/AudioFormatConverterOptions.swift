// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import SPFKBase

/// Options controlling an audio format conversion.
///
/// Leave any property `nil` to adopt the corresponding value from the input file.
/// `bitRate` assumes a stereo bit rate; the converter halves it for mono output.
public struct AudioFormatConverterOptions: Sendable {
    // MARK: - Static

    /// Formats supported for output conversion.
    public static let supportedOutputFormats: [AudioFileType] = [
        .wav, .aiff, .caf,
        .m4a, .mp3,
        .flac, .ogg,
    ]

    public static let supportedOutputFormatsString: String = {
        var parts = AudioFormatConverterOptions.supportedOutputFormats
            .map { $0.pathExtension.uppercased() }

        if parts.count > 1 { parts[parts.count - 1] = "and \(parts[parts.count - 1])" }
        return parts.joined(separator: ", ")
    }()

    /// Discrete bit depths supported for PCM output.
    public static let supportedBitsPerChannel: [UInt32] = [16, 24, 32]

    /// Discrete encoder bit rates in bits per second supported for compressed output.
    public static let supportedBitRates: [UInt32] = [64000, 96000, 128_000, 160_000, 192_000, 256_000, 320_000]

    /// Discrete sample rates in Hertz supported for conversion.
    public static let supportedSampleRates: [Double] = [22050, 44100, 48000, 88200, 96000]

    /// Supported output channel counts.
    public static let supportedChannelCounts: [UInt32] = [1, 2]

    /// Clamping range derived from ``supportedBitsPerChannel``.
    public static var bitsPerChannelRange: ClosedRange<UInt32> {
        supportedBitsPerChannel.first! ... supportedBitsPerChannel.last!
    }

    /// Clamping range derived from ``supportedBitRates``.
    public static var bitRateRange: ClosedRange<UInt32> {
        supportedBitRates.first! ... supportedBitRates.last!
    }

    // MARK: - Properties

    /// The target audio file format. Only values in ``supportedOutputFormats`` are accepted.
    public var format: AudioFileType? {
        didSet {
            guard let format, Self.supportedOutputFormats.contains(format) else {
                format = nil
                return
            }
        }
    }

    /// Sample Rate in Hertz
    public var sampleRate: Double?

    /// Bits per channel for PCM output (clamped to ``bitsPerChannelRange``).
    public var bitsPerChannel: UInt32? {
        didSet {
            if let bitsPerChannel, bitsPerChannel < Self.bitsPerChannelRange.lowerBound {
                Log.error("bitsPerChannel is too low and will be clamped", bitsPerChannel)
            }

            bitsPerChannel = bitsPerChannel?.clamped(to: Self.bitsPerChannelRange)
        }
    }

    /// Encoder bit rate in bits per second for compressed output (clamped to ``bitRateRange``).
    public var bitRate: UInt32 = 256_000 {
        didSet {
            if bitRate < Self.bitRateRange.lowerBound {
                Log.error(
                    "bitRate is too low \(bitRate) and will be clamped to \(Self.bitRateRange). Did you *= 1000? Will be clamped to \(Self.bitRateRange)"
                )
            }

            bitRate = bitRate.clamped(to: Self.bitRateRange)
        }
    }

    /// Controls whether bit depth upsampling is allowed. Defaults to ``BitDepthRule/any``.
    public var bitDepthRule: BitDepthRule = .any

    /// Target channel count, or `nil` to preserve the source channel layout.
    public var channels: UInt32?

    /// Maps to PCM Conversion format option `AVLinearPCMIsNonInterleaved`
    public var isInterleaved: Bool?

    /// Whether to overwrite an existing output file, rename it, or throw an error if it exists
    public var conflictScheme: FileConflictScheme = .overwrite

    // MARK: - Initializers

    /// Creates default options (all values `nil`, adopting the input file's properties).
    public init() {}

    /// Create options by parsing the contents of the url and using the audio settings
    /// in the file
    /// - Parameter url: The audio file to open and parse
    public init?(url: URL) {
        guard let avFile = try? AVAudioFile(forReading: url) else { return nil }
        self.init(audioFile: avFile)
    }

    /// Create options by parsing the audioFile for its settings
    /// - Parameter audioFile: an AVAudioFile to parse
    public init?(audioFile: AVAudioFile) {
        let streamDescription = audioFile.fileFormat.streamDescription.pointee

        format = AudioFileType(rawValue: audioFile.url.pathExtension.lowercased())
        sampleRate = streamDescription.mSampleRate
        bitsPerChannel = streamDescription.mBitsPerChannel
        channels = streamDescription.mChannelsPerFrame
    }

    /// Create PCM Options
    /// - Parameters:
    ///   - pcmFormat: wav, aif, or caf
    ///   - sampleRate: Sample Rate
    ///   - bitDepth: Bit Depth, or bits per channel
    ///   - channels: How many channels
    public init(
        pcmFormat: AudioFileType,
        sampleRate: Double? = nil,
        bitsPerChannel: UInt32? = nil,
        channels: UInt32? = nil,
        bitDepthRule: BitDepthRule = .any
    ) throws {
        guard pcmFormat.isPCM else {
            throw NSError(description: "Not a pcm format \(pcmFormat.pathExtension)")
        }

        format = pcmFormat
        self.sampleRate = sampleRate
        self.bitsPerChannel = bitsPerChannel
        self.channels = channels
        self.bitDepthRule = bitDepthRule
    }

    /// Creates options targeting the given format with all other values at their defaults.
    public init(format: AudioFileType, conflictScheme: FileConflictScheme = .overwrite) {
        self.format = format
        self.conflictScheme = conflictScheme
    }
}

// MARK: - Codable

extension AudioFormatConverterOptions: Codable, Serializable {
    enum CodingKeys: String, CodingKey {
        case format
        case sampleRate
        case bitsPerChannel
        case bitRate
        case bitDepthRule
        case channels
        case isInterleaved
        case conflictScheme
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AudioFormatConverterOptions()

        // Assign through properties to trigger didSet validation
        format = try container.decodeIfPresent(AudioFileType.self, forKey: .format) ?? defaults.format
        sampleRate = try container.decodeIfPresent(Double.self, forKey: .sampleRate) ?? defaults.sampleRate
        bitsPerChannel = try container.decodeIfPresent(UInt32.self, forKey: .bitsPerChannel) ?? defaults.bitsPerChannel
        bitRate = try container.decodeIfPresent(UInt32.self, forKey: .bitRate) ?? defaults.bitRate
        bitDepthRule = try container.decodeIfPresent(BitDepthRule.self, forKey: .bitDepthRule) ?? defaults.bitDepthRule
        channels = try container.decodeIfPresent(UInt32.self, forKey: .channels) ?? defaults.channels
        isInterleaved = try container.decodeIfPresent(Bool.self, forKey: .isInterleaved) ?? defaults.isInterleaved
        conflictScheme = try container.decodeIfPresent(FileConflictScheme.self, forKey: .conflictScheme) ?? defaults.conflictScheme
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(sampleRate, forKey: .sampleRate)
        try container.encodeIfPresent(bitsPerChannel, forKey: .bitsPerChannel)
        try container.encode(bitRate, forKey: .bitRate)
        try container.encode(bitDepthRule, forKey: .bitDepthRule)
        try container.encodeIfPresent(channels, forKey: .channels)
        try container.encodeIfPresent(isInterleaved, forKey: .isInterleaved)
        try container.encode(conflictScheme, forKey: .conflictScheme)
    }
}

// MARK: - Equatable, Hashable

extension AudioFormatConverterOptions: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.format == rhs.format && lhs.sampleRate == rhs.sampleRate && lhs.bitsPerChannel == rhs.bitsPerChannel
            && lhs.bitRate == rhs.bitRate && lhs.bitDepthRule == rhs.bitDepthRule && lhs.channels == rhs.channels
            && lhs.isInterleaved == rhs.isInterleaved && lhs.conflictScheme == rhs.conflictScheme
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(format)
        hasher.combine(sampleRate)
        hasher.combine(bitsPerChannel)
        hasher.combine(bitRate)
        hasher.combine(bitDepthRule)
        hasher.combine(channels)
        hasher.combine(isInterleaved)
        hasher.combine(conflictScheme)
    }
}

// MARK: - Presets

extension AudioFormatConverterOptions {
    /// Preset: stereo 16-bit WAV at the system default sample rate.
    public static var waveStereo48k16bit: AudioFormatConverterOptions {
        get async {
            var o = AudioFormatConverterOptions()
            o.format = .wav
            o.sampleRate = await AudioDefaults.shared.sampleRate
            o.bitsPerChannel = 16
            o.channels = 2
            o.bitDepthRule = .any
            return o
        }
    }
}
