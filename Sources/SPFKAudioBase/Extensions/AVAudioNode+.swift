// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio

import AVFoundation
import SPFKBase
import SPFKBaseC

extension AVAudioNode: @retroactive TypeDescribable {
    private func error(function: String, string: String) -> NSError {
        Log.printCallStack()

        return NSError(description: "\(typeName).\(function) Error: \(string)")
    }

    public var resolvedName: String {
        auAudioUnit.audioUnitName ??
            auAudioUnit.audioUnitShortName ??
            description
    }

    public var ioConnectionDescription: String {
        let name = auAudioUnit.audioUnitName ?? typeName

        guard let engine else {
            return "\(name) <engine is nil> → 🔇"
        }

        let inputPoint = engine.inputConnectionPoint(for: self, inputBus: 0)
        let outputPoints = engine.outputConnectionPoints(for: self, outputBus: 0)

        let icon = outputPoints.count > 0 ? "→" : "🔇"
        let inputConnected = inputPoint != nil ? "✓ Input" : "No Input"
        var out = name + " (\(inputConnected), \(outputPoints.count) out\(outputPoints.pluralString)) \(icon) "

        for point in outputPoints {
            if let node = point.node {
                if node == engine.outputNode {
                    out += "🔊" // made it to the engine output
                    break
                } else {
                    out += node.ioConnectionDescription
                }
            }
        }

        return out
    }

    public var isOutputNodeConnected: Bool {
        guard let engine else { return false }
        let points = engine.outputConnectionPoints(for: self, outputBus: 0)
        return points.isNotEmpty
    }
}

extension AVAudioNode {
    /// Convenience to disconnect via the engine if it's non nil
    public func disconnectOutput() throws {
        guard let engine else {
            throw error(function: #function, string: "engine is nil")
        }

        try ExceptionTrap.withThrowing { [engine] in
            engine.disconnectNodeOutput(self)
        }
    }

    /// Convenience to disconnect via the engine if it's non nil
    public func disconnectInput() throws {
        guard let engine else {
            throw error(function: #function, string: "engine is nil")
        }

        try ExceptionTrap.withThrowing { [engine] in
            engine.disconnectNodeInput(self)
        }
    }

    public func detach() throws {
        guard let engine else {
            throw error(function: #function, string: "engine is nil")
        }

        try ExceptionTrap.withThrowing { [engine] in
            engine.detach(self)
        }
    }

    /// Disconnect without breaking other connections.
    public func disconnect(input: AVAudioNode) async throws {
        guard let engine else {
            throw error(function: #function, string: "engine is nil")
        }

        var newConnections: [AVAudioNode: [AVAudioConnectionPoint]] = [:]

        for bus in 0 ..< numberOfInputs {
            if let cp = engine.inputConnectionPoint(for: self, inputBus: bus) {
                if cp.node === input {
                    let points = engine.outputConnectionPoints(for: input, outputBus: 0)
                    newConnections[input] = points.filter { $0.node != self }
                }
            }
        }

        for (node, connections) in newConnections {
            if connections.isEmpty {
                engine.disconnectNodeOutput(node)

            } else {
                await engine.connect(node, to: connections, fromBus: 0, format: AudioDefaults.shared.systemFormat)
            }
        }
    }

    /// Make a connection without breaking other connections.
    public func connect(input: AVAudioNode, bus: Int, format: AVAudioFormat? = nil) throws {
        guard let engine else {
            throw error(function: #function, string: "engine is nil")
        }

        let format = format ?? engine.outputFormat

        var points = engine.outputConnectionPoints(for: input, outputBus: 0)

        if points.contains(where: {
            $0.node === self && $0.bus == bus
        }) {
            return
        }

        points.append(AVAudioConnectionPoint(node: self, bus: bus))
        engine.connect(input, to: points, fromBus: 0, format: format)
    }
}
