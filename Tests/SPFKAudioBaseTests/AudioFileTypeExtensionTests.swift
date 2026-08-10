import AVFoundation
import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("AudioFileType Extensions")
struct AudioFileTypeExtensionTests {
    // MARK: - Init from path extension

    @Test("init from standard path extensions")
    func initFromPathExtension() {
        #expect(AudioFileType(pathExtension: "wav") == .wav)
        #expect(AudioFileType(pathExtension: "mp3") == .mp3)
        #expect(AudioFileType(pathExtension: "aiff") == .aiff)
        #expect(AudioFileType(pathExtension: "caf") == .caf)
        #expect(AudioFileType(pathExtension: "flac") == .flac)
    }

    @Test("init normalizes case")
    func initCaseInsensitive() {
        #expect(AudioFileType(pathExtension: "WAV") == .wav)
        #expect(AudioFileType(pathExtension: "Mp3") == .mp3)
    }

    @Test("init handles aliases")
    func initAliases() {
        #expect(AudioFileType(pathExtension: "aif") == .aiff)
        #expect(AudioFileType(pathExtension: "wave") == .wav)
        #expect(AudioFileType(pathExtension: "bwf") == .wav)
    }

    @Test("init returns nil for unknown extensions")
    func initUnknown() {
        #expect(AudioFileType(pathExtension: "xyz") == nil)
        #expect(AudioFileType(pathExtension: "") == nil)
    }

    // MARK: - Properties

    @Test("pathExtension matches rawValue")
    func pathExtension() {
        #expect(AudioFileType.wav.pathExtension == "wav")
        #expect(AudioFileType.mp3.pathExtension == "mp3")
    }

    @Test("supportsMetadata for common types")
    func supportsMetadata() {
        #expect(AudioFileType.wav.supportsMetadata)
        #expect(AudioFileType.aiff.supportsMetadata)
        #expect(AudioFileType.mp3.supportsMetadata)
        #expect(AudioFileType.m4a.supportsMetadata)
        #expect(AudioFileType.flac.supportsMetadata)

        #expect(!AudioFileType.caf.supportsMetadata)
        #expect(!AudioFileType.au.supportsMetadata)
    }

    @Test("isPCM for PCM formats")
    func isPCM() {
        #expect(AudioFileType.wav.isPCM)
        #expect(AudioFileType.aiff.isPCM)
        #expect(AudioFileType.caf.isPCM)

        #expect(!AudioFileType.mp3.isPCM)
        #expect(!AudioFileType.m4a.isPCM)
    }

    @Test("isAudio for audio formats")
    func isAudio() {
        #expect(AudioFileType.wav.isAudio)
        #expect(AudioFileType.mp3.isAudio)
        #expect(AudioFileType.aiff.isAudio)
    }

    @Test("isVideo for video formats")
    func isVideo() {
        #expect(AudioFileType.mov.isVideo)
        #expect(AudioFileType.m4v.isVideo)
        #expect(!AudioFileType.wav.isVideo)
    }

    /// The listing of a file's audio tracks is gated on this alone, so anything `isVideo` answers
    /// yes to has to be here — or a video container loses its picker on a property meant to widen
    /// the set.
    @Test("multi-audio-track types cover every video type")
    func multiAudioTrackTypesCoverVideo() {
        for type in AudioFileType.allCases where type.isVideo {
            #expect(type.supportsMultipleAudioTracks, "\(type) is video but not multi-track capable")
        }
    }

    /// The audio containers the video test misses: `.mka` and the MPEG-4 audio pair carry alternate
    /// tracks, while a single-stream format must stay out to keep an import from opening an asset
    /// per file for a choice that cannot exist.
    @Test("multi-audio-track types include the audio containers that carry alternates")
    func multiAudioTrackTypesIncludeAudioContainers() {
        #expect(AudioFileType.mka.supportsMultipleAudioTracks)
        #expect(AudioFileType.m4a.supportsMultipleAudioTracks)
        #expect(AudioFileType.m4b.supportsMultipleAudioTracks)

        #expect(!AudioFileType.wav.supportsMultipleAudioTracks)
        #expect(!AudioFileType.mp3.supportsMultipleAudioTracks)
        #expect(!AudioFileType.flac.supportsMultipleAudioTracks)
        #expect(!AudioFileType.aiff.supportsMultipleAudioTracks)
    }

    @Test("mimeType returns correct values")
    func mimeType() {
        #expect(AudioFileType.wav.mimeType == "audio/wav")
        #expect(AudioFileType.mp3.mimeType == "audio/mpeg")
        #expect(AudioFileType.aiff.mimeType == "audio/aiff")
        #expect(AudioFileType.caf.mimeType == "audio/x-caf")
        #expect(AudioFileType.mp4.mimeType == "video/mp4")
    }

    @Test("avFileType mappings")
    func avFileType() {
        #expect(AudioFileType.wav.avFileType == .wav)
        #expect(AudioFileType.aiff.avFileType == .aiff)
        #expect(AudioFileType.mp3.avFileType == .mp3)
        #expect(AudioFileType.m4a.avFileType == .m4a)
        #expect(AudioFileType.ogg.avFileType == nil)
    }

    @Test("audioFileTypeID mappings")
    func audioFileTypeID() {
        #expect(AudioFileType.wav.audioFileTypeID == kAudioFileWAVEType)
        #expect(AudioFileType.aiff.audioFileTypeID == kAudioFileAIFFType)
        #expect(AudioFileType.mp3.audioFileTypeID == kAudioFileMP3Type)
        #expect(AudioFileType.flac.audioFileTypeID == kAudioFileFLACType)
        #expect(AudioFileType.ogg.audioFileTypeID == nil)
    }

    @Test("fileTypeName for known types")
    func fileTypeName() {
        #expect(AudioFileType.wav.fileTypeName == "Waveform Audio")
        #expect(AudioFileType.aiff.fileTypeName == "Audio Interchange File Format")
        #expect(AudioFileType.mp3.fileTypeName == "MPEG Layer 3")
        #expect(AudioFileType.au.fileTypeName == nil)
    }

    @Test("stringValue falls back to rawValue")
    func stringValue() {
        #expect(AudioFileType.wav.stringValue == "Waveform Audio")
        #expect(AudioFileType.au.stringValue == "au") // no fileTypeName
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codable() throws {
        let original = AudioFileType.wav
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioFileType.self, from: data)
        #expect(decoded == original)
    }

    @Test("decode from raw string")
    func decodeFromString() throws {
        let json = "\"mp3\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AudioFileType.self, from: json)
        #expect(decoded == .mp3)
    }

    @Test("decode invalid string throws")
    func decodeInvalid() {
        let json = "\"xyz\"".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(AudioFileType.self, from: json)
        }
    }
}
