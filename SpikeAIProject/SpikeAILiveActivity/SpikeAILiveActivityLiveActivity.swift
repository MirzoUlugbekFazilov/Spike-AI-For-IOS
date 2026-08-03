//
//  SpikeAILiveActivityLiveActivity.swift
//  SpikeAILiveActivity
//
//  Created by Мирзо-Улугбек Фазилов on 24/05/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Data

struct LiveTaskItem: Codable, Hashable {
    let title: String
    let done: Bool
    let priority: String // "low", "medium", "high"
}

struct DailyGoalsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var completedGoals: Int
        var totalGoals: Int
        var streak: Int
        var motivation: String
        var tasks: [LiveTaskItem]

        init(completedGoals: Int, totalGoals: Int, streak: Int, motivation: String, tasks: [LiveTaskItem] = []) {
            self.completedGoals = completedGoals
            self.totalGoals = totalGoals
            self.streak = streak
            self.motivation = motivation
            self.tasks = tasks
        }
    }

    var title: String
}

// MARK: - Live Activity Localization

/// Lightweight localization helper for the Live Activity extension.
/// Reads the user's chosen language from App Group UserDefaults.
enum LALocalization {

    private static let language: String = {
        UserDefaults(suiteName: "group.com.spikeai.spikeai")?
            .string(forKey: "spike_app_language") ?? "en"
    }()

    static subscript(key: String) -> String {
        translations[language]?[key] ?? translations["en"]?[key] ?? key
    }

    static func format(_ key: String, _ arg: Int) -> String {
        String(format: self[key], arg)
    }

    private static let translations: [String: [String: String]] = [
        "en": [
            "today": "Today",
            "tasks": "Tasks",
            "streak": "Streak",
            "done_label": "Done",
            "more_to_go": "+%d more to go",
            "open_app_review": "Open the app to review today's goals.",
        ],
        "es": [
            "today": "Hoy",
            "tasks": "Tareas",
            "streak": "Racha",
            "done_label": "Hecho",
            "more_to_go": "+%d más por hacer",
            "open_app_review": "Abre la app para revisar las metas de hoy.",
        ],
        "fr": [
            "today": "Aujourd'hui",
            "tasks": "Tâches",
            "streak": "Série",
            "done_label": "Fait",
            "more_to_go": "+%d de plus",
            "open_app_review": "Ouvrez l'app pour voir les objectifs du jour.",
        ],
        "de": [
            "today": "Heute",
            "tasks": "Aufgaben",
            "streak": "Serie",
            "done_label": "Erledigt",
            "more_to_go": "+%d weitere",
            "open_app_review": "Öffne die App, um die heutigen Ziele zu sehen.",
        ],
        "pt": [
            "today": "Hoje",
            "tasks": "Tarefas",
            "streak": "Sequência",
            "done_label": "Feito",
            "more_to_go": "+%d a mais",
            "open_app_review": "Abra o app para revisar as metas de hoje.",
        ],
        "ru": [
            "today": "Сегодня",
            "tasks": "Задачи",
            "streak": "Серия",
            "done_label": "Готово",
            "more_to_go": "+%d ещё",
            "open_app_review": "Откройте приложение, чтобы просмотреть задачи на сегодня.",
        ],
        "uz": [
            "today": "Bugun",
            "tasks": "Vazifalar",
            "streak": "Ketma-ketlik",
            "done_label": "Bajarildi",
            "more_to_go": "+%d ta qoldi",
            "open_app_review": "Bugungi maqsadlarni ko'rish uchun ilovani oching.",
        ],
        "zh": [
            "today": "今天",
            "tasks": "任务",
            "streak": "连续",
            "done_label": "完成",
            "more_to_go": "+%d 个待完成",
            "open_app_review": "打开应用查看今天的目标。",
        ],
        "ja": [
            "today": "今日",
            "tasks": "タスク",
            "streak": "連続",
            "done_label": "完了",
            "more_to_go": "+%d 件残り",
            "open_app_review": "アプリを開いて今日の目標を確認しましょう。",
        ],
        "ko": [
            "today": "오늘",
            "tasks": "작업",
            "streak": "연속",
            "done_label": "완료",
            "more_to_go": "+%d개 남음",
            "open_app_review": "앱을 열어 오늘의 목표를 확인하세요.",
        ],
        "ar": [
            "today": "اليوم",
            "tasks": "المهام",
            "streak": "السلسلة",
            "done_label": "تم",
            "more_to_go": "+%d للإنجاز",
            "open_app_review": "افتح التطبيق لمراجعة أهداف اليوم.",
        ],
        "hi": [
            "today": "आज",
            "tasks": "कार्य",
            "streak": "स्ट्रीक",
            "done_label": "पूर्ण",
            "more_to_go": "+%d और बाकी",
            "open_app_review": "आज के लक्ष्यों की समीक्षा करने के लिए ऐप खोलें।",
        ],
        "tr": [
            "today": "Bugün",
            "tasks": "Görevler",
            "streak": "Seri",
            "done_label": "Tamam",
            "more_to_go": "+%d daha",
            "open_app_review": "Bugünün hedeflerini görmek için uygulamayı açın.",
        ],
        "it": [
            "today": "Oggi",
            "tasks": "Attività",
            "streak": "Serie",
            "done_label": "Fatto",
            "more_to_go": "+%d in più",
            "open_app_review": "Apri l'app per controllare gli obiettivi di oggi.",
        ],
        "pl": [
            "today": "Dziś",
            "tasks": "Zadania",
            "streak": "Seria",
            "done_label": "Gotowe",
            "more_to_go": "+%d więcej",
            "open_app_review": "Otwórz aplikację, aby sprawdzić dzisiejsze cele.",
        ],
        "uk": [
            "today": "Сьогодні",
            "tasks": "Завдання",
            "streak": "Серія",
            "done_label": "Готово",
            "more_to_go": "+%d ще",
            "open_app_review": "Відкрийте додаток, щоб переглянути цілі на сьогодні.",
        ],
        "nl": [
            "today": "Vandaag",
            "tasks": "Taken",
            "streak": "Reeks",
            "done_label": "Klaar",
            "more_to_go": "+%d meer",
            "open_app_review": "Open de app om de doelen van vandaag te bekijken.",
        ],
        "sv": [
            "today": "Idag",
            "tasks": "Uppgifter",
            "streak": "Svit",
            "done_label": "Klart",
            "more_to_go": "+%d till",
            "open_app_review": "Öppna appen för att se dagens mål.",
        ],
        "id": [
            "today": "Hari Ini",
            "tasks": "Tugas",
            "streak": "Streak",
            "done_label": "Selesai",
            "more_to_go": "+%d lagi",
            "open_app_review": "Buka aplikasi untuk melihat tujuan hari ini.",
        ],
        "vi": [
            "today": "Hôm nay",
            "tasks": "Nhiệm vụ",
            "streak": "Chuỗi",
            "done_label": "Xong",
            "more_to_go": "+%d còn lại",
            "open_app_review": "Mở ứng dụng để xem mục tiêu hôm nay.",
        ],
        "kk": [
            "today": "Бүгін",
            "tasks": "Тапсырмалар",
            "streak": "Сериясы",
            "done_label": "Дайын",
            "more_to_go": "+%d қалды",
            "open_app_review": "Бүгінгі мақсаттарды қарау үшін қолданбаны ашыңыз.",
        ],
        "ms": [
            "today": "Hari Ini",
            "tasks": "Tugasan",
            "streak": "Kesinambungan",
            "done_label": "Siap",
            "more_to_go": "+%d lagi",
            "open_app_review": "Buka aplikasi untuk menyemak matlamat hari ini.",
        ],
        "tg": [
            "today": "Имрӯз",
            "tasks": "Вазифаҳо",
            "streak": "Силсила",
            "done_label": "Тайёр",
            "more_to_go": "+%d боқимонда",
            "open_app_review": "Барои дидани ҳадафҳои имрӯз барномаро кушоед.",
        ],
    ]
}

// MARK: - Color Palette

private enum Palette {
    static let accent      = Color(red: 0.50, green: 0.45, blue: 1.0)
    static let accentAlt   = Color(red: 0.60, green: 0.35, blue: 1.0)
    static let greenHi     = Color(red: 0.20, green: 0.90, blue: 0.50)
    static let greenLo     = Color(red: 0.00, green: 0.80, blue: 0.70)
    static let streakGold  = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let streakAmber = Color(red: 1.0, green: 0.55, blue: 0.10)

    static func priorityColor(_ p: String) -> Color {
        switch p {
        case "high":   return .red
        case "medium": return .orange
        default:       return Color(red: 0.45, green: 0.65, blue: 1.0)
        }
    }
}

// MARK: - Ring Metric Cell (Cal AI style)

private struct RingCell: View {
    let icon: String
    let iconColor: Color
    let ringProgress: Double
    let ringColor: LinearGradient
    let value: String
    let label: String

    private let ringSize: CGFloat = 42
    private let strokeWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)
                    .frame(width: ringSize, height: ringSize)
                if ringProgress > 0 {
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringSize, height: ringSize)
                }
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}

// MARK: - Live Activity Widget

struct SpikeAILiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyGoalsActivityAttributes.self) { context in
            let prog = progress(for: context.state)
            let isComplete = context.state.completedGoals >= context.state.totalGoals

            // ── Lock Screen / Banner ─────────────────────────────────
            lockScreenView(state: context.state, prog: prog, isComplete: isComplete)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let prog = progress(for: context.state)
            let isComplete = context.state.completedGoals >= context.state.totalGoals
            let pending = context.state.tasks.filter { !$0.done }

            return DynamicIsland {
                // ── Expanded ──
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: isComplete ? "checkmark.seal.fill" : "checklist.checked")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isComplete ? .green : .white)
                        Text("Spike AI")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.streakGold)
                        Text("\(context.state.streak)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar + percentage
                        HStack(spacing: 10) {
                            ProgressView(value: prog)
                                .tint(isComplete ? Color.green : Palette.accent)
                            Text(progressPercent(for: context.state))
                                .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        // Pending tasks (up to 3)
                        if !pending.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(pending.prefix(3), id: \.self) { task in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .stroke(.white.opacity(0.25), lineWidth: 1.2)
                                            .frame(width: 10, height: 10)
                                        Text(task.title)
                                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .lineLimit(1)
                                        Spacer()
                                        Circle()
                                            .fill(Palette.priorityColor(task.priority))
                                            .frame(width: 4, height: 4)
                                            .opacity(0.6)
                                    }
                                }
                                if pending.count > 3 {
                                    Text(LALocalization.format("more_to_go", pending.count - 3))
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.3))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 16)
                                }
                            }
                        } else {
                            Text(context.state.motivation)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                // Mini ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: prog)
                        .stroke(isComplete ? Color.green : Palette.accent,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: isComplete ? "checkmark" : "checklist.checked")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isComplete ? .green : .white)
                }
                .frame(width: 18, height: 18)
            } compactTrailing: {
                Text("\(context.state.completedGoals)/\(context.state.totalGoals)")
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(isComplete ? .green : .white)
            } minimal: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: prog)
                        .stroke(isComplete ? Color.green : Palette.accent,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .padding(2)
            }
            .keylineTint(Palette.accent)
        }
    }

    // MARK: Lock Screen — Cal AI Style

    @ViewBuilder
    private func lockScreenView(state: DailyGoalsActivityAttributes.ContentState,
                                prog: Double, isComplete: Bool) -> some View {
        let pct = Int((prog * 100).rounded())
        let streakProg = min(1, Double(state.streak) / 10.0)
        let dividerH: CGFloat = 50

        VStack(spacing: 0) {
            // ── Header: "Today" left, app icon + "Spike AI" right ──
            HStack(alignment: .center) {
                Text(LALocalization["today"])
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                HStack(spacing: 5) {
                    Image("SpikeLogoWidget")
                        .renderingMode(.original)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 24)
                    Text("Spike AI")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // ── Metrics row with vertical dividers ──
            HStack(spacing: 0) {
                // Tasks
                RingCell(
                    icon: "checklist.checked",
                    iconColor: Palette.accent,
                    ringProgress: prog,
                    ringColor: LinearGradient(colors: [Palette.accent, Palette.accentAlt],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                    value: "\(state.completedGoals)/\(state.totalGoals)",
                    label: LALocalization["tasks"]
                )
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: dividerH)

                // Streak
                RingCell(
                    icon: "flame.fill",
                    iconColor: Palette.streakGold,
                    ringProgress: streakProg,
                    ringColor: LinearGradient(colors: [Palette.streakGold, Palette.streakAmber],
                                              startPoint: .top, endPoint: .bottom),
                    value: "\(state.streak)",
                    label: LALocalization["streak"]
                )
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: dividerH)

                // Done %
                RingCell(
                    icon: isComplete ? "checkmark.circle.fill" : "chart.pie.fill",
                    iconColor: isComplete ? Palette.greenHi : Palette.greenHi.opacity(0.85),
                    ringProgress: prog,
                    ringColor: LinearGradient(colors: [Palette.greenHi, Palette.greenLo],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                    value: "\(pct)%",
                    label: LALocalization["done_label"]
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
    }

    private func progress(for state: DailyGoalsActivityAttributes.ContentState) -> Double {
        guard state.totalGoals > 0 else { return 0 }
        return min(1, max(0, Double(state.completedGoals) / Double(state.totalGoals)))
    }

    private func progressPercent(for state: DailyGoalsActivityAttributes.ContentState) -> String {
        "\(Int((progress(for: state) * 100).rounded()))%"
    }
}

// MARK: - Previews

extension DailyGoalsActivityAttributes {
    fileprivate static var preview: DailyGoalsActivityAttributes {
        DailyGoalsActivityAttributes(title: "Daily Goals")
    }
}

extension DailyGoalsActivityAttributes.ContentState {
    fileprivate static var partial: DailyGoalsActivityAttributes.ContentState {
        .init(
            completedGoals: 2, totalGoals: 5, streak: 4,
            motivation: "Finish the next clear step.",
            tasks: [
                LiveTaskItem(title: "Review pull request", done: true, priority: "high"),
                LiveTaskItem(title: "Write unit tests", done: true, priority: "medium"),
                LiveTaskItem(title: "Go to the gym", done: false, priority: "high"),
                LiveTaskItem(title: "Read 20 pages", done: false, priority: "medium"),
                LiveTaskItem(title: "Prepare slides", done: false, priority: "low"),
            ]
        )
    }

    fileprivate static var complete: DailyGoalsActivityAttributes.ContentState {
        .init(
            completedGoals: 3, totalGoals: 3, streak: 5,
            motivation: "Daily plan complete.",
            tasks: [
                LiveTaskItem(title: "Review pull request", done: true, priority: "high"),
                LiveTaskItem(title: "Go to the gym", done: true, priority: "high"),
                LiveTaskItem(title: "Read 20 pages", done: true, priority: "medium"),
            ]
        )
    }
}

extension DailyGoalsActivityAttributes.ContentState {
    fileprivate static var many: DailyGoalsActivityAttributes.ContentState {
        .init(
            completedGoals: 3, totalGoals: 9, streak: 7,
            motivation: "Consistency beats intensity.",
            tasks: [
                LiveTaskItem(title: "Morning workout", done: true, priority: "high"),
                LiveTaskItem(title: "Review pull request", done: true, priority: "high"),
                LiveTaskItem(title: "Reply to emails", done: true, priority: "medium"),
                LiveTaskItem(title: "Team standup", done: false, priority: "high"),
                LiveTaskItem(title: "Finish API integration", done: false, priority: "high"),
                LiveTaskItem(title: "Read 20 pages", done: false, priority: "medium"),
                LiveTaskItem(title: "Buy groceries", done: false, priority: "low"),
                LiveTaskItem(title: "Prepare slides", done: false, priority: "medium"),
            ]
        )
    }
}

#Preview("Notification", as: .content, using: DailyGoalsActivityAttributes.preview) {
    SpikeAILiveActivityLiveActivity()
} contentStates: {
    DailyGoalsActivityAttributes.ContentState.partial
    DailyGoalsActivityAttributes.ContentState.complete
    DailyGoalsActivityAttributes.ContentState.many
}
