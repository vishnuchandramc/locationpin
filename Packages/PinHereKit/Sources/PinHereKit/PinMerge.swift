import Foundation

public enum PinMergeError: Error, Equatable {
    case differentPins
}

extension Pin {
    /// Merges two copies of the same pin that arrived over different channels
    /// (WatchConnectivity and iCloud). Idempotent, commutative and associative,
    /// so delivery order and duplicates never matter.
    ///
    /// - Content (note, place, coordinate, radius): newer `contentModifiedAt` wins.
    /// - Lifecycle: the more advanced value wins, regardless of timestamps.
    public static func merge(_ a: Pin, _ b: Pin) throws(PinMergeError) -> Pin {
        guard a.id == b.id else { throw .differentPins }
        var result = contentWinner(a, b)
        result.lifecycle = max(a.lifecycle, b.lifecycle)
        return result
    }

    /// Picks the copy with newer content. Ties are broken deterministically so
    /// every device converges on the same result.
    private static func contentWinner(_ a: Pin, _ b: Pin) -> Pin {
        if a.contentModifiedAt != b.contentModifiedAt {
            return a.contentModifiedAt > b.contentModifiedAt ? a : b
        }
        return a.tieBreakKey >= b.tieBreakKey ? a : b
    }

    private var tieBreakKey: String {
        [note ?? "", placeName ?? "", "\(radius)", "\(coordinate.latitude)", "\(coordinate.longitude)", "\(captureAccuracy)"]
            .joined(separator: "\u{1F}")
    }
}
