import Foundation

public struct Coordinate: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// The synced lifecycle of a pin. It only ever moves forward, so when two
/// devices disagree the more advanced value wins regardless of timestamps.
/// A Done marked on the watch can never be undone by a stale copy from the phone.
public enum PinLifecycle: Int, Codable, Comparable, Sendable, CaseIterable {
    case active = 0
    case done = 1
    case archived = 2

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A to-do pinned to a place. This is the synced record.
///
/// Arming state (dormant, armed, alerted) and the last alert time are
/// deliberately not here. They cycle backwards ("Not now" returns a pin to
/// dormant), so they cannot obey the forward-only rule, and the watch is the
/// sole detector, so no other device needs to agree on them.
public struct Pin: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var coordinate: Coordinate
    /// Horizontal accuracy of the capture fix, in metres.
    public var captureAccuracy: Double
    /// Alert radius in metres.
    public var radius: Double
    public var note: String?
    public var placeName: String?
    public var lifecycle: PinLifecycle
    /// Last edit to note, place name, coordinate or radius.
    public var contentModifiedAt: Date

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        coordinate: Coordinate,
        captureAccuracy: Double,
        radius: Double = PinHereDefaults.alertRadius,
        note: String? = nil,
        placeName: String? = nil,
        lifecycle: PinLifecycle = .active,
        contentModifiedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.coordinate = coordinate
        self.captureAccuracy = captureAccuracy
        self.radius = radius
        self.note = note
        self.placeName = placeName
        self.lifecycle = lifecycle
        self.contentModifiedAt = contentModifiedAt ?? createdAt
    }
}
