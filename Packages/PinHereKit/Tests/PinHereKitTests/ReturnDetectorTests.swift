import Foundation
import Testing
@testable import PinHereKit

// Bengaluru, so quiet hours are tested in a real local time zone.
private let calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Kolkata")!
    return c
}()

/// 24 Oct 2026 at the given local hour and minute in Bengaluru.
private func at(_ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: hour, minute: minute))!
}

private let detector = ReturnDetector(calendar: calendar)

private func makePin(lifecycle: PinLifecycle = .active, radius: Double = 150) -> Pin {
    Pin(
        createdAt: at(9),
        coordinate: Coordinate(latitude: 12.9716, longitude: 77.6412),
        captureAccuracy: 15,
        radius: radius,
        note: "buy charger cable",
        lifecycle: lifecycle
    )
}

private func run(
    _ events: [(DetectorEvent, Date)],
    pin: Pin = makePin(),
    from state: DetectorPinState = .new
) -> (state: DetectorPinState, effects: [DetectorEffect]) {
    var state = state
    var effects: [DetectorEffect] = []
    for (event, date) in events {
        let step = detector.handle(event, pin: pin, state: state, now: date)
        state = step.state
        effects += step.effects
    }
    return (state, effects)
}

@Suite("Arming")
struct ArmingTests {
    @Test func newPinIsDormantAndWatchesForLeaving() {
        let pin = makePin()
        #expect(DetectorPinState.new.arming == .dormant)
        #expect(detector.region(for: pin, state: .new) == .init(center: pin.coordinate, radius: 300, trigger: .exit))
    }

    @Test func entryWhileDormantNeverAlerts() {
        let result = run([(.enteredAlertRegion(speed: 1), at(10))])
        #expect(result.state.arming == .dormant)
        #expect(result.effects.isEmpty)
    }

    @Test func leavingTheArmingRegionArmsAndSwitchesToEntry() {
        let pin = makePin(radius: 200)
        let result = run([(.exitedArmingRegion, at(10))], pin: pin)
        #expect(result.state.arming == .armed)
        #expect(detector.region(for: pin, state: result.state) == .init(center: pin.coordinate, radius: 200, trigger: .entry))
    }

    @Test(arguments: [(299.0, ArmingState.dormant), (301.0, ArmingState.armed)])
    func distanceUpdateArmsBeyondArmingDistance(distance: Double, expected: ArmingState) {
        #expect(run([(.distanceUpdated(metres: distance), at(10))]).state.arming == expected)
    }
}

@Suite("Alerting")
struct AlertingTests {
    @Test func walkingBackAlerts() {
        let result = run([
            (.exitedArmingRegion, at(10)),
            (.enteredAlertRegion(speed: 1.3), at(18)),
        ])
        #expect(result.state.arming == .alerted)
        #expect(result.state.lastAlertAt == at(18))
        #expect(result.effects == [.alert])
    }

    @Test func unknownSpeedAlerts() {
        let result = run([(.exitedArmingRegion, at(10)), (.enteredAlertRegion(speed: nil), at(18))])
        #expect(result.effects == [.alert])
    }

    @Test func negativeSpeedIsTreatedAsUnknown() {
        // CoreLocation reports -1 when speed is invalid.
        let result = run([(.exitedArmingRegion, at(10)), (.enteredAlertRegion(speed: -1), at(18))])
        #expect(result.effects == [.alert])
    }

    @Test func exactlyAtThresholdStillAlerts() {
        let result = run([(.exitedArmingRegion, at(10)), (.enteredAlertRegion(speed: 4), at(18))])
        #expect(result.effects == [.alert])
    }

    @Test func doneAndArchivedPinsAreNotMonitoredAndNeverAlert() {
        for lifecycle in [PinLifecycle.done, .archived] {
            let pin = makePin(lifecycle: lifecycle)
            let armed = DetectorPinState(arming: .armed)
            #expect(detector.region(for: pin, state: armed) == nil)
            #expect(run([(.enteredAlertRegion(speed: 1), at(18))], pin: pin, from: armed).effects.isEmpty)
        }
    }
}

@Suite("Speed gate")
struct SpeedGateTests {
    private let enteredFast: [(DetectorEvent, Date)] = [
        (.exitedArmingRegion, at(10)),
        (.enteredAlertRegion(speed: 12), at(18)),
    ]

    @Test func confidentHighSpeedHoldsAndSchedulesOneRecheck() {
        let result = run(enteredFast)
        #expect(result.state.arming == .holding)
        #expect(result.effects == [.scheduleSpeedRecheck(after: 60)])
    }

    @Test func holdingKeepsWatchingTheAlertRegion() {
        let pin = makePin()
        let result = run(enteredFast, pin: pin)
        #expect(detector.region(for: pin, state: result.state)?.trigger == .entry)
    }

    @Test(arguments: [1.0, nil])
    func slowOrUnknownOnRecheckInsideRadiusAlerts(speed: Double?) {
        let result = run(enteredFast + [(.speedRechecked(.init(distance: 80, speed: speed)), at(18, 1))])
        #expect(result.state.arming == .alerted)
        #expect(result.effects.last == .alert)
    }

    @Test func stillFastOnRecheckIsADriveBy() {
        let result = run(enteredFast + [(.speedRechecked(.init(distance: 80, speed: 9)), at(18, 1))])
        #expect(result.state.arming == .dormant)
        #expect(result.effects == [.scheduleSpeedRecheck(after: 60)])
    }

    @Test func noFixOnRecheckIsADriveBy() {
        let result = run(enteredFast + [(.speedRechecked(nil), at(18, 1))])
        #expect(result.state.arming == .dormant)
    }

    @Test func slowButAlreadyOutsideRadiusIsADriveBy() {
        let result = run(enteredFast + [(.speedRechecked(.init(distance: 400, speed: 0.5)), at(18, 1))])
        #expect(result.state.arming == .dormant)
    }

    @Test func recheckWhenNotHoldingIsIgnored() {
        let result = run([(.speedRechecked(.init(distance: 10, speed: 1)), at(18))])
        #expect(result.state.arming == .dormant)
        #expect(result.effects.isEmpty)
    }
}

@Suite("Resolving and re-alerting")
struct ResolveTests {
    private let alerted: [(DetectorEvent, Date)] = [
        (.exitedArmingRegion, at(10)),
        (.enteredAlertRegion(speed: 1), at(18)),
    ]

    @Test func doneMarksThePinDone() {
        let result = run(alerted + [(.responded(.done), at(18, 1))])
        #expect(result.effects == [.alert, .markDone])
    }

    @Test func notNowReturnsToDormantAndMustReArm() {
        let result = run(alerted + [
            (.responded(.notNow), at(18, 1)),
            (.enteredAlertRegion(speed: 1), at(18, 50)),
        ])
        #expect(result.state.arming == .dormant)
        #expect(result.effects == [.alert])
    }

    @Test func navigateLeavesThePinWaitingForAResponse() {
        let result = run(alerted + [(.responded(.navigate), at(18, 1))])
        #expect(result.state.arming == .alerted)
    }

    @Test func leavingAfterAnIgnoredAlertReArms() {
        // An ignored alert behaves like Not now; leaving 300 m arms it again.
        let pin = makePin()
        let alertedState = run(alerted, pin: pin).state
        #expect(detector.region(for: pin, state: alertedState)?.trigger == .exit)
        let result = run([(.exitedArmingRegion, at(18, 20))], pin: pin, from: alertedState)
        #expect(result.state.arming == .armed)
    }

    @Test func everyReturnAlertsOnceTheFloorHasPassed() {
        let result = run(alerted + [
            (.responded(.notNow), at(18, 1)),
            (.exitedArmingRegion, at(18, 10)),
            (.enteredAlertRegion(speed: 1), at(18, 31)),
        ])
        #expect(result.effects == [.alert, .alert])
        #expect(result.state.lastAlertAt == at(18, 31))
    }

    @Test func returnInsideThirtyMinutesIsSuppressedButStaysArmed() {
        let result = run(alerted + [
            (.responded(.notNow), at(18, 1)),
            (.exitedArmingRegion, at(18, 10)),
            (.enteredAlertRegion(speed: 1), at(18, 29)),
        ])
        #expect(result.effects == [.alert])
        #expect(result.state.arming == .armed)
    }
}

@Suite("Quiet hours")
struct QuietHoursTests {
    @Test(arguments: [(22, 0), (23, 30), (0, 0), (6, 59)])
    func entryDuringQuietHoursIsIgnoredAndStaysArmed(hour: Int, minute: Int) {
        let armed = DetectorPinState(arming: .armed)
        let result = run([(.enteredAlertRegion(speed: 1), at(hour, minute))], from: armed)
        #expect(result.state.arming == .armed)
        #expect(result.effects.isEmpty)
    }

    @Test(arguments: [(7, 0), (21, 59), (12, 0)])
    func entryOutsideQuietHoursAlerts(hour: Int, minute: Int) {
        let armed = DetectorPinState(arming: .armed)
        #expect(run([(.enteredAlertRegion(speed: 1), at(hour, minute))], from: armed).effects == [.alert])
    }

    @Test func heldEntryRecheckedDuringQuietHoursIsIgnored() {
        let result = run([
            (.exitedArmingRegion, at(20)),
            (.enteredAlertRegion(speed: 10), at(21, 59)),
            (.speedRechecked(.init(distance: 50, speed: 1)), at(22, 0)),
        ])
        #expect(result.state.arming == .armed)
        #expect(!result.effects.contains(.alert))
    }

    @Test func daytimeWindowWithoutWrapWorks() {
        let quiet = QuietHours(startHour: 13, endHour: 15)
        #expect(quiet.contains(at(14), calendar: calendar))
        #expect(!quiet.contains(at(15), calendar: calendar))
        #expect(!quiet.contains(at(12, 59), calendar: calendar))
    }

    @Test func equalStartAndEndMeansNoQuietHours() {
        #expect(!QuietHours(startHour: 22, endHour: 22).contains(at(22), calendar: calendar))
    }
}

@Suite("Which pins are monitored")
struct MonitoringSelectionTests {
    private func pins(_ count: Int) -> [Pin] {
        (0..<count).map { i in
            Pin(createdAt: at(9).addingTimeInterval(Double(i)), coordinate: .init(latitude: 12.97, longitude: 77.64), captureAccuracy: 10)
        }
    }

    @Test func freeTierMonitorsTheOldestFiveActivePins() {
        let all = pins(7)
        let chosen = ReturnDetector.monitoredPins(all, unlocked: false)
        #expect(chosen.map(\.id) == all.prefix(5).map(\.id))
    }

    @Test func unlockedMonitorsUpToEighteen() {
        let all = pins(25)
        #expect(ReturnDetector.monitoredPins(all, unlocked: true).count == 18)
    }

    @Test func completedPinsFreeASlot() {
        var all = pins(6)
        all[0].lifecycle = .done
        let chosen = ReturnDetector.monitoredPins(all, unlocked: false)
        #expect(chosen.map(\.id) == all.dropFirst().map(\.id))
    }

    @Test func orderIsByCreationNotInputOrder() {
        let all = pins(6)
        let chosen = ReturnDetector.monitoredPins(all.reversed(), unlocked: false)
        #expect(chosen.map(\.id) == all.prefix(5).map(\.id))
    }
}
