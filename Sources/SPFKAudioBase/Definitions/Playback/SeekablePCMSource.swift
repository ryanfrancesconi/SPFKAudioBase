// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFAudio
import AVFoundation

/// A decoded-PCM source whose read position can be moved, for audio `AVAudioFile` cannot open.
///
/// Refines ``WaveformPCMSource``, which is sequential on purpose — a waveform scan reads front to
/// back and never revisits a chunk, and staying sequential is what lets a conforming type stream a
/// feature-length film without its audio existing in memory at once. Playback wants the same
/// samples and exactly one thing more: a playhead the user can move.
///
/// Positions are frames of ``WaveformPCMSource/processingFormat`` counted from the start of the
/// source — the same space ``WaveformPCMSource/totalFrameCount`` is expressed in.
/// **`Sendable` on the same terms `MatroskaSampleBufferReader` is**: a conformer holds a position in
/// a file and is emphatically not safe to drive from two places at once, so it is expected to be
/// `@unchecked Sendable` with that invariant stated. What the conformance buys is that a player can
/// hand one to a feed `Task` — the alternative being a serial dispatch queue, which is the GCD this
/// codebase has otherwise removed.
public protocol SeekablePCMSource: WaveformPCMSource, Sendable {
    /// The frame the next read will start at.
    var framePosition: AVAudioFramePosition { get }

    /// Repositions so the next read starts at `frame`.
    ///
    /// **Landing exactly is the contract.** A compressed source generally cannot begin decoding at
    /// an arbitrary sample — it restarts at whatever boundary its container indexes — so a
    /// conforming type is expected to decode from the boundary at or before `frame` and discard the
    /// difference, rather than reporting that boundary as the new position. A caller scrubbing a
    /// waveform has no way to compensate for a position that is only approximately where it asked.
    func seek(toFrame frame: AVAudioFramePosition) throws
}
