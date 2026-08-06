//
//  SpikeAlarmActivity.swift
//  SpikeAILiveActivity
//
//  Lock Screen / Dynamic Island presentation for AlarmKit task alarms. The
//  system draws the full-screen alert on top of the Lock Screen and whatever
//  app is in front; this widget supplies the banner form of the same alarm.
//

import ActivityKit
import WidgetKit
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif

#if canImport(AlarmKit)

/// Must stay identical to SpikeAI/SpikeAlarmKit.swift — ActivityKit matches
/// attribute types across the app and this extension by name.
@available(iOS 26.0, *)
struct SpikeAlarmMetadata: AlarmMetadata {
    let taskTitle: String

    init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
}

@available(iOS 26.0, *)
struct SpikeAlarmActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<SpikeAlarmMetadata>.self) { context in
            lockScreenView(taskTitle: context.attributes.metadata?.taskTitle,
                           tint: context.attributes.tintColor)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let tint = context.attributes.tintColor
            let taskTitle = context.attributes.metadata?.taskTitle ?? LALocalization["reminder_title"]

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(LALocalization["reminder_title"])
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(taskTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tint)
            } compactTrailing: {
                Text(LALocalization["reminder_title"])
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tint)
            }
            .keylineTint(tint)
        }
    }

    @ViewBuilder
    private func lockScreenView(taskTitle: String?, tint: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.85), lineWidth: 3)
                    .frame(width: 46, height: 46)
                Image(systemName: "alarm.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(LALocalization["reminder_title"])
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(taskTitle ?? LALocalization["reminder_title"])
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#endif
