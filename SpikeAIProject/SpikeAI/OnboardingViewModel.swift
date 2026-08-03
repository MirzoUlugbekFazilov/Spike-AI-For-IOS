//
//  OnboardingViewModel.swift
//  Spike AI
//
//  Manages state for the first-launch onboarding flow.
//

import Foundation

// MARK: - Language Data

struct AppLanguage: Identifiable, Hashable {
    let id: String      // locale code
    let name: String    // native name
    let flag: String    // emoji flag
}

let supportedLanguages: [AppLanguage] = [
    .init(id: "en", name: "English",       flag: "🇺🇸"),
    .init(id: "es", name: "Español",       flag: "🇪🇸"),
    .init(id: "fr", name: "Français",      flag: "🇫🇷"),
    .init(id: "de", name: "Deutsch",       flag: "🇩🇪"),
    .init(id: "pt", name: "Português",     flag: "🇧🇷"),
    .init(id: "ru", name: "Русский",       flag: "🇷🇺"),
    .init(id: "uz", name: "Oʻzbekcha",    flag: "🇺🇿"),
    .init(id: "zh", name: "中文",           flag: "🇨🇳"),
    .init(id: "ja", name: "日本語",         flag: "🇯🇵"),
    .init(id: "ko", name: "한국어",          flag: "🇰🇷"),
    .init(id: "ar", name: "العربية",       flag: "🇸🇦"),
    .init(id: "hi", name: "हिन्दी",          flag: "🇮🇳"),
    .init(id: "tr", name: "Türkçe",        flag: "🇹🇷"),
    .init(id: "it", name: "Italiano",      flag: "🇮🇹"),
    .init(id: "pl", name: "Polski",        flag: "🇵🇱"),
    .init(id: "uk", name: "Українська",    flag: "🇺🇦"),
    .init(id: "nl", name: "Nederlands",    flag: "🇳🇱"),
    .init(id: "sv", name: "Svenska",       flag: "🇸🇪"),
    .init(id: "id", name: "Indonesia",     flag: "🇮🇩"),
    .init(id: "vi", name: "Tiếng Việt",   flag: "🇻🇳"),
    .init(id: "kk", name: "Қазақша",      flag: "🇰🇿"),
]

/// "Choose your language" localized in each language, keyed by language prefix.
let chooseLanguagePrompt: [String: String] = [
    "en": "Choose your language",
    "es": "Elige tu idioma",
    "fr": "Choisissez votre langue",
    "de": "Wähle deine Sprache",
    "pt": "Escolha seu idioma",
    "ru": "Выберите язык",
    "uz": "Tilni tanlang",
    "zh": "选择你的语言",
    "ja": "言語を選択",
    "ko": "언어를 선택하세요",
    "ar": "اختر لغتك",
    "hi": "अपनी भाषा चुनें",
    "tr": "Dilinizi seçin",
    "it": "Scegli la tua lingua",
    "pl": "Wybierz język",
    "uk": "Оберіть мову",
    "nl": "Kies je taal",
    "sv": "Välj ditt språk",
    "id": "Pilih bahasa",
    "vi": "Chọn ngôn ngữ",
    "kk": "Тілді таңдаңыз",
]

// MARK: - View Model

@MainActor @Observable
final class OnboardingViewModel {

    // MARK: - Keys

    static let completedKey  = "linear_welcome_onboarding_done"
    static let languageKey   = "spike_app_language"

    // MARK: - Navigation

    var currentPage = 0
    let totalPages = 7     // language + 6 onboarding screens

    // MARK: - User Selections

    var selectedLanguage: String = {
        if let saved = UserDefaults.standard.string(forKey: "spike_app_language"),
           supportedLanguages.contains(where: { $0.id == saved }) {
            return saved
        }
        let device = Locale.current.language.languageCode?.identifier ?? "en"
        // Pre-select device language if supported, else English
        return supportedLanguages.contains(where: { $0.id == device }) ? device : "en"
    }()

    var selectedFrequency: String?
    var selectedIdentities: Set<String> = []
    var screenTimeHandled = false

    // MARK: - Computed

    var canContinue: Bool { true }

    /// Localized prompt for the language picker based on device language.
    var localizedChooseLanguage: String {
        let device = Locale.current.language.languageCode?.identifier ?? "en"
        return chooseLanguagePrompt[device] ?? chooseLanguagePrompt["en"]!
    }

    // MARK: - Actions

    func advance() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    func saveSelections() {
        let d = UserDefaults.standard
        d.set(selectedLanguage,            forKey: Self.languageKey)
        d.set(selectedFrequency,           forKey: "linear_onboarding_frequency")
        d.set(Array(selectedIdentities),   forKey: "linear_onboarding_identities")
        d.set(true,                        forKey: Self.completedKey)
    }

    // MARK: - Static

    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }
}
