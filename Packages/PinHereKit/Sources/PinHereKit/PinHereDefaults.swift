import Foundation

/// Tuning values from the PRD. Radius and arming distance are starting
/// guesses to be replaced with week-two prototype data.
public enum PinHereDefaults {
    /// Default alert radius, in metres.
    public static let alertRadius: Double = 150
    /// Distance the user must move away before a pin arms, in metres.
    public static let armingDistance: Double = 300
    /// Minimum time between two alerts for the same pin.
    public static let reAlertFloor: TimeInterval = 30 * 60
    /// Above this confident speed an entry is held as a drive-by, in m/s.
    public static let speedHoldThreshold: Double = 4
    /// Delay before re-checking a held entry.
    public static let speedRecheckDelay: TimeInterval = 60
    /// Pins firing within this window are grouped into one alert.
    public static let groupingWindow: TimeInterval = 30
    /// Quiet hours, as hours of the day in the user's time zone.
    public static let quietHoursStart = 22
    public static let quietHoursEnd = 7
    /// System region limit is about 20; two slots are kept in reserve.
    public static let maxActivePinsPerDevice = 18
    /// Free tier limit on active pins.
    public static let freeActivePinLimit = 5
    /// How long the capture confirmation card stays up.
    public static let confirmationCardDuration: TimeInterval = 4
}
