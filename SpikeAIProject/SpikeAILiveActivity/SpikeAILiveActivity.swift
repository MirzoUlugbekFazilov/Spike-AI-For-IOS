//
//  SpikeAILiveActivity.swift
//  SpikeAILiveActivity
//
//  Created by Мирзо-Улугбек Фазилов on 24/05/2026.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        Timeline(entries: [SimpleEntry(date: Date(), configuration: configuration)], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct SpikeAILiveActivityEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spike AI")
                .font(.headline)
            Text(entry.configuration.label)
                .font(.subheadline.weight(.semibold))
            Text(LALocalization["open_app_review"])
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

struct SpikeAILiveActivity: Widget {
    let kind: String = "SpikeAILiveActivity"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SpikeAILiveActivityEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var focus: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.label = "Focus"
        return intent
    }

    fileprivate static var goals: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.label = "Daily Goals"
        return intent
    }
}

#Preview(as: .systemSmall) {
    SpikeAILiveActivity()
} timeline: {
    SimpleEntry(date: .now, configuration: .focus)
    SimpleEntry(date: .now, configuration: .goals)
}
