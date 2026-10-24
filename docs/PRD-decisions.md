# Pin Here — PRD decisions from grilling session (12 Oct 2026)

Amendments to "Location Todo — Product Requirements Document". Each item overrides the PRD where they conflict.

## Name and positioning
- Name: **Pin Here**. Siri phrase is the name itself: "Hey Siri, Pin Here" (silent pin) or "Hey Siri, Pin Here, buy charger cable". Siri never prompts for a note. Check App Store name collisions before week one.
- Positioning: "Pin a to-do to where you're standing. Get a tap when you're back, even without your phone."
- Response to the "Apple copies it" risk: the moat is wrist-native detection plus capture speed, not feature count. Category and shared pins are "nice later", not defensibility.

## Architecture
- Capture speed and delivery reliability are co-equal P0 bets.
- **Phone-free delivery is an anchor.** The watch is the sole return detector. The phone remains the data owner and never runs geofences in v1.
- **Apple Watch is required for v1.** No phone-only mode. Onboarding stops with a clear message if no watch is paired; the store page says "Requires Apple Watch". iPhone capture entry points (Action button, Lock Screen control, Siri) stay, as a secondary path for watch owners, and feed the watch via sync.
- Detector is still written as one platform-neutral module so a phone detector can be added in a later version without rewriting the state machine.
- Fallback if watch detection fails the week-two gate: "phone detects, watch displays" (this is the one case where a phone detector is built in v1); phone-free moves to v1.1; positioning reverts to the PRD line and the Apple risk is recorded as uncovered.
- Active pin cap: 18 per device. A5 (nearest-N re-ranking via umbrella region) moves to P1 / v1.1. Paid tier = unlimited saved pins, up to 18 armed.
- Minimum OS: iOS 26, watchOS 26.

## State machine
- States: dormant → armed → alerted → done / archived. Status only moves forward.
- Arm: leave ~300 m. Alert: enter 150 m radius (default, tune from prototype).
- Re-alert: every return. "Not now" or ignore → dormant; must re-arm by leaving 300 m. 30-minute floor between alerts for the same pin.
- Speed gate: **unknown speed = alert.** Hold only on a confident reading above ~4 m/s. One retry ~60 s later; if still fast or no fix, treat as drive-by and wait for the next re-armed return.
- Quiet hours (P1): default 10 pm–7 am. Entry during quiet hours is ignored, pin stays armed, nothing is scheduled; next entry event outside the window fires.
- Grouping (P1): pins firing within a 30 s window show one alert ("<note> … and 2 more nearby"). Done / Not now act on all; Navigate goes to the nearest; opening the alert shows per-pin rows.

## Capture
- **Silent-first.** Complication tap saves the pin immediately, success haptic, then a ~4 s confirmation card: place name, "Add note" button, 2–3 recent-note chips. No action → silent pin named after nearest place. "Add note" → system dictation sheet. (The PRD's custom live-transcript screen is not buildable on watchOS; C3's 4 s silence timeout is replaced by the card auto-dismiss.)

## Sync
- Both channels: WatchConnectivity (fast path) and private CloudKit via SwiftData (catch-up, phone replacement).
- Stable pin id + modified timestamp. All incoming records are idempotent upserts. Note/radius/photo: newest timestamp wins. Lifecycle (active → done → archived): most advanced wins regardless of timestamp. No conflict UI.
- Correction (24 Oct): arming state (dormant/armed/alerted) is not part of the forward-only rule, because "Not now" moves it backwards. It is detector-local on the watch and never synced.

## Onboarding and permissions (in order)
1. When In Use location (phone): "to save where you're standing"
2. Notifications incl. time-sensitive (phone): "so the reminder reaches your wrist"
3. Test pin from the watch → **demo alert ~10 s later**, same haptic/layout/actions, labelled "This is what a return feels like"; test pin deleted after
4. Always location (phone): "to tap you when you're back, even with the app closed and your phone at home"
5. Microphone/speech on first Add note; camera on first photo

## Pricing
- Free: **5 active pins.** Sixth capture on the watch still saves (haptic + "Saved. Unlock on your phone to arm it.") and stays dormant. Paywall sheet appears on the phone only, never on the watch.
- One-time unlock ~$4.99 US, regional pricing in India.

## Markets
- Worldwide, English-only UI. Beta in Bengaluru plus one English-speaking city abroad; every tester must own an Apple Watch.
- Week-one check: 20 silent pins around Bengaluru; if fewer than half get a useful POI name, auto-name falls back to street name + map thumbnail and recent-note chips carry silent pins.

## Week-two go/no-go gate (watch only, phone at home, on foot, dense street)
| Measure | Pass |
| --- | --- |
| Return detection | ≥ 8 of 10 returns alert while pin is in sight |
| Alert latency | median < 90 s from crossing the 150 m boundary |
| Silent capture | median < 2 s from complication tap to haptic |
| Battery | < 5 % extra watch drain per day with 5 armed pins |

Fail detection or latency → adopt fallback that day, +1 week (11 total). Fail battery only → tune radius / monitored-pin count.

## Open items still outstanding
- Default radius (150 m) and arming distance (300 m): set from week-two data.
- App Store name availability for "Pin Here".
