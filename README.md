# Pin Here

Pin a to-do to where you're standing. Get a tap when you're back, even without your phone.
Product requirements: [docs/Pin Here — Product Requirements Document.md](docs/Pin%20Here%20—%20Product%20Requirements%20Document.md)

## Layout

| Path | What it is |
| --- | --- |
| `project.yml` | XcodeGen spec. The `.xcodeproj` is generated and not committed |
| `Config/Base.xcconfig` | Bundle ID prefix, app group, iCloud container, deployment targets |
| `App/iOS` | iPhone app: data owner, map and list, settings |
| `App/Watch` | Watch app: capture, return detection, alerts |
| `App/WatchWidget` | Complication and Smart Stack widget |
| `Packages/PinHereKit` | Platform-neutral core: pin model, sync merge, detector. Tests run on the Mac |

## First-time setup

```sh
brew install xcodegen
echo 'DEVELOPMENT_TEAM = YOURTEAMID' > Config/Local.xcconfig
xcodegen
open PinHere.xcodeproj
```

Run the core tests without Xcode:

```sh
cd Packages/PinHereKit && swift test
```

Re-run `xcodegen` after adding or removing files, or after editing `project.yml`.

## Identifiers

Register these in the Apple Developer portal under your team.

| Kind | Identifier |
| --- | --- |
| iPhone app | `com.vishnuchandramc.pinhere` |
| Watch app | `com.vishnuchandramc.pinhere.watchkitapp` |
| Watch widget | `com.vishnuchandramc.pinhere.watchkitapp.widget` |
| App group | `group.com.vishnuchandramc.pinhere` |
| iCloud container | `iCloud.com.vishnuchandramc.pinhere` |

Capabilities: iCloud with CloudKit, Push Notifications, App Groups, Time Sensitive Notifications.
