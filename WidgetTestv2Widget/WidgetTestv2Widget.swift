//
//  WidgetTestv2Widget.swift
//  WidgetTestv2Widget
//
//  Created by Chris Golding on 10/12/23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀", count: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀", count: 1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let count = UserDefaults.standard.integer(forKey: "value")
            let entry = SimpleEntry(date: entryDate, emoji: "😀", count: count)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let count: Int
}

struct WidgetTestv2WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Text("Time:")
                Text(entry.date, style: .time)
            }
//
//            Text("Emoji:")
//            Text(entry.emoji)
            
            Button("Tap Me", intent: DoSomethingIntent())
            Text("Count :\(entry.count)")
        }
    }
}

struct WidgetTestv2Widget: Widget {
    let kind: String = "WidgetTestv2Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                WidgetTestv2WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetTestv2WidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    WidgetTestv2Widget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀", count: 1)
    SimpleEntry(date: .now, emoji: "🤩", count: 2)
}
