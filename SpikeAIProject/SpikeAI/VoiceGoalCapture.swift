//
//  VoiceGoalCapture.swift
//  Spike AI
//
//  Speak your goals: tap the mic on Home, say what you plan to do — including
//  times and priorities — and Spike AI turns it into short scheduled goals.
//
//  Flow:  connectivity check
//      -> listening (live transcript, silence auto-stop, final-result wait)
//      -> parsing   (Hugging Face via the parse-voice-goals edge function)
//      -> review    (editable drafts, one tap to save)
//
//  Two deliberate choices:
//   • The feature requires internet, so it says so up front instead of quietly
//     degrading. Apple's server-based recognition is materially more accurate
//     than the on-device model, and the parsing step is a network call anyway.
//   • The model never does calendar math. It returns a relative day offset and
//     a wall-clock time; this file resolves both against the user's calendar.
//

import AVFoundation
import Network
import Speech
import Supabase
import SwiftUI
import UIKit
import UserNotifications

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Draft Model
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// One goal the user spoke, resolved into concrete dates and editable in the
/// review step before anything is written to Supabase.
struct VoiceGoalDraft: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var priority: TaskPriority
    /// Day the goal is scheduled for (time components stripped).
    var day: Date
    /// Full date + time for the reminder, or nil when the user named no time.
    var reminder: Date?
    /// User asked to be reminded about this goal.
    var wantsNotification: Bool = false
    /// User asked for a ringing alarm rather than a quiet notification.
    var wantsAlarm: Bool = false
    var isSelected: Bool = true

    /// A reminder the system can no longer fire.
    var reminderIsInPast: Bool {
        guard let reminder else { return false }
        return reminder <= Date().addingTimeInterval(60)
    }

    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: day)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Edge Function Payloads
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct VoiceGoalParseRequest: Encodable {
    let transcript: String
    let today: String
    let nowTime: String
    let language: String

    enum CodingKeys: String, CodingKey {
        case transcript, today, language
        case nowTime = "now_time"
    }
}

private struct VoiceGoalParseResponse: Decodable {
    let goals: [RawGoal]
    let summary: String?
    let fallback: Bool?
    /// Why the server fell back to its heuristic parser. Diagnostic only.
    let fallbackReason: String?

    enum CodingKeys: String, CodingKey {
        case goals, summary, fallback
        case fallbackReason = "fallback_reason"
    }

    struct RawGoal: Decodable {
        let title: String
        let priority: String?
        let dayOffset: Int?
        let time: String?
        let notify: Bool?
        let alarm: Bool?

        enum CodingKeys: String, CodingKey {
            case title, priority, time, notify, alarm
            case dayOffset = "day_offset"
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Reachability
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// One-shot connectivity probe. `NWPathMonitor` delivers the current path as
/// soon as it starts, so this settles immediately in practice; the timeout only
/// guards against it never firing at all.
enum VoiceReachability {
    private final class OnceBox: @unchecked Sendable {
        private let lock = NSLock()
        private var claimed = false
        func claim() -> Bool {
            lock.lock(); defer { lock.unlock() }
            if claimed { return false }
            claimed = true
            return true
        }
    }

    static func isOnline() async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { await probe() }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return true // Optimistic: let the network call surface the real error.
            }
            let first = await group.next() ?? true
            group.cancelAll()
            return first
        }
    }

    private static func probe() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let once = OnceBox()
            monitor.pathUpdateHandler = { path in
                guard once.claim() else { return }
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: DispatchQueue(label: "com.spikeai.voice.reachability"))
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Capture Model
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor @Observable
final class VoiceGoalCaptureModel {

    enum Phase: Equatable {
        case preparing
        case listening
        case parsing
        case review
        case offline
        case denied(Permission)
        /// Recording failed — retry means record again.
        case recordingFailed(String)
        /// Parsing failed — retry means re-send the transcript we already have.
        case parseFailed(String)
    }

    enum Permission: Equatable {
        case microphone
        case speech
    }

    // ── Tuning ───────────────────────────────────────────────────────────
    /// Silence after real speech that ends the recording. Long enough that a
    /// mid-sentence pause to think doesn't cut the user off.
    private let silenceWindow: TimeInterval = 2.5
    /// Give up if the user never says anything.
    private let emptyTimeout: TimeInterval = 15
    /// Hard ceiling on a single recording.
    private let maxDuration: TimeInterval = 120
    /// How long to wait for the recogniser's higher-accuracy final pass.
    private let finalResultTimeout: TimeInterval = 3.0

    // ── Observable state ─────────────────────────────────────────────────
    private(set) var phase: Phase = .preparing
    private(set) var transcript = ""
    private(set) var summary = ""
    /// Smoothed mic level, 0...1, drives the orb animation.
    private(set) var level: CGFloat = 0
    private(set) var usedFallbackParser = false
    var drafts: [VoiceGoalDraft] = []

    // ── Audio plumbing ───────────────────────────────────────────────────
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var watchdog: Task<Void, Never>?
    private var startedAt = Date()
    private var lastVoiceAt = Date()
    private var isFinishing = false
    private var hasFinalResult = false
    /// Kept so a failed parse can be retried without re-recording.
    private var lastTranscript = ""
    private var language = "en"

    var selectedCount: Int { drafts.filter(\.isSelected).count }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Lifecycle
    // ─────────────────────────────────────────────────────────────────────

    /// Checks connectivity and permissions, then starts listening.
    func start(language: String) async {
        reset()
        self.language = language
        phase = .preparing

        // This feature needs the network for both recognition and parsing, so
        // say so before taking over the microphone.
        guard await VoiceReachability.isOnline() else {
            phase = .offline
            return
        }
        guard await ensureSpeechPermission() else {
            phase = .denied(.speech)
            return
        }
        guard await ensureMicrophonePermission() else {
            phase = .denied(.microphone)
            return
        }

        do {
            try beginRecording()
            phase = .listening
            startedAt = Date()
            lastVoiceAt = Date()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            startWatchdog()
        } catch {
            print("[Spike AI] ❌ Recording failed to start: \(error)")
            teardownAudio()
            releaseRecognition()
            phase = .recordingFailed(AppLocalization.string("voice_error_mic"))
        }
    }

    /// Returns the engine to a clean, tapless, stopped state.
    private func teardownAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.reset()
        level = 0
    }

    /// User tapped Done, or silence was detected.
    func finishListening() {
        guard phase == .listening, !isFinishing else { return }
        isFinishing = true
        watchdog?.cancel()
        watchdog = nil

        // Stop feeding audio but keep the task alive: the recogniser's final
        // pass is more accurate than the partials shown while speaking.
        stopAudioInput()
        phase = .parsing
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            await waitForFinalTranscript()
            releaseRecognition()

            let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            isFinishing = false

            guard !spoken.isEmpty else {
                phase = .recordingFailed(AppLocalization.string("voice_error_nothing_heard"))
                return
            }

            lastTranscript = spoken
            await runParse()
        }
    }

    /// Retry after a parse failure — reuses the transcript, no re-recording.
    func retryParse() async {
        guard !lastTranscript.isEmpty else { return }
        await runParse()
    }

    /// Stops everything and returns to a clean slate.
    func cancel() {
        watchdog?.cancel()
        watchdog = nil
        stopAudioInput()
        releaseRecognition()
        reset()
    }

    private func reset() {
        phase = .preparing
        transcript = ""
        summary = ""
        level = 0
        drafts = []
        usedFallbackParser = false
        isFinishing = false
        hasFinalResult = false
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Permissions
    // ─────────────────────────────────────────────────────────────────────

    private func ensureSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default: return false
        }
    }

    private func ensureMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Recording
    // ─────────────────────────────────────────────────────────────────────

    private func beginRecording() throws {
        guard let speechRecognizer = Self.makeRecognizer(language: language) else {
            throw NSError(domain: "SpikeVoice", code: 1)
        }
        speechRecognizer.defaultTaskHint = .dictation
        recognizer = speechRecognizer

        // `.measurement` deliberately disables the system's input processing
        // chain — the right call when you are measuring a signal, the wrong one
        // when a person is dictating across a room. `.default` keeps automatic
        // gain control and noise reduction on, which is the real accuracy win
        // for quiet, accented or far-field speech.
        //
        // Deliberately NOT using the voice-processing I/O unit
        // (`setVoiceProcessingEnabled`): it needs an output path for echo
        // cancellation, so under a `.record`-only session the engine fails to
        // start and the whole feature dies with "the microphone couldn't start".
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        // Always use Apple's server model: it is markedly more accurate than the
        // on-device model, especially for accented and non-English speech, and
        // this feature already requires a connection.
        request.requiresOnDeviceRecognition = false
        // Bias the language model toward the vocabulary this screen actually
        // hears — scheduling words and priority words are exactly the tokens the
        // parser depends on, and the ones most often misheard.
        request.contextualStrings = Self.contextualStrings(for: language)
        recognitionRequest = request

        // A failed attempt leaves a running engine and an installed tap behind.
        // Clearing them here is what makes "Try again" a real retry instead of
        // a second run into the same wall.
        teardownAudio()

        let inputNode = audioEngine.inputNode

        // Ask the hardware directly. `outputFormat(forBus:)` can report a zero
        // format until the engine is running, which would fail the check below
        // for a microphone that is in fact fine.
        var format = inputNode.inputFormat(forBus: 0)
        if format.sampleRate <= 0 || format.channelCount <= 0 {
            format = inputNode.outputFormat(forBus: 0)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("[Spike AI] ❌ Mic reported an unusable format: \(format)")
            throw NSError(domain: "SpikeVoice", code: 2)
        }

        inputNode.removeTap(onBus: 0)
        // Passing nil lets the engine use the node's own format, which is the
        // most forgiving option across routes (built-in, wired, Bluetooth).
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            request.append(buffer)
            let power = Self.meterLevel(from: buffer)
            Task { @MainActor [weak self] in self?.applyLevel(power) }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            // One clean retry: transient route changes (AirPods connecting as
            // the sheet opens) are the usual cause and they settle immediately.
            print("[Spike AI] ⚠️ Engine start failed, retrying: \(error.localizedDescription)")
            inputNode.removeTap(onBus: 0)
            audioEngine.reset()
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
                request.append(buffer)
                let power = Self.meterLevel(from: buffer)
                Task { @MainActor [weak self] in self?.applyLevel(power) }
            }
            audioEngine.prepare()
            try audioEngine.start()
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            // Only Sendable values cross back to the main actor.
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                self?.handleRecognition(text: text, isFinal: isFinal, failed: failed)
            }
        }
    }

    private func handleRecognition(text: String?, isFinal: Bool, failed: Bool) {
        if let text, !text.isEmpty, text != transcript {
            transcript = text
            lastVoiceAt = Date()
        }

        if isFinal { hasFinalResult = true }

        // An error once we already have words is usually just the stream
        // closing; only surface it when nothing was captured at all.
        if failed {
            hasFinalResult = true
            if transcript.isEmpty, phase == .listening {
                stopAudioInput()
                releaseRecognition()
                phase = .recordingFailed(AppLocalization.string("voice_error_nothing_heard"))
            }
        }
    }

    /// Waits briefly for the recogniser's final, most accurate transcription.
    private func waitForFinalTranscript() async {
        let deadline = Date().addingTimeInterval(finalResultTimeout)
        while !hasFinalResult, Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func applyLevel(_ power: CGFloat) {
        // Exponential smoothing keeps the orb from strobing on every buffer.
        level = level * 0.7 + power * 0.3
    }

    private func startWatchdog() {
        watchdog?.cancel()
        watchdog = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard let self, self.phase == .listening else { return }

                let now = Date()
                let elapsed = now.timeIntervalSince(self.startedAt)
                let quietFor = now.timeIntervalSince(self.lastVoiceAt)

                if self.transcript.isEmpty {
                    if elapsed >= self.emptyTimeout {
                        self.stopAudioInput()
                        self.releaseRecognition()
                        self.phase = .recordingFailed(
                            AppLocalization.string("voice_error_nothing_heard"))
                        return
                    }
                } else if quietFor >= self.silenceWindow || elapsed >= self.maxDuration {
                    self.finishListening()
                    return
                }
            }
        }
    }

    /// Stops capturing audio. The recognition task stays alive so it can
    /// deliver its final result.
    private func stopAudioInput() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        level = 0
    }

    private func releaseRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        recognizer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Parsing
    // ─────────────────────────────────────────────────────────────────────

    private func runParse() async {
        phase = .parsing

        guard await VoiceReachability.isOnline() else {
            phase = .offline
            return
        }

        let outcome = await Self.parse(transcript: lastTranscript, language: language)

        switch outcome {
        case .success(let drafts, let summary, let usedFallback):
            self.drafts = drafts
            self.summary = summary
            self.usedFallbackParser = usedFallback
            self.phase = .review
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .noGoals:
            phase = .parseFailed(AppLocalization.string("voice_error_no_goals"))
        case .offline:
            phase = .offline
        case .failure:
            phase = .parseFailed(AppLocalization.string("voice_error_parse"))
        }
    }

    private enum ParseOutcome {
        case success(drafts: [VoiceGoalDraft], summary: String, usedFallback: Bool)
        case noGoals
        case offline
        case failure
    }

    private static func parse(transcript: String, language: String) async -> ParseOutcome {
        let calendar = Calendar.current
        let now = Date()

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        let request = VoiceGoalParseRequest(
            transcript: transcript,
            today: dayFormatter.string(from: now),
            nowTime: timeFormatter.string(from: now),
            language: language
        )

        do {
            let response: VoiceGoalParseResponse = try await supabase.functions
                .invoke("parse-voice-goals", options: FunctionInvokeOptions(body: request))

            if response.fallback == true {
                // The model path was skipped. Without this line the only symptom
                // is quietly worse goals and no way to tell why.
                print("[Spike AI] ⚠️ voice parse fell back — \(response.fallbackReason ?? "reason not reported")")
            }

            let drafts = response.goals.compactMap {
                makeDraft(from: $0, calendar: calendar, now: now)
            }
            guard !drafts.isEmpty else { return .noGoals }

            return .success(
                drafts: drafts,
                summary: response.summary ?? "",
                usedFallback: response.fallback ?? false
            )
        } catch {
            print("[Spike AI] ⚠️ parse-voice-goals failed: \(error.localizedDescription)")
            if await !VoiceReachability.isOnline() { return .offline }

            // The server round trip failed, but the user's words are right here.
            // Splitting them on device is far better than a dead end — they land
            // in the same editable review list and can fix anything we got wrong.
            let local = localDrafts(from: transcript, calendar: calendar, now: now)
            if !local.isEmpty {
                return .success(drafts: local, summary: "", usedFallback: true)
            }
            return .failure
        }
    }

    /// On-device last resort. Delegates to `SpokenGoalParser`, which implements
    /// the same hard filter, locality and compression rules as the edge
    /// function — the user cannot tell which side produced their list, so the
    /// two must not disagree.
    private static func localDrafts(
        from transcript: String,
        calendar: Calendar,
        now: Date
    ) -> [VoiceGoalDraft] {
        let startOfToday = calendar.startOfDay(for: now)

        return SpokenGoalParser.parse(transcript).map { parsed in
            let day = calendar.date(byAdding: .day, value: parsed.dayOffset, to: startOfToday)
                ?? startOfToday

            var reminder: Date?
            if let time = parsed.time {
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = time.hour
                components.minute = time.minute
                components.second = 0
                reminder = calendar.date(from: components)
            }

            return VoiceGoalDraft(
                title: String(parsed.title.prefix(80)),
                priority: parsed.priority,
                day: day,
                reminder: reminder,
                wantsNotification: parsed.notify,
                wantsAlarm: parsed.alarm
            )
        }
    }

    private static func makeDraft(
        from raw: VoiceGoalParseResponse.RawGoal,
        calendar: Calendar,
        now: Date
    ) -> VoiceGoalDraft? {
        let rawTitle = raw.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTitle.isEmpty else { return nil }

        // The title says WHAT, the reminder says WHEN — "Breakfast at 5:52 AM"
        // becomes "Breakfast" with 05:52 on the reminder. The server applies the
        // same rules, but its deployment can lag the app and models drift, so
        // the client guarantees it rather than trusting the response.
        let cleaned = SpokenGoalParser.cleanTitle(rawTitle)
        let title = cleaned.isEmpty ? rawTitle : cleaned

        // A time or day the model wrote only into the title would be lost once
        // it's stripped, so recover it. An explicit field always wins.
        let startOfToday = calendar.startOfDay(for: now)
        var offset = min(max(raw.dayOffset ?? 0, 0), 365)
        if offset == 0 { offset = SpokenGoalParser.relativeDayOffset(in: rawTitle) }
        let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday

        var namedTime: (hour: Int, minute: Int)?
        if let time = raw.time {
            let parts = time.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
               (0...23).contains(hour), (0...59).contains(minute) {
                namedTime = (hour, minute)
            }
        }
        if namedTime == nil { namedTime = SpokenGoalParser.time(in: rawTitle) }

        var reminder: Date?
        if let namedTime {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = namedTime.hour
            components.minute = namedTime.minute
            components.second = 0
            reminder = calendar.date(from: components)
        }

        let wantsAlarm = raw.alarm ?? false
        // An alarm is a reminder, and naming a time means the user expects one.
        let wantsNotification = (raw.notify ?? false) || wantsAlarm || reminder != nil

        return VoiceGoalDraft(
            title: String(title.prefix(80)),
            priority: TaskPriority(rawValue: (raw.priority ?? "medium").lowercased()) ?? .medium,
            day: day,
            reminder: reminder,
            wantsNotification: wantsNotification,
            wantsAlarm: wantsAlarm
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Saving
    // ─────────────────────────────────────────────────────────────────────

    /// Writes the selected drafts to Supabase and schedules their reminders.
    /// Returns the earliest day a goal landed on, so Home can jump to it.
    @discardableResult
    func save(store: TaskStore, userId: UUID) async -> Date? {
        let selected = drafts.filter(\.isSelected)
        guard !selected.isEmpty else { return nil }

        var notificationsAllowed: Bool?
        var earliestDay: Date?

        for draft in selected {
            let key = draft.dayKey
            // Respect the same 25-per-day ceiling the manual Add sheet enforces.
            guard store.tasksFor(date: key).count < 25 else { continue }

            let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            let taskId = UUID().uuidString
            await store.add(
                id: taskId,
                title: title,
                priority: draft.priority,
                scheduledDate: key,
                userId: userId
            )

            if earliestDay == nil || draft.day < earliestDay! { earliestDay = draft.day }

            // A reminder needs both the user's intent and a time to fire at.
            guard draft.wantsNotification,
                  let reminder = draft.reminder,
                  reminder > Date().addingTimeInterval(60) else { continue }

            // Ask for notification permission once, and only if a reminder needs it.
            if notificationsAllowed == nil {
                notificationsAllowed = await Self.requestNotificationPermission()
            }
            guard notificationsAllowed == true else { continue }

            if draft.wantsAlarm {
                // Rings on the Lock Screen until stopped, same path as the
                // Alarm toggle in the manual Add Goal sheet.
                TaskReminderStore.shared.setAlarm(for: taskId, title: title, at: reminder)
            } else {
                TaskReminderStore.shared.setNotification(for: taskId, title: title, at: reminder)
            }
        }

        if earliestDay != nil { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        return earliestDay
    }

    private static func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        return (try? await center.requestAuthorization(
            options: [.alert, .badge, .sound, .timeSensitive])) ?? false
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Audio helpers
    // ─────────────────────────────────────────────────────────────────────

    /// RMS of a buffer mapped onto a 0...1 curve that looks good on an orb.
    private nonisolated static func meterLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<count {
            let sample = channel[index]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(count))

        // -50 dB (silence) .. 0 dB (loud) -> 0...1
        let decibels = 20 * log10(max(rms, 0.000_001))
        let normalized = (decibels + 50) / 50
        return CGFloat(min(max(normalized, 0), 1))
    }

    /// Vocabulary hints for the recogniser. These are the words that carry the
    /// structured fields — if "urgent" or "remind me" is misheard, the parser
    /// loses the priority or the reminder entirely, so biasing toward them is
    /// worth more than biasing toward the goal nouns.
    private nonisolated static func contextualStrings(for language: String) -> [String] {
        var hints = [
            "today", "tomorrow", "tonight", "this morning", "this afternoon", "this evening",
            "at", "by", "am", "pm", "o'clock", "half past", "quarter past",
            "urgent", "important", "critical", "high priority", "low priority",
            "no rush", "whenever", "if I have time",
            "remind me", "reminder", "notify me", "notification",
            "alarm", "wake me", "set an alarm", "ring",
            "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
        ]

        // The recogniser is running in the user's language; give it the same
        // trigger words there so non-English speakers get the same benefit.
        switch language {
        case "ru":
            hints += ["сегодня", "завтра", "срочно", "важно", "напомни", "будильник", "в"]
        case "uz":
            hints += ["bugun", "ertaga", "shoshilinch", "muhim", "eslat", "signal", "soat"]
        case "es":
            hints += ["hoy", "mañana", "urgente", "importante", "recuérdame", "alarma", "a las"]
        case "fr":
            hints += ["aujourd'hui", "demain", "urgent", "important", "rappelle-moi", "réveil", "à"]
        case "de":
            hints += ["heute", "morgen", "dringend", "wichtig", "erinnere mich", "Wecker", "um"]
        case "tr":
            hints += ["bugün", "yarın", "acil", "önemli", "hatırlat", "alarm", "saat"]
        default:
            break
        }

        return hints
    }

    /// Matches the recogniser to the app language, degrading to the device
    /// locale and then en-US when a language has no speech model.
    private nonisolated static func makeRecognizer(language: String) -> SFSpeechRecognizer? {
        let supported = SFSpeechRecognizer.supportedLocales()
        if supported.contains(where: { $0.identifier.hasPrefix(language) }),
           let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) {
            return recognizer
        }
        return SFSpeechRecognizer() ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Brand
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum VoiceBrand {
    static let top = Color(red: 0.55, green: 0.40, blue: 1.0)
    static let bottom = Color(red: 0.40, green: 0.25, blue: 0.85)
    static var gradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var horizontalGradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .leading, endPoint: .trailing)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Home Button
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Purple mic button that sits directly above the "+" FAB on Home.
struct VoiceGoalButton: View {
    var isDisabled: Bool
    var action: () -> Void

    /// Pulses to advertise itself until the feature is used once, then settles
    /// down — same pattern as the daily-quote button.
    @AppStorage("spike_voice_goals_used") private var hasUsedVoice = false
    @State private var breathe = false

    private var shouldPulse: Bool { !hasUsedVoice && !isDisabled }

    var body: some View {
        Button {
            hasUsedVoice = true
            withAnimation(.easeOut(duration: 0.3)) { breathe = false }
            action()
        } label: {
            ZStack {
                if shouldPulse {
                    Circle()
                        .stroke(VoiceBrand.top.opacity(0.5), lineWidth: 2)
                        .frame(width: 52, height: 52)
                        .scaleEffect(breathe ? 1.4 : 1.0)
                        .opacity(breathe ? 0.0 : 0.8)
                }

                Circle()
                    .fill(VoiceBrand.gradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: VoiceBrand.top.opacity(shouldPulse && breathe ? 0.55 : 0.30),
                            radius: shouldPulse && breathe ? 14 : 8, y: 4)

                Image(systemName: "mic.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityLabel(Text(AppLocalization.string("voice_add_goals")))
        .onAppear {
            guard shouldPulse else { return }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                breathe = true
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Voice Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct VoiceGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Environment(AppLocalization.self) private var loc

    /// Called with the earliest day a goal landed on, so Home can show it.
    var onSaved: (Date) -> Void = { _ in }

    @State private var model = VoiceGoalCaptureModel()
    @State private var isSaving = false
    @State private var showTranscript = false

    var body: some View {
        NavigationStack {
            ZStack {
                SpikeGradientBackground()
                content
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc["cancel"]) {
                        model.cancel()
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .interactiveDismissDisabled(model.phase == .parsing || isSaving)
        .task { await model.start(language: loc.language) }
        .onDisappear { model.cancel() }
    }

    private var navigationTitle: String {
        switch model.phase {
        case .listening, .preparing: loc["voice_title_speak"]
        case .review: loc["voice_title_review"]
        default: ""
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .preparing:
            ProgressView().controlSize(.large)
        case .listening:
            listeningView
        case .parsing:
            parsingView
        case .review:
            reviewView
        case .offline:
            offlineView
        case .denied(let permission):
            deniedView(permission)
        case .recordingFailed(let message):
            statusView(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: loc["voice_try_again_title"],
                message: message,
                actionTitle: loc["voice_try_again"]
            ) {
                Task { await model.start(language: loc.language) }
            }
        case .parseFailed(let message):
            statusView(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: loc["voice_try_again_title"],
                message: message,
                actionTitle: loc["voice_try_again"],
                secondaryTitle: loc["voice_record_again"],
                secondaryAction: { Task { await model.start(language: loc.language) } }
            ) {
                Task { await model.retryParse() }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Listening
    // ─────────────────────────────────────────────────────────────────────

    private var listeningView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            MicOrb(level: model.level)

            VStack(spacing: 6) {
                Text(loc["voice_listening"])
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(loc["voice_listening_hint"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            transcriptCard

            Spacer(minLength: 8)

            primaryButton(
                title: loc["voice_done"],
                systemImage: "checkmark",
                isEnabled: !model.transcript.isEmpty
            ) {
                model.finishListening()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private var transcriptCard: some View {
        ScrollView {
            Text(model.transcript.isEmpty ? loc["voice_waiting"] : model.transcript)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(model.transcript.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeOut(duration: 0.15), value: model.transcript)
        }
        .frame(maxHeight: 170)
        .padding(18)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.spikeCardBorder, lineWidth: 0.5))
        .padding(.horizontal, 24)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Parsing
    // ─────────────────────────────────────────────────────────────────────

    private var parsingView: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(VoiceBrand.gradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: VoiceBrand.top.opacity(0.5), radius: 20, y: 6)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }

            VStack(spacing: 6) {
                Text(loc["voice_understanding"])
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text(loc["voice_understanding_hint"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Review
    // ─────────────────────────────────────────────────────────────────────

    private var reviewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    summaryCard

                    if model.usedFallbackParser {
                        noticeCard(icon: "exclamationmark.circle",
                                   text: loc["voice_fallback_note"])
                    }

                    ForEach($model.drafts) { $draft in
                        VoiceGoalDraftRow(draft: $draft, loc: loc)
                    }

                    transcriptDisclosure
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }

            saveBar
        }
    }

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(VoiceBrand.top)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.drafts.count == 1
                     ? loc["voice_heard_one"]
                     : String(format: loc["voice_heard_count"], model.drafts.count))
                    .font(.system(size: 17, weight: .bold, design: .rounded))

                if !model.summary.isEmpty {
                    Text(model.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(loc["voice_review_hint"])
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(VoiceBrand.top.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var transcriptDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showTranscript.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 12, weight: .semibold))
                    Text(loc["voice_what_you_said"])
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(showTranscript ? 0 : -90))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if showTranscript {
                Text(model.transcript)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 6)
    }

    private func noticeCard(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            primaryButton(
                title: model.selectedCount == 1
                    ? loc["voice_add_one"]
                    : String(format: loc["voice_add_count"], model.selectedCount),
                systemImage: "checkmark",
                isEnabled: model.selectedCount > 0 && !isSaving,
                isBusy: isSaving
            ) {
                saveGoals()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func saveGoals() {
        guard let userId = auth.userId, !isSaving else { return }
        isSaving = true
        Task {
            let landedOn = await model.save(store: store, userId: userId)
            isSaving = false
            if let landedOn { onSaved(landedOn) }
            dismiss()
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Offline / errors
    // ─────────────────────────────────────────────────────────────────────

    private var offlineView: some View {
        statusView(
            icon: "wifi.slash",
            tint: VoiceBrand.top,
            title: loc["voice_offline_title"],
            message: loc["voice_offline_message"],
            actionTitle: loc["voice_try_again"]
        ) {
            Task {
                if model.phase == .offline, !model.transcript.isEmpty {
                    await model.retryParse()
                } else {
                    await model.start(language: loc.language)
                }
            }
        }
    }

    private func deniedView(_ permission: VoiceGoalCaptureModel.Permission) -> some View {
        statusView(
            icon: permission == .microphone ? "mic.slash.fill" : "waveform.slash",
            tint: .orange,
            title: loc["voice_permission_title"],
            message: permission == .microphone
                ? loc["voice_permission_mic"]
                : loc["voice_permission_speech"],
            actionTitle: loc["voice_open_settings"]
        ) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func statusView(
        icon: String,
        tint: Color,
        title: String,
        message: String,
        actionTitle: String,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle().fill(tint.opacity(0.14)).frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(tint)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            VStack(spacing: 10) {
                primaryButton(title: actionTitle, systemImage: nil, isEnabled: true, action: action)
                    .padding(.horizontal, 24)

                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Shared button
    // ─────────────────────────────────────────────────────────────────────

    private func primaryButton(
        title: String,
        systemImage: String?,
        isEnabled: Bool,
        isBusy: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(VoiceBrand.horizontalGradient))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Draft Row
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct VoiceGoalDraftRow: View {
    @Binding var draft: VoiceGoalDraft
    let loc: AppLocalization

    @State private var showTimePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { draft.isSelected.toggle() }
                } label: {
                    Image(systemName: draft.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21))
                        .foregroundStyle(draft.isSelected ? Color.green : Color.secondary)
                }
                .buttonStyle(.plain)

                TextField(loc["what_to_do"], text: $draft.title, axis: .vertical)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1...2)
            }

            HStack(spacing: 8) {
                priorityMenu
                dayChip
                timeChip
                Spacer(minLength: 0)
            }
            .padding(.leading, 33)

            if draft.reminder != nil, draft.reminderIsInPast {
                Label(loc["voice_time_passed"], systemImage: "clock.badge.exclamationmark")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.leading, 33)
            }
        }
        .padding(14)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.spikeCardBorder, lineWidth: 0.5))
        .opacity(draft.isSelected ? 1 : 0.5)
        .sheet(isPresented: $showTimePicker) { timePickerSheet }
    }

    private var priorityMenu: some View {
        Menu {
            ForEach(TaskPriority.allCases) { option in
                Button {
                    draft.priority = option
                } label: {
                    Label(option.label, systemImage: option.icon)
                }
            }
        } label: {
            chip(icon: draft.priority.icon, text: draft.priority.label, tint: draft.priority.color)
        }
    }

    private var dayChip: some View {
        chip(icon: "calendar", text: dayLabel, tint: .secondary)
    }

    private var timeChip: some View {
        Button {
            showTimePicker = true
        } label: {
            chip(
                icon: chipIcon,
                text: draft.reminder.map(timeLabel) ?? loc["voice_no_time"],
                tint: chipTint
            )
        }
        .buttonStyle(.plain)
    }

    /// Alarm outranks notification, which outranks "no reminder" — the chip
    /// shows what will actually happen at that time.
    private var chipIcon: String {
        guard draft.reminder != nil, draft.wantsNotification else { return "bell.slash" }
        return draft.wantsAlarm ? "alarm.fill" : "bell.fill"
    }

    private var chipTint: Color {
        guard draft.reminder != nil, draft.wantsNotification else { return .secondary }
        return draft.wantsAlarm ? .orange : .green
    }

    private func chip(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14))
        .clipShape(Capsule())
    }

    private var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Toggle(loc["voice_reminder"], isOn: Binding(
                    get: { draft.reminder != nil && draft.wantsNotification },
                    set: { isOn in
                        draft.wantsNotification = isOn
                        if isOn {
                            if draft.reminder == nil {
                                let calendar = Calendar.current
                                var components = calendar.dateComponents(
                                    [.year, .month, .day], from: draft.day)
                                components.hour = 9
                                components.minute = 0
                                draft.reminder = calendar.date(from: components)
                            }
                        } else {
                            draft.reminder = nil
                            draft.wantsAlarm = false
                        }
                    }
                ))
                .tint(.green)
                .padding(.horizontal)

                if draft.reminder != nil, draft.wantsNotification {
                    Toggle(loc["alarm_sound"], isOn: Binding(
                        get: { draft.wantsAlarm },
                        set: { isOn in
                            draft.wantsAlarm = isOn
                            // Same contract as the manual Add Goal sheet: get the
                            // Lock Screen permission while the user is deciding.
                            guard isOn, SpikeAlarmScheduler.isSupported else { return }
                            Task { await SpikeAlarmScheduler.requestAuthorization() }
                        }
                    ))
                    .tint(.orange)
                    .padding(.horizontal)

                    DatePicker(
                        loc["time"],
                        selection: Binding(
                            get: { draft.reminder ?? draft.day },
                            set: { draft.reminder = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle(loc["voice_reminder"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc["done"]) { showTimePicker = false }
                }
            }
        }
        .presentationDetents([.height(430)])
    }

    private var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(draft.day) { return loc["today"] }
        if calendar.isDateInTomorrow(draft.day) { return loc["tomorrow"] }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: loc.language)
        formatter.setLocalizedDateFormatFromTemplate("EEEd MMM")
        return formatter.string(from: draft.day)
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: loc.language)
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Mic Orb
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Concentric rings that swell with the user's voice.
private struct MicOrb: View {
    let level: CGFloat

    @State private var idlePulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                let ringScale = 1.0 + (level * 0.55) + (CGFloat(index) * 0.22)
                Circle()
                    .stroke(VoiceBrand.top.opacity(0.35 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: 108, height: 108)
                    .scaleEffect(ringScale)
                    .animation(.easeOut(duration: 0.18), value: level)
            }

            Circle()
                .fill(VoiceBrand.top.opacity(0.18))
                .frame(width: 108, height: 108)
                .scaleEffect(1 + level * 0.3)
                .animation(.easeOut(duration: 0.18), value: level)

            Circle()
                .fill(VoiceBrand.gradient)
                .frame(width: 86, height: 86)
                .shadow(color: VoiceBrand.top.opacity(0.5), radius: 18, y: 6)
                .scaleEffect(idlePulse ? 1.04 : 0.98)

            Image(systemName: "waveform")
                .font(.system(size: 33, weight: .medium))
                .foregroundStyle(.white)
                .scaleEffect(1 + level * 0.12)
                .animation(.easeOut(duration: 0.18), value: level)
        }
        .frame(height: 180)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                idlePulse = true
            }
        }
    }
}
