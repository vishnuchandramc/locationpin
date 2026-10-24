import SwiftUI
import WidgetKit

struct ArmedPinsEntry: TimelineEntry {
    let date: Date
    let armedNearby: Int
}

struct ArmedPinsProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArmedPinsEntry {
        ArmedPinsEntry(date: .now, armedNearby: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ArmedPinsEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArmedPinsEntry>) -> Void) {
        completion(Timeline(entries: [placeholder(in: context)], policy: .never))
    }
}

/// Shows the count of armed pins nearby, or a plain pin glyph when there are none.
struct ComplicationView: View {
    let entry: ArmedPinsEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.armedNearby > 0 {
                Text("\(entry.armedNearby)").font(.title2.bold())
            } else {
                Image(systemName: "mappin")
                    .font(.title2)
            }
        }
        .accessibilityLabel(entry.armedNearby > 0 ? "\(entry.armedNearby) pins nearby" : "Pin here")
        .widgetURL(URL(string: "pinhere://capture"))
    }
}

@main
struct PinHereComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinHereComplication", provider: ArmedPinsProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pin Here")
        .description("Pin a to-do to where you're standing.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular])
    }
}
