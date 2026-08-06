//
//  SpikeAILiveActivityBundle.swift
//  SpikeAILiveActivity
//
//  Created by Мирзо-Улугбек Фазилов on 24/05/2026.
//

import WidgetKit
import SwiftUI

@main
struct SpikeAILiveActivityBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        SpikeAILiveActivityLiveActivity()
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            SpikeAlarmActivityWidget()
        }
        #endif
    }
}
