//
//  QuotesTranslations.swift
//  Spike AI
//
//  Master index for bundled quote translations.
//  Each language is stored in its own file (QuotesLang_XX.swift).
//  Index matches QuotesData.all[i].
//

import Foundation

enum QuotesTranslations {
    static let all: [String: [String]] = [
        "es": QuotesLang_es.quotes,
        "fr": QuotesLang_fr.quotes,
        "de": QuotesLang_de.quotes,
        "pt": QuotesLang_pt.quotes,
        "ru": QuotesLang_ru.quotes,
        "uz": QuotesLang_uz.quotes,
        "zh": QuotesLang_zh.quotes,
        "ja": QuotesLang_ja.quotes,
        "ko": QuotesLang_ko.quotes,
        "ar": QuotesLang_ar.quotes,
        "hi": QuotesLang_hi.quotes,
        "tr": QuotesLang_tr.quotes,
        "it": QuotesLang_it.quotes,
        "pl": QuotesLang_pl.quotes,
        "uk": QuotesLang_uk.quotes,
        "nl": QuotesLang_nl.quotes,
        "sv": QuotesLang_sv.quotes,
        "id": QuotesLang_id.quotes,
        "vi": QuotesLang_vi.quotes,
        "kk": QuotesLang_kk.quotes,
        "ms": QuotesLang_ms.quotes,
        "tg": QuotesLang_tg.quotes,
    ]
}
