//
//  ShieldConfigurationExtension.swift
//  SpikeAIShield
//
//  Customizes the system shield screen that appears when a user
//  tries to open a shielded app.
//
//  FOCUS MODE: Friendly "Are you sure?" confirmation.
//               User can choose to open the app or go back.
//               This does NOT block — it just asks.
//
//  LOCK-IN MODE: Red focus block screen with no bypass.
//  ATHLETE MODE: Movement unlock screen with no shield bypass.
//
//  When all daily goals are completed, the goal-based modes (Focus and
//  Lock-in) show a congratulatory message and let the user through.
//  Athlete mode is movement-based, so it always asks for exercise to
//  unlock — regardless of goal completion.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// MARK: - Shield Localization Helper

/// Provides localized strings for the Shield extension.
/// Reads the user's chosen language from App Group UserDefaults
/// since the extension cannot import main-app modules.
struct ShieldLocalization {

    /// Reads the language fresh from App Group every time.
    private var language: String {
        UserDefaults(suiteName: "group.com.spikeai.spikeai")?
            .string(forKey: "spike_app_language") ?? "en"
    }

    subscript(key: String) -> String {
        let lang = language
        if let langDict = ShieldLocalization.translations[lang],
           let value = langDict[key] {
            return value
        }
        // Fallback to English
        return ShieldLocalization.translations["en"]?[key] ?? key
    }

    // MARK: Translation Dictionary

    static let translations: [String: [String: String]] = [

        // ── English ──────────────────────────────────────────────
        "en": [
            "shield_all_done_title": "You're all done!",
            "shield_all_done_subtitle": "You already finished your goals.\nEnjoy your free time — you earned it.",
            "shield_open_app": "Open app",
            "shield_uncompleted_goals": "You still have uncompleted goals",
            "shield_are_you_sure_subtitle": "Are you sure you want to open this app?",
            "shield_no_back_to_goals": "No, back to goals",
            "shield_are_you_sure": "Are you sure?",
            "shield_no_go_back": "No, go back",
            "shield_yes_open": "Yes, open app",
            "shield_blocked_title": "Blocked for Focus",
            "shield_blocked_goals": "You still have uncompleted goals.\nPlease finish them to unlock this app.",
            "shield_blocked_mode": "This app is blocked while Lock-in mode is active.\nReturn to Spike AI to change your mode.",
            "shield_close": "Close",
            "shield_open_camera_check": "Open Camera Check",
            "shield_exercise_title": "Exercise Required",
            "shield_exercise_subtitle": "Please go to Spike AI Athlete Mode and do a push-up or stand-up to open %@.\nEach rep gives 1 minute.",
            "shield_this_app": "this app"
        ],

        // ── Spanish ──────────────────────────────────────────────
        "es": [
            "shield_all_done_title": "¡Ya terminaste!",
            "shield_all_done_subtitle": "Ya completaste tus objetivos.\nDisfruta tu tiempo libre — te lo ganaste.",
            "shield_open_app": "Abrir app",
            "shield_uncompleted_goals": "Aún tienes objetivos sin completar",
            "shield_are_you_sure_subtitle": "¿Estás seguro de que quieres abrir esta app?",
            "shield_no_back_to_goals": "No, volver a los objetivos",
            "shield_are_you_sure": "¿Estás seguro?",
            "shield_no_go_back": "No, volver",
            "shield_yes_open": "Sí, abrir app",
            "shield_blocked_title": "Bloqueada por Enfoque",
            "shield_blocked_goals": "Aún tienes objetivos sin completar.\nComplétalos para desbloquear esta app.",
            "shield_blocked_mode": "Esta app está bloqueada mientras el modo Concentración está activo.\nVuelve a Spike AI para cambiar tu modo.",
            "shield_close": "Cerrar",
            "shield_open_camera_check": "Abrir verificación con cámara",
            "shield_exercise_title": "Ejercicio requerido",
            "shield_exercise_subtitle": "Ve al modo Atleta de Spike AI y haz una flexión o sentadilla para abrir %@.\nCada repetición te da 1 minuto.",
            "shield_this_app": "esta app"
        ],

        // ── French ───────────────────────────────────────────────
        "fr": [
            "shield_all_done_title": "Vous avez tout terminé !",
            "shield_all_done_subtitle": "Vous avez atteint tous vos objectifs.\nProfitez de votre temps libre — vous l'avez mérité.",
            "shield_open_app": "Ouvrir l'app",
            "shield_uncompleted_goals": "Vous avez encore des objectifs à compléter",
            "shield_are_you_sure_subtitle": "Êtes-vous sûr de vouloir ouvrir cette app ?",
            "shield_no_back_to_goals": "Non, retour aux objectifs",
            "shield_are_you_sure": "Êtes-vous sûr ?",
            "shield_no_go_back": "Non, revenir",
            "shield_yes_open": "Oui, ouvrir l'app",
            "shield_blocked_title": "Bloquée pour la concentration",
            "shield_blocked_goals": "Vous avez encore des objectifs à compléter.\nTerminez-les pour débloquer cette app.",
            "shield_blocked_mode": "Cette app est bloquée tant que le mode Concentration est actif.\nRetournez sur Spike AI pour changer de mode.",
            "shield_close": "Fermer",
            "shield_open_camera_check": "Ouvrir la vérification caméra",
            "shield_exercise_title": "Exercice requis",
            "shield_exercise_subtitle": "Allez dans le mode Athlète de Spike AI et faites une pompe ou un lever pour ouvrir %@.\nChaque répétition donne 1 minute.",
            "shield_this_app": "cette app"
        ],

        // ── German ───────────────────────────────────────────────
        "de": [
            "shield_all_done_title": "Alles erledigt!",
            "shield_all_done_subtitle": "Du hast alle Ziele erreicht.\nGenieße deine Freizeit — du hast sie dir verdient.",
            "shield_open_app": "App öffnen",
            "shield_uncompleted_goals": "Du hast noch unerledigte Ziele",
            "shield_are_you_sure_subtitle": "Bist du sicher, dass du diese App öffnen möchtest?",
            "shield_no_back_to_goals": "Nein, zurück zu den Zielen",
            "shield_are_you_sure": "Bist du sicher?",
            "shield_no_go_back": "Nein, zurück",
            "shield_yes_open": "Ja, App öffnen",
            "shield_blocked_title": "Für Fokus blockiert",
            "shield_blocked_goals": "Du hast noch unerledigte Ziele.\nSchließe sie ab, um diese App freizuschalten.",
            "shield_blocked_mode": "Diese App ist blockiert, solange der Konzentrationsmodus aktiv ist.\nKehre zu Spike AI zurück, um den Modus zu ändern.",
            "shield_close": "Schließen",
            "shield_open_camera_check": "Kamera-Check öffnen",
            "shield_exercise_title": "Übung erforderlich",
            "shield_exercise_subtitle": "Gehe zum Athlet-Modus in Spike AI und mache einen Liegestütz oder Aufsteher, um %@ zu öffnen.\nJede Wiederholung gibt 1 Minute.",
            "shield_this_app": "diese App"
        ],

        // ── Portuguese ───────────────────────────────────────────
        "pt": [
            "shield_all_done_title": "Tudo pronto!",
            "shield_all_done_subtitle": "Você já concluiu seus objetivos.\nAproveite seu tempo livre — você mereceu.",
            "shield_open_app": "Abrir app",
            "shield_uncompleted_goals": "Você ainda tem objetivos não concluídos",
            "shield_are_you_sure_subtitle": "Tem certeza de que quer abrir este app?",
            "shield_no_back_to_goals": "Não, voltar aos objetivos",
            "shield_are_you_sure": "Tem certeza?",
            "shield_no_go_back": "Não, voltar",
            "shield_yes_open": "Sim, abrir app",
            "shield_blocked_title": "Bloqueado para Foco",
            "shield_blocked_goals": "Você ainda tem objetivos não concluídos.\nConclua-os para desbloquear este app.",
            "shield_blocked_mode": "Este app está bloqueado enquanto o modo Concentração está ativo.\nVolte ao Spike AI para alterar seu modo.",
            "shield_close": "Fechar",
            "shield_open_camera_check": "Abrir verificação por câmera",
            "shield_exercise_title": "Exercício necessário",
            "shield_exercise_subtitle": "Vá ao modo Atleta do Spike AI e faça uma flexão ou agachamento para abrir %@.\nCada repetição dá 1 minuto.",
            "shield_this_app": "este app"
        ],

        // ── Russian ──────────────────────────────────────────────
        "ru": [
            "shield_all_done_title": "Всё готово!",
            "shield_all_done_subtitle": "Вы выполнили все задачи.\nНаслаждайтесь свободным временем — вы это заслужили.",
            "shield_open_app": "Открыть приложение",
            "shield_uncompleted_goals": "У вас ещё есть невыполненные задачи",
            "shield_are_you_sure_subtitle": "Вы уверены, что хотите открыть это приложение?",
            "shield_no_back_to_goals": "Нет, вернуться к задачам",
            "shield_are_you_sure": "Вы уверены?",
            "shield_no_go_back": "Нет, вернуться",
            "shield_yes_open": "Да, открыть",
            "shield_blocked_title": "Заблокировано для фокуса",
            "shield_blocked_goals": "У вас ещё есть невыполненные задачи.\nЗавершите их, чтобы разблокировать это приложение.",
            "shield_blocked_mode": "Это приложение заблокировано, пока активен режим концентрации.\nВернитесь в Spike AI, чтобы изменить режим.",
            "shield_close": "Закрыть",
            "shield_open_camera_check": "Открыть проверку камерой",
            "shield_exercise_title": "Требуется упражнение",
            "shield_exercise_subtitle": "Перейдите в режим «Атлет» в Spike AI и сделайте отжимание или приседание, чтобы открыть %@.\nКаждое повторение даёт 1 минуту.",
            "shield_this_app": "это приложение"
        ],

        // ── Uzbek ────────────────────────────────────────────────
        "uz": [
            "shield_all_done_title": "Hammasi tayyor!",
            "shield_all_done_subtitle": "Siz barcha maqsadlaringizni bajardingiz.\nBo'sh vaqtingizdan rohatlaning — buni qo'lga kiritdingiz.",
            "shield_open_app": "Ilovani ochish",
            "shield_uncompleted_goals": "Sizda hali bajarilmagan maqsadlar bor",
            "shield_are_you_sure_subtitle": "Bu ilovani ochmoqchi ekanligingizga ishonchingiz komilmi?",
            "shield_no_back_to_goals": "Yo'q, maqsadlarga qaytish",
            "shield_are_you_sure": "Ishonchingiz komilmi?",
            "shield_no_go_back": "Yo'q, orqaga",
            "shield_yes_open": "Ha, ilovani ochish",
            "shield_blocked_title": "Diqqat uchun bloklangan",
            "shield_blocked_goals": "Sizda hali tugatilmagan maqsadlar bor.\nUshbu ilovani ochish uchun ularni yakunlang.",
            "shield_blocked_mode": "Bu ilova konsentratsiya rejimi faol bo'lganda bloklangan.\nRejimni o'zgartirish uchun Spike AI ga qayting.",
            "shield_close": "Yopish",
            "shield_open_camera_check": "Kamera tekshiruvini ochish",
            "shield_exercise_title": "Mashq talab qilinadi",
            "shield_exercise_subtitle": "Spike AI Sportchi rejimiga o'ting va %@ ochish uchun bir marta otjimaniya yoki o'rnidan turish qiling.\nHar bir takrorlash 1 daqiqa beradi.",
            "shield_this_app": "bu ilovani"
        ],

        // ── Chinese (Simplified) ─────────────────────────────────
        "zh": [
            "shield_all_done_title": "全部完成！",
            "shield_all_done_subtitle": "你已经完成了所有目标。\n享受你的空闲时间吧——你值得拥有。",
            "shield_open_app": "打开应用",
            "shield_uncompleted_goals": "你还有未完成的目标",
            "shield_are_you_sure_subtitle": "你确定要打开这个应用吗？",
            "shield_no_back_to_goals": "不，返回目标",
            "shield_are_you_sure": "你确定吗？",
            "shield_no_go_back": "不，返回",
            "shield_yes_open": "是的，打开应用",
            "shield_blocked_title": "已为专注而屏蔽",
            "shield_blocked_goals": "你还有未完成的目标。\n请完成它们以解锁此应用。",
            "shield_blocked_mode": "在专注模式激活期间，此应用已被屏蔽。\n请返回 Spike AI 更改你的模式。",
            "shield_close": "关闭",
            "shield_open_camera_check": "打开摄像头检测",
            "shield_exercise_title": "需要运动",
            "shield_exercise_subtitle": "请前往 Spike AI 运动模式，做一个俯卧撑或起立来打开%@。\n每次重复可获得 1 分钟。",
            "shield_this_app": "此应用"
        ],

        // ── Japanese ─────────────────────────────────────────────
        "ja": [
            "shield_all_done_title": "すべて完了！",
            "shield_all_done_subtitle": "目標をすべて達成しました。\n自由な時間を楽しんでください — あなたはそれに値します。",
            "shield_open_app": "アプリを開く",
            "shield_uncompleted_goals": "未完了の目標があります",
            "shield_are_you_sure_subtitle": "このアプリを開いてもよろしいですか？",
            "shield_no_back_to_goals": "いいえ、目標に戻る",
            "shield_are_you_sure": "よろしいですか？",
            "shield_no_go_back": "いいえ、戻る",
            "shield_yes_open": "はい、開く",
            "shield_blocked_title": "集中のためブロック中",
            "shield_blocked_goals": "まだ完了していない目標があります。\nこのアプリのロックを解除するには目標を完了してください。",
            "shield_blocked_mode": "集中モードが有効な間、このアプリはブロックされています。\nSpike AI に戻ってモードを変更してください。",
            "shield_close": "閉じる",
            "shield_open_camera_check": "カメラチェックを開く",
            "shield_exercise_title": "運動が必要です",
            "shield_exercise_subtitle": "Spike AI のスウェットモードに移動して、腕立て伏せまたはスタンドアップをして%@を開いてください。\n1回ごとに1分間使えます。",
            "shield_this_app": "このアプリ"
        ],

        // ── Korean ───────────────────────────────────────────────
        "ko": [
            "shield_all_done_title": "모두 완료했어요!",
            "shield_all_done_subtitle": "모든 목표를 달성했습니다.\n자유 시간을 즐기세요 — 충분히 자격이 있어요.",
            "shield_open_app": "앱 열기",
            "shield_uncompleted_goals": "아직 완료하지 않은 목표가 있어요",
            "shield_are_you_sure_subtitle": "이 앱을 열겠습니까?",
            "shield_no_back_to_goals": "아니요, 목표로 돌아가기",
            "shield_are_you_sure": "확실합니까?",
            "shield_no_go_back": "아니요, 돌아가기",
            "shield_yes_open": "네, 앱 열기",
            "shield_blocked_title": "집중을 위해 차단됨",
            "shield_blocked_goals": "아직 완료하지 않은 목표가 있습니다.\n이 앱을 잠금 해제하려면 목표를 완료하세요.",
            "shield_blocked_mode": "집중 모드가 활성화된 동안 이 앱은 차단되어 있습니다.\nSpike AI로 돌아가서 모드를 변경하세요.",
            "shield_close": "닫기",
            "shield_open_camera_check": "카메라 확인 열기",
            "shield_exercise_title": "운동이 필요합니다",
            "shield_exercise_subtitle": "Spike AI 스웨트 모드로 이동하여 팔굽혀펴기 또는 스쿼트를 해서 %@을(를) 여세요.\n1회 반복당 1분이 주어집니다.",
            "shield_this_app": "이 앱"
        ],

        // ── Arabic ───────────────────────────────────────────────
        "ar": [
            "shield_all_done_title": "أنجزت كل شيء!",
            "shield_all_done_subtitle": "لقد أكملت جميع أهدافك.\nاستمتع بوقت فراغك — أنت تستحق ذلك.",
            "shield_open_app": "فتح التطبيق",
            "shield_uncompleted_goals": "لا يزال لديك أهداف لم تكتمل",
            "shield_are_you_sure_subtitle": "هل أنت متأكد أنك تريد فتح هذا التطبيق؟",
            "shield_no_back_to_goals": "لا، العودة إلى الأهداف",
            "shield_are_you_sure": "هل أنت متأكد؟",
            "shield_no_go_back": "لا، الرجوع",
            "shield_yes_open": "نعم، افتح التطبيق",
            "shield_blocked_title": "محظور للتركيز",
            "shield_blocked_goals": "لا تزال لديك أهداف غير مكتملة.\nأكملها لإلغاء قفل هذا التطبيق.",
            "shield_blocked_mode": "هذا التطبيق محظور أثناء تفعيل وضع التركيز.\nعد إلى Spike AI لتغيير الوضع.",
            "shield_close": "إغلاق",
            "shield_open_camera_check": "فتح فحص الكاميرا",
            "shield_exercise_title": "التمرين مطلوب",
            "shield_exercise_subtitle": "انتقل إلى وضع التمرين في Spike AI وقم بتمرين ضغط أو وقوف لفتح %@.\nكل تكرار يمنحك دقيقة واحدة.",
            "shield_this_app": "هذا التطبيق"
        ],

        // ── Hindi ────────────────────────────────────────────────
        "hi": [
            "shield_all_done_title": "सब पूरा हो गया!",
            "shield_all_done_subtitle": "आपने अपने सभी लक्ष्य पूरे कर लिए।\nअपने खाली समय का आनंद लें — आपने इसे अर्जित किया है।",
            "shield_open_app": "ऐप खोलें",
            "shield_uncompleted_goals": "आपके अभी भी अधूरे लक्ष्य हैं",
            "shield_are_you_sure_subtitle": "क्या आप वाकई इस ऐप को खोलना चाहते हैं?",
            "shield_no_back_to_goals": "नहीं, लक्ष्यों पर वापस जाएं",
            "shield_are_you_sure": "क्या आप निश्चित हैं?",
            "shield_no_go_back": "नहीं, वापस जाएं",
            "shield_yes_open": "हाँ, ऐप खोलें",
            "shield_blocked_title": "फ़ोकस के लिए ब्लॉक किया गया",
            "shield_blocked_goals": "आपके अभी भी अधूरे लक्ष्य हैं।\nइस ऐप को अनलॉक करने के लिए उन्हें पूरा करें।",
            "shield_blocked_mode": "एकाग्रता मोड सक्रिय होने पर यह ऐप ब्लॉक है।\nमोड बदलने के लिए Spike AI पर लौटें।",
            "shield_close": "बंद करें",
            "shield_open_camera_check": "कैमरा जाँच खोलें",
            "shield_exercise_title": "व्यायाम आवश्यक है",
            "shield_exercise_subtitle": "Spike AI स्वेट मोड में जाएं और %@ खोलने के लिए एक पुश-अप या स्टैंड-अप करें।\nहर दोहराव 1 मिनट देता है।",
            "shield_this_app": "यह ऐप"
        ],

        // ── Turkish ──────────────────────────────────────────────
        "tr": [
            "shield_all_done_title": "Her şey tamam!",
            "shield_all_done_subtitle": "Tüm hedeflerini tamamladın.\nBoş zamanının tadını çıkar — hak ettin.",
            "shield_open_app": "Uygulamayı aç",
            "shield_uncompleted_goals": "Hâlâ tamamlanmamış hedeflerin var",
            "shield_are_you_sure_subtitle": "Bu uygulamayı açmak istediğinden emin misin?",
            "shield_no_back_to_goals": "Hayır, hedeflere dön",
            "shield_are_you_sure": "Emin misin?",
            "shield_no_go_back": "Hayır, geri dön",
            "shield_yes_open": "Evet, uygulamayı aç",
            "shield_blocked_title": "Odaklanma için engellendi",
            "shield_blocked_goals": "Hâlâ tamamlanmamış hedeflerin var.\nBu uygulamanın kilidini açmak için onları tamamla.",
            "shield_blocked_mode": "Odaklanma modu etkinken bu uygulama engellenmiştir.\nModunu değiştirmek için Spike AI'a geri dön.",
            "shield_close": "Kapat",
            "shield_open_camera_check": "Kamera kontrolünü aç",
            "shield_exercise_title": "Egzersiz gerekli",
            "shield_exercise_subtitle": "Spike AI Ter Modu'na git ve %@ açmak için bir şınav veya kalkış yap.\nHer tekrar 1 dakika verir.",
            "shield_this_app": "bu uygulamayı"
        ],

        // ── Italian ──────────────────────────────────────────────
        "it": [
            "shield_all_done_title": "Hai finito tutto!",
            "shield_all_done_subtitle": "Hai completato tutti i tuoi obiettivi.\nGoditi il tempo libero — te lo sei meritato.",
            "shield_open_app": "Apri app",
            "shield_uncompleted_goals": "Hai ancora obiettivi da completare",
            "shield_are_you_sure_subtitle": "Sei sicuro di voler aprire questa app?",
            "shield_no_back_to_goals": "No, torna agli obiettivi",
            "shield_are_you_sure": "Sei sicuro?",
            "shield_no_go_back": "No, torna indietro",
            "shield_yes_open": "Sì, apri l'app",
            "shield_blocked_title": "Bloccata per la concentrazione",
            "shield_blocked_goals": "Hai ancora obiettivi non completati.\nCompletali per sbloccare questa app.",
            "shield_blocked_mode": "Questa app è bloccata mentre la modalità Concentrazione è attiva.\nTorna su Spike AI per cambiare modalità.",
            "shield_close": "Chiudi",
            "shield_open_camera_check": "Apri verifica fotocamera",
            "shield_exercise_title": "Esercizio richiesto",
            "shield_exercise_subtitle": "Vai alla modalità Atleta di Spike AI e fai una flessione o un alzata per aprire %@.\nOgni ripetizione dà 1 minuto.",
            "shield_this_app": "questa app"
        ],

        // ── Polish ───────────────────────────────────────────────
        "pl": [
            "shield_all_done_title": "Wszystko gotowe!",
            "shield_all_done_subtitle": "Ukończyłeś wszystkie swoje cele.\nCiesz się wolnym czasem — zasłużyłeś na to.",
            "shield_open_app": "Otwórz aplikację",
            "shield_uncompleted_goals": "Masz jeszcze nieukończone cele",
            "shield_are_you_sure_subtitle": "Czy na pewno chcesz otworzyć tę aplikację?",
            "shield_no_back_to_goals": "Nie, wróć do celów",
            "shield_are_you_sure": "Czy jesteś pewien?",
            "shield_no_go_back": "Nie, cofnij",
            "shield_yes_open": "Tak, otwórz aplikację",
            "shield_blocked_title": "Zablokowane dla skupienia",
            "shield_blocked_goals": "Masz jeszcze nieukończone cele.\nUkończ je, aby odblokować tę aplikację.",
            "shield_blocked_mode": "Ta aplikacja jest zablokowana, gdy tryb skupienia jest aktywny.\nWróć do Spike AI, aby zmienić tryb.",
            "shield_close": "Zamknij",
            "shield_open_camera_check": "Otwórz sprawdzanie kamerą",
            "shield_exercise_title": "Wymagane ćwiczenie",
            "shield_exercise_subtitle": "Przejdź do trybu Sportowca w Spike AI i zrób pompkę lub przysiad, aby otworzyć %@.\nKażde powtórzenie daje 1 minutę.",
            "shield_this_app": "tę aplikację"
        ],

        // ── Ukrainian ───────────────────────────────────────────
        "uk": [
            "shield_all_done_title": "Усе готово!",
            "shield_all_done_subtitle": "Ви виконали всі свої цілі.\nНасолоджуйтесь вільним часом — ви це заслужили.",
            "shield_open_app": "Відкрити додаток",
            "shield_uncompleted_goals": "У вас ще є невиконані цілі",
            "shield_are_you_sure_subtitle": "Ви впевнені, що хочете відкрити цей додаток?",
            "shield_no_back_to_goals": "Ні, повернутися до цілей",
            "shield_are_you_sure": "Ви впевнені?",
            "shield_no_go_back": "Ні, повернутися",
            "shield_yes_open": "Так, відкрити",
            "shield_blocked_title": "Заблоковано для фокусу",
            "shield_blocked_goals": "У вас ще є невиконані цілі.\nЗавершіть їх, щоб розблокувати цей застосунок.",
            "shield_blocked_mode": "Цей додаток заблоковано, поки режим концентрації активний.\nПоверніться до Spike AI, щоб змінити режим.",
            "shield_close": "Закрити",
            "shield_open_camera_check": "Відкрити перевірку камерою",
            "shield_exercise_title": "Потрібна вправа",
            "shield_exercise_subtitle": "Перейдіть до режиму «Атлет» у Spike AI та зробіть віджимання або присідання, щоб відкрити %@.\nКожне повторення дає 1 хвилину.",
            "shield_this_app": "цей додаток"
        ],

        // ── Dutch ────────────────────────────────────────────────
        "nl": [
            "shield_all_done_title": "Je bent helemaal klaar!",
            "shield_all_done_subtitle": "Je hebt al je doelen behaald.\nGeniet van je vrije tijd — je hebt het verdiend.",
            "shield_open_app": "Open app",
            "shield_uncompleted_goals": "Je hebt nog onvoltooide doelen",
            "shield_are_you_sure_subtitle": "Weet je zeker dat je deze app wilt openen?",
            "shield_no_back_to_goals": "Nee, terug naar doelen",
            "shield_are_you_sure": "Weet je het zeker?",
            "shield_no_go_back": "Nee, ga terug",
            "shield_yes_open": "Ja, open app",
            "shield_blocked_title": "Geblokkeerd voor focus",
            "shield_blocked_goals": "Je hebt nog niet-voltooide doelen.\nVoltooi ze om deze app te ontgrendelen.",
            "shield_blocked_mode": "Deze app is geblokkeerd terwijl de focusmodus actief is.\nGa terug naar Spike AI om je modus te wijzigen.",
            "shield_close": "Sluiten",
            "shield_open_camera_check": "Cameracontrole openen",
            "shield_exercise_title": "Oefening vereist",
            "shield_exercise_subtitle": "Ga naar de Atleetmodus in Spike AI en doe een push-up of sta op om %@ te openen.\nElke herhaling geeft 1 minuut.",
            "shield_this_app": "deze app"
        ],

        // ── Swedish ──────────────────────────────────────────────
        "sv": [
            "shield_all_done_title": "Du är klar!",
            "shield_all_done_subtitle": "Du har slutfört alla dina mål.\nNjut av din fritid — du har förtjänat det.",
            "shield_open_app": "Öppna app",
            "shield_uncompleted_goals": "Du har fortfarande oavslutade mål",
            "shield_are_you_sure_subtitle": "Är du säker på att du vill öppna den här appen?",
            "shield_no_back_to_goals": "Nej, tillbaka till målen",
            "shield_are_you_sure": "Är du säker?",
            "shield_no_go_back": "Nej, gå tillbaka",
            "shield_yes_open": "Ja, öppna appen",
            "shield_blocked_title": "Blockerad för fokus",
            "shield_blocked_goals": "Du har fortfarande oavslutade mål.\nSlutför dem för att låsa upp den här appen.",
            "shield_blocked_mode": "Den här appen är blockerad medan fokusläget är aktivt.\nGå tillbaka till Spike AI för att ändra läge.",
            "shield_close": "Stäng",
            "shield_open_camera_check": "Öppna kamerakontroll",
            "shield_exercise_title": "Träning krävs",
            "shield_exercise_subtitle": "Gå till Atletläget i Spike AI och gör en armhävning eller uppresning för att öppna %@.\nVarje repetition ger 1 minut.",
            "shield_this_app": "den här appen"
        ],

        // ── Indonesian ──────────────────────────────────────────
        "id": [
            "shield_all_done_title": "Semuanya selesai!",
            "shield_all_done_subtitle": "Kamu sudah menyelesaikan semua tujuanmu.\nNikmati waktu luangmu — kamu pantas mendapatkannya.",
            "shield_open_app": "Buka aplikasi",
            "shield_uncompleted_goals": "Kamu masih punya tujuan yang belum selesai",
            "shield_are_you_sure_subtitle": "Apakah kamu yakin ingin membuka aplikasi ini?",
            "shield_no_back_to_goals": "Tidak, kembali ke tujuan",
            "shield_are_you_sure": "Apakah kamu yakin?",
            "shield_no_go_back": "Tidak, kembali",
            "shield_yes_open": "Ya, buka aplikasi",
            "shield_blocked_title": "Diblokir untuk Fokus",
            "shield_blocked_goals": "Kamu masih punya tujuan yang belum selesai.\nSelesaikan untuk membuka aplikasi ini.",
            "shield_blocked_mode": "Aplikasi ini diblokir selama mode Fokus aktif.\nKembali ke Spike AI untuk mengubah mode.",
            "shield_close": "Tutup",
            "shield_open_camera_check": "Buka pemeriksaan kamera",
            "shield_exercise_title": "Olahraga diperlukan",
            "shield_exercise_subtitle": "Buka mode Atlet di Spike AI dan lakukan push-up atau berdiri untuk membuka %@.\nSetiap pengulangan memberi 1 menit.",
            "shield_this_app": "aplikasi ini"
        ],

        // ── Vietnamese ───────────────────────────────────────────
        "vi": [
            "shield_all_done_title": "Bạn đã hoàn thành!",
            "shield_all_done_subtitle": "Bạn đã hoàn thành tất cả mục tiêu.\nHãy tận hưởng thời gian rảnh — bạn xứng đáng.",
            "shield_open_app": "Mở ứng dụng",
            "shield_uncompleted_goals": "Bạn vẫn còn mục tiêu chưa hoàn thành",
            "shield_are_you_sure_subtitle": "Bạn có chắc muốn mở ứng dụng này không?",
            "shield_no_back_to_goals": "Không, quay lại mục tiêu",
            "shield_are_you_sure": "Bạn có chắc không?",
            "shield_no_go_back": "Không, quay lại",
            "shield_yes_open": "Có, mở ứng dụng",
            "shield_blocked_title": "Đã chặn để tập trung",
            "shield_blocked_goals": "Bạn vẫn còn mục tiêu chưa hoàn thành.\nHãy hoàn thành chúng để mở khóa ứng dụng này.",
            "shield_blocked_mode": "Ứng dụng này bị chặn khi chế độ Tập trung đang hoạt động.\nQuay lại Spike AI để thay đổi chế độ.",
            "shield_close": "Đóng",
            "shield_open_camera_check": "Mở kiểm tra camera",
            "shield_exercise_title": "Yêu cầu tập thể dục",
            "shield_exercise_subtitle": "Hãy vào chế độ Vận động viên của Spike AI và thực hiện một lần chống đẩy hoặc đứng lên để mở %@.\nMỗi lần lặp cho bạn 1 phút.",
            "shield_this_app": "ứng dụng này"
        ],

        // ── Kazakh ───────────────────────────────────────────────
        "kk": [
            "shield_all_done_title": "Бәрі дайын!",
            "shield_all_done_subtitle": "Сіз барлық мақсаттарыңызды орындадыңыз.\nБос уақытыңызды рахаттана өткізіңіз — сіз оны тауып алдыңыз.",
            "shield_open_app": "Қолданбаны ашу",
            "shield_uncompleted_goals": "Сізде әлі аяқталмаған мақсаттар бар",
            "shield_are_you_sure_subtitle": "Бұл қолданбаны ашқыңыз келетініне сенімдісіз бе?",
            "shield_no_back_to_goals": "Жоқ, мақсаттарға оралу",
            "shield_are_you_sure": "Сенімдісіз бе?",
            "shield_no_go_back": "Жоқ, артқа қайту",
            "shield_yes_open": "Иә, қолданбаны ашу",
            "shield_blocked_title": "Назар аудару үшін бұғатталған",
            "shield_blocked_goals": "Сізде әлі орындалмаған мақсаттар бар.\nОсы қолданбаны ашу үшін оларды аяқтаңыз.",
            "shield_blocked_mode": "Бұл қолданба шоғырлану режимі белсенді кезде бұғатталған.\nРежимді өзгерту үшін Spike AI-ға оралыңыз.",
            "shield_close": "Жабу",
            "shield_open_camera_check": "Камера тексеруін ашу",
            "shield_exercise_title": "Жаттығу қажет",
            "shield_exercise_subtitle": "Spike AI Sportşy режиміне өтіп, %@ ашу үшін бір рет қол жаттығуы немесе тұрып-отыру жасаңыз.\nӘр қайталау 1 минут береді.",
            "shield_this_app": "бұл қолданбаны"
        ],

        // ── Malay ──────────────────────────────────────────────
        "ms": [
            "shield_all_done_title": "Semuanya siap!",
            "shield_all_done_subtitle": "Anda sudah menyelesaikan semua matlamat.\nNikmati masa lapang anda — anda layak mendapatnya.",
            "shield_open_app": "Buka aplikasi",
            "shield_uncompleted_goals": "Anda masih ada matlamat yang belum selesai",
            "shield_are_you_sure_subtitle": "Adakah anda pasti mahu membuka aplikasi ini?",
            "shield_no_back_to_goals": "Tidak, kembali ke matlamat",
            "shield_are_you_sure": "Adakah anda pasti?",
            "shield_no_go_back": "Tidak, kembali",
            "shield_yes_open": "Ya, buka aplikasi",
            "shield_blocked_title": "Disekat untuk Fokus",
            "shield_blocked_goals": "Anda masih mempunyai matlamat yang belum selesai.\nSelesaikannya untuk membuka kunci aplikasi ini.",
            "shield_blocked_mode": "Aplikasi ini disekat semasa mod Fokus aktif.\nKembali ke Spike AI untuk menukar mod anda.",
            "shield_close": "Tutup",
            "shield_open_camera_check": "Buka semakan kamera",
            "shield_exercise_title": "Senaman diperlukan",
            "shield_exercise_subtitle": "Pergi ke Mod Atlet Spike AI dan lakukan tekan tubi atau bangun berdiri untuk membuka %@.\nSetiap ulangan memberi 1 minit.",
            "shield_this_app": "aplikasi ini"
        ],

        // ── Tajik ──────────────────────────────────────────────
        "tg": [
            "shield_all_done_title": "Ҳама чиз тайёр!",
            "shield_all_done_subtitle": "Шумо ҳамаи ҳадафҳои худро иҷро кардед.\nАз вақти холии худ лаззат баред — шумо онро сазовор ҳастед.",
            "shield_open_app": "Барномаро кушоед",
            "shield_uncompleted_goals": "Шумо ҳанӯз ҳадафҳои иҷро нашуда доред",
            "shield_are_you_sure_subtitle": "Шумо мутмаин ҳастед, ки мехоҳед ин барномаро кушоед?",
            "shield_no_back_to_goals": "Не, бозгашт ба ҳадафҳо",
            "shield_are_you_sure": "Шумо мутмаин ҳастед?",
            "shield_no_go_back": "Не, бозгашт",
            "shield_yes_open": "Ҳа, барномаро кушоед",
            "shield_blocked_title": "Барои тамаркуз маҳдуд шудааст",
            "shield_blocked_goals": "Шумо ҳанӯз ҳадафҳои иҷронашуда доред.\nБарои кушодани ин барнома онҳоро ба анҷом расонед.",
            "shield_blocked_mode": "Ин барнома ҳангоми фаъол будани режими тамаркуз маҳдуд аст.\nБарои иваз кардани режим ба Spike AI баргардед.",
            "shield_close": "Пӯшидан",
            "shield_open_camera_check": "Санҷиши камераро кушодан",
            "shield_exercise_title": "Машқ лозим аст",
            "shield_exercise_subtitle": "Ба режими Варзишгар дар Spike AI равед ва барои кушодани %@ як бор синабаланд ё истодашавӣ кунед.\nҲар такрор 1 дақиқа медиҳад.",
            "shield_this_app": "ин барнома"
        ]
    ]
}

// MARK: - Shield Configuration Data Source

@objc(SpikeAIShieldConfig)
class SpikeAIShieldConfig: ShieldConfigurationDataSource {

    private var loc: ShieldLocalization { ShieldLocalization() }

    private var defaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: "group.com.spikeai.spikeai")
        if let defaults,
           defaults.dictionaryRepresentation().isEmpty,
           let legacy = UserDefaults(suiteName: "group.Mirzo-Ulugbek-Fazilov.Linear")
        {
            for (key, value) in legacy.dictionaryRepresentation() {
                defaults.set(value, forKey: key)
            }
        }
        return defaults
    }

    private var currentMode: String {
        defaults?.string(forKey: "linear_focus_mode") ?? "medium"
    }

    private var allGoalsCompleted: Bool {
        let completed = defaults?.integer(forKey: "linear_goals_completed") ?? 0
        let total = defaults?.integer(forKey: "linear_goals_total") ?? 0
        // No tasks = nothing to complete → treat as "all done"
        return total == 0 || completed >= total
    }

    private var hasUncompletedGoals: Bool {
        let completed = defaults?.integer(forKey: "linear_goals_completed") ?? 0
        let total = defaults?.integer(forKey: "linear_goals_total") ?? 0
        return total > 0 && completed < total
    }

    /// Spike AI logo loaded from the extension's asset catalog.
    private var spikeLogo: UIImage? {
        UIImage(named: "SpikeLogo")
    }

    // MARK: Application Shield

    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        shieldForMode(name: application.localizedDisplayName)
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        shieldForMode(name: application.localizedDisplayName)
    }

    // MARK: Web Domain Shield

    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        shieldForMode(name: webDomain.domain)
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        shieldForMode(name: webDomain.domain)
    }

    // MARK: Shield Router

    private func shieldForMode(name: String?) -> ShieldConfiguration {
        // Athlete (sweat) mode is movement-based, not goal-based — apps are
        // always unlocked with exercise, so it must keep asking for reps even
        // after every goal is finished. Handle it before the goals check.
        if currentMode == "sweat" {
            return sweatConfig(name: name)
        }

        // Focus / Lock-in are goal-based: once all goals are done, show the
        // congratulatory pass-through and let the user through.
        if allGoalsCompleted {
            return goalsCompletedConfig()
        }

        switch currentMode {
        case "hard":
            return hardConfig(name: name)
        default:
            return mediumConfig(name: name)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── All Goals Completed ──────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func goalsCompletedConfig() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.95),
            icon: spikeLogo,
            title: ShieldConfiguration.Label(
                text: loc["shield_all_done_title"],
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: loc["shield_all_done_subtitle"],
                color: UIColor.white.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: loc["shield_open_app"],
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.3, green: 0.75, blue: 0.45, alpha: 1.0),
            secondaryButtonLabel: nil
        )
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Focus: "Are you sure?" ────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func mediumConfig(name: String?) -> ShieldConfiguration {
        let titleText: String
        let subtitleText: String
        let secondaryText: String

        if hasUncompletedGoals {
            titleText = loc["shield_uncompleted_goals"]
            subtitleText = loc["shield_are_you_sure_subtitle"]
            secondaryText = loc["shield_no_back_to_goals"]
        } else {
            titleText = loc["shield_are_you_sure"]
            subtitleText = loc["shield_are_you_sure_subtitle"]
            secondaryText = loc["shield_no_go_back"]
        }

        return ShieldConfiguration(
            // The light material adds a white veil that always washes orange out
            // to a pale peach ("too bright"). The dark material instead deepens it
            // — paired with a saturated, red-shifted orange this lands on a rich,
            // professional deep orange (not pale, not muddy brown).
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: brightOrange,
            icon: spikeLogo,
            title: ShieldConfiguration.Label(
                text: titleText,
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor.white.withAlphaComponent(0.92)
            ),
            // "Yes, open app" — primary (top) RED-filled button, white text.
            primaryButtonLabel: ShieldConfiguration.Label(
                text: loc["shield_yes_open"],
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.88, green: 0.20, blue: 0.16, alpha: 1.0),
            // "No, back to goals" — secondary (bottom) button, white text.
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: secondaryText,
                color: .white
            )
        )
    }

    /// Deep, saturated orange for the Focus shield. Red-shifted with zero blue so
    /// the dark material deepens it into a rich burnt orange (rather than washing
    /// to pale peach or muddying to brown).
    private var brightOrange: UIColor {
        UIColor(red: 1.0, green: 0.50, blue: 0.0, alpha: 1.0)
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Lock-in: Blocked ──────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func hardConfig(name: String?) -> ShieldConfiguration {
        let subtitleText: String
        if hasUncompletedGoals {
            subtitleText = loc["shield_blocked_goals"]
        } else {
            subtitleText = loc["shield_blocked_mode"]
        }

        return ShieldConfiguration(
            // `.dark` darkened the red into a dull maroon. The ultra-thin DARK
            // material renders saturated colors vividly (same as the teal Athlete
            // shield), so a bright full-opacity red now reads as a true bright red.
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 1.0, green: 0.19, blue: 0.16, alpha: 1.0),
            icon: spikeLogo,
            title: ShieldConfiguration.Label(
                text: loc["shield_blocked_title"],
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor.white.withAlphaComponent(0.85)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: loc["shield_close"],
                // Deep, fully-saturated red so it reads as a strong, visible red
                // on the white pill (the lighter red rendered as faded salmon).
                color: UIColor(red: 0.84, green: 0.0, blue: 0.0, alpha: 1.0)
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Sweat: Movement Unlock ─────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func sweatConfig(name: String?) -> ShieldConfiguration {
        let appName = name ?? loc["shield_this_app"]
        let subtitleText = String(format: loc["shield_exercise_subtitle"], appName)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.systemTeal.withAlphaComponent(0.96),
            icon: spikeLogo,
            title: ShieldConfiguration.Label(
                text: loc["shield_exercise_title"],
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor.white.withAlphaComponent(0.82)
            ),
            // "Close" — single white-filled button. Dark blue text (instead of
            // light teal) for strong, professional contrast on the white pill.
            primaryButtonLabel: ShieldConfiguration.Label(
                text: loc["shield_close"],
                color: UIColor(red: 0.05, green: 0.27, blue: 0.50, alpha: 1.0)
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }
}
