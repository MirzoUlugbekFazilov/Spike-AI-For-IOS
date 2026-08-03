//
//  SpikeAILiveActivityControl.swift
//  SpikeAILiveActivity
//
//  Created by Мирзо-Улугбек Фазилов on 24/05/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 18.0, *)
struct SpikeAILiveActivityControl: ControlWidget {
    static let kind: String = "Mirzo-Ulugbek-Fazilov.SpikeAI.FocusStatus"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Focus Status",
                isOn: value.isRunning,
                action: FocusStatusIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "Active" : "Inactive", systemImage: "shield.checkered")
            }
        }
        .displayName("Focus Status")
        .description("Shows the current Spike AI focus status.")
    }
}

@available(iOSApplicationExtension 18.0, *)
extension SpikeAILiveActivityControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: FocusStatusConfiguration) -> Value {
            SpikeAILiveActivityControl.Value(isRunning: false, name: configuration.focusLabel)
        }

        func currentValue(configuration: FocusStatusConfiguration) async throws -> Value {
            SpikeAILiveActivityControl.Value(isRunning: false, name: configuration.focusLabel)
        }
    }
}

@available(iOSApplicationExtension 18.0, *)
struct FocusStatusConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Focus Status Configuration"

    @Parameter(title: "Label", default: "Focus")
    var focusLabel: String
}

@available(iOSApplicationExtension 18.0, *)
struct FocusStatusIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Update focus status"

    @Parameter(title: "Label")
    var name: String

    @Parameter(title: "Focus is active")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
