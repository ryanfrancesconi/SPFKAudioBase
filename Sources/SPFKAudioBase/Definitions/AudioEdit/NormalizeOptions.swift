// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Parameters for a normalization analysis pass.
///
/// Produced by `NormalizeDialog` and consumed by `NormalizeAnalyzer`. Not stored
/// per-file — only the resulting `NormalizeDescription.gain` is persisted on
/// `PlaylistElement.audioEditDescription.normalize`.
public struct NormalizeOptions: Codable, Sendable {
    public var mode: NormalizeMode

    // LUFS mode
    public var targetLUFS: Float
    public var ceilingEnabled: Bool
    public var ceilingdBTP: Float

    // Peak mode
    public var targetPeakdBFS: Float

    // Common
    public var maximumGainEnabled: Bool
    public var maximumGaindB: Float

    public init(
        mode: NormalizeMode = .lufs,
        targetLUFS: Float = -14.0,
        ceilingEnabled: Bool = true,
        ceilingdBTP: Float = -1.0,
        targetPeakdBFS: Float = -0.1,
        maximumGainEnabled: Bool = true,
        maximumGaindB: Float = 20.0
    ) {
        self.mode = mode
        self.targetLUFS = targetLUFS
        self.ceilingEnabled = ceilingEnabled
        self.ceilingdBTP = ceilingdBTP
        self.targetPeakdBFS = targetPeakdBFS
        self.maximumGainEnabled = maximumGainEnabled
        self.maximumGaindB = maximumGaindB
    }
}

// MARK: - Codable

extension NormalizeOptions {
    private enum CodingKeys: String, CodingKey {
        case mode, targetLUFS, ceilingEnabled, ceilingdBTP
        case targetPeakdBFS, maximumGainEnabled, maximumGaindB
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decodeIfPresent(NormalizeMode.self, forKey: .mode) ?? .lufs
        targetLUFS = try c.decodeIfPresent(Float.self, forKey: .targetLUFS) ?? -14.0
        ceilingEnabled = try c.decodeIfPresent(Bool.self, forKey: .ceilingEnabled) ?? true
        ceilingdBTP = try c.decodeIfPresent(Float.self, forKey: .ceilingdBTP) ?? -1.0
        targetPeakdBFS = try c.decodeIfPresent(Float.self, forKey: .targetPeakdBFS) ?? -0.1
        maximumGainEnabled = try c.decodeIfPresent(Bool.self, forKey: .maximumGainEnabled) ?? true
        maximumGaindB = try c.decodeIfPresent(Float.self, forKey: .maximumGaindB) ?? 20.0
    }
}
