# Pin Here — Product Requirements Document

Oct 12, 2026 · @Vishnu Chandra MC · v2, revised after design review

## Summary

Pin Here pins a to-do to the spot you are standing on, from your wrist, in about a second, and taps your wrist when you come back, even when your phone is at home. The product makes two bets: location reminders fail at capture, so the fastest capture wins; and they fail at delivery when the phone is not there, so the watch must detect the return on its own.

|  | v1 decision |
| --- | --- |
| Platforms | iPhone (iOS 26+) and Apple Watch (watchOS 26+), native Swift and SwiftUI. **Apple Watch required.** |
| Core loop | Tap, walk on. The pin arms when you leave and alerts when you return, from the watch itself |
| Out of scope for v1 | Lists, due dates, projects, sharing, Android, accounts, phone-only mode |
| Data | On device, synced through the user's private iCloud. No server, no account |
| Price | Free for 5 active pins; one-time unlock for unlimited |
| Build estimate | About 10 weeks for one engineer to App Store submission; 11 if the week-two fallback is taken |

The name is the Siri phrase. "Hey Siri, Pin Here" saves a silent pin. "Hey Siri, Pin Here, buy charger cable" saves one with a note. App Store name availability is to be checked before week one.

## How Apple would approach this pitch

A review at Apple Park would spend little time on the feature list and most of it on one question: why does this deserve to exist next to Reminders? The honest answer is that it does not, unless capture is at least five times faster and the alert works where Reminders cannot. Everything in this PRD follows from that.

This section reflects Apple's publicly known product culture (demo over slides, a single accountable owner, privacy as a design input, saying no to most features). It is a framing device, not inside knowledge.

| The question they would ask | Our answer | What it forces in the product |
| --- | --- | --- |
| Who is this for, and what is the one thing it does? | People who notice something to buy or do while on the way elsewhere. It remembers the place for them | One primary action on every screen. No lists, tags or projects in v1 |
| Reminders already has location alerts. Why this? | Reminders takes about six steps and a place search, and its geofences run on the phone. We take one tap, and the watch detects the return with no phone nearby | Capture time and phone-free detection are the headline bets. Anything that adds a step to capture is rejected |
| Show me. Don't tell me | The pitch is a 20-second live demo: raise wrist, tap, walk away, walk back, feel the tap. Phone left on the table | The demo path must be flawless before any secondary feature is started |
| What did you say no to? | Due dates, priorities, sub-tasks, collaboration, Android, a web app, a phone-only mode | A written non-goals list, enforced |
| Why should anyone trust you with Always location? | Location never leaves the device and the user's own iCloud. No account, no analytics on coordinates | No server. Privacy nutrition label reads "Data Not Collected" |
| Does it feel like it belongs on the platform? | System typography, system map, system haptics, Siri, the Action button, Smart Stack | No custom chrome. Platform conventions win over branding |
| Does it work for everyone? | VoiceOver, Dynamic Type, haptic-only alerts, one-handed use | Accessibility is P0, not a later pass |
| What happens when it is wrong? | A false alert costs trust, but a silently missed one costs more. Alert when in doubt, make "Not now" one tap, and never alert the same pin twice within 30 minutes | Alert on unknown speed, a 30-minute floor per pin, and a one-tap "Not now" that re-arms the pin |

The working method is the same as the questions imply: start from the experience and work back to the technology, prototype on the wrist in week one, and cut scope rather than polish.

## Problem and user insight

People forget errands they noticed in passing because the thought arrives at the wrong moment: hands full, walking, on the way to something else. By the time they pass the shop again, the thought is gone.

Existing tools solve the alert and ignore the capture:

- **Apple Reminders** supports "remind me at a location", but needs the app opened, a title typed, the details sheet, and a place search. Nobody does that mid-stride. Its geofences also run on the iPhone, so a walk without the phone gets no alert.
- **Siri** ("remind me when I get here") is the closest alternative. It is unreliable in noisy streets, awkward to say aloud in public, and the resulting reminder is buried in a general list.
- **Photos and notes-to-self** capture fast but never resurface at the right place.

Three insights follow.

1. The place is already known, because the user is standing in it. The app should never ask "where?". It should only ask "what?", and even that is optional.
2. The user is inside the area when they create the pin, so a plain arrival trigger either fires at once or never. The pin has to arm only after the user leaves, then fire on the next return.
3. The device that notices "you are back" must be the one physically on the user. For a wrist-first product that is the watch, not the phone.

## Target users and jobs to be done

The v1 user owns an iPhone and an Apple Watch, runs errands on foot or by two-wheeler or car in a city, and already uses Reminders or a notes app loosely.

| Persona | Situation | Job to be done |
| --- | --- | --- |
| The commuter | Passes the same shops daily, notices things on the way to work | "When I pass this shop on the way home, remind me to pick this up" |
| The household runner | Carries a mental list for the home across several shops | "Don't let me walk past the hardware shop again without buying the bulb" |
| The explorer | Spots a restaurant, shop or sight while travelling or walking | "Remember this place so I come back to it, without stopping now" |

The primary job, in the user's words: "I'm busy now. Remind me of this when I'm back here."

People without an Apple Watch are not served in v1. The product's selling point is detection on the wrist with the phone absent, and a phone-only mode would ship a version that cannot deliver it. The iPhone app still offers capture through the Action button, a Lock Screen control and Siri, as a secondary path for watch owners whose watch is not on the wrist at that moment. A phone-only mode is a candidate for v1.1 and the detector is written so it can be added without rewriting the state machine.

## Goals, non-goals and success metrics

The goal of v1 is to prove one loop: a pin captured in about a second leads to an alert, delivered by the watch alone, that the user acts on.

**Goals**

- Capture a pin from the watch in one tap, with a note as an optional second tap.
- Detect the return on the watch, with no phone nearby, and alert on the wrist without draining the battery.
- Earn Always location permission through a clear, honest explanation.

**Non-goals for v1**

- A general to-do app: no lists, due dates, priorities or sub-tasks.
- Sharing or collaboration.
- Android, web, iPad or Mac.
- A phone-only mode.
- Accounts, a backend, or any analytics that include location.

**Success metrics.** The targets below are proposals to validate in beta, not benchmarks.

| Metric | Definition | Proposed target |
| --- | --- | --- |
| Time to capture, silent | Median seconds from complication tap to success haptic, on watch | 2 s or less |
| Time to capture, with note | Median seconds from complication tap to pin saved with a dictated note | 5 s or less |
| Phone-free detection | Share of on-foot returns, phone absent, that alert while the pin is in sight | 80% or more |
| Alert usefulness | Share of alerts ending in Done or Navigate, not dismissed | 60% or more |
| False alerts | Share of alerts marked "Not now" within 10 s | Under 15% |
| Always permission | Share of onboarded users granting Always location | 55% or more |
| Repeat capture | Share of new users who create a third pin within 14 days | 35% or more |
| Battery | Added daily drain on the watch attributable to the app, five armed pins | Under 5% |
| Paid conversion | Share of users who hit the free limit and unlock | 20% or more of those who hit it |

Usage metrics are counted on device and reported, if at all, as anonymous totals with no coordinates.

## Core experience

The whole product is four moments: capture, arm, alert, resolve. The user is only present for the first and the third.

1. **Capture (watch, about 1 second).** The user taps the complication, or presses the Action button on Apple Watch Ultra, or says "Hey Siri, Pin Here". The app saves the current location immediately and fires the success haptic. A confirmation card shows for about four seconds: the place name on top, an "Add note" button, and two or three recent-note chips beneath. Tapping nothing dismisses the card and the pin is named after the nearest place. Tapping "Add note" opens the system dictation sheet. Tapping a chip uses that note. The watch returns to the face on its own.
2. **Arm (automatic).** The pin stays dormant while the user is still nearby. Once they are more than about 300 m away, it arms. The user never sees this state unless they open the app.
3. **Alert (watch, then phone).** When the watch detects re-entry to the pin's radius and the user is not confidently moving fast, the watch taps the wrist and shows the note, the place name and three actions: Done, Navigate, Not now. The alert is raised by the watch itself; the phone does not need to be present.
4. **Resolve.** Done archives the pin. Navigate opens Apple Maps walking directions to the exact spot. Not now returns the pin to dormant; it re-arms when the user next leaves 300 m and fires on the next return. Ignoring the alert behaves like Not now. A pin never alerts twice within 30 minutes.

**Capture on iPhone** follows the same shape, for a watch owner whose watch is off the wrist: Action button, Lock Screen control, or Siri, then an optional note or photo. The pin syncs to the watch, which detects the return.

**The iPhone app** is a map with the pins on it and a list below, sorted by distance. It exists for review, editing and settings. A user who never opens it should still get full value.

**Edge cases the flow must handle**

| Case | Behaviour |
| --- | --- |
| No note given | Pin is named after the nearest place, for example "Near Croma, Indiranagar"; where no point of interest is close, the street name and a map thumbnail |
| Poor GPS at capture (indoors, mall) | Save anyway, widen the alert radius, show accuracy on the pin |
| User never leaves the area for hours | Pin stays dormant; no alert until they have left and come back |
| Driving past at speed | Hold only on a confident speed reading above about 4 m/s. Unknown speed alerts. One re-check about a minute later; if still fast or no fix, wait for the next re-armed return |
| Shop likely closed (late night) | Entry during quiet hours (default 10 pm to 7 am) is ignored. The pin stays armed and the next entry outside the window fires |
| Several pins in one area | Pins firing within 30 s show one alert: first note in large type, "and 2 more nearby" beneath. Done and Not now act on all; Navigate goes to the nearest; opening the alert shows each pin with its own Done |
| Phone at home | Capture, detection and the alert all happen on the watch. Pins sync to the phone when the two are next together or through iCloud |
| Same pin, repeated passes | Every return alerts, provided the user left 300 m in between and 30 minutes have passed since the last alert |
| Free limit reached on the watch | The pin still saves, with the haptic and "Saved. Unlock on your phone to arm it." It stays dormant until unlocked. The paywall sheet appears on the phone only |

## Functional requirements

P0 is the demo loop and nothing else; a v1 that ships only P0 is still a complete product.

| ID | Requirement | Priority |
| --- | --- | --- |
| C1 | Watch complication and Smart Stack widget that save a pin in one tap, with the success haptic within 300 ms | P0 |
| C2 | Save current location at tap time, before any other input | P0 |
| C3 | Confirmation card for about 4 s with "Add note" (system dictation sheet) and recent-note chips; auto-dismiss saves a silent pin | P0 |
| C4 | Capture and return detection both work on the watch with the phone absent; pins sync later | P0 |
| C5 | Siri phrase "Pin Here" with an optional trailing note, never prompted, on watch and phone | P0 |
| C6 | iPhone capture through the same App Intent: Action button, Lock Screen control, Shortcuts | P1 |
| A1 | Pin arms only after the user has left the 300 m arming radius | P0 |
| A2 | Return detection and the alert run on the watch as a time-sensitive local notification with a distinct haptic | P0 |
| A3 | Alert actions: Done, Navigate, Not now | P0 |
| A4 | Speed gate: alert on unknown speed; hold on a confident reading above about 4 m/s with one re-check | P0 |
| A5 | Re-alert on every return after re-arming, with a 30-minute floor per pin | P0 |
| A6 | Cap of 18 active pins per device; further captures save as dormant | P0 |
| A7 | Monitor only the nearest pins and re-rank using an umbrella region, lifting the 18 cap | P1 (v1.1) |
| M1 | iPhone map and distance-sorted list of active pins; edit note, radius, delete | P0 |
| M2 | Onboarding: When In Use, notifications, watch test pin, demo alert, then Always | P0 |
| M3 | VoiceOver labels, Dynamic Type, and haptic-only alerts throughout | P0 |
| M4 | Watch-required check: onboarding stops with a plain explanation if no watch is paired | P0 |
| S1 | Sync between watch and phone over WatchConnectivity and private iCloud, with idempotent upserts and a forward-only lifecycle | P0 |
| N1 | Auto-name pins from the nearest point of interest, with street-name fallback | P1 |
| N2 | Quiet hours, default 10 pm to 7 am, with per-pin override; entries inside the window are ignored | P1 |
| N3 | Group alerts for pins firing within 30 s, with shared actions and drill-down | P1 |
| N4 | Photo attached to a pin from iPhone capture | P1 |
| N5 | Auto-archive pins untouched for 60 days, with a prompt first | P2 |
| N6 | History of completed pins | P2 |
| N7 | Free limit of 5 active pins and one-time unlock, paywall on the phone only | P1 |

IDs: C capture, A alerting, M management, S sync, N next.

## Design language

The app should feel like something Apple forgot to ship: quiet, native and nearly invisible. The design follows the Human Interface Guidelines' three themes of clarity, deference and depth, and adds four principles of its own.

**Principles**

1. **The wrist is the product.** The iPhone app is the filing cabinet. Design effort goes to the watch first.
2. **One screen, one action.** Each watch screen has a single obvious thing to do. No scrolling during capture.
3. **The map is the interface.** Content is the user's own places. Chrome stays out of the way.
4. **Felt, not read.** The user should know what happened from the haptic alone, without looking.

**Visual system**

| Element | Decision |
| --- | --- |
| Typography | SF Pro on iPhone, SF Compact on watch, system text styles only so Dynamic Type works everywhere |
| Colour | System backgrounds and labels. One accent colour for pins and the primary button, chosen to read on both map styles and to differ from Maps' red and Reminders' blue |
| Iconography | SF Symbols only. One custom glyph: the pin, in three states (dormant outline, armed filled, done checkmark) |
| Materials | The current system materials and controls for sheets and bars over the map; no custom blur or shadow |
| Map | MapKit standard style, muted, with the user's pins as the only strong colour |
| Motion | A pin drops with a short spring on capture. Nothing else animates for decoration. Respect Reduce Motion |
| Dark mode | Default on watch. Full support on iPhone, including the map |

**Watch**

- The tap saves first. The confirmation card is the only capture screen: place name in large type, one "Add note" button, and recent-note chips. No keyboard, no options, no microphone unless asked for.
- "Add note" opens the system dictation sheet. The app does not draw its own transcript; the speech framework needed for that is not available on watchOS.
- The complication shows the count of armed pins nearby, or a plain pin glyph when there are none. In the Smart Stack, the widget rises when the user is near a pin.
- The alert is a short-look notification: note in large type, place name beneath, three actions. A grouped alert adds "and N more nearby" under the first note.

**Haptics**

| Moment | Haptic | Meaning |
| --- | --- | --- |
| Pin saved | Success | "Got it, keep walking" |
| Return alert | A distinct double tap, different from the default notification | "You are back at a pin" |
| Marked done | Light click | "Cleared" |
| Capture failed | Failure | "Look at the screen" |

**iPhone**

- One screen: map on top, a resizable sheet with the list below, in the manner of Maps and Find My.
- A single floating "Pin here" button. Long-press on the map drops a pin elsewhere.
- A pin's detail is a small sheet: note, place, photo, radius slider, Done and Delete.
- Settings live in a single short sheet. Target: fewer than eight controls.

**Voice and copy**

- Plain, short, second person. "Pinned. I'll tap you when you're back."
- Alerts lead with the user's own words, not the app's name: "Buy charger cable" then "Near Croma".
- Never scold. A snoozed pin says "Next time", not "Overdue".

## Ease-of-use concerns

The biggest usability risk is not the interface; it is trust. One alert at the wrong time, or one missed return, and the user goes back to forgetting.

| Concern | Why it matters | Mitigation |
| --- | --- | --- |
| Capture takes too long | The user is walking. Past about five seconds they give up | Location saved on tap. Silent pin is the default. Note is an opt-in second tap |
| Speaking aloud in public | Many people will not dictate on a street | Silent capture is the primary path. Recent-note chips cover repeat errands without speech |
| Dictation errors | A wrong transcript makes the alert meaningless | Keep the audio clip with the pin for 24 hours as a fallback; show the place name always |
| "Did it save?" | No confidence means no habit | Success haptic plus checkmark within 300 ms of the tap |
| Alerts at the wrong moment | Driving past, shop closed, in a hurry | Speed gate on confident readings only, quiet hours, one-tap "Not now" that never nags |
| Too many alerts | Dense areas with several pins | Grouping within 30 s, and a 30-minute floor per pin |
| Missed alerts | Watch geofences can be late by a minute or a few hundred metres | Alert on unknown speed, larger default radius (150 m), and a Smart Stack widget as a passive second channel |
| Permission wall | Always location is a scary ask on first launch | Ask for When In Use first, let the user feel a demo alert, then ask for Always with a one-line reason |
| Stale pins pile up | An old list makes every alert feel like noise | Auto-archive prompt at 60 days. Done is always one tap |
| Complication not installed | Without it, capture is slow and the product fails quietly | Onboarding ends with a guided "add to watch face" step and a test pin |
| Indoor and mall accuracy | GPS drifts indoors; the pin lands in the wrong place | Show accuracy, snap to the nearest named place, let the user nudge the pin on the phone |
| Learning curve | Any tutorial is a failure of the design | No tutorial. The test pin and demo alert teach the whole loop in under a minute |
| No watch paired | The product cannot deliver its promise | Onboarding stops at a plain screen saying the app needs an Apple Watch. The store page says so first |

**Accessibility**

- Every action is reachable by VoiceOver with meaningful labels, including pin state.
- Alerts are complete through haptics and speech alone.
- All text uses Dynamic Type; watch layouts are tested at the largest size.
- Colour is never the only signal for pin state; the glyph shape changes too.
- Double tap on supported watches triggers the primary action (Done) on an alert.

## Privacy and permissions

The app collects nothing: pins, notes and photos stay on the user's devices and in their private iCloud database, and the developer has no server to send them to. This is both the right design and the strongest marketing line the product has.

Permissions are asked in this order. The first two come before the test pin because the demo alert cannot show without them.

| Step | Permission | Where | Why, in the user's terms |
| --- | --- | --- | --- |
| 1 | Location, When In Use | Phone, during onboarding | "To save where you're standing" |
| 2 | Notifications, including time-sensitive | Phone, immediately after | "So the reminder reaches your wrist" |
| 3 | Test pin from the watch, then a demo alert about 10 s later | Watch | "This is what a return feels like" |
| 4 | Location, Always | Phone, right after the demo alert | "To tap you when you're back, even with the app closed and your phone at home" |
| 5 | Microphone and speech | First "Add note" | "To turn what you say into the note" |
| 6 | Camera | First photo, iPhone only | "To attach a photo to this pin" |

The watch inherits location authorization from the phone app, so the Always ask stays on the phone, but its wording names the watch.

**Commitments**

- No account, no sign-in, no third-party SDKs.
- No analytics containing coordinates, place names or note text.
- Speech recognition runs on device where the language supports it.
- The app works in a reduced mode with When In Use only: pins show on the map and in the widget, but there are no background alerts. The app says so plainly instead of nagging.
- App Store privacy label target: Data Not Collected.

**App Review.** Always location draws scrutiny. The purpose strings, the onboarding screen and the review notes must all state the same single reason: alerting on return to a saved place.

## Technical approach and platform constraints

The app is fully native Swift and SwiftUI with no backend. **The watch owns capture, return detection and the alert. The phone owns the data.** Cross-platform frameworks do not target watchOS, and almost all the work here is platform APIs, so they add cost without benefit.

| Area | Approach |
| --- | --- |
| Capture entry points | App Intents, exposed to the complication, Smart Stack widget, Action button, Lock Screen control, Siri and Shortcuts from one definition. The Siri phrase is the app name with an optional note parameter |
| Watch location | One-shot location request on the watch at tap time; save coordinates with their accuracy |
| Dictation | System dictation sheet on watch; on-device speech recognition on iPhone where available |
| Storage and sync | SwiftData with a private CloudKit database on both devices. WatchConnectivity as the fast path when both are reachable. Each pin has a stable id and a modified timestamp; every incoming record is an upsert. Note, radius and photo: newer timestamp wins. The synced lifecycle (active, done, archived) only moves forward, so the more advanced value wins regardless of timestamp. Arming state (dormant, armed, alerted) and the last alert time are not synced: they cycle backwards on "Not now" and only the watch, as sole detector, needs them. No conflict UI |
| Geofencing | Core Location condition monitoring on the watch, with circular regions around armed pins. The same detector module is compiled for iOS so a phone detector can be added later without a rewrite |
| The 20-region limit | v1 caps active pins at 18 per device. Nearest-N re-ranking with an umbrella region is v1.1 |
| Arming | A pin starts dormant. An exit event, or distance beyond about 300 m, arms it. "Not now" returns it to dormant |
| Speed gate | On an entry event, read the current speed. Unknown or below about 4 m/s: alert. Confidently above: hold, request one more fix about 60 s later through a short background session, alert if that fix is slow or unknown, otherwise wait for the next re-armed return |
| Re-alert floor | A pin does not alert again within 30 minutes of its last alert |
| Alerts | Local notifications on the watch at time-sensitive level with a custom category and actions |
| Place naming | Reverse geocoding plus a nearby point-of-interest search at capture time; street-name fallback when no point of interest is close |
| Maps hand-off | Open Apple Maps with the pin's coordinates and walking directions |

**Constraints to design around**

- Geofence events are not instant. Entry can lag by a minute or more and is accurate to roughly 100 m or worse, so the product promise is "near", never "at the door".
- Background execution on the watch after a region event is brief and less generous than on the phone. The speed check and notification must finish within it. Nothing in the design depends on a timed background wake.
- Speed is often absent from the first fix after an entry event. Treating unknown as slow is deliberate.
- The custom live-transcript capture screen is not buildable on watchOS; the system dictation sheet is the only option, and the app does not control its timing.
- If the user force-quits the app, region monitoring still relaunches it, but the user may revoke Always location at any time. The app must detect and explain the reduced mode.
- Battery: region monitoring is low-power. Continuous GPS is never used in the background.

## High-ROI feature additions

Four additions cost days, not weeks, and each removes a reason the core loop fails; they belong in v1 as P1. Category pins and shared pins are larger bets that could justify a subscription later, but they are not the product's defence against Apple; phone-free detection is.

| Feature | What it does | Why it pays back | When |
| --- | --- | --- | --- |
| Recent-note quick picks | Offers the last few notes as chips on the capture card | The no-speech path for repeat errands like "milk"; part of the P0 capture card | v1 |
| Auto-name pins from nearest place | Labels a pin "Near Croma" when no note is given | Makes silent, one-tap capture useful, which is how most people will capture in public | v1 |
| Quiet hours | Ignores entries at night so the next daytime return alerts | Removes the most common useless alert | v1 |
| Photo on a pin | Snap the product or shopfront from the iPhone | A photo beats a mis-heard transcript, and suits travellers | v1 |
| Smart Stack relevance | The widget surfaces itself on the watch when a pin is near | A passive second channel when the geofence is late | v1.1 |
| Nearest-N re-ranking | Lifts the 18 active pin cap | Only matters to heavy users; needs real-world watch background data first | v1.1 |
| Auto-archive stale pins | Prompts to clear pins untouched for 60 days | Keeps alerts meaningful with almost no build cost | v1.1 |
| Phone-only mode | Phone detects for users without a watch | Opens the larger iPhone audience once the watch loop is proven | v1.1 candidate |
| Category pins | "Next time I'm near any pharmacy" | Turns one pin into many chances to complete it | v1.2 |
| Shared pins | Send a pin to a partner; whoever passes first gets the tap | The only built-in growth loop | v1.2 |
| Heading-home trip mode | Alerts only on the return leg of a trip | Matches the original use case closely, but needs route inference | Later |
| Completed history | A list of done pins | Mild satisfaction, little effect on retention | Later |
| CarPlay | Capture and alerts in the car | Small audience and a separate review process | Later, if ever |

## Monetisation and pricing

v1 is free for five active pins with a one-time unlock for unlimited saved pins. A subscription is not justified until there is an ongoing cost or a shared feature to pay for.

| Tier | Price | Includes |
| --- | --- | --- |
| Free | 0 | 5 active pins, all capture methods, alerts, sync |
| Unlimited (one-time) | About $4.99 in the US, regionally priced lower in India | Unlimited saved pins (up to 18 armed at once in v1), photos, per-pin radius and quiet hours |
| Plus (later, optional) | About $10 to $15 a year | Shared pins and category reminders, once those ship |

**Why this shape**

- Five free pins get a user through a typical week before the wall. Completing a pin frees a slot, so light users are never blocked.
- The wall never appears on the wrist. A sixth capture on the watch still saves, with the haptic and "Saved. Unlock on your phone to arm it." The pin stays dormant until unlocked. The purchase sheet lives on the phone.
- One-time pricing matches a utility used a few times a month, and "no subscription" earns goodwill and word of mouth.
- Running costs are close to zero: the developer programme fee is the only fixed cost.

**Expectation.** A typical indie launch at this price earns hundreds of dollars a year, good traction a few thousand, and an App Store feature tens of thousands. These are assumptions, not data. Distribution, not pricing, decides which row applies.

## Milestones and launch plan

The plan is about 10 weeks for one engineer, and each phase ends at a gate that can stop the project cheaply. The week-two gate is a written go/no-go on the product's anchor.

1. **Weeks 1 to 2: wrist prototype.** Complication, silent capture, watch-side geofence, alert, with no UI polish. Nothing on the phone beyond sync. Gate: all four numbers below, measured on a watch with the phone left at home, on foot in a dense street.

   | Measure | Pass |
   | --- | --- |
   | Return detection | 8 of 10 returns or more alert while the pin is in sight |
   | Alert latency | Median under 90 s from crossing the 150 m boundary |
   | Silent capture | Median under 2 s from complication tap to haptic |
   | Battery | Under 5% extra watch drain per day with 5 armed pins |

   Fail detection or latency: adopt the fallback that day. The phone detects and the watch displays, phone-free delivery moves to v1.1, the positioning reverts to the capture-only line, and one week is added, making 11. Fail only battery: tune the arming radius and monitored-pin count, not the architecture. Also in week one: capture 20 silent pins around Bengaluru and count useful place names; fewer than half means the street-name fallback is P0.

2. **Weeks 3 to 5: P0 build.** Arming, speed gate, re-alert floor, 18-pin cap, iPhone map and list, sync, onboarding with the demo alert, watch-required check. Gate: one week of personal daily use with no missed returns and no more than one false alert.
3. **Weeks 6 to 7: P1 and design pass.** Place naming, quiet hours, grouping, photos, haptics, accessibility audit. Gate: VoiceOver walkthrough passes end to end.
4. **Weeks 8 to 9: TestFlight beta.** 30 to 50 testers, every one with an Apple Watch, in Bengaluru and one English-speaking city abroad. Gate: alert usefulness at 60% or more, false alerts under 15%, phone-free detection at 80% or more.
5. **Week 10: App Store submission.** Purchase flow, store page, review notes for Always location.

**Launch**

- Worldwide availability, English-only interface, regional pricing.
- The store page leads with a 15-second video of the wrist loop with the phone visibly left on a table, not screenshots of a map. "Requires Apple Watch" appears above the fold.
- Positioning line: "Pin a to-do to where you're standing. Get a tap when you're back, even without your phone."
- Channels: Apple Watch and indie-app communities, a Product Hunt launch, and a submission to Apple's editorial team for watch-first apps.
- The first update ships within three weeks of launch, driven by beta feedback, to signal an active app.

## Risks and open questions

The largest risk is that the watch cannot detect returns reliably on its own. The second is that Apple adds a one-tap "remind me when I'm back here" action to Reminders.

| Risk | Likelihood | Impact | Response |
| --- | --- | --- | --- |
| Watch-side detection is late or silent too often | Medium | High | The four-number gate at week two, with the phone-detects fallback decided that day |
| Apple ships the same capture shortcut | Medium | High | The moat is wrist-native detection with no phone, plus capture speed. Reminders' geofences run on the phone and that is unlikely to change for a minor feature. If the fallback is taken, this risk is uncovered and is written down as such |
| Geofence delay makes alerts feel unreliable | Medium | High | Alert on unknown speed, larger radius, widget as second channel, honest "near" framing |
| Low Always-permission grant rate | Medium | High | Deferred ask after the demo alert; useful reduced mode |
| App Review rejects the Always location use | Low | High | Single clear purpose, consistent strings, demo video in review notes |
| Users capture once and never return | High | Medium | Demo alert in onboarding, five free pins, Smart Stack presence |
| Discovery: nobody finds the app | High | High | Watch-first positioning for editorial features; the demo video as the main asset |
| Watch-required shrinks the audience | High | Medium | Accepted for v1. Phone-only mode is a v1.1 candidate once the loop is proven |
| Point-of-interest data is thin in Indian cities | Medium | Medium | Week-one count; street-name fallback and recent-note chips carry silent pins |
| Dictation quality in Indian languages and mixed speech | Medium | Low | Silent capture is the default; audio fallback, photo capture |

**Decided since v1 of this document**

- Name: Pin Here. Siri phrase is the name.
- Watch required; watch is the sole detector; phone owns data.
- Silent-first capture with an opt-in note.
- Every return alerts after re-arming, 30-minute floor per pin.
- Alert on unknown speed.
- 18 active pins per device; re-ranking deferred.
- Free limit 5, paywall on the phone only.
- iOS 26 and watchOS 26 minimum.
- Worldwide English launch, two-city beta.
- Quiet hours default 10 pm to 7 am, entries ignored, pin stays armed.

**Open questions**

- [ ] Default radius: 150 m is a starting guess; set it from week-two data.
- [ ] Arming distance: 300 m is a starting guess; set it from week-two data.
- [ ] App Store availability of the name "Pin Here".
- [ ] Whether the watch's inherited location authorization is sufficient for background detection on every supported model, or the watch app must request it separately.
