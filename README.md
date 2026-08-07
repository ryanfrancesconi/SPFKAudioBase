# SPFKAudioBase
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-audio-base)](https://github.com/ryanfrancesconi/spfk-audio-base/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)

Shared audio types, AVFoundation extensions, and processing utilities for the SPFK package ecosystem. Provides the foundational layer used by [SPFKTempo](https://github.com/ryanfrancesconi/spfk-tempo), [SPFKLoudness](https://github.com/ryanfrancesconi/spfk-loudness), [SPFKMusicalAnalysis](https://github.com/ryanfrancesconi/spfk-musical-analysis), and other packages.

## Core Types

### Bpm

A tempo value in beats per minute with octave-equivalent matching.

```swift
let tempo = Bpm(120)!

tempo.quarterNoteDuration  // 0.5 seconds
tempo.multiples            // [15, 30, 60, 120, 240, 480, 960]
tempo.isMultiple(of: 60)   // true (120 is 2x of 60)
tempo.isMultiple(of: Bpm(61)!, tolerance: 2.0)  // true (within ±2 BPM)
```

### LoudnessDescription

EBU R128 loudness metrics for audio files.

```swift
var loudness = LoudnessDescription()
loudness.loudnessIntegrated = -24.13    // LUFS
loudness.loudnessRange = 1.43           // LU
loudness.maxTruePeakLevel = -0.07       // dBTP
loudness.maxMomentaryLoudness = -19.51  // LUFS
loudness.maxShortTermLoudness = -22.99  // LUFS

loudness.isValid       // true
loudness.stringValue   // "I -24.1 LUFS, TP -0.1 dB, LRA 1.4 LU, M -19.5 LU, S -23.0 LU"

// Average across files
let average = [loudness1, loudness2, loudness3].average
```

### AudioFileType

Enum representing audio formats with Core Audio, UTType, and MIME type mappings.

```swift
let type = AudioFileType(pathExtension: "m4a")
type?.fileTypeName       // "Apple MPEG-4 Audio"
type?.avFileType         // .m4a
type?.utType             // .mpeg4Audio
type?.mimeType           // "audio/mp4"
type?.isAudio            // true
type?.isPCM              // false
type?.supportsMetadata   // true
```

Capability is answered per question rather than by one "supported" flag, because the answers
genuinely differ by format — `supportsMetadata`, `supportsXMP`, `supportsBEXT`, `supportsIXML`,
`isAVAudioFileWritable`, `isMatroska`.

```swift
let mkv = AudioFileType(pathExtension: "mkv")
mkv?.isMatroska          // true
mkv?.supportsMetadata    // true  — TagLib 2.x has a full Matroska implementation
mkv?.avFileType          // nil   — AVFoundation cannot open it at all
```

**`isMatroska` covers `.mka`, `.mkv` and `.webm`** (WebM is a Matroska profile, so one parser
serves all three). These are the formats absent from `AVURLAsset.audiovisualTypes()`, where
`AVAudioFile(forReading:)` throws `'fmt?'` — so any AV-backed read returns nothing and a caller
has to route to the demuxer in
[spfk-matroska](https://github.com/ryanfrancesconi/spfk-matroska) instead. Metadata is unaffected
by that limit, which is why they are in `metadataTypes` while having no `avFileType`.

### CountableResult

Generic consensus voting for iterative analysis with early exit.

```swift
var results = CountableResult<Int>(matchesRequired: 3)

results.append(120)  // false
results.append(121)  // false
results.append(120)  // false
results.append(120)  // true — 120 reached 3 matches

results.suggestedValue  // 120
results.choose()        // 120 (most frequent)
```

### NoteName and MusicalTonality

Chromatic note names and tonality for musical key detection.

```swift
let note = NoteName(string: "Db")  // .cSharp
note?.description                  // "C#"
note?.enharmonic                   // "Db"

let tonality = MusicalTonality(string: "minor")  // .minor
```

## Audio File Scanning

`AudioFileScanner` streams an audio file in fixed-size chunks with progress reporting. Used by analysis engines (BPM, loudness, musical key) to process audio incrementally.

```swift
let scanner = AudioFileScanner(
    bufferDuration: 0.5,
    sendPeriodicProgressEvery: 4,
    minimumDuration: 15   // loop short files in-memory
) { event in
    switch event {
    case .progress(let url, let value):
        print("\(url.lastPathComponent): \(value)")
    case .data(let format, let length, let samples):
        // process PCM samples
        break
    case .periodicProgress(let url, let value):
        // run intermediate analysis
        break
    case .complete(let url):
        print("Done: \(url.lastPathComponent)")
    }
}

try await scanner.process(url: audioFileURL)
```

When `minimumDuration` is set and the file is shorter than half that value, the scanner loops by seeking back to frame 0, providing enough material for algorithms that require a minimum input length.

## Waveform Visualization

Parse audio files into drawing-ready waveform data at multiple resolution levels.

```swift
let parser = WaveformDataParser(resolution: .medium)
let waveform = try await parser.parse(url: audioFileURL)

waveform.channelCount     // 2
waveform.audioDuration     // 180.5
waveform.samplesPerPoint   // 64 (.medium)

// Extract a time range
let segment = try waveform.subdata(in: 10.0 ..< 20.0)
```

Resolution levels control the tradeoff between detail and data size:

| Resolution | Samples per Point | Best For |
|------------|------------------|----------|
| `.lossless` | 1 | Full-resolution editing |
| `.veryHigh` | 16 | Detailed zoomed views |
| `.high` | 32 | Standard waveform display |
| `.medium` | 64 | Overview display |
| `.low` | 128 | Thumbnail views |

## AVFoundation Extensions

### AVAudioPCMBuffer

```swift
let buffer = try AVAudioPCMBuffer(url: audioFileURL)

buffer.duration        // seconds
buffer.rmsValue        // RMS across all channels
buffer.isSilent        // true if all samples are zero

// Processing
let normalized = try buffer.normalize()
let reversed = try buffer.reverse()
let faded = try buffer.fade(inTime: 0.1, outTime: 0.5)
let converted = try buffer.convert(to: targetFormat)
let peak = try buffer.peak()

// Editing
let segment = try buffer.extract(from: 1.0, to: 5.0)
let looped = try buffer.loop(numberOfDuplicates: 3)
try buffer.append(otherBuffer)
try buffer.write(to: outputURL)
```

### AVAudioFile

```swift
let file = try AVAudioFile(forReading: url)

file.duration              // seconds
file.dataRate              // kbps (estimated)
try await file.estimatedDataRate()  // kbps (accurate)

let buffer = try file.toAVAudioPCMBuffer()
let partial = try file.toAVAudioPCMBuffer(maxDuration: 10)
let channelData = try file.toFloatChannelData()
```

### AVAudioFormat

```swift
format.readableDescription  // "44100 Hz, 16-bit, Stereo"
format.bitsPerChannel       // 16
format.bitRate              // 1411200.0

AVAudioFormat.createPCMFormat(bitsPerChannel: 24, channels: 2, sampleRate: 96000)
```

### AVAudioEngine

```swift
engine.outputFormat
engine.maxFramesPerSlice

engine.safeAttach(nodes: [mixer, effect])
engine.safeDetach(nodes: [mixer, effect])
engine.connectAndAttach(source, to: destination, format: format)
```

### AVAudioNode

```swift
node.resolvedName              // human-readable name
node.isOutputNodeConnected     // true if has output
node.ioConnectionDescription   // ASCII-art connection visualization

try node.disconnectOutput()
try node.disconnectInput()
try await node.disconnect(input: specificInput)
```

## System Audio Configuration

`AudioDefaults` manages the system audio format as a thread-safe actor:

```swift
await AudioDefaults.shared.update(systemFormat: deviceFormat)
await AudioDefaults.shared.sampleRate  // 48000.0
await AudioDefaults.shared.isSupported(sampleRate: 22050)  // depends on enforcement
```

## Time Formatting

`RealTimeDomain` provides time display string formatting:

```swift
RealTimeDomain.string(seconds: 3661.5)
// "1:01:01.500"

RealTimeDomain.string(seconds: 125.0, showHours: false, showMilliseconds: false)
// "2:05"

RealTimeDomain.seconds(string: "1:30.250")
// 90.25
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [spfk-base](https://github.com/ryanfrancesconi/spfk-base) | Core utilities, logging, type extensions |
| [spfk-testing](https://github.com/ryanfrancesconi/spfk-testing) | Test audio resources (test target only) |

## Requirements

- **Platforms:** macOS 13+, iOS 16+
- **Swift:** 6.2+

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
