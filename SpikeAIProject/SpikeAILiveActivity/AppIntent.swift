//
//  AppIntent.swift
//  SpikeAILiveActivity
//
//  Created by Мирзо-Улугбек Фазилов on 24/05/2026.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Daily Goals" }
    static var description: IntentDescription { "Shows Spike AI focus progress and daily goals." }

    @Parameter(title: "Label", default: "Focus")
    var label: String
}
