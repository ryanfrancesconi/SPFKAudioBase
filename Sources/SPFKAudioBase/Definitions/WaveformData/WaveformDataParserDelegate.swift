// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

public protocol WaveformDataParserDelegate: AnyObject, Sendable {
    func waveformDataParser(event: WaveformDataLoadEvent) async
}
