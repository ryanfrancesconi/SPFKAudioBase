
@testable import SPFKAudioBase
import Testing

@Suite("NoteName Tests")
struct NoteNameTests {
    @Test("Initialize with standard key names")
    func standardInitialization() {
        #expect(NoteName(string: "C") == .c)
        #expect(NoteName(string: "F#") == .fSharp)
        #expect(NoteName(string: "A") == .a)
    }

    @Test("Initialize with enharmonic names", arguments: [
        ("Db", NoteName.cSharp),
        ("Eb", .dSharp),
        ("Gb", .fSharp),
        ("Ab", .gSharp),
        ("Bb", .aSharp)
    ])
    func enharmonicInitialization(input: String, expected: NoteName) {
        #expect(NoteName(string: input) == expected)
    }

    @Test("Initialization is case-insensitive")
    func caseInsensitivity() {
        #expect(NoteName(string: "c#") == .cSharp)
        #expect(NoteName(string: "gb") == .fSharp)
    }

    @Test("Invalid strings return nil")
    func invalidStrings() {
        #expect(NoteName(string: "H") == nil)
        #expect(NoteName(string: "123") == nil)
    }

    // MARK: - Properties

    @Test("Description returns correct string")
    func descriptions() {
        #expect(NoteName.cSharp.description == "C#")
        #expect(NoteName.b.description == "B")
    }

    @Test("Enharmonic property returns correct flat name")
    func enharmonics() {
        #expect(NoteName.cSharp.enharmonic == "Db")
        #expect(NoteName.a.enharmonic == "A") // Natural stays same
    }
}
