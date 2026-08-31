# SPFKAudioBase
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-audio-base)](https://github.com/ryanfrancesconi/spfk-audio-base/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)

Shared audio types, AVFoundation extensions and processing utilities for the SPFK package ecosystem
— the foundational layer under [spfk-tempo](https://github.com/ryanfrancesconi/spfk-tempo),
[spfk-loudness](https://github.com/ryanfrancesconi/spfk-loudness),
[spfk-musical-analysis](https://github.com/ryanfrancesconi/spfk-musical-analysis) and the rest.

## Requirements

- **Platforms:** macOS 13+, iOS 16+
- **Swift:** 6.2+

## Core types

| Type | Description |
|------|-------------|
| **`AudioFileType`** | Every audio format the products handle, with its Core Audio, `UTType` and MIME mappings |
| **`Bpm`** | A tempo in beats per minute, with octave-equivalent matching and a tolerance |
| **`LoudnessDescription`** | EBU R128 metrics — integrated, range, true peak, max momentary and short-term — with averaging across files |
| **`NoteName`** / **`MusicalTonality`** | Chromatic note names with enharmonics, and major/minor |
| **`CountableResult`** | Consensus voting for iterative analysis, with early exit once a value reaches the required number of matches |
| **`BufferPeak`** | A peak measurement over a buffer |
| **`AudioTaper`** | The shape of a fade or gain ramp |
| **`RealTimeDomain`** | Time display strings, and parsing them back |
| **`AudioDefaults`** | The system audio format, as an actor |

### AudioFileType capability

Capability is answered per question rather than by one "supported" flag, because the answers
genuinely differ by format — `supportsMetadata`, `supportsXMP`, `supportsBEXT`, `supportsIXML`,
`isAVAudioFileWritable`, `isMatroska`.

**`isMatroska` covers `.mka`, `.mkv` and `.webm`** (WebM is a Matroska profile, so one parser
serves all three). These are the formats absent from `AVURLAsset.audiovisualTypes()`, where
`AVAudioFile(forReading:)` throws `'fmt?'` — so any AV-backed read returns nothing and a caller
has to route to the demuxer in
[spfk-matroska](https://github.com/ryanfrancesconi/spfk-matroska) instead. Metadata is unaffected
by that limit, which is why they are in `metadataTypes` while having no `avFileType`.

### AudioTaper

`value` sets the curvature exponent and `skew` blends that power curve with its own inverse,
concave against convex. Every consumer — PCM buffer fading, parameter automation, and the drawn
overlay — evaluates the same gain function, so a fade renders as it was auditioned. Use the named
presets rather than raw values; the two properties are only meaningful together.

## Edits

Non-destructive edits are described here and rendered elsewhere, so a pending edit can be persisted
with the element and survive a relaunch.

| Type | Description |
|------|-------------|
| **`AudioEditDescription`** | The pending edits on a file. Applied in pipeline order: trim, normalize, fade |
| **`FadeDescription`** | In and out times, and the taper each uses |
| **`NormalizeDescription`** / **`NormalizeMode`** / **`NormalizeOptions`** | Target level and how it is measured |

A `nil` description means no edits are queued, and one with all-default values is functionally the
same thing. It is cleared once the edit has been rendered and written.

## Conversion

| Type | Description |
|------|-------------|
| **`AudioFormatConverterOptions`** | Format, sample rate, bit depth and bit rate for a conversion. Any property left `nil` adopts the input file's value; `bitRate` states a stereo rate, halved for mono |
| **`BitDepthRule`** | Whether the converter may go above the source's bit depth |
| **`AudioEditHandling`** | What happens to pending edits during an export |
| **`FileConflictScheme`** | What to do when the destination exists |
| **`MetadataCopyScheme`** | Which metadata categories travel with a conversion |
| **`PasteAttributesOptions`** | Which sections and which individual fields a Paste Attributes transfers |

`PasteAttributesOptions` has section-level flags plus per-section exclusion sets, so a field can be
skipped while its section stays on.

## Scanning and detection

| Type | Description |
|------|-------------|
| **`AudioFileScanner`** | Streams a file in fixed-size chunks with progress, for analysis engines that work incrementally |
| **`AudioSilenceScanner`** | Locates silence boundaries and non-silent regions, with a vDSP peak-magnitude fast path that skips silent chunks without per-frame inspection, so memory stays constant whatever the file length |
| **`SegmentDetector`** / **`SegmentDetectorOptions`** | Non-silent regions as time-ordered trims, with gap bridging, a minimum length and boundary padding |
| **`AudioTools`** | Looping a file that is too short for an analysis window to have enough material |
| **`URLProgressEvent`** | Per-file progress from any of the above |

`AudioFileScanner` can loop short files in memory: when a `minimumDuration` is set and the file is
shorter than half of it, the scanner seeks back to frame 0 rather than ending, giving algorithms
with a minimum input length enough to work with.

## Playback sources

`SeekablePCMSource` extends `spfk-base`'s `SequentialPCMSource` with exactly one thing: a playhead
the user can move. Positions are frames of the processing format counted from the start of the
source.

A conformer holds a position in a file and is emphatically not safe to drive from two places at
once, so it is expected to be `@unchecked Sendable` with that invariant stated. What the conformance
buys is that a player can hand one to a feed `Task` — the alternative being a serial dispatch queue,
which is the GCD this codebase has otherwise removed.

## Audio unit state

`AudioUnitChainState` and `AudioUnitInsert` persist an effects chain — which units, in which order,
with which saved state — so a workspace reopens with the chain it had.

## AVFoundation extensions

| Extension on | What it adds |
|------|-------------|
| **`AVAudioPCMBuffer`** | Duration, RMS, silence check; normalize, reverse, fade, convert and peak; extract a range, loop, append and write |
| **`AVAudioFile`** | Duration, estimated and accurate data rate, conversion to a buffer (whole or capped) or to float channel data |
| **`AVAudioFormat`** | A readable description, bits per channel, bit rate, and PCM format construction |
| **`AVAudioEngine`** | Output format, max frames per slice, and safe attach/detach/connect |
| **`AVAudioNode`** | A resolved name, output-connection check, an ASCII connection diagram, and disconnecting inputs and outputs |
| **`AudioComponentDescription`** | Identity and a stable UID for an audio unit |
| **`AUValue`**, **`AVAudioTime`**, **`TimeInterval`** | dB and linear conversion, host time, normalization |

## Dependencies

| Package | Purpose |
|---------|---------|
| [spfk-base](https://github.com/ryanfrancesconi/spfk-base) | Core utilities, logging, type extensions |
| [spfk-testing](https://github.com/ryanfrancesconi/spfk-testing) | Test audio resources (test target only) |

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
