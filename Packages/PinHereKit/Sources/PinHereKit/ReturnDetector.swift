import Foundation

// MARK: - State

/// Where a pin is in its arm-and-alert cycle. Unlike `PinLifecycle` this moves
/// backwards ("Not now" returns to dormant), so it is never synced. It lives
/// only on the device that detects returns: the watch.
public enum ArmingState: String, Codable, Hashable, Sendable {
    /// The user is still near the pin, or chose "Not now". Waiting for them to leave.
    case dormant
    /// The user has left. The next return alerts.
    case armed
    /// The user entered fast. Waiting for one speed re-check before deciding.
    case holding
    /// An alert is showing and the user has not resolved it.
    case alerted
}

public struct DetectorPinState: Codable, Hashable, Sendable {
    public var arming: ArmingState
    public var lastAlertAt: Date?

    public init(arming: ArmingState = .dormant, lastAlertAt: Date? = nil) {
        self.arming = arming
        self.lastAlertAt = lastAlertAt
    }

    /// A freshly captured pin. The user is standing in it, so it starts dormant.
    public static let new = DetectorPinState()
}

// MARK: - Inputs and outputs

/// A location reading taken for the speed re-check.
public struct LocationFix: Hashable, Sendable {
    /// Distance from the pin's centre, in metres.
    public var distance: Double
    /// Speed in metres per second. `nil` or negative means unknown.
    public var speed: Double?

    public init(distance: Double, speed: Double?) {
        self.distance = distance
        self.speed = speed
    }
}

public enum AlertResponse: String, Hashable, Sendable {
    case done, navigate, notNow
}

public enum DetectorEvent: Hashable, Sendable {
    /// The system reported leaving the arming region.
    case exitedArmingRegion
    /// A location update placed the user this far from the pin.
    case distanceUpdated(metres: Double)
    /// The system reported entering the alert region, with the speed if known.
    case enteredAlertRegion(speed: Double?)
    /// The scheduled speed re-check ran. `nil` means no fix arrived in time.
    case speedRechecked(LocationFix?)
    /// The user acted on the alert.
    case responded(AlertResponse)
}

public enum DetectorEffect: Hashable, Sendable {
    /// Deliver the return alert for this pin.
    case alert
    /// Ask for one more fix after this delay and report it as `speedRechecked`.
    case scheduleSpeedRecheck(after: TimeInterval)
    /// Move the synced pin's lifecycle to done.
    case markDone
}

/// The one region the platform layer should monitor for a pin right now.
public struct MonitoredRegion: Hashable, Sendable {
    public enum Trigger: Hashable, Sendable { case entry, exit }

    public var center: Coordinate
    public var radius: Double
    public var trigger: Trigger
}

// MARK: - Quiet hours

/// A daily window, in local hours, during which return alerts are not delivered.
/// Wraps past midnight when `startHour > endHour`. Equal hours mean no window.
public struct QuietHours: Hashable, Sendable, Codable {
    public var startHour: Int
    public var endHour: Int

    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }

    public static let `default` = QuietHours(
        startHour: PinHereDefaults.quietHoursStart,
        endHour: PinHereDefaults.quietHoursEnd
    )

    public func contains(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        if startHour == endHour { return false }
        if startHour < endHour { return hour >= startHour && hour < endHour }
        return hour >= startHour || hour < endHour
    }
}

// MARK: - Detector

/// Decides when a pin arms and when it alerts. Pure: no CoreLocation, no clock,
/// no I/O. The platform layer feeds it events and carries out its effects.
///
/// Each pin uses one monitored region at a time. While dormant or alerted it
/// watches for an exit at the arming distance; while armed or holding it
/// watches for an entry at the pin's alert radius.
public struct ReturnDetector: Sendable {
    public var calendar: Calendar
    public var quietHours: QuietHours
    public var armingDistance: Double
    public var reAlertFloor: TimeInterval
    public var speedHoldThreshold: Double
    public var speedRecheckDelay: TimeInterval

    public init(
        calendar: Calendar = .autoupdatingCurrent,
        quietHours: QuietHours = .default,
        armingDistance: Double = PinHereDefaults.armingDistance,
        reAlertFloor: TimeInterval = PinHereDefaults.reAlertFloor,
        speedHoldThreshold: Double = PinHereDefaults.speedHoldThreshold,
        speedRecheckDelay: TimeInterval = PinHereDefaults.speedRecheckDelay
    ) {
        self.calendar = calendar
        self.quietHours = quietHours
        self.armingDistance = armingDistance
        self.reAlertFloor = reAlertFloor
        self.speedHoldThreshold = speedHoldThreshold
        self.speedRecheckDelay = speedRecheckDelay
    }

    public func region(for pin: Pin, state: DetectorPinState) -> MonitoredRegion? {
        guard pin.lifecycle == .active else { return nil }
        switch state.arming {
        case .dormant, .alerted:
            return MonitoredRegion(center: pin.coordinate, radius: armingDistance, trigger: .exit)
        case .armed, .holding:
            return MonitoredRegion(center: pin.coordinate, radius: pin.radius, trigger: .entry)
        }
    }

    public func handle(
        _ event: DetectorEvent,
        pin: Pin,
        state: DetectorPinState,
        now: Date
    ) -> (state: DetectorPinState, effects: [DetectorEffect]) {
        guard pin.lifecycle == .active else { return (state, []) }
        var next = state

        switch (event, state.arming) {
        // Leaving arms a dormant pin, and re-arms one whose alert was ignored.
        case (.exitedArmingRegion, .dormant), (.exitedArmingRegion, .alerted):
            next.arming = .armed
            return (next, [])

        case (.distanceUpdated(let metres), .dormant), (.distanceUpdated(let metres), .alerted):
            if metres > armingDistance { next.arming = .armed }
            return (next, [])

        case (.enteredAlertRegion(let speed), .armed):
            if isConfidentlyFast(speed) {
                next.arming = .holding
                return (next, [.scheduleSpeedRecheck(after: speedRecheckDelay)])
            }
            return deliverIfAllowed(from: next, now: now)

        case (.speedRechecked(let fix), .holding):
            guard let fix, fix.distance <= pin.radius, !isConfidentlyFast(fix.speed) else {
                // Still fast, gone, or no fix: a drive-by. Wait for the next re-armed return.
                next.arming = .dormant
                return (next, [])
            }
            next.arming = .armed
            return deliverIfAllowed(from: next, now: now)

        case (.responded(.done), .alerted):
            return (next, [.markDone])

        case (.responded(.notNow), .alerted):
            next.arming = .dormant
            return (next, [])

        default:
            // Navigate keeps the alert open; everything else is out of sequence.
            return (state, [])
        }
    }

    /// Alerts unless quiet hours or the re-alert floor apply. Either way the
    /// pin stays armed so a later entry can still fire.
    private func deliverIfAllowed(
        from state: DetectorPinState,
        now: Date
    ) -> (state: DetectorPinState, effects: [DetectorEffect]) {
        var next = state
        next.arming = .armed
        if quietHours.contains(now, calendar: calendar) { return (next, []) }
        if let last = state.lastAlertAt, now.timeIntervalSince(last) < reAlertFloor { return (next, []) }
        next.arming = .alerted
        next.lastAlertAt = now
        return (next, [.alert])
    }

    /// Unknown speed (nil or negative, as CoreLocation reports it) counts as slow.
    private func isConfidentlyFast(_ speed: Double?) -> Bool {
        guard let speed, speed >= 0 else { return false }
        return speed > speedHoldThreshold
    }

    /// The pins that get a monitored region: active pins, oldest first, up to the
    /// free limit or the per-device cap. Later captures stay unmonitored until a
    /// slot frees up.
    public static func monitoredPins(_ pins: some Sequence<Pin>, unlocked: Bool) -> [Pin] {
        let limit = unlocked ? PinHereDefaults.maxActivePinsPerDevice : PinHereDefaults.freeActivePinLimit
        return pins
            .filter { $0.lifecycle == .active }
            .sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
            .prefix(limit)
            .map { $0 }
    }
}
