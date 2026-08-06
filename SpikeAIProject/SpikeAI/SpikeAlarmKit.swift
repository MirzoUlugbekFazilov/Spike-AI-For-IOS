//
//  SpikeAlarmKit.swift
//  Spike AI
//
//  AlarmKit bridge. On iOS 26+ a task alarm is handed to the system so it
//  presents a full-screen alert over the Lock Screen and over whatever app is
//  in front, ringing until the user taps Stop. Older systems fall back to the
//  chained notification burst + in-app overlay in ContentView.swift.
//

import Foundation
import CryptoKit
#if canImport(AlarmKit)
import AlarmKit
import ActivityKit
import SwiftUI
#endif

#if canImport(AlarmKit)
/// Payload carried alongside the system alarm so the Live Activity
/// presentation in the widget extension can show which task is ringing.
/// Duplicated verbatim in SpikeAILiveActivity/SpikeAlarmActivity.swift —
/// keep the two definitions in sync.
@available(iOS 26.0, *)
struct SpikeAlarmMetadata: AlarmMetadata {
    let taskTitle: String

    init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
}
#endif

/// Bundled alarm tone. Also used as the notification sound on the legacy path.
let spikeAlarmSoundFileName = "AlarmTone.wav"

@MainActor
enum SpikeAlarmScheduler {

    /// True when the system can own the alarm end to end (Lock Screen alert,
    /// rings through silent mode and Focus, stops only on user action).
    static var isSupported: Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    /// Task ids come from Supabase as UUID strings; anything else is folded
    /// into a stable UUID so the same task always maps to the same alarm.
    static func alarmID(for taskId: String) -> UUID {
        if let uuid = UUID(uuidString: taskId) { return uuid }
        let digest = Array(Insecure.MD5.hash(data: Data(taskId.utf8)))
        return digest.withUnsafeBufferPointer { buffer in
            NSUUID(uuidBytes: buffer.baseAddress) as UUID
        }
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            let state = try? await manager.requestAuthorization()
            return state == .authorized
        @unknown default:
            return false
        }
        #else
        return false
        #endif
    }

    /// Schedules the system alarm. Returns false when AlarmKit is unavailable
    /// or the user declined it — the caller then arms the legacy fallback.
    static func schedule(taskId: String, title: String, at date: Date) async -> Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        guard await requestAuthorization() else {
            print("[Spike AI] ⚠️ AlarmKit not authorized — falling back to notifications")
            return false
        }

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: title))
        } else {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: title),
                stopButton: AlarmButton(
                    text: LocalizedStringResource(stringLiteral: AppLocalization.string("alarm_stop")),
                    textColor: .white,
                    systemImageName: "stop.fill"
                )
            )
        }

        // No countdown and no paused presentation: the alarm has no timer of
        // its own, it just rings from `date` until the user stops it.
        let attributes = AlarmAttributes<SpikeAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: SpikeAlarmMetadata(taskTitle: title),
            tintColor: .orange
        )

        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            sound: .named(spikeAlarmSoundFileName)
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: alarmID(for: taskId), configuration: configuration)
            print("[Spike AI] ✅ AlarmKit alarm scheduled for \(date)")
            return true
        } catch {
            print("[Spike AI] ❌ AlarmKit scheduling FAILED: \(error.localizedDescription)")
            return false
        }
        #else
        return false
        #endif
    }

    /// Silences an alarm that is currently ringing.
    static func stop(taskId: String) {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        try? AlarmManager.shared.stop(id: alarmID(for: taskId))
        #endif
    }

    /// Removes an alarm that has not fired yet.
    static func cancel(taskId: String) {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        let manager = AlarmManager.shared
        let id = alarmID(for: taskId)
        try? manager.stop(id: id)
        try? manager.cancel(id: id)
        #endif
    }

    /// Ids of system alarms that are still live (scheduled or ringing), or nil
    /// when AlarmKit cannot be queried — callers must not read nil as "none
    /// left" or they would mark every pending alarm as already stopped.
    static func liveAlarmIDs() -> Set<UUID>? {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return nil }
        let manager = AlarmManager.shared
        guard manager.authorizationState == .authorized,
              let alarms = try? manager.alarms else { return nil }
        return Set(alarms.map(\.id))
        #else
        return nil
        #endif
    }
}
