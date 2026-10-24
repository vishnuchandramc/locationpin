import Foundation
import Testing
@testable import PinHereKit

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func pin(
    id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
    note: String? = nil,
    lifecycle: PinLifecycle = .active,
    modified: Date = t0
) -> Pin {
    Pin(
        id: id,
        createdAt: t0,
        coordinate: Coordinate(latitude: 12.9716, longitude: 77.6412),
        captureAccuracy: 20,
        note: note,
        lifecycle: lifecycle,
        contentModifiedAt: modified
    )
}

@Suite("Pin merge")
struct PinMergeTests {
    @Test func newerContentWins() throws {
        let old = pin(note: "buy bulb", modified: t0)
        let new = pin(note: "buy two bulbs", modified: t0.addingTimeInterval(60))
        #expect(try Pin.merge(old, new).note == "buy two bulbs")
        #expect(try Pin.merge(new, old).note == "buy two bulbs")
    }

    @Test func doneFromWatchSurvivesStaleEditFromPhone() throws {
        // Watch marks Done offline; phone edits the note later.
        let watch = pin(note: "milk", lifecycle: .done, modified: t0)
        let phone = pin(note: "oat milk", lifecycle: .active, modified: t0.addingTimeInterval(120))
        let merged = try Pin.merge(watch, phone)
        #expect(merged.lifecycle == .done)
        #expect(merged.note == "oat milk")
    }

    @Test(arguments: PinLifecycle.allCases, PinLifecycle.allCases)
    func lifecycleNeverMovesBackward(a: PinLifecycle, b: PinLifecycle) throws {
        let merged = try Pin.merge(pin(lifecycle: a), pin(lifecycle: b, modified: t0.addingTimeInterval(1)))
        #expect(merged.lifecycle == max(a, b))
    }

    @Test func mergeIsIdempotent() throws {
        let p = pin(note: "charger", lifecycle: .done)
        #expect(try Pin.merge(p, p) == p)
    }

    @Test func equalTimestampsConvergeOnBothDevices() throws {
        let a = pin(note: "apples")
        let b = pin(note: "pears")
        #expect(try Pin.merge(a, b) == Pin.merge(b, a))
    }

    @Test func refusesToMergeDifferentPins() {
        let other = pin(id: UUID())
        #expect(throws: PinMergeError.differentPins) {
            try Pin.merge(pin(), other)
        }
    }
}
