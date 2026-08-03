//
//  AppLocalization.swift
//  Spike AI
//
//  Runtime localization system supporting 24 languages.
//  All UI strings are translated and served via an @Observable manager.
//

import Foundation
import SwiftUI

// MARK: - Localization Manager            

@MainActor @Observable
final class AppLocalization {

    var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "spike_app_language")
            // Also save to App Group so Shield extension can read it
            UserDefaults(suiteName: "group.com.spikeai.spikeai")?.set(language, forKey: "spike_app_language")
        }
    }

    init() {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? {
            let device = Locale.current.language.languageCode?.identifier ?? "en"
            return Self.all.keys.contains(device) ? device : "en"
        }()
        language = lang
        // Sync to App Group on init so Shield extension always has the current language
        UserDefaults(suiteName: "group.com.spikeai.spikeai")?.set(lang, forKey: "spike_app_language")
    }

    subscript(_ key: String) -> String {
        Self.all[language]?[key] ?? Self.all["en"]?[key] ?? key
    }

    /// Static lookup for non-view contexts (notifications, background tasks).
    /// Reads the current language from UserDefaults.
    static func string(_ key: String) -> String {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
        return all[lang]?[key] ?? all["en"]?[key] ?? key
    }

    // MARK: - All Translations

    private static let all: [String: [String: String]] = [
        "en": en, "es": es, "fr": fr, "de": de, "pt": pt,
        "ru": ru, "uz": uz, "zh": zh, "ja": ja, "ko": ko,
        "ar": ar, "hi": hi, "tr": tr, "it": it, "pl": pl,
        "uk": uk, "nl": nl, "sv": sv, "id": id_,
        "vi": vi, "kk": kk, "ms": ms, "tg": tg,
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - English (base)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let en: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "About focus modes",
        "no_active_goals_title": "No active goals",
        "no_active_goals_btn": "Got it",
        "no_active_goals_msg": "Focus and Lock-in only run while you have an uncompleted goal to work toward. Add a goal — or reactivate one — then start your session.",
        // Tab bar
        "tab_home": "Home",
        "tab_progress": "Progress",
        "tab_mode": "Mode",
        "tab_profile": "Profile",

        // Home
        "today": "Today",
        "tomorrow": "Tomorrow",
        "yesterday": "Yesterday",
        "back_to_today": "Back to Today",
        "add_first_task": "Tap + to add your first task",
        "no_tasks_this_day": "No tasks on this day",
        "new_task": "New Task",
        "what_to_do": "What do you need to do?",
        "task": "Task",
        "schedule": "Schedule",
        "pick_date_hint": "Pick any future date — today, next week, or months ahead.",
        "priority": "Priority",
        "low": "Low",
        "medium": "Medium",
        "high": "High",
        "notification": "Notification",
        "silent_push": "Silent push notification",
        "notification_desc": "Sends a one-time push notification at the scheduled time. It appears quietly on your Lock Screen and Notification Center.",
        "reminder": "Reminder",
        "alarm_sound": "Alarm with sound & vibration",
        "reminder_desc": "Works like an alarm — a special sound will play and your phone will vibrate continuously until you press the Dismiss button on screen. Great for meetings and deadlines.",
        "cancel": "Cancel",
        "add": "Add",
        "edit": "Edit",
        "delete": "Delete",
        "jump_to_date": "Jump to Date",
        "done": "Done",
        "task_limit": "You've reached the 25-task limit for this date.",
        "time": "Time",
        "date": "Date",
        "select_date": "Select Date",

        // Alarm
        "reminder_title": "Reminder",
        "dismiss": "Dismiss",

        // Progress
        "daily_progress": "Daily Progress",
        "streaks": "streaks",
        "focus_days": "focus days",
        "consistency": "consistency",
        "set_first_goal": "Set your first goal for today",
        "all_goals_completed": "All daily goals completed",
        "goals_completed": "of",
        "daily_goals_completed": "daily goals completed",
        "daily_goals": "Daily Goals",
        "remaining": "remaining",
        "no_goals_planned": "No goals planned",
        "complete_to_focus": "Complete every task to mark today as a focus day.",
        "add_task_to_start": "Add a task from Home to start tracking daily goals.",
        "daily_plan_complete": "Daily plan complete",
        "ai_weekly_summary": "AI Weekly Summary",
        "creating_summary": "Creating your weekly summary...",
        "generate_summary": "Generate Summary",
        "refresh_summary": "Refresh Summary",
        "first_summary_coming": "Your first AI weekly summary is on the way.",
        "first_summary_desc": "It will be ready on %@ at 9 PM. It includes insights about your progress, missed tasks, and the best focus mode for you.",
        "next_update": "Next update: %@",
        "weekly_recap": "Your weekly recap of focus days, tasks, and productivity trends is ready.",
        "screen_time_7day": "7-Day Screen Time",
        "best_streak": "Best Streak",
        "days": "days",
        "milestones": "Milestones",
        "milestone_unlocked": "Milestone Unlocked",
        "continue_btn": "Continue",
        "history_calendar": "History Calendar",
        "monthly_scope_btn": "Monthly",
        "yearly_scope_btn": "Yearly",
        "mode_used": "Mode Used",
        "completed": "Completed",
        "not_completed": "Not Completed",
        "no_completed_tasks": "No completed tasks recorded for this day.",
        "everything_completed": "Everything was completed.",
        "no_missed_tasks": "No missed tasks recorded for this day.",
        "streak_day": "Streak Day",
        "missed_day": "Missed Day",
        "first_name": "First Name",
        "last_name": "Last Name",
        "avatar_color": "Avatar Color",
        "whats_your_name": "What's your name?",
        "name_helps": "This helps personalize your experience.",
        "name_save_failed": "We couldn't save your name. Check your connection and try again.",
        "continue_btn_name": "Continue",
        "restoring_session": "Restoring your session...",
        "wins": "Wins",
        "next_action": "Next Action",
        "average": "average",
        "todays_completion": "Today's completion",
        "streaks_this_month": "streaks this month",
        "streak_days": "streak days",
        "non_streak_days": "non-streak days",
        "monthly_streak_summary": "%d streaks this month • %d streak days, %d non-streak days",
        "duration_average": "%@ average",

        // Profile
        "personal_details": "Personal Details",
        "personal_info": "Personal Information",
        "update_email_name": "Update your email and full name.",
        "and_username": "and username",
        "invite_friends": "Invite Friends",
        "refer_friend_title": "Refer a friend and earn $10",
        "refer_friend_desc": "Earn $10 per friend that signs up with your promo code.",
        "upgrade_family_plan": "Upgrade to Family Plan",
        "goals_tracking": "Goals & Tracking",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Edit Nutrition Goals",
        "tracking_reminders": "Tracking Reminders",
        "email_not_editable": "Your email is connected to your login and cannot be edited here.",
        "theme": "Theme",
        "theme_desc": "Use system appearance or choose a fixed light/dark mode.",
        "appearance": "Appearance",
        "appearance_desc": "Choose light, dark, or system appearance",
        "live_activity_profile_desc": "Show your daily progress on your Lock Screen and Dynamic Island",
        "system": "System",
        "light": "Light",
        "dark": "Dark",
        "live_activity": "Live Activity",
        "live_activity_desc": "Show today's goals, streak, and a fresh motivation on the Lock Screen.",
        "privacy_policy": "Privacy Policy",
        "privacy_desc": "Review how app data and device permissions are used.",
        "terms_of_service": "Terms and Conditions",
        "terms_desc": "Read the rules for using the app and its focus tools.",
        "follow_us": "Follow Us",
        "sign_out": "Sign Out",
        "sign_out_desc": "End this session on the current device.",
        "delete_account": "Delete Account",
        "delete_account_desc": "Permanently delete your account and synced app data.",
        "delete_account_title": "Delete Account",
        "delete_account_msg": "This action is permanent. All your data will be deleted and cannot be recovered.",
        "delete_account_continue": "Continue",
        "delete_account_final_title": "Delete Permanently?",
        "delete_account_final_msg": "Please confirm one more time. If you delete your account, Spike AI will sign you out and send you back to the login page.",
        "deleting_account": "Deleting account...",
        "delete_failed": "Account deletion failed. Please try again or contact support.",
        "language": "Language",
        "language_desc": "Choose the language for all app content.",
        "set_name": "Set your name",
        "profile_name_prompt": "What should we call you?",
        "profile_name_desc": "Add the name Spike AI should use across your profile and productivity experience.",
        "full_name": "Full Name",
        "display_name": "Display Name",
        "email": "Email",
        "save_changes": "Save Changes",
        "save_footer": "Changes are saved to your profile and used anywhere your identity appears in the app.",
        "signed_in": "Signed in",
        "account": "Account",
        "preferences": "Preferences",
        "support_legal": "Support & Legal",
        "account_actions": "Account Actions",
        "pref_show_completed": "Show Completed Tasks",
        "pref_show_completed_desc": "Keep completed tasks visible in your daily list.",
        "pref_quotes": "Motivational Quotes",
        "pref_quotes_desc": "Show an inspiring quote on your progress screen.",
        "legal_updated": "Last updated: May 25, 2026",
        "privacy_body": """
        Last updated: May 25, 2026

        Spike AI is a productivity and focus app. This Privacy Policy explains how Spike AI handles information used to provide accounts, task planning, reminders, focus modes, Screen Time controls, progress tracking, and AI-generated productivity summaries.

        Information we collect: account identifiers such as your email address and user ID; profile details you choose to provide, such as display name and full name; tasks, goals, reminders, completion history, focus mode settings, app-selection tokens, and progress metrics. We may also store technical records needed to keep the service reliable and secure.

        Screen Time and app selections: app, category, and web-domain selections are handled through Apple's FamilyControls and ManagedSettings frameworks. Spike AI stores the Apple-provided tokens needed to apply your selected focus modes. We do not use these selections for advertising.

        Camera use in Athlete Mode: camera access is used for on-device body-pose checks so you can earn temporary app access through movement. Spike AI does not upload video frames for this feature and does not use camera data for advertising.

        Notifications and reminders: Spike AI uses notification permission to send task reminders, alarms, and focus nudges that you configure. You can change notification access in iOS Settings at any time.

        AI summaries: if you generate a progress summary, recent task, goal, focus, and productivity metrics may be processed by Spike AI's backend to produce the summary. Avoid entering sensitive personal information into task names or goals if you do not want it processed for productivity features.

        How we use information: to authenticate you, sync your account, provide focus tools, schedule reminders, show progress, personalize productivity insights, protect against misuse, troubleshoot issues, and comply with legal obligations. Spike AI does not sell your personal information.

        Data deletion: you can sign out or request permanent account deletion from Profile. Account deletion removes your authentication account and synced app data associated with that account, subject to limited retention required for security, fraud prevention, dispute resolution, or legal compliance.

        Your choices: you can edit profile details, change language and appearance preferences, disable Live Activity, revoke device permissions in Settings, stop using specific focus modes, or delete your account.

        Contact: for privacy questions or account deletion issues, contact Spike AI support through the support channel provided by the app or App Store listing.
        """,
        "terms_body": """
        Last updated: May 25, 2026

        These Terms and Conditions govern your use of Spike AI, including tasks, reminders, focus modes, Screen Time app prompts and shields, Athlete Mode movement checks, progress tracking, and AI-generated summaries.

        Eligibility and account: you are responsible for the account you create and for keeping access to your email and device secure. Use accurate information where the app asks for profile details.

        Productivity purpose: Spike AI is designed to support personal productivity and intentional device use. It is not a medical, mental health, emergency, safety, parental-control, employment-monitoring, or device-management service. Do not rely on Spike AI where failure of a reminder, block, prompt, camera check, notification, network request, or Apple permission could cause harm.

        Your responsibilities: choose focus settings that are appropriate for your situation; review app selections before activating a mode; turn modes off when they no longer match your needs; obey applicable law and Apple's platform terms; and avoid entering sensitive information into tasks or goals unless you are comfortable using it in the app.

        Acceptable use: do not misuse Spike AI, interfere with another person's device or account, attempt to bypass security or platform restrictions, reverse engineer protected parts of the service, overload the backend, or use the app for unlawful, abusive, deceptive, or harmful activity.

        Permissions and availability: some features require iOS permissions such as Screen Time, notifications, camera, Live Activities, and network access. Apple, device settings, operating system behavior, connectivity, and backend availability can affect whether features work as expected.

        AI-generated content: progress summaries may be generated using automated systems. They are for reflection and productivity coaching only. Review them with your own judgment before relying on them.

        Account deletion and termination: you may request account deletion from Profile. Spike AI may suspend or terminate access if required by law, platform rules, security concerns, or serious misuse.

        Changes: Spike AI may update these Terms as the app evolves. Continued use after an update means you accept the updated Terms.

        Contact: for questions about these Terms, contact Spike AI support through the support channel provided by the app or App Store listing.
        """,

        // Focus Mode
        "focus_title": "Focus",
        "select_mode": "Select Mode",
        "chill": "Chill",
        "focus": "Focus",
        "lock_in": "Lock-in",
        "sweat": "Athlete",
        "gentle_nudges": "Gentle nudges",
        "confirm_intent": "Confirm intent",
        "no_bypass": "No bypass",
        "move_to_unlock": "Move to unlock",
        "activate_focus": "Activate Focus Mode",
        "deactivate_focus": "Deactivate Focus Mode",
        "mode_active": "Mode Active",
        "reminders_scheduled": "Reminders scheduled",
        "apps_prompt_active": "app(s) — \"Are you sure?\" prompt active",
        "apps_blocked": "app(s) blocked",
        "temp_access_active": "Temporary access active",
        "apps_require_movement": "app(s) require movement to unlock",
        "notifications_label": "Notifications",
        "notifications_enabled": "Notifications enabled",
        "notifications_denied": "Notifications denied",
        "enable_notif_settings": "Enable notifications in Settings.",
        "allow_notif_desc": "Allow notifications so Spike AI can send you focus reminders.",
        "enable_notifications": "Enable Notifications",
        "screen_time_access": "Screen Time Access",
        "screen_time_authorized": "Screen Time authorized",
        "allow_screen_time": "Allow Screen Time Access",
        "tap_to_allow": "Tap below to allow Screen Time access.",
        "open_settings_manual": "Or open Settings to enable manually",
        "open_settings": "Open Settings",
        "app_selection": "App Selection",
        "selections": "selection(s)",
        "choose_apps_confirm": "Choose which apps to confirm before opening.",
        "choose_apps_block": "Choose which apps to block.",
        "choose_apps_movement": "Choose which apps to unlock with movement.",
        "change_selection": "Change Selection",
        "select_apps": "Select Apps",
        "movement_unlock": "Movement Unlock",
        "movement_desc": "Push-ups and stand-ups are tracked with AI body detection. Each verified rep adds 1 minute of access to selected apps.",
        "access_available": "Access available for %@",
        "open_camera": "Open Camera Check",
        "lock_in_mode": "Lock-in mode",
        "lock_in_warning": "Apps show a red screen with no bypass. You must come back here to turn Lock-in Mode off.",
        "sweat_mode": "Athlete Mode",
        "do_exercises": "Do push-ups or stand-ups to earn time",
        "add_minutes": "Add %d Minute(s)",
        "keep_in_view": "Keep your shoulders, arms, or hips in view",
        "camera_required": "Camera access is required for movement checks.",
        "camera_disabled": "Camera access is disabled. Enable it in Settings to use Athlete Mode.",
        "camera_unavailable": "Camera access is unavailable.",
        "starting_camera": "Starting camera...",
        "camera_active": "Camera active",
        "allow_camera": "Allow Camera Access",
        "focus_mode_title": "Focus Mode",
        "focus_mode_desc": "Take control of your digital habits with focused, professional modes.",
        "about_permissions": "About Permissions",
        "permissions_desc": "Chill Mode requires notification permission. Focus, Lock-in, and Athlete Modes require Screen Time authorization. Athlete Mode also uses camera access for movement checks.",
        "get_started": "Get Started",
        "skip": "Skip",
        "unlocked_for": "Unlocked for %@",

        // Chill mode descriptions
        "chill_desc": "Daily reminders via notifications. No app control — just gentle nudges to stay intentional.",
        "focus_desc": "When you open a selected app, Spike AI asks \"Are you sure?\" You can open it normally or go back to your tasks. Apps are not blocked.",
        "lock_in_desc": "Selected apps are blocked while Lock-in is active. You can turn the mode off from Spike AI.",
        "sweat_desc": "Selected apps stay blocked until you complete a camera-checked push-up or stand-up. Each verified rep unlocks 1 minute.",

        // Motivational (deactivation)
        "giving_up_title": "You're making progress — don't stop now",
        "giving_up_msg": "You still have uncompleted goals for today. Every finished task builds momentum. Stay committed — your future self will thank you.",
        "giving_up_continue": "Stay Focused",
        "giving_up_stop": "Turn Off Anyway",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Your personal productivity system",
        "start_setup": "Start Setup",
        "make_phone_work": "Make your phone work\nfor your goals.",
        "onboarding_welcome_desc": "Reduce mindless scrolling, protect focus time, and turn real tasks into visible progress.",
        "did_you_know": "Did you know?",
        "did_you_know_subtitle": "A person spends 7 hours per day on average on their phone. That's",
        "hours_per_day": "hours a day",
        "days_per_month": "days per month",
        "days_per_year": "days per year",
        "years_of_life": "years of your life",
        "screen_time_reality": "And some people spend even more.",
        "dont_worry_title": "Don't worry",
        "spike_has_your_back": "Spike AI has your back",
        "solution_desc": "We'll help you maximize your productivity, get closer to your goals, and build the habits that transform you into the best version of yourself.",
        "screen_time_access_title": "Screen Time Access",
        "grant_access": "Grant Access",
        "which_apps": "Choose your\ndistracting apps",
        "choose_apps_protect": "Select the apps that waste your time. We'll block them during focus modes.",
        "apple_screen_time_required": "Apple requires Screen Time access before Spike AI can show your app list.",
        "save_apps": "Save & Continue",
        "change_selected_apps": "Change selected apps",
        "ready_change_life": "Ready to change\nyour life?",
        "ready_change_desc": "Create your account to save your choices and start your journey.",
        "benefit_no_distraction": "Distracting apps will no longer bother you",
        "benefit_discover_modes": "Discover 4 different types of focus modes",
        "benefit_track_progress": "Track your progress and get closer to your goals",
        "create_account": "Create Account",
        "protect_focus": "Protect Focus",
        "block_feeds": "Block feeds",
        "finish_tasks": "Finish tasks",
        "energy_plus_three": "+3 Energy",
        "selected_count": "%d selected",
        "no_apps_selected": "No apps selected yet",
        "saved_for_modes": "Saved for protection modes",
        "select_apps_to_control": "Select the apps you want to control",
        "clean_room": "Clean Room",
        "snap_proof": "Snap proof when finished",
        "ai_verifies_task": "AI verifies the task",
        "energy_earned": "+3 Energy earned",
        "on_track": "On track",
        "energy": "Energy",
        "tasks_completed": "Tasks completed",
        "focus_protected": "Focus protected",
        "scrolling_avoided": "Scrolling avoided",
        "continue_apple": "Continue with Apple",
        "continue_google": "Continue with Google",
        "continue_email": "Continue with email",
        "enter_email": "Enter your email",
        "send_sign_in_link": "We'll send you a sign-in link",
        "check_email": "Check your email",
        "sent_link_to": "We sent a sign-in link to",
        "tap_link": "Tap the link to sign in automatically.",
        "open_mail": "Open Mail App",
        "open_with": "Open with",
        "didnt_get_email": "Didn't get the email?",
        "resend": "Resend",
        "resend_in": "Resend in %ds",
        "new_link_sent": "A new link has been sent!",
        "valid_email": "Enter a valid email address.",
        "by_continuing": "By continuing, you agree to Spike AI's",
        "and_word": "and",

        // Screen Time Onboarding
        "screen_time_title": "Screen Time",
        "screen_time_permission_desc": "Spike AI needs Screen Time permission for Focus, Lock-in, and Athlete modes. This lets it show app prompts and blocks for the apps you choose.",
        "screen_time_denied": "Permission was denied. You can enable it in Settings.",
        "ask_before_opening": "Ask Before Opening",
        "block_apps_completely": "Block Apps Completely",
        "stay_accountable": "Stay Accountable",
        "stay_accountable_desc": "Track progress and keep your focus habits visible.",
        "skip_for_now": "Skip for Now",

        // Live Activity
        "daily_goals_title": "Daily Goals",
        "of_done": "of %d done",
        "more_to_go": "+%d more to go",

        // Chill morning
        "good_morning": "Good morning! Stay intentional today. Review your tasks and stay focused.",

        // General
        "error": "Error",
        "ok": "OK",
        "yes": "Yes",
        "no": "No",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Switch to Chill Mode?",
        "stay_focused_btn": "Stay Focused",
        "switch_anyway_btn": "Switch Anyway",
        "switch_to_chill_msg": "You still have uncompleted goals. Switching to Chill Mode removes app blocking, which increases the risk of not finishing your goals today.",
        "task_notification": "Task Notification",
        "missed_alarm": "Missed Alarm",
        "quote_of_day": "Quote of the Day",
        "new_quotes_daily": "New quotes arrive daily at 5:00 AM",
        "focus_day_label": "Focus Day",
        "missed_label": "Missed",
        "access_granted": "Access granted",
        "goal_reminder": "Goal Reminder",
        "spike_ai_focus": "Spike AI Focus",
        "goals_required_title": "Goals Required",
        "goals_required_desc_focus": "Focus mode blocks selected apps only when you have uncompleted goals. Add goals in the Home tab to activate app blocking.",
        "goals_required_desc_lockin": "Lock-in mode blocks selected apps only when you have uncompleted goals. Add goals in the Home tab to activate app blocking.",
        "save": "Save",
        "no_goals_reminder_body": "You haven't set any goals for today. Take a moment to plan your day!",
        "dont_forget": "Don't forget",
        "chill_morning_body": "Good morning! Stay intentional today. Review your tasks and stay focused.",
        "every_day": "Every day",
        "weekdays": "Weekdays",
        "weekends": "Weekends",
        "time_to_focus": "Time to focus!",

        // Additional UI strings
        "next_quote_in": "Next quote in %@",
        "enable_notif_chill": "Enable notifications before starting Chill mode.",
        "enable_screen_time_mode": "Enable Screen Time access before starting this mode.",
        "select_app_before_mode": "Select at least one app, category, or website before starting this mode.",
        "mode_not_ready": "This mode is not ready to start.",
        "protection_stopped_no_apps": "Protection stopped because no apps are selected.",
        "protection_stopped_screen_time": "Protection stopped because Screen Time access changed.",
        "max_reminders": "You can keep up to %d focus reminders.",
        "front_camera_unavailable": "Front camera is unavailable.",
        "task_title_empty": "Task title cannot be empty.",
        "goal_title_empty": "Goal title cannot be empty.",
        "rate_limit_wait": "Please wait %d seconds before generating another summary.",
        "missed_alarm_for": "You missed the alarm for: %@",
        "stay_with_plan": "Stay with the plan.",
        "motivation_small_wins": "Small wins compound.",
        "motivation_next_step": "Finish the next clear step.",
        "motivation_protect_hour": "Protect the hour in front of you.",
        "motivation_consistency": "Consistency beats intensity.",

        // Milestones
        "milestone_3day_streak": "3-day streak",
        "milestone_3day_desc": "A steady rhythm started.",
        "milestone_7day_streak": "7-day streak",
        "milestone_7day_desc": "A full focused week.",
        "milestone_10h_protected": "10 hours protected",
        "milestone_10h_desc": "Time protected for what matters.",
        "milestone_30_focus": "30 focus days",
        "milestone_30_desc": "Consistency with real weight.",

        // Narratives
        "narrative_improved": "Your screen time improved compared to last week.",
        "narrative_consistent": "You stayed consistent this week and protected your focus.",
        "narrative_more_days": "You completed more focus days than usual.",
        "narrative_building": "You are building the rhythm one focused day at a time.",

        // Screen time
        "screen_time_trend_pending": "Screen time trend will appear as usage history grows.",
        "screen_time_improved": "Screen time improved by %d%%",
        "screen_time_higher": "Screen time is slightly higher than usual",
        "screen_time_steady": "Screen time is steady this week",

        // Benchmarks
        "benchmark_pending": "Average screen time will appear as the app records usage history. The global reference point is about 7 hours per day.",
        "benchmark_below": "Your 7-day average is %@, which is below the 7-hour global average. That is a strong direction.",
        "benchmark_above": "Your 7-day average is %@, above the 7-hour global average. A small reduction today can move the trend.",
        "benchmark_matching": "Your 7-day average is %@, matching the 7-hour global average.",

        // Task editing
        "edit_task": "Edit Task",
        "task_name_placeholder": "Task name",
        "task_reminder_default": "Task reminder",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Spanish
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let es: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Acerca de los modos de enfoque",
        "no_active_goals_title": "No hay objetivos activos",
        "no_active_goals_btn": "Entendido",
        "no_active_goals_msg": "Los modos Enfoque y Bloqueo solo funcionan mientras tienes un objetivo sin completar en el que trabajar. Añade un objetivo — o reactiva uno — y luego inicia tu sesión.",
        // Tab bar
        "tab_home": "Inicio", "tab_progress": "Progreso", "tab_mode": "Modo", "tab_profile": "Perfil",

        // Home
        "today": "Hoy", "tomorrow": "Mañana", "yesterday": "Ayer",
        "back_to_today": "Volver a Hoy",
        "add_first_task": "Toca + para agregar tu primera tarea",
        "no_tasks_this_day": "Sin tareas en este día",
        "new_task": "Nueva Tarea",
        "what_to_do": "¿Qué necesitas hacer?",
        "task": "Tarea", "schedule": "Horario",
        "pick_date_hint": "Elige cualquier fecha futura — hoy, la próxima semana o meses después.",
        "priority": "Prioridad", "low": "Baja", "medium": "Media", "high": "Alta",
        "notification": "Notificación",
        "silent_push": "Notificación silenciosa",
        "notification_desc": "Envía una notificación única a la hora programada. Aparece silenciosamente en tu pantalla de bloqueo y Centro de Notificaciones.",
        "reminder": "Recordatorio",
        "alarm_sound": "Alarma con sonido y vibración",
        "reminder_desc": "Funciona como una alarma — un sonido especial sonará y tu teléfono vibrará continuamente hasta que presiones el botón Descartar en pantalla. Ideal para reuniones y plazos.",
        "cancel": "Cancelar", "add": "Agregar", "edit": "Editar", "delete": "Eliminar",
        "jump_to_date": "Ir a Fecha", "done": "Listo",
        "task_limit": "Has alcanzado el límite de 25 tareas para esta fecha.",
        "time": "Hora", "date": "Fecha", "select_date": "Seleccionar Fecha",

        // Alarm
        "reminder_title": "Recordatorio", "dismiss": "Descartar",

        // Progress
        "daily_progress": "Progreso Diario", "streaks": "rachas", "focus_days": "días de enfoque",
        "consistency": "consistencia",
        "set_first_goal": "Establece tu primera meta para hoy",
        "all_goals_completed": "Todas las metas diarias completadas",
        "goals_completed": "de", "daily_goals_completed": "metas diarias completadas",
        "daily_goals": "Metas Diarias", "remaining": "restantes",
        "no_goals_planned": "Sin metas planificadas",
        "complete_to_focus": "Completa todas las tareas para marcar hoy como día de enfoque.",
        "add_task_to_start": "Agrega una tarea desde Inicio para comenzar a registrar metas diarias.",
        "daily_plan_complete": "Plan diario completado",
        "ai_weekly_summary": "Resumen Semanal IA",
        "creating_summary": "Creando tu resumen semanal...",
        "generate_summary": "Generar Resumen", "refresh_summary": "Actualizar Resumen",
        "first_summary_coming": "Tu primer resumen semanal de IA está en camino.",
        "first_summary_desc": "Estará listo el %@ a las 9 PM. Incluye información sobre tu progreso, tareas pendientes y el mejor modo de enfoque para ti.",
        "next_update": "Próxima actualización: %@",
        "weekly_recap": "Tu resumen semanal de días de enfoque, tareas y tendencias de productividad está listo.",
        "screen_time_7day": "Tiempo de Pantalla 7 Días", "best_streak": "Mejor Racha",
        "days": "días", "milestones": "Logros", "milestone_unlocked": "Logro Desbloqueado",
        "continue_btn": "Continuar", "history_calendar": "Calendario Historial",
        "mode_used": "Modo Usado", "completed": "Completado", "not_completed": "No Completado",
        "no_completed_tasks": "No hay tareas completadas registradas para este día.",
        "everything_completed": "Todo fue completado.",
        "no_missed_tasks": "No hay tareas pendientes registradas para este día.",
        "streak_day": "Día de Racha", "missed_day": "Día Perdido",
        "first_name": "Nombre", "last_name": "Apellido",
        "avatar_color": "Color de Avatar",
        "whats_your_name": "¿Cómo te llamas?",
        "name_helps": "Esto ayuda a personalizar tu experiencia.",
        "name_save_failed": "No pudimos guardar tu nombre. Revisa tu conexión e inténtalo de nuevo.",
        "continue_btn_name": "Continuar",
        "wins": "Victorias", "next_action": "Siguiente Acción", "average": "promedio",
        "todays_completion": "Progreso de hoy",
        "streaks_this_month": "rachas este mes",
        "streak_days": "días de racha", "non_streak_days": "días sin racha",
        "monthly_streak_summary": "%d rachas este mes • %d días de racha, %d días sin racha",
        "duration_average": "%@ promedio",

        // Profile
        "personal_details": "Datos Personales",
        "personal_info": "Información Personal",
        "update_email_name": "Actualiza tu correo electrónico y nombre completo.",
        "and_username": "y nombre de usuario",
        "invite_friends": "Invitar Amigos",
        "refer_friend_title": "Recomienda a un amigo y gana $10",
        "refer_friend_desc": "Gana $10 por cada amigo que se registre con tu código promocional.",
        "upgrade_family_plan": "Mejorar al Plan Familiar",
        "goals_tracking": "Metas y Seguimiento",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Editar Metas de Nutrición",
        "tracking_reminders": "Recordatorios de Seguimiento",
        "email_not_editable": "Tu correo está vinculado a tu inicio de sesión y no se puede editar aquí.",
        "theme": "Tema",
        "theme_desc": "Usa la apariencia del sistema o elige modo claro/oscuro fijo.",
        "appearance": "Apariencia",
        "appearance_desc": "Elige apariencia clara, oscura o del sistema",
        "live_activity_profile_desc": "Muestra tu progreso diario en la pantalla de bloqueo y la Dynamic Island",
        "system": "Sistema", "light": "Claro", "dark": "Oscuro",
        "live_activity": "Actividad en Vivo",
        "live_activity_desc": "Muestra las metas de hoy, racha y una motivación fresca en la pantalla de bloqueo.",
        "privacy_policy": "Política de Privacidad",
        "privacy_desc": "Revisa cómo se usan los datos de la app y los permisos del dispositivo.",
        "terms_of_service": "Términos y Condiciones",
        "terms_desc": "Lee las reglas de uso de la app y sus herramientas de enfoque.",
        "follow_us": "Síguenos",
        "sign_out": "Cerrar Sesión",
        "sign_out_desc": "Finalizar esta sesión en el dispositivo actual.",
        "delete_account": "Eliminar Cuenta",
        "delete_account_desc": "Eliminar permanentemente tu cuenta y datos sincronizados de la app.",
        "delete_account_title": "Eliminar Cuenta",
        "delete_account_msg": "Esta acción es permanente. Todos tus datos serán eliminados y no podrán recuperarse.",
        "delete_account_continue": "Continuar",
        "delete_account_final_title": "¿Eliminar Permanentemente?",
        "delete_account_final_msg": "Por favor confirma una vez más. Si eliminas tu cuenta, Spike AI cerrará tu sesión y te enviará a la página de inicio de sesión.",
        "deleting_account": "Eliminando cuenta...",
        "delete_failed": "Error al eliminar la cuenta. Inténtalo de nuevo o contacta soporte.",
        "language": "Idioma",
        "language_desc": "Elige el idioma para todo el contenido de la app.",
        "set_name": "Configura tu nombre",
        "profile_name_prompt": "¿Cómo debemos llamarte?",
        "profile_name_desc": "Agrega el nombre que Spike AI debe usar en tu perfil y experiencia de productividad.",
        "full_name": "Nombre Completo", "display_name": "Nombre para Mostrar",
        "email": "Correo Electrónico",
        "save_changes": "Guardar Cambios",
        "save_footer": "Los cambios se guardan en tu perfil y se usan en cualquier lugar donde aparezca tu identidad en la app.",
        "signed_in": "Sesión iniciada",
        "account": "Cuenta", "preferences": "Preferencias",
        "support_legal": "Soporte y Legal", "account_actions": "Acciones de Cuenta",
        "pref_show_completed": "Mostrar Tareas Completadas",
        "pref_show_completed_desc": "Mantener tareas completadas visibles en tu lista diaria.",
        "pref_quotes": "Frases Motivacionales",
        "pref_quotes_desc": "Mostrar una frase inspiradora en la pantalla de progreso.",
        "legal_updated": "Última actualización: 25 de mayo de 2026",
        "privacy_body": """
        Última actualización: 25 de mayo de 2026

        Spike AI es una aplicación de productividad y enfoque. Esta Política de Privacidad explica cómo Spike AI gestiona la información utilizada para proporcionar cuentas, planificación de tareas, recordatorios, modos de enfoque, controles de Tiempo de Pantalla, seguimiento del progreso y resúmenes de productividad generados por IA.

        Información que recopilamos: identificadores de cuenta como tu dirección de correo electrónico e ID de usuario; datos de perfil que eliges proporcionar, como nombre para mostrar y nombre completo; tareas, metas, recordatorios, historial de finalización, configuración de modos de enfoque, tokens de selección de apps y métricas de progreso. También podemos almacenar registros técnicos necesarios para mantener el servicio confiable y seguro.

        Tiempo de Pantalla y selección de apps: las selecciones de apps, categorías y dominios web se gestionan a través de los frameworks FamilyControls y ManagedSettings de Apple. Spike AI almacena los tokens proporcionados por Apple necesarios para aplicar los modos de enfoque seleccionados. No utilizamos estas selecciones con fines publicitarios.

        Uso de la cámara en Modo Sudor: el acceso a la cámara se usa para verificaciones de postura corporal en el dispositivo para que puedas obtener acceso temporal a apps mediante movimiento. Spike AI no sube fotogramas de video para esta función y no utiliza datos de la cámara con fines publicitarios.

        Notificaciones y recordatorios: Spike AI utiliza el permiso de notificaciones para enviar recordatorios de tareas, alarmas y avisos de enfoque que tú configuras. Puedes cambiar el acceso a notificaciones en los Ajustes de iOS en cualquier momento.

        Resúmenes de IA: si generas un resumen de progreso, las métricas recientes de tareas, metas, enfoque y productividad pueden ser procesadas por el servidor de Spike AI para producir el resumen. Evita ingresar información personal sensible en nombres de tareas o metas si no deseas que sea procesada para funciones de productividad.

        Cómo usamos la información: para autenticarte, sincronizar tu cuenta, proporcionar herramientas de enfoque, programar recordatorios, mostrar el progreso, personalizar información de productividad, proteger contra el uso indebido, solucionar problemas y cumplir con obligaciones legales. Spike AI no vende tu información personal.

        Eliminación de datos: puedes cerrar sesión o solicitar la eliminación permanente de la cuenta desde Perfil. La eliminación de cuenta remueve tu cuenta de autenticación y los datos sincronizados de la app asociados con esa cuenta, sujeto a retención limitada requerida para seguridad, prevención de fraude, resolución de disputas o cumplimiento legal.

        Tus opciones: puedes editar los datos del perfil, cambiar preferencias de idioma y apariencia, desactivar la Actividad en Vivo, revocar permisos del dispositivo en Ajustes, dejar de usar modos de enfoque específicos o eliminar tu cuenta.

        Contacto: para preguntas sobre privacidad o problemas con la eliminación de cuenta, contacta al soporte de Spike AI a través del canal de soporte proporcionado por la app o la página de la App Store.
        """,
        "terms_body": """
        Última actualización: 25 de mayo de 2026

        Estos Términos y Condiciones rigen tu uso de Spike AI, incluyendo tareas, recordatorios, modos de enfoque, avisos y bloqueos de apps de Tiempo de Pantalla, verificaciones de movimiento del Modo Sudor, seguimiento del progreso y resúmenes generados por IA.

        Elegibilidad y cuenta: eres responsable de la cuenta que creas y de mantener seguro el acceso a tu correo electrónico y dispositivo. Usa información precisa cuando la app solicite datos de perfil.

        Propósito de productividad: Spike AI está diseñado para apoyar la productividad personal y el uso intencional del dispositivo. No es un servicio médico, de salud mental, de emergencia, de seguridad, de control parental, de monitoreo laboral ni de gestión de dispositivos. No dependas de Spike AI donde la falla de un recordatorio, bloqueo, aviso, verificación de cámara, notificación, solicitud de red o permiso de Apple pueda causar daño.

        Tus responsabilidades: elige configuraciones de enfoque apropiadas para tu situación; revisa las selecciones de apps antes de activar un modo; desactiva los modos cuando ya no se ajusten a tus necesidades; cumple con la ley aplicable y los términos de la plataforma de Apple; y evita ingresar información sensible en tareas o metas a menos que te sientas cómodo usándola en la app.

        Uso aceptable: no hagas uso indebido de Spike AI, no interfieras con el dispositivo o la cuenta de otra persona, no intentes eludir restricciones de seguridad o de la plataforma, no hagas ingeniería inversa de partes protegidas del servicio, no sobrecargues el servidor ni uses la app para actividades ilegales, abusivas, engañosas o dañinas.

        Permisos y disponibilidad: algunas funciones requieren permisos de iOS como Tiempo de Pantalla, notificaciones, cámara, Actividades en Vivo y acceso a red. Apple, la configuración del dispositivo, el comportamiento del sistema operativo, la conectividad y la disponibilidad del servidor pueden afectar si las funciones operan como se espera.

        Contenido generado por IA: los resúmenes de progreso pueden generarse usando sistemas automatizados. Son solo para reflexión y orientación de productividad. Revísalos con tu propio criterio antes de confiar en ellos.

        Eliminación de cuenta y terminación: puedes solicitar la eliminación de cuenta desde Perfil. Spike AI puede suspender o terminar el acceso si lo requiere la ley, las reglas de la plataforma, preocupaciones de seguridad o uso indebido grave.

        Cambios: Spike AI puede actualizar estos Términos a medida que la app evolucione. El uso continuado después de una actualización significa que aceptas los Términos actualizados.

        Contacto: para preguntas sobre estos Términos, contacta al soporte de Spike AI a través del canal de soporte proporcionado por la app o la página de la App Store.
        """,

        // Focus Mode
        "focus_title": "Enfoque", "select_mode": "Seleccionar Modo",
        "chill": "Chill", "focus": "Enfoque", "lock_in": "Bloqueo", "sweat": "Atleta",
        "gentle_nudges": "Avisos suaves", "confirm_intent": "Confirmar intención",
        "no_bypass": "Sin escape", "move_to_unlock": "Muévete para desbloquear",
        "activate_focus": "Activar Modo de Enfoque", "deactivate_focus": "Desactivar Modo de Enfoque",
        "mode_active": "Modo Activo",
        "reminders_scheduled": "Recordatorios programados",
        "apps_prompt_active": "app(s) — aviso \"¿Estás seguro?\" activo",
        "apps_blocked": "app(s) bloqueadas",
        "temp_access_active": "Acceso temporal activo",
        "apps_require_movement": "app(s) requieren movimiento para desbloquear",
        "notifications_label": "Notificaciones",
        "notifications_enabled": "Notificaciones habilitadas",
        "notifications_denied": "Notificaciones denegadas",
        "enable_notif_settings": "Habilita las notificaciones en Ajustes.",
        "allow_notif_desc": "Permite notificaciones para que Spike AI pueda enviarte recordatorios de enfoque.",
        "enable_notifications": "Habilitar Notificaciones",
        "screen_time_access": "Acceso a Tiempo de Pantalla",
        "screen_time_authorized": "Tiempo de Pantalla autorizado",
        "allow_screen_time": "Permitir Tiempo de Pantalla",
        "tap_to_allow": "Toca abajo para permitir el acceso a Tiempo de Pantalla.",
        "open_settings_manual": "O abre Ajustes para habilitarlo manualmente",
        "open_settings": "Abrir Ajustes",
        "app_selection": "Selección de Apps", "selections": "selección(es)",
        "choose_apps_confirm": "Elige qué apps confirmar antes de abrir.",
        "choose_apps_block": "Elige qué apps bloquear.",
        "choose_apps_movement": "Elige qué apps desbloquear con movimiento.",
        "change_selection": "Cambiar Selección", "select_apps": "Seleccionar Apps",
        "movement_unlock": "Desbloqueo por Movimiento",
        "movement_desc": "Las flexiones y sentadillas se rastrean con detección corporal por IA. Cada repetición verificada agrega 1 minuto de acceso a las apps seleccionadas.",
        "access_available": "Acceso disponible por %@",
        "open_camera": "Abrir Verificación de Cámara",
        "lock_in_mode": "Modo Bloqueo",
        "lock_in_warning": "Las apps muestran una pantalla roja sin escape. Debes volver aquí para desactivar el Modo Bloqueo.",
        "sweat_mode": "Modo Atleta",
        "do_exercises": "Haz flexiones o sentadillas para ganar tiempo",
        "add_minutes": "Agregar %d Minuto(s)",
        "keep_in_view": "Mantén tus hombros, brazos o caderas visibles",
        "camera_required": "Se requiere acceso a la cámara para las verificaciones de movimiento.",
        "camera_disabled": "El acceso a la cámara está deshabilitado. Habilítalo en Ajustes para usar el Modo Sudor.",
        "camera_unavailable": "El acceso a la cámara no está disponible.",
        "starting_camera": "Iniciando cámara...",
        "camera_active": "Cámara activa",
        "allow_camera": "Permitir Acceso a la Cámara",
        "focus_mode_title": "Modo de Enfoque",
        "focus_mode_desc": "Toma el control de tus hábitos digitales con modos enfocados y profesionales.",
        "about_permissions": "Sobre Permisos",
        "permissions_desc": "El Modo Chill requiere permiso de notificaciones. Los Modos Enfoque, Bloqueo y Sudor requieren autorización de Tiempo de Pantalla. El Modo Sudor también usa acceso a la cámara para verificaciones de movimiento.",
        "get_started": "Comenzar", "skip": "Omitir",
        "unlocked_for": "Desbloqueado por %@",

        // Chill mode descriptions
        "chill_desc": "Recordatorios diarios mediante notificaciones. Sin control de apps — solo avisos suaves para mantener la intención.",
        "focus_desc": "Al abrir una app seleccionada, Spike AI pregunta \"¿Estás seguro?\" Puedes abrirla normalmente o volver a tus tareas. Las apps no se bloquean.",
        "lock_in_desc": "Las apps seleccionadas se bloquean mientras el Bloqueo está activo. Puedes desactivar el modo desde Spike AI.",
        "sweat_desc": "Las apps seleccionadas permanecen bloqueadas hasta que completes una flexión o sentadilla verificada por cámara. Cada repetición verificada desbloquea 1 minuto.",

        // Motivational (deactivation)
        "giving_up_title": "Estás progresando — no te detengas ahora",
        "giving_up_msg": "Aún tienes metas sin completar para hoy. Cada tarea terminada construye impulso. Mantente comprometido — tu yo futuro te lo agradecerá.",
        "giving_up_continue": "Mantener Enfoque", "giving_up_stop": "Desactivar de Todas Formas",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Tu sistema personal de productividad",
        "start_setup": "Iniciar Configuración",
        "make_phone_work": "Haz que tu teléfono trabaje\npara tus metas.",
        "onboarding_welcome_desc": "Reduce el desplazamiento sin sentido, protege el tiempo de enfoque y convierte tareas reales en progreso visible.",
        "did_you_know": "¿Sabías que?",
        "did_you_know_subtitle": "Una persona pasa 7 horas diarias en promedio en su teléfono. Eso son",
        "hours_per_day": "horas al día",
        "days_per_month": "días al mes",
        "days_per_year": "días al año",
        "years_of_life": "años de tu vida",
        "screen_time_reality": "Y algunas personas pasan aún más.",
        "dont_worry_title": "No te preocupes",
        "spike_has_your_back": "Spike AI te respalda",
        "solution_desc": "Te ayudaremos a maximizar tu productividad, acercarte a tus metas y construir los hábitos que te transforman en la mejor versión de ti mismo.",
        "screen_time_access_title": "Acceso a Tiempo de Pantalla",
        "grant_access": "Conceder Acceso",
        "which_apps": "Elige tus\napps distractoras",
        "choose_apps_protect": "Selecciona las apps que te hacen perder tiempo. Las bloquearemos durante los modos de enfoque.",
        "apple_screen_time_required": "Apple requiere acceso a Tiempo de Pantalla antes de que Spike AI pueda mostrar tu lista de apps.",
        "save_apps": "Guardar y Continuar",
        "change_selected_apps": "Cambiar apps seleccionadas",
        "ready_change_life": "¿Listo para cambiar\ntu vida?",
        "ready_change_desc": "Crea tu cuenta para guardar tus elecciones y comenzar tu viaje.",
        "benefit_no_distraction": "Las apps distractoras ya no te molestarán",
        "benefit_discover_modes": "Descubre 4 tipos diferentes de modos de enfoque",
        "benefit_track_progress": "Sigue tu progreso y acércate a tus metas",
        "create_account": "Crear Cuenta",
        "protect_focus": "Proteger Enfoque",
        "block_feeds": "Bloquear feeds",
        "finish_tasks": "Terminar tareas",
        "energy_plus_three": "+3 Energía",
        "selected_count": "%d seleccionadas",
        "no_apps_selected": "Ninguna app seleccionada aún",
        "saved_for_modes": "Guardadas para modos de protección",
        "select_apps_to_control": "Selecciona las apps que quieres controlar",
        "clean_room": "Limpiar Habitación",
        "snap_proof": "Foto de prueba al terminar",
        "ai_verifies_task": "La IA verifica la tarea",
        "energy_earned": "+3 Energía ganada",
        "on_track": "En camino",
        "energy": "Energía",
        "tasks_completed": "Tareas completadas",
        "focus_protected": "Enfoque protegido",
        "scrolling_avoided": "Desplazamiento evitado",
        "continue_apple": "Continuar con Apple",
        "continue_google": "Continuar con Google",
        "continue_email": "Continuar con correo",
        "enter_email": "Ingresa tu correo",
        "send_sign_in_link": "Te enviaremos un enlace de inicio de sesión",
        "check_email": "Revisa tu correo",
        "sent_link_to": "Enviamos un enlace de inicio de sesión a",
        "tap_link": "Toca el enlace para iniciar sesión automáticamente.",
        "open_mail": "Abrir App de Correo",
        "open_with": "Abrir con",
        "didnt_get_email": "¿No recibiste el correo?",
        "resend": "Reenviar",
        "resend_in": "Reenviar en %ds",
        "new_link_sent": "¡Se ha enviado un nuevo enlace!",
        "valid_email": "Ingresa un correo electrónico válido.",
        "by_continuing": "Al continuar, aceptas los",
        "and_word": "y",

        // Screen Time Onboarding
        "screen_time_title": "Tiempo de Pantalla",
        "screen_time_permission_desc": "Spike AI necesita permiso de Tiempo de Pantalla para los modos Enfoque, Bloqueo y Sudor. Esto le permite mostrar avisos y bloqueos de apps para las apps que elijas.",
        "screen_time_denied": "El permiso fue denegado. Puedes habilitarlo en Ajustes.",
        "ask_before_opening": "Preguntar Antes de Abrir",
        "block_apps_completely": "Bloquear Apps Completamente",
        "stay_accountable": "Mantente Responsable",
        "stay_accountable_desc": "Sigue el progreso y mantén visibles tus hábitos de enfoque.",
        "skip_for_now": "Omitir por Ahora",

        // Live Activity
        "daily_goals_title": "Metas Diarias",
        "of_done": "de %d listas",
        "more_to_go": "+%d más por hacer",

        // Chill morning
        "good_morning": "¡Buenos días! Mantén la intención hoy. Revisa tus tareas y mantén el enfoque.",

        // General
        "error": "Error", "ok": "OK", "yes": "Sí", "no": "No",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "¿Cambiar a Modo Relax?",
        "stay_focused_btn": "Mantener Enfoque",
        "switch_anyway_btn": "Cambiar de Todos Modos",
        "switch_to_chill_msg": "Aún tienes metas sin completar. Cambiar al Modo Relax elimina el bloqueo de apps, lo que aumenta el riesgo de no terminar tus metas hoy.",
        "task_notification": "Notificación de Tarea",
        "missed_alarm": "Alarma Perdida",
        "quote_of_day": "Frase del Día",
        "new_quotes_daily": "Nuevas frases llegan cada día a las 5:00 AM",
        "focus_day_label": "Día de Enfoque",
        "missed_label": "Perdido",
        "access_granted": "Acceso concedido",
        "goal_reminder": "Recordatorio de Meta",
        "spike_ai_focus": "Spike AI Enfoque",
        "goals_required_title": "Metas Requeridas",
        "goals_required_desc_focus": "El modo Enfoque bloquea las apps seleccionadas solo cuando tienes metas sin completar. Añade metas en la pestaña Inicio para activar el bloqueo de apps.",
        "goals_required_desc_lockin": "El modo Concentración bloquea las apps seleccionadas solo cuando tienes metas sin completar. Añade metas en la pestaña Inicio para activar el bloqueo de apps.",
        "save": "Guardar",
        "no_goals_reminder_body": "No has establecido ninguna meta para hoy. ¡Tómate un momento para planificar tu día!",
        "dont_forget": "No olvides",
        "chill_morning_body": "¡Buenos días! Sé intencional hoy. Revisa tus tareas y mantén el enfoque.",
        "every_day": "Todos los días",
        "weekdays": "Días laborables",
        "weekends": "Fines de semana",
        "time_to_focus": "¡Hora de concentrarse!",

        // Additional UI strings
        "next_quote_in": "Próxima cita en %@",
        "enable_notif_chill": "Activa las notificaciones antes de iniciar el modo Relax.",
        "enable_screen_time_mode": "Activa el acceso a Tiempo en Pantalla antes de iniciar este modo.",
        "select_app_before_mode": "Selecciona al menos una app, categoría o sitio web antes de iniciar este modo.",
        "mode_not_ready": "Este modo no está listo para iniciarse.",
        "protection_stopped_no_apps": "La protección se detuvo porque no hay apps seleccionadas.",
        "protection_stopped_screen_time": "La protección se detuvo porque el acceso a Tiempo en Pantalla cambió.",
        "max_reminders": "Puedes tener hasta %d recordatorios de enfoque.",
        "front_camera_unavailable": "La cámara frontal no está disponible.",
        "task_title_empty": "El título de la tarea no puede estar vacío.",
        "goal_title_empty": "El título de la meta no puede estar vacío.",
        "rate_limit_wait": "Espera %d segundos antes de generar otro resumen.",
        "missed_alarm_for": "Perdiste la alarma de: %@",
        "stay_with_plan": "Sigue con el plan.",
        "motivation_small_wins": "Las pequeñas victorias se acumulan.",
        "motivation_next_step": "Completa el siguiente paso.",
        "motivation_protect_hour": "Protege la hora que tienes delante.",
        "motivation_consistency": "La constancia supera la intensidad.",
        "monthly_scope_btn": "Mensual",
        "yearly_scope_btn": "Anual",
        "restoring_session": "Restaurando tu sesión...",

        // Milestones
        "milestone_3day_streak": "Racha de 3 días",
        "milestone_3day_desc": "Un ritmo constante ha comenzado.",
        "milestone_7day_streak": "Racha de 7 días",
        "milestone_7day_desc": "Una semana enfocada completa.",
        "milestone_10h_protected": "10 horas protegidas",
        "milestone_10h_desc": "Tiempo protegido para lo que importa.",
        "milestone_30_focus": "30 días de enfoque",
        "milestone_30_desc": "Consistencia con peso real.",

        // Narratives
        "narrative_improved": "Tu tiempo de pantalla mejoró en comparación con la semana pasada.",
        "narrative_consistent": "Mantuviste la consistencia esta semana y protegiste tu enfoque.",
        "narrative_more_days": "Completaste más días de enfoque de lo habitual.",
        "narrative_building": "Estás construyendo el ritmo un día enfocado a la vez.",

        // Screen time
        "screen_time_trend_pending": "La tendencia de tiempo de pantalla aparecerá a medida que crezca el historial de uso.",
        "screen_time_improved": "El tiempo de pantalla mejoró un %d%%",
        "screen_time_higher": "El tiempo de pantalla es ligeramente mayor de lo habitual",
        "screen_time_steady": "El tiempo de pantalla es estable esta semana",

        // Benchmarks
        "benchmark_pending": "El promedio de tiempo de pantalla aparecerá a medida que la app registre historial de uso. El punto de referencia global es de unas 7 horas por día.",
        "benchmark_below": "Tu promedio de 7 días es %@, por debajo del promedio global de 7 horas. Es una dirección sólida.",
        "benchmark_above": "Tu promedio de 7 días es %@, por encima del promedio global de 7 horas. Una pequeña reducción hoy puede cambiar la tendencia.",
        "benchmark_matching": "Tu promedio de 7 días es %@, igual al promedio global de 7 horas.",

        // Task editing
        "edit_task": "Editar Tarea",
        "task_name_placeholder": "Nombre de la tarea",
        "task_reminder_default": "Recordatorio de tarea",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - French
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let fr: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "À propos des modes de concentration",
        "no_active_goals_title": "Aucun objectif actif",
        "no_active_goals_btn": "Compris",
        "no_active_goals_msg": "Les modes Focus et Verrouillage ne fonctionnent que si vous avez un objectif inachevé à atteindre. Ajoutez un objectif — ou réactivez-en un — puis démarrez votre session.",
        // Tab bar
        "tab_home": "Accueil", "tab_progress": "Progrès", "tab_mode": "Mode", "tab_profile": "Profil",

        // Home
        "today": "Aujourd'hui", "tomorrow": "Demain", "yesterday": "Hier",
        "back_to_today": "Retour à Aujourd'hui",
        "add_first_task": "Appuyez sur + pour ajouter votre première tâche",
        "no_tasks_this_day": "Aucune tâche ce jour",
        "new_task": "Nouvelle Tâche",
        "what_to_do": "Que devez-vous faire ?",
        "task": "Tâche", "schedule": "Planifier",
        "pick_date_hint": "Choisissez une date future — aujourd'hui, la semaine prochaine ou dans quelques mois.",
        "priority": "Priorité", "low": "Basse", "medium": "Moyenne", "high": "Haute",
        "notification": "Notification",
        "silent_push": "Notification silencieuse",
        "notification_desc": "Envoie une notification unique à l'heure prévue. Elle apparaît discrètement sur votre écran de verrouillage et dans le Centre de notifications.",
        "reminder": "Rappel",
        "alarm_sound": "Alarme avec son et vibration",
        "reminder_desc": "Fonctionne comme une alarme — un son spécial retentira et votre téléphone vibrera continuellement jusqu'à ce que vous appuyiez sur le bouton Ignorer à l'écran. Idéal pour les réunions et les échéances.",
        "cancel": "Annuler", "add": "Ajouter", "edit": "Modifier", "delete": "Supprimer",
        "jump_to_date": "Aller à une Date", "done": "Terminé",
        "task_limit": "Vous avez atteint la limite de 25 tâches pour cette date.",
        "time": "Heure", "date": "Date", "select_date": "Sélectionner une Date",

        // Alarm
        "reminder_title": "Rappel", "dismiss": "Ignorer",

        // Progress
        "daily_progress": "Progrès Quotidien", "streaks": "séries", "focus_days": "jours de focus",
        "consistency": "régularité",
        "set_first_goal": "Définissez votre premier objectif pour aujourd'hui",
        "all_goals_completed": "Tous les objectifs quotidiens accomplis",
        "goals_completed": "de", "daily_goals_completed": "objectifs quotidiens accomplis",
        "daily_goals": "Objectifs Quotidiens", "remaining": "restants",
        "no_goals_planned": "Aucun objectif planifié",
        "complete_to_focus": "Terminez chaque tâche pour marquer aujourd'hui comme jour de focus.",
        "add_task_to_start": "Ajoutez une tâche depuis Accueil pour commencer à suivre les objectifs quotidiens.",
        "daily_plan_complete": "Plan quotidien accompli",
        "ai_weekly_summary": "Résumé Hebdomadaire IA",
        "creating_summary": "Création de votre résumé hebdomadaire...",
        "generate_summary": "Générer le Résumé", "refresh_summary": "Actualiser le Résumé",
        "first_summary_coming": "Votre premier résumé hebdomadaire IA est en route.",
        "first_summary_desc": "Il sera prêt le %@ à 21h. Il comprend des analyses sur vos progrès, les tâches manquées et le meilleur mode de focus pour vous.",
        "next_update": "Prochaine mise à jour : %@",
        "weekly_recap": "Votre bilan hebdomadaire des jours de focus, tâches et tendances de productivité est prêt.",
        "screen_time_7day": "Temps d'Écran 7 Jours", "best_streak": "Meilleure Série",
        "days": "jours", "milestones": "Jalons", "milestone_unlocked": "Jalon Débloqué",
        "continue_btn": "Continuer", "history_calendar": "Calendrier Historique",
        "mode_used": "Mode Utilisé", "completed": "Terminé", "not_completed": "Non Terminé",
        "no_completed_tasks": "Aucune tâche terminée enregistrée pour ce jour.",
        "everything_completed": "Tout a été accompli.",
        "no_missed_tasks": "Aucune tâche manquée enregistrée pour ce jour.",
        "streak_day": "Jour de Série", "missed_day": "Jour Manqué",
        "first_name": "Prénom", "last_name": "Nom de Famille",
        "avatar_color": "Couleur de l'Avatar",
        "whats_your_name": "Comment vous appelez-vous ?",
        "name_helps": "Cela aide à personnaliser votre expérience.",
        "name_save_failed": "Nous n'avons pas pu enregistrer votre nom. Vérifiez votre connexion et réessayez.",
        "continue_btn_name": "Continuer",
        "wins": "Victoires", "next_action": "Prochaine Action", "average": "moyenne",
        "todays_completion": "Avancement du jour",
        "streaks_this_month": "séries ce mois-ci",
        "streak_days": "jours de série", "non_streak_days": "jours sans série",
        "monthly_streak_summary": "%d séries ce mois-ci • %d jours de série, %d jours sans série",
        "duration_average": "%@ en moyenne",

        // Profile
        "personal_details": "Détails Personnels",
        "personal_info": "Informations Personnelles",
        "update_email_name": "Mettez à jour votre e-mail et votre nom complet.",
        "and_username": "et nom d'utilisateur",
        "invite_friends": "Inviter des Amis",
        "refer_friend_title": "Parrainez un ami et gagnez 10 $",
        "refer_friend_desc": "Gagnez 10 $ par ami qui s'inscrit avec votre code promo.",
        "upgrade_family_plan": "Passer au Forfait Famille",
        "goals_tracking": "Objectifs et Suivi",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Modifier les Objectifs Nutritionnels",
        "tracking_reminders": "Rappels de Suivi",
        "email_not_editable": "Votre e-mail est lié à votre connexion et ne peut pas être modifié ici.",
        "theme": "Thème",
        "theme_desc": "Utilisez l'apparence du système ou choisissez un mode clair/sombre fixe.",
        "appearance": "Apparence",
        "appearance_desc": "Choisissez l'apparence claire, sombre ou système",
        "live_activity_profile_desc": "Affichez vos progrès quotidiens sur l'écran de verrouillage et la Dynamic Island",
        "system": "Système", "light": "Clair", "dark": "Sombre",
        "live_activity": "Activité en Direct",
        "live_activity_desc": "Affichez les objectifs du jour, la série et une motivation fraîche sur l'écran de verrouillage.",
        "privacy_policy": "Politique de Confidentialité",
        "privacy_desc": "Consultez comment les données de l'app et les permissions de l'appareil sont utilisées.",
        "terms_of_service": "Conditions d'Utilisation",
        "terms_desc": "Lisez les règles d'utilisation de l'app et de ses outils de focus.",
        "follow_us": "Suivez-nous",
        "sign_out": "Déconnexion",
        "sign_out_desc": "Terminer cette session sur l'appareil actuel.",
        "delete_account": "Supprimer le Compte",
        "delete_account_desc": "Supprimer définitivement votre compte et les données synchronisées de l'app.",
        "delete_account_title": "Supprimer le Compte",
        "delete_account_msg": "Cette action est définitive. Toutes vos données seront supprimées et ne pourront pas être récupérées.",
        "delete_account_continue": "Continuer",
        "delete_account_final_title": "Supprimer Définitivement ?",
        "delete_account_final_msg": "Veuillez confirmer une dernière fois. Si vous supprimez votre compte, Spike AI vous déconnectera et vous renverra à la page de connexion.",
        "deleting_account": "Suppression du compte...",
        "delete_failed": "La suppression du compte a échoué. Veuillez réessayer ou contacter le support.",
        "language": "Langue",
        "language_desc": "Choisissez la langue pour tout le contenu de l'app.",
        "set_name": "Définir votre nom",
        "profile_name_prompt": "Comment devons-nous vous appeler ?",
        "profile_name_desc": "Ajoutez le nom que Spike AI doit utiliser dans votre profil et votre expérience de productivité.",
        "full_name": "Nom Complet", "display_name": "Nom d'Affichage",
        "email": "E-mail",
        "save_changes": "Enregistrer les Modifications",
        "save_footer": "Les modifications sont enregistrées dans votre profil et utilisées partout où votre identité apparaît dans l'app.",
        "signed_in": "Connecté",
        "account": "Compte", "preferences": "Préférences",
        "support_legal": "Support et Mentions Légales", "account_actions": "Actions du Compte",
        "pref_show_completed": "Afficher les Tâches Terminées",
        "pref_show_completed_desc": "Garder les tâches terminées visibles dans votre liste quotidienne.",
        "pref_quotes": "Citations Motivantes",
        "pref_quotes_desc": "Afficher une citation inspirante sur votre écran de progrès.",
        "legal_updated": "Dernière mise à jour : 25 mai 2026",
        "privacy_body": """
        Dernière mise à jour : 25 mai 2026

        Spike AI est une application de productivité et de concentration. Cette Politique de Confidentialité explique comment Spike AI gère les informations utilisées pour fournir les comptes, la planification des tâches, les rappels, les modes de focus, les contrôles de Temps d'Écran, le suivi des progrès et les résumés de productivité générés par l'IA.

        Informations que nous collectons : les identifiants de compte tels que votre adresse e-mail et votre identifiant utilisateur ; les détails de profil que vous choisissez de fournir, tels que le nom d'affichage et le nom complet ; les tâches, objectifs, rappels, l'historique d'accomplissement, les paramètres des modes de focus, les jetons de sélection d'apps et les métriques de progrès. Nous pouvons également stocker des enregistrements techniques nécessaires pour maintenir le service fiable et sécurisé.

        Temps d'Écran et sélection d'apps : les sélections d'apps, de catégories et de domaines web sont gérées via les frameworks FamilyControls et ManagedSettings d'Apple. Spike AI stocke les jetons fournis par Apple nécessaires à l'application de vos modes de focus sélectionnés. Nous n'utilisons pas ces sélections à des fins publicitaires.

        Utilisation de la caméra en Mode Effort : l'accès à la caméra est utilisé pour des vérifications de posture corporelle sur l'appareil afin que vous puissiez obtenir un accès temporaire aux apps par le mouvement. Spike AI ne télécharge pas de trames vidéo pour cette fonctionnalité et n'utilise pas les données de la caméra à des fins publicitaires.

        Notifications et rappels : Spike AI utilise l'autorisation de notifications pour envoyer des rappels de tâches, des alarmes et des incitations au focus que vous configurez. Vous pouvez modifier l'accès aux notifications dans les Réglages iOS à tout moment.

        Résumés IA : si vous générez un résumé de progrès, les métriques récentes de tâches, d'objectifs, de focus et de productivité peuvent être traitées par le serveur de Spike AI pour produire le résumé. Évitez de saisir des informations personnelles sensibles dans les noms de tâches ou d'objectifs si vous ne souhaitez pas qu'elles soient traitées pour les fonctionnalités de productivité.

        Comment nous utilisons les informations : pour vous authentifier, synchroniser votre compte, fournir des outils de focus, planifier des rappels, afficher les progrès, personnaliser les analyses de productivité, protéger contre les abus, résoudre les problèmes et respecter les obligations légales. Spike AI ne vend pas vos informations personnelles.

        Suppression des données : vous pouvez vous déconnecter ou demander la suppression définitive de votre compte depuis le Profil. La suppression du compte supprime votre compte d'authentification et les données synchronisées de l'app associées à ce compte, sous réserve d'une conservation limitée requise pour la sécurité, la prévention de la fraude, la résolution des litiges ou la conformité légale.

        Vos choix : vous pouvez modifier les détails de votre profil, changer les préférences de langue et d'apparence, désactiver l'Activité en Direct, révoquer les permissions de l'appareil dans les Réglages, arrêter d'utiliser des modes de focus spécifiques ou supprimer votre compte.

        Contact : pour toute question relative à la confidentialité ou tout problème de suppression de compte, contactez le support Spike AI via le canal de support fourni par l'app ou la fiche de l'App Store.
        """,
        "terms_body": """
        Dernière mise à jour : 25 mai 2026

        Ces Conditions d'Utilisation régissent votre utilisation de Spike AI, y compris les tâches, les rappels, les modes de focus, les invites et blocages d'apps du Temps d'Écran, les vérifications de mouvement du Mode Effort, le suivi des progrès et les résumés générés par l'IA.

        Éligibilité et compte : vous êtes responsable du compte que vous créez et du maintien de la sécurité d'accès à votre e-mail et à votre appareil. Utilisez des informations exactes lorsque l'app demande des détails de profil.

        Finalité de productivité : Spike AI est conçu pour soutenir la productivité personnelle et l'utilisation intentionnelle de l'appareil. Ce n'est pas un service médical, de santé mentale, d'urgence, de sécurité, de contrôle parental, de surveillance de l'emploi ou de gestion d'appareils. Ne comptez pas sur Spike AI là où la défaillance d'un rappel, d'un blocage, d'une invite, d'une vérification caméra, d'une notification, d'une requête réseau ou d'une permission Apple pourrait causer un préjudice.

        Vos responsabilités : choisissez des paramètres de focus appropriés à votre situation ; vérifiez les sélections d'apps avant d'activer un mode ; désactivez les modes quand ils ne correspondent plus à vos besoins ; respectez la loi applicable et les conditions de la plateforme Apple ; et évitez de saisir des informations sensibles dans les tâches ou objectifs à moins que vous ne soyez à l'aise avec leur utilisation dans l'app.

        Utilisation acceptable : n'abusez pas de Spike AI, n'interférez pas avec l'appareil ou le compte d'une autre personne, ne tentez pas de contourner les restrictions de sécurité ou de la plateforme, ne procédez pas à l'ingénierie inverse de parties protégées du service, ne surchargez pas le serveur et n'utilisez pas l'app pour des activités illégales, abusives, trompeuses ou nuisibles.

        Permissions et disponibilité : certaines fonctionnalités nécessitent des permissions iOS telles que le Temps d'Écran, les notifications, la caméra, les Activités en Direct et l'accès réseau. Apple, les paramètres de l'appareil, le comportement du système d'exploitation, la connectivité et la disponibilité du serveur peuvent affecter le fonctionnement attendu des fonctionnalités.

        Contenu généré par l'IA : les résumés de progrès peuvent être générés à l'aide de systèmes automatisés. Ils sont destinés uniquement à la réflexion et à l'accompagnement en productivité. Examinez-les avec votre propre jugement avant de vous y fier.

        Suppression de compte et résiliation : vous pouvez demander la suppression de votre compte depuis le Profil. Spike AI peut suspendre ou résilier l'accès si la loi, les règles de la plateforme, des préoccupations de sécurité ou un abus grave l'exigent.

        Modifications : Spike AI peut mettre à jour ces Conditions à mesure que l'app évolue. L'utilisation continue après une mise à jour signifie que vous acceptez les Conditions mises à jour.

        Contact : pour toute question sur ces Conditions, contactez le support Spike AI via le canal de support fourni par l'app ou la fiche de l'App Store.
        """,

        // Focus Mode
        "focus_title": "Focus", "select_mode": "Sélectionner le Mode",
        "chill": "Zen", "focus": "Focus", "lock_in": "Verrouillage", "sweat": "Athlète",
        "gentle_nudges": "Rappels doux", "confirm_intent": "Confirmer l'intention",
        "no_bypass": "Sans contournement", "move_to_unlock": "Bougez pour déverrouiller",
        "activate_focus": "Activer le Mode Focus", "deactivate_focus": "Désactiver le Mode Focus",
        "mode_active": "Mode Actif",
        "reminders_scheduled": "Rappels programmés",
        "apps_prompt_active": "app(s) — invite \"Êtes-vous sûr ?\" active",
        "apps_blocked": "app(s) bloquée(s)",
        "temp_access_active": "Accès temporaire actif",
        "apps_require_movement": "app(s) nécessitent du mouvement pour déverrouiller",
        "notifications_label": "Notifications",
        "notifications_enabled": "Notifications activées",
        "notifications_denied": "Notifications refusées",
        "enable_notif_settings": "Activez les notifications dans les Réglages.",
        "allow_notif_desc": "Autorisez les notifications pour que Spike AI puisse vous envoyer des rappels de focus.",
        "enable_notifications": "Activer les Notifications",
        "screen_time_access": "Accès Temps d'Écran",
        "screen_time_authorized": "Temps d'Écran autorisé",
        "allow_screen_time": "Autoriser le Temps d'Écran",
        "tap_to_allow": "Appuyez ci-dessous pour autoriser l'accès au Temps d'Écran.",
        "open_settings_manual": "Ou ouvrez les Réglages pour activer manuellement",
        "open_settings": "Ouvrir les Réglages",
        "app_selection": "Sélection d'Apps", "selections": "sélection(s)",
        "choose_apps_confirm": "Choisissez les apps à confirmer avant ouverture.",
        "choose_apps_block": "Choisissez les apps à bloquer.",
        "choose_apps_movement": "Choisissez les apps à déverrouiller par le mouvement.",
        "change_selection": "Modifier la Sélection", "select_apps": "Sélectionner des Apps",
        "movement_unlock": "Déverrouillage par Mouvement",
        "movement_desc": "Les pompes et les levers sont suivis par détection corporelle IA. Chaque répétition vérifiée ajoute 1 minute d'accès aux apps sélectionnées.",
        "access_available": "Accès disponible pour %@",
        "open_camera": "Ouvrir la Vérification Caméra",
        "lock_in_mode": "Mode Verrouillage",
        "lock_in_warning": "Les apps affichent un écran rouge sans contournement. Vous devez revenir ici pour désactiver le Mode Verrouillage.",
        "sweat_mode": "Mode Athlète",
        "do_exercises": "Faites des pompes ou des levers pour gagner du temps",
        "add_minutes": "Ajouter %d Minute(s)",
        "keep_in_view": "Gardez vos épaules, bras ou hanches dans le champ",
        "camera_required": "L'accès à la caméra est requis pour les vérifications de mouvement.",
        "camera_disabled": "L'accès à la caméra est désactivé. Activez-le dans les Réglages pour utiliser le Mode Effort.",
        "camera_unavailable": "L'accès à la caméra n'est pas disponible.",
        "starting_camera": "Démarrage de la caméra...",
        "camera_active": "Caméra active",
        "allow_camera": "Autoriser l'Accès à la Caméra",
        "focus_mode_title": "Mode Focus",
        "focus_mode_desc": "Prenez le contrôle de vos habitudes numériques avec des modes ciblés et professionnels.",
        "about_permissions": "À Propos des Permissions",
        "permissions_desc": "Le Mode Zen nécessite l'autorisation de notifications. Les Modes Focus, Verrouillage et Effort nécessitent l'autorisation du Temps d'Écran. Le Mode Effort utilise également la caméra pour les vérifications de mouvement.",
        "get_started": "Commencer", "skip": "Passer",
        "unlocked_for": "Déverrouillé pour %@",

        // Chill mode descriptions
        "chill_desc": "Rappels quotidiens par notifications. Pas de contrôle d'apps — juste des incitations douces pour rester intentionnel.",
        "focus_desc": "Quand vous ouvrez une app sélectionnée, Spike AI demande \"Êtes-vous sûr ?\" Vous pouvez l'ouvrir normalement ou revenir à vos tâches. Les apps ne sont pas bloquées.",
        "lock_in_desc": "Les apps sélectionnées sont bloquées tant que le Verrouillage est actif. Vous pouvez désactiver le mode depuis Spike AI.",
        "sweat_desc": "Les apps sélectionnées restent bloquées jusqu'à ce que vous effectuiez une pompe ou un lever vérifié par caméra. Chaque répétition vérifiée débloque 1 minute.",

        // Motivational (deactivation)
        "giving_up_title": "Vous progressez — n'abandonnez pas maintenant",
        "giving_up_msg": "Vous avez encore des objectifs non atteints pour aujourd'hui. Chaque tâche terminée construit de l'élan. Restez engagé — votre futur vous en remerciera.",
        "giving_up_continue": "Rester Concentré", "giving_up_stop": "Désactiver Quand Même",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Votre système de productivité personnel",
        "start_setup": "Démarrer la Configuration",
        "make_phone_work": "Faites travailler votre téléphone\npour vos objectifs.",
        "onboarding_welcome_desc": "Réduisez le défilement irréfléchi, protégez votre temps de concentration et transformez de vraies tâches en progrès visibles.",
        "did_you_know": "Le saviez-vous ?",
        "did_you_know_subtitle": "Une personne passe en moyenne 7 heures par jour sur son téléphone. Cela représente",
        "hours_per_day": "heures par jour",
        "days_per_month": "jours par mois",
        "days_per_year": "jours par an",
        "years_of_life": "années de votre vie",
        "screen_time_reality": "Et certaines personnes passent encore plus de temps.",
        "dont_worry_title": "Ne vous inquiétez pas",
        "spike_has_your_back": "Spike AI est là pour vous",
        "solution_desc": "Nous vous aiderons à maximiser votre productivité, à vous rapprocher de vos objectifs et à construire les habitudes qui vous transformeront en la meilleure version de vous-même.",
        "screen_time_access_title": "Accès Temps d'Écran",
        "grant_access": "Accorder l'Accès",
        "which_apps": "Choisissez vos\napps distrayantes",
        "choose_apps_protect": "Sélectionnez les apps qui vous font perdre du temps. Nous les bloquerons pendant les modes de focus.",
        "apple_screen_time_required": "Apple exige l'accès au Temps d'Écran avant que Spike AI puisse afficher votre liste d'apps.",
        "save_apps": "Enregistrer et Continuer",
        "change_selected_apps": "Modifier les apps sélectionnées",
        "ready_change_life": "Prêt à changer\nvotre vie ?",
        "ready_change_desc": "Créez votre compte pour enregistrer vos choix et commencer votre parcours.",
        "benefit_no_distraction": "Les apps distrayantes ne vous dérangeront plus",
        "benefit_discover_modes": "Découvrez 4 types différents de modes de focus",
        "benefit_track_progress": "Suivez vos progrès et rapprochez-vous de vos objectifs",
        "create_account": "Créer un Compte",
        "protect_focus": "Protéger le Focus",
        "block_feeds": "Bloquer les fils",
        "finish_tasks": "Terminer les tâches",
        "energy_plus_three": "+3 Énergie",
        "selected_count": "%d sélectionnée(s)",
        "no_apps_selected": "Aucune app sélectionnée",
        "saved_for_modes": "Enregistrées pour les modes de protection",
        "select_apps_to_control": "Sélectionnez les apps que vous souhaitez contrôler",
        "clean_room": "Ranger la Chambre",
        "snap_proof": "Photo-preuve une fois terminé",
        "ai_verifies_task": "L'IA vérifie la tâche",
        "energy_earned": "+3 Énergie gagnée",
        "on_track": "En bonne voie",
        "energy": "Énergie",
        "tasks_completed": "Tâches accomplies",
        "focus_protected": "Focus protégé",
        "scrolling_avoided": "Défilement évité",
        "continue_apple": "Continuer avec Apple",
        "continue_google": "Continuer avec Google",
        "continue_email": "Continuer par e-mail",
        "enter_email": "Entrez votre e-mail",
        "send_sign_in_link": "Nous vous enverrons un lien de connexion",
        "check_email": "Vérifiez votre e-mail",
        "sent_link_to": "Nous avons envoyé un lien de connexion à",
        "tap_link": "Appuyez sur le lien pour vous connecter automatiquement.",
        "open_mail": "Ouvrir l'App Mail",
        "open_with": "Ouvrir avec",
        "didnt_get_email": "Vous n'avez pas reçu l'e-mail ?",
        "resend": "Renvoyer",
        "resend_in": "Renvoyer dans %ds",
        "new_link_sent": "Un nouveau lien a été envoyé !",
        "valid_email": "Entrez une adresse e-mail valide.",
        "by_continuing": "En continuant, vous acceptez les",
        "and_word": "et",

        // Screen Time Onboarding
        "screen_time_title": "Temps d'Écran",
        "screen_time_permission_desc": "Spike AI a besoin de l'autorisation Temps d'Écran pour les modes Focus, Verrouillage et Effort. Cela lui permet d'afficher des invites et des blocages pour les apps que vous choisissez.",
        "screen_time_denied": "L'autorisation a été refusée. Vous pouvez l'activer dans les Réglages.",
        "ask_before_opening": "Demander Avant d'Ouvrir",
        "block_apps_completely": "Bloquer les Apps Complètement",
        "stay_accountable": "Restez Responsable",
        "stay_accountable_desc": "Suivez vos progrès et gardez vos habitudes de focus visibles.",
        "skip_for_now": "Passer pour l'Instant",

        // Live Activity
        "daily_goals_title": "Objectifs Quotidiens",
        "of_done": "sur %d terminé(s)",
        "more_to_go": "+%d encore",

        // Chill morning
        "good_morning": "Bonjour ! Restez intentionnel aujourd'hui. Révisez vos tâches et gardez le focus.",

        // General
        "error": "Erreur", "ok": "OK", "yes": "Oui", "no": "Non",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Passer en Mode Détente ?",
        "stay_focused_btn": "Rester Concentré",
        "switch_anyway_btn": "Changer Quand Même",
        "switch_to_chill_msg": "Vous avez encore des objectifs non atteints. Passer en Mode Détente désactive le blocage des apps, ce qui augmente le risque de ne pas terminer vos objectifs aujourd'hui.",
        "task_notification": "Notification de Tâche",
        "missed_alarm": "Alarme Manquée",
        "quote_of_day": "Citation du Jour",
        "new_quotes_daily": "De nouvelles citations arrivent chaque jour à 5h00",
        "focus_day_label": "Journée Focus",
        "missed_label": "Manqué",
        "access_granted": "Accès accordé",
        "goal_reminder": "Rappel d'Objectif",
        "spike_ai_focus": "Spike AI Focus",
        "goals_required_title": "Objectifs Requis",
        "goals_required_desc_focus": "Le mode Focus bloque les apps sélectionnées uniquement lorsque vous avez des objectifs non atteints. Ajoutez des objectifs dans l'onglet Accueil pour activer le blocage des apps.",
        "goals_required_desc_lockin": "Le mode Concentration bloque les apps sélectionnées uniquement lorsque vous avez des objectifs non atteints. Ajoutez des objectifs dans l'onglet Accueil pour activer le blocage des apps.",
        "save": "Enregistrer",
        "no_goals_reminder_body": "Vous n'avez défini aucun objectif pour aujourd'hui. Prenez un moment pour planifier votre journée !",
        "dont_forget": "N'oubliez pas",
        "chill_morning_body": "Bonjour ! Restez intentionnel aujourd'hui. Passez en revue vos tâches et restez concentré.",
        "every_day": "Tous les jours",
        "weekdays": "Jours ouvrables",
        "weekends": "Week-ends",
        "time_to_focus": "C'est l'heure de se concentrer !",

        // Additional UI strings
        "next_quote_in": "Prochaine citation dans %@",
        "enable_notif_chill": "Activez les notifications avant de lancer le mode Détente.",
        "enable_screen_time_mode": "Activez l'accès au Temps d'écran avant de lancer ce mode.",
        "select_app_before_mode": "Sélectionnez au moins une app, catégorie ou site web avant de lancer ce mode.",
        "mode_not_ready": "Ce mode n'est pas prêt à démarrer.",
        "protection_stopped_no_apps": "La protection s'est arrêtée car aucune app n'est sélectionnée.",
        "protection_stopped_screen_time": "La protection s'est arrêtée car l'accès au Temps d'écran a changé.",
        "max_reminders": "Vous pouvez avoir jusqu'à %d rappels de concentration.",
        "front_camera_unavailable": "La caméra frontale n'est pas disponible.",
        "task_title_empty": "Le titre de la tâche ne peut pas être vide.",
        "goal_title_empty": "Le titre de l'objectif ne peut pas être vide.",
        "rate_limit_wait": "Veuillez patienter %d secondes avant de générer un autre résumé.",
        "missed_alarm_for": "Vous avez manqué l'alarme pour : %@",
        "stay_with_plan": "Tenez le cap.",
        "motivation_small_wins": "Les petites victoires s'accumulent.",
        "motivation_next_step": "Terminez la prochaine étape.",
        "motivation_protect_hour": "Protégez l'heure devant vous.",
        "motivation_consistency": "La régularité bat l'intensité.",
        "monthly_scope_btn": "Mensuel",
        "yearly_scope_btn": "Annuel",
        "restoring_session": "Restauration de votre session...",

        // Milestones
        "milestone_3day_streak": "Série de 3 jours",
        "milestone_3day_desc": "Un rythme régulier a commencé.",
        "milestone_7day_streak": "Série de 7 jours",
        "milestone_7day_desc": "Une semaine de concentration complète.",
        "milestone_10h_protected": "10 heures protégées",
        "milestone_10h_desc": "Du temps protégé pour l'essentiel.",
        "milestone_30_focus": "30 jours de concentration",
        "milestone_30_desc": "De la constance avec du poids réel.",

        // Narratives
        "narrative_improved": "Votre temps d'écran a diminué par rapport à la semaine dernière.",
        "narrative_consistent": "Vous êtes resté constant cette semaine et avez protégé votre concentration.",
        "narrative_more_days": "Vous avez complété plus de jours de concentration que d'habitude.",
        "narrative_building": "Vous construisez le rythme un jour concentré à la fois.",

        // Screen time
        "screen_time_trend_pending": "La tendance du temps d'écran apparaîtra au fur et à mesure que l'historique d'utilisation se développe.",
        "screen_time_improved": "Le temps d'écran a diminué de %d%%",
        "screen_time_higher": "Le temps d'écran est légèrement supérieur à la normale",
        "screen_time_steady": "Le temps d'écran est stable cette semaine",

        // Benchmarks
        "benchmark_pending": "Le temps d'écran moyen apparaîtra lorsque l'app aura enregistré un historique d'utilisation. Le point de référence mondial est d'environ 7 heures par jour.",
        "benchmark_below": "Votre moyenne sur 7 jours est de %@, en dessous de la moyenne mondiale de 7 heures. C'est une bonne direction.",
        "benchmark_above": "Votre moyenne sur 7 jours est de %@, au-dessus de la moyenne mondiale de 7 heures. Une petite réduction aujourd'hui peut changer la tendance.",
        "benchmark_matching": "Votre moyenne sur 7 jours est de %@, égale à la moyenne mondiale de 7 heures.",

        // Task editing
        "edit_task": "Modifier la tâche",
        "task_name_placeholder": "Nom de la tâche",
        "task_reminder_default": "Rappel de tâche",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - German
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let de: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Über die Fokusmodi",
        "no_active_goals_title": "Keine aktiven Ziele",
        "no_active_goals_btn": "Verstanden",
        "no_active_goals_msg": "Fokus und Sperre laufen nur, solange du ein unerledigtes Ziel hast, auf das du hinarbeitest. Füge ein Ziel hinzu — oder aktiviere eines erneut — und starte dann deine Sitzung.",
        // Tab bar
        "tab_home": "Start", "tab_progress": "Fortschritt", "tab_mode": "Modus", "tab_profile": "Profil",

        // Home
        "today": "Heute", "tomorrow": "Morgen", "yesterday": "Gestern",
        "back_to_today": "Zurück zu Heute",
        "add_first_task": "Tippe auf +, um deine erste Aufgabe hinzuzufügen",
        "no_tasks_this_day": "Keine Aufgaben an diesem Tag",
        "new_task": "Neue Aufgabe",
        "what_to_do": "Was musst du erledigen?",
        "task": "Aufgabe", "schedule": "Planen",
        "pick_date_hint": "Wähle ein beliebiges Datum — heute, nächste Woche oder in einigen Monaten.",
        "priority": "Priorität", "low": "Niedrig", "medium": "Mittel", "high": "Hoch",
        "notification": "Benachrichtigung",
        "silent_push": "Stille Push-Benachrichtigung",
        "notification_desc": "Sendet eine einmalige Push-Benachrichtigung zur geplanten Zeit. Sie erscheint leise auf deinem Sperrbildschirm und in der Mitteilungszentrale.",
        "reminder": "Erinnerung",
        "alarm_sound": "Alarm mit Ton und Vibration",
        "reminder_desc": "Funktioniert wie ein Wecker — ein spezieller Ton wird abgespielt und dein Telefon vibriert ununterbrochen, bis du die Schaltfläche Ablehnen auf dem Bildschirm drückst. Ideal für Besprechungen und Fristen.",
        "cancel": "Abbrechen", "add": "Hinzufügen", "edit": "Bearbeiten", "delete": "Löschen",
        "jump_to_date": "Zu Datum springen", "done": "Fertig",
        "task_limit": "Du hast das Limit von 25 Aufgaben für dieses Datum erreicht.",
        "time": "Zeit", "date": "Datum", "select_date": "Datum Auswählen",

        // Alarm
        "reminder_title": "Erinnerung", "dismiss": "Ablehnen",

        // Progress
        "daily_progress": "Täglicher Fortschritt", "streaks": "Serien", "focus_days": "Fokustage",
        "consistency": "Beständigkeit",
        "set_first_goal": "Setze dein erstes Ziel für heute",
        "all_goals_completed": "Alle Tagesziele erreicht",
        "goals_completed": "von", "daily_goals_completed": "Tagesziele erreicht",
        "daily_goals": "Tagesziele", "remaining": "übrig",
        "no_goals_planned": "Keine Ziele geplant",
        "complete_to_focus": "Schließe jede Aufgabe ab, um heute als Fokustag zu markieren.",
        "add_task_to_start": "Füge eine Aufgabe von Start hinzu, um Tagesziele zu verfolgen.",
        "daily_plan_complete": "Tagesplan abgeschlossen",
        "ai_weekly_summary": "KI-Wochenbericht",
        "creating_summary": "Dein Wochenbericht wird erstellt...",
        "generate_summary": "Bericht Erstellen", "refresh_summary": "Bericht Aktualisieren",
        "first_summary_coming": "Dein erster KI-Wochenbericht ist unterwegs.",
        "first_summary_desc": "Er wird am %@ um 21 Uhr bereit sein. Er enthält Einblicke in deinen Fortschritt, verpasste Aufgaben und den besten Fokusmodus für dich.",
        "next_update": "Nächste Aktualisierung: %@",
        "weekly_recap": "Deine wöchentliche Zusammenfassung der Fokustage, Aufgaben und Produktivitätstrends ist bereit.",
        "screen_time_7day": "7-Tage-Bildschirmzeit", "best_streak": "Beste Serie",
        "days": "Tage", "milestones": "Meilensteine", "milestone_unlocked": "Meilenstein Freigeschaltet",
        "continue_btn": "Weiter", "history_calendar": "Verlaufskalender",
        "mode_used": "Verwendeter Modus", "completed": "Erledigt", "not_completed": "Nicht Erledigt",
        "no_completed_tasks": "Keine abgeschlossenen Aufgaben für diesen Tag verzeichnet.",
        "everything_completed": "Alles wurde erledigt.",
        "no_missed_tasks": "Keine verpassten Aufgaben für diesen Tag verzeichnet.",
        "streak_day": "Serientag", "missed_day": "Verpasster Tag",
        "first_name": "Vorname", "last_name": "Nachname",
        "avatar_color": "Avatar-Farbe",
        "whats_your_name": "Wie heißt du?",
        "name_helps": "Das hilft dabei, dein Erlebnis zu personalisieren.",
        "name_save_failed": "Wir konnten deinen Namen nicht speichern. Überprüfe deine Verbindung und versuche es erneut.",
        "continue_btn_name": "Weiter",
        "wins": "Erfolge", "next_action": "Nächste Aktion", "average": "Durchschnitt",
        "todays_completion": "Heutiger Fortschritt",
        "streaks_this_month": "Serien diesen Monat",
        "streak_days": "Serientage", "non_streak_days": "Tage ohne Serie",
        "monthly_streak_summary": "%d Serien diesen Monat • %d Serientage, %d Tage ohne Serie",
        "duration_average": "%@ Durchschnitt",

        // Profile
        "personal_details": "Persönliche Daten",
        "personal_info": "Persönliche Informationen",
        "update_email_name": "Aktualisiere deine E-Mail und deinen vollständigen Namen.",
        "and_username": "und Benutzername",
        "invite_friends": "Freunde Einladen",
        "refer_friend_title": "Empfiehl einen Freund und verdiene 10 $",
        "refer_friend_desc": "Verdiene 10 $ pro Freund, der sich mit deinem Promo-Code anmeldet.",
        "upgrade_family_plan": "Zum Familientarif Wechseln",
        "goals_tracking": "Ziele und Tracking",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Ernährungsziele Bearbeiten",
        "tracking_reminders": "Tracking-Erinnerungen",
        "email_not_editable": "Deine E-Mail ist mit deinem Login verbunden und kann hier nicht bearbeitet werden.",
        "theme": "Design",
        "theme_desc": "Verwende die Systemdarstellung oder wähle einen festen Hell-/Dunkelmodus.",
        "appearance": "Darstellung",
        "appearance_desc": "Wähle helle, dunkle oder Systemdarstellung",
        "live_activity_profile_desc": "Zeige deinen täglichen Fortschritt auf dem Sperrbildschirm und der Dynamic Island",
        "system": "System", "light": "Hell", "dark": "Dunkel",
        "live_activity": "Live-Aktivität",
        "live_activity_desc": "Zeige die heutigen Ziele, Serien und eine frische Motivation auf dem Sperrbildschirm.",
        "privacy_policy": "Datenschutzrichtlinie",
        "privacy_desc": "Erfahre, wie App-Daten und Geräteberechtigungen verwendet werden.",
        "terms_of_service": "Nutzungsbedingungen",
        "terms_desc": "Lies die Regeln zur Nutzung der App und ihrer Fokus-Werkzeuge.",
        "follow_us": "Folge uns",
        "sign_out": "Abmelden",
        "sign_out_desc": "Diese Sitzung auf dem aktuellen Gerät beenden.",
        "delete_account": "Konto Löschen",
        "delete_account_desc": "Dein Konto und die synchronisierten App-Daten dauerhaft löschen.",
        "delete_account_title": "Konto Löschen",
        "delete_account_msg": "Diese Aktion ist dauerhaft. Alle deine Daten werden gelöscht und können nicht wiederhergestellt werden.",
        "delete_account_continue": "Weiter",
        "delete_account_final_title": "Dauerhaft Löschen?",
        "delete_account_final_msg": "Bitte bestätige noch einmal. Wenn du dein Konto löschst, meldet Spike AI dich ab und leitet dich zur Anmeldeseite weiter.",
        "deleting_account": "Konto wird gelöscht...",
        "delete_failed": "Kontolöschung fehlgeschlagen. Bitte versuche es erneut oder kontaktiere den Support.",
        "language": "Sprache",
        "language_desc": "Wähle die Sprache für alle App-Inhalte.",
        "set_name": "Name festlegen",
        "profile_name_prompt": "Wie sollen wir dich nennen?",
        "profile_name_desc": "Füge den Namen hinzu, den Spike AI in deinem Profil und deiner Produktivitätserfahrung verwenden soll.",
        "full_name": "Vollständiger Name", "display_name": "Anzeigename",
        "email": "E-Mail",
        "save_changes": "Änderungen Speichern",
        "save_footer": "Änderungen werden in deinem Profil gespeichert und überall verwendet, wo deine Identität in der App erscheint.",
        "signed_in": "Angemeldet",
        "account": "Konto", "preferences": "Einstellungen",
        "support_legal": "Support und Rechtliches", "account_actions": "Kontoaktionen",
        "pref_show_completed": "Erledigte Aufgaben Anzeigen",
        "pref_show_completed_desc": "Erledigte Aufgaben in deiner täglichen Liste sichtbar halten.",
        "pref_quotes": "Motivationszitate",
        "pref_quotes_desc": "Ein inspirierendes Zitat auf deinem Fortschrittsbildschirm anzeigen.",
        "legal_updated": "Zuletzt aktualisiert: 25. Mai 2026",
        "privacy_body": """
        Zuletzt aktualisiert: 25. Mai 2026

        Spike AI ist eine Produktivitäts- und Fokus-App. Diese Datenschutzrichtlinie erläutert, wie Spike AI Informationen verarbeitet, die für Konten, Aufgabenplanung, Erinnerungen, Fokusmodi, Bildschirmzeit-Steuerung, Fortschrittsverfolgung und KI-generierte Produktivitätsberichte verwendet werden.

        Informationen, die wir erfassen: Kontokennungen wie deine E-Mail-Adresse und Benutzer-ID; Profildetails, die du angeben möchtest, wie Anzeigename und vollständiger Name; Aufgaben, Ziele, Erinnerungen, Erledigungsverlauf, Fokusmodus-Einstellungen, App-Auswahl-Token und Fortschrittsmetriken. Wir können auch technische Aufzeichnungen speichern, die zur Aufrechterhaltung eines zuverlässigen und sicheren Dienstes erforderlich sind.

        Bildschirmzeit und App-Auswahl: App-, Kategorie- und Webdomain-Auswahlen werden über Apples FamilyControls- und ManagedSettings-Frameworks verarbeitet. Spike AI speichert die von Apple bereitgestellten Token, die zur Anwendung deiner ausgewählten Fokusmodi erforderlich sind. Wir verwenden diese Auswahlen nicht für Werbung.

        Kameranutzung im Schweiß-Modus: Der Kamerazugriff wird für geräteinterne Körperhaltungsprüfungen verwendet, damit du durch Bewegung temporären App-Zugang erhalten kannst. Spike AI lädt für diese Funktion keine Videoframes hoch und verwendet Kameradaten nicht für Werbung.

        Benachrichtigungen und Erinnerungen: Spike AI verwendet die Benachrichtigungsberechtigung, um von dir konfigurierte Aufgabenerinnerungen, Alarme und Fokus-Hinweise zu senden. Du kannst den Benachrichtigungszugriff jederzeit in den iOS-Einstellungen ändern.

        KI-Zusammenfassungen: Wenn du eine Fortschrittszusammenfassung erstellst, können aktuelle Aufgaben-, Ziel-, Fokus- und Produktivitätsmetriken vom Spike-AI-Server verarbeitet werden, um die Zusammenfassung zu erstellen. Vermeide die Eingabe sensibler persönlicher Informationen in Aufgabennamen oder Zielen, wenn du nicht möchtest, dass sie für Produktivitätsfunktionen verarbeitet werden.

        Wie wir Informationen verwenden: Um dich zu authentifizieren, dein Konto zu synchronisieren, Fokus-Werkzeuge bereitzustellen, Erinnerungen zu planen, Fortschritte anzuzeigen, Produktivitätseinblicke zu personalisieren, vor Missbrauch zu schützen, Probleme zu beheben und gesetzliche Verpflichtungen zu erfüllen. Spike AI verkauft deine persönlichen Informationen nicht.

        Datenlöschung: Du kannst dich abmelden oder die dauerhafte Kontolöschung über das Profil anfordern. Die Kontolöschung entfernt dein Authentifizierungskonto und die synchronisierten App-Daten, die mit diesem Konto verknüpft sind, vorbehaltlich einer begrenzten Aufbewahrung, die für Sicherheit, Betrugsprävention, Streitbeilegung oder gesetzliche Compliance erforderlich ist.

        Deine Optionen: Du kannst Profildetails bearbeiten, Sprach- und Darstellungseinstellungen ändern, die Live-Aktivität deaktivieren, Geräteberechtigungen in den Einstellungen widerrufen, bestimmte Fokusmodi nicht mehr verwenden oder dein Konto löschen.

        Kontakt: Bei Fragen zum Datenschutz oder Problemen mit der Kontolöschung wende dich an den Spike-AI-Support über den von der App oder dem App-Store-Eintrag bereitgestellten Supportkanal.
        """,
        "terms_body": """
        Zuletzt aktualisiert: 25. Mai 2026

        Diese Nutzungsbedingungen regeln deine Nutzung von Spike AI, einschließlich Aufgaben, Erinnerungen, Fokusmodi, Bildschirmzeit-App-Hinweise und -Sperren, Schweiß-Modus-Bewegungsprüfungen, Fortschrittsverfolgung und KI-generierte Zusammenfassungen.

        Berechtigung und Konto: Du bist für das von dir erstellte Konto verantwortlich und dafür, den Zugang zu deiner E-Mail und deinem Gerät sicher zu halten. Verwende genaue Angaben, wenn die App nach Profildetails fragt.

        Produktivitätszweck: Spike AI wurde entwickelt, um persönliche Produktivität und bewusste Gerätenutzung zu unterstützen. Es ist kein medizinischer, psychischer, Notfall-, Sicherheits-, Kinderschutz-, Arbeitsüberwachungs- oder Geräteverwaltungsdienst. Verlasse dich nicht auf Spike AI, wenn der Ausfall einer Erinnerung, Sperre, Aufforderung, Kameraprüfung, Benachrichtigung, Netzwerkanfrage oder Apple-Berechtigung Schaden verursachen könnte.

        Deine Verantwortlichkeiten: Wähle Fokuseinstellungen, die deiner Situation angemessen sind; überprüfe die App-Auswahl vor der Aktivierung eines Modus; deaktiviere Modi, wenn sie nicht mehr deinen Bedürfnissen entsprechen; befolge das geltende Recht und Apples Plattformbedingungen; und vermeide die Eingabe sensibler Informationen in Aufgaben oder Zielen, es sei denn, du bist mit deren Verwendung in der App einverstanden.

        Akzeptable Nutzung: Missbrauche Spike AI nicht, störe nicht das Gerät oder Konto einer anderen Person, versuche nicht, Sicherheits- oder Plattformbeschränkungen zu umgehen, führe kein Reverse Engineering geschützter Teile des Dienstes durch, überlade das Backend nicht und nutze die App nicht für rechtswidrige, missbräuchliche, betrügerische oder schädliche Aktivitäten.

        Berechtigungen und Verfügbarkeit: Einige Funktionen erfordern iOS-Berechtigungen wie Bildschirmzeit, Benachrichtigungen, Kamera, Live-Aktivitäten und Netzwerkzugang. Apple, Geräteeinstellungen, Betriebssystemverhalten, Konnektivität und Backend-Verfügbarkeit können beeinflussen, ob Funktionen wie erwartet funktionieren.

        KI-generierte Inhalte: Fortschrittszusammenfassungen können mit automatisierten Systemen erstellt werden. Sie dienen nur zur Reflexion und Produktivitätsbegleitung. Überprüfe sie mit eigenem Urteilsvermögen, bevor du dich auf sie verlässt.

        Kontolöschung und Kündigung: Du kannst die Kontolöschung über das Profil anfordern. Spike AI kann den Zugang aussetzen oder beenden, wenn dies durch Gesetze, Plattformregeln, Sicherheitsbedenken oder schweren Missbrauch erforderlich ist.

        Änderungen: Spike AI kann diese Bedingungen aktualisieren, wenn sich die App weiterentwickelt. Die fortgesetzte Nutzung nach einer Aktualisierung bedeutet, dass du die aktualisierten Bedingungen akzeptierst.

        Kontakt: Bei Fragen zu diesen Bedingungen wende dich an den Spike-AI-Support über den von der App oder dem App-Store-Eintrag bereitgestellten Supportkanal.
        """,

        // Focus Mode
        "focus_title": "Fokus", "select_mode": "Modus Wählen",
        "chill": "Sanft", "focus": "Fokus", "lock_in": "Sperre", "sweat": "Athlet",
        "gentle_nudges": "Sanfte Hinweise", "confirm_intent": "Absicht bestätigen",
        "no_bypass": "Kein Umgehen", "move_to_unlock": "Bewegen zum Entsperren",
        "activate_focus": "Fokusmodus Aktivieren", "deactivate_focus": "Fokusmodus Deaktivieren",
        "mode_active": "Modus Aktiv",
        "reminders_scheduled": "Erinnerungen geplant",
        "apps_prompt_active": "App(s) — \"Bist du sicher?\"-Abfrage aktiv",
        "apps_blocked": "App(s) gesperrt",
        "temp_access_active": "Temporärer Zugang aktiv",
        "apps_require_movement": "App(s) erfordern Bewegung zum Entsperren",
        "notifications_label": "Benachrichtigungen",
        "notifications_enabled": "Benachrichtigungen aktiviert",
        "notifications_denied": "Benachrichtigungen abgelehnt",
        "enable_notif_settings": "Aktiviere Benachrichtigungen in den Einstellungen.",
        "allow_notif_desc": "Erlaube Benachrichtigungen, damit Spike AI dir Fokus-Erinnerungen senden kann.",
        "enable_notifications": "Benachrichtigungen Aktivieren",
        "screen_time_access": "Bildschirmzeit-Zugriff",
        "screen_time_authorized": "Bildschirmzeit autorisiert",
        "allow_screen_time": "Bildschirmzeit Erlauben",
        "tap_to_allow": "Tippe unten, um den Bildschirmzeit-Zugriff zu erlauben.",
        "open_settings_manual": "Oder öffne die Einstellungen, um es manuell zu aktivieren",
        "open_settings": "Einstellungen Öffnen",
        "app_selection": "App-Auswahl", "selections": "Auswahl(en)",
        "choose_apps_confirm": "Wähle, welche Apps vor dem Öffnen bestätigt werden sollen.",
        "choose_apps_block": "Wähle, welche Apps gesperrt werden sollen.",
        "choose_apps_movement": "Wähle, welche Apps durch Bewegung entsperrt werden sollen.",
        "change_selection": "Auswahl Ändern", "select_apps": "Apps Auswählen",
        "movement_unlock": "Entsperrung durch Bewegung",
        "movement_desc": "Liegestütze und Kniebeugen werden mit KI-Körpererkennung verfolgt. Jede verifizierte Wiederholung fügt 1 Minute Zugang zu ausgewählten Apps hinzu.",
        "access_available": "Zugang verfügbar für %@",
        "open_camera": "Kamera-Prüfung Öffnen",
        "lock_in_mode": "Sperrmodus",
        "lock_in_warning": "Apps zeigen einen roten Bildschirm ohne Umgehung. Du musst hierher zurückkehren, um den Sperrmodus auszuschalten.",
        "sweat_mode": "Athlet-Modus",
        "do_exercises": "Mache Liegestütze oder Kniebeugen, um Zeit zu verdienen",
        "add_minutes": "%d Minute(n) Hinzufügen",
        "keep_in_view": "Halte deine Schultern, Arme oder Hüften sichtbar",
        "camera_required": "Kamerazugriff ist für Bewegungsprüfungen erforderlich.",
        "camera_disabled": "Kamerazugriff ist deaktiviert. Aktiviere ihn in den Einstellungen, um den Schweiß-Modus zu nutzen.",
        "camera_unavailable": "Kamerazugriff ist nicht verfügbar.",
        "starting_camera": "Kamera wird gestartet...",
        "camera_active": "Kamera aktiv",
        "allow_camera": "Kamerazugriff Erlauben",
        "focus_mode_title": "Fokusmodus",
        "focus_mode_desc": "Übernimm die Kontrolle über deine digitalen Gewohnheiten mit fokussierten, professionellen Modi.",
        "about_permissions": "Über Berechtigungen",
        "permissions_desc": "Der Sanft-Modus benötigt die Benachrichtigungsberechtigung. Der Fokus-, Sperr- und Schweiß-Modus benötigen die Bildschirmzeit-Autorisierung. Der Schweiß-Modus nutzt auch den Kamerazugriff für Bewegungsprüfungen.",
        "get_started": "Loslegen", "skip": "Überspringen",
        "unlocked_for": "Entsperrt für %@",

        // Chill mode descriptions
        "chill_desc": "Tägliche Erinnerungen über Benachrichtigungen. Keine App-Steuerung — nur sanfte Hinweise, um bewusst zu bleiben.",
        "focus_desc": "Wenn du eine ausgewählte App öffnest, fragt Spike AI \"Bist du sicher?\" Du kannst sie normal öffnen oder zu deinen Aufgaben zurückkehren. Apps werden nicht gesperrt.",
        "lock_in_desc": "Ausgewählte Apps sind gesperrt, solange die Sperre aktiv ist. Du kannst den Modus über Spike AI deaktivieren.",
        "sweat_desc": "Ausgewählte Apps bleiben gesperrt, bis du eine kamerageprüfte Liegestütze oder Kniebeuge absolvierst. Jede verifizierte Wiederholung schaltet 1 Minute frei.",

        // Motivational (deactivation)
        "giving_up_title": "Du machst Fortschritte — hör nicht auf",
        "giving_up_msg": "Du hast noch unerledigte Ziele für heute. Jede abgeschlossene Aufgabe baut Schwung auf. Bleib dran — dein zukünftiges Ich wird es dir danken.",
        "giving_up_continue": "Fokus Beibehalten", "giving_up_stop": "Trotzdem Deaktivieren",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Dein persönliches Produktivitätssystem",
        "start_setup": "Einrichtung Starten",
        "make_phone_work": "Lass dein Handy für\ndeine Ziele arbeiten.",
        "onboarding_welcome_desc": "Reduziere gedankenloses Scrollen, schütze deine Fokuszeit und verwandle echte Aufgaben in sichtbaren Fortschritt.",
        "did_you_know": "Wusstest du das?",
        "did_you_know_subtitle": "Ein Mensch verbringt durchschnittlich 7 Stunden pro Tag am Handy. Das sind",
        "hours_per_day": "Stunden am Tag",
        "days_per_month": "Tage im Monat",
        "days_per_year": "Tage im Jahr",
        "years_of_life": "Jahre deines Lebens",
        "screen_time_reality": "Und manche Menschen verbringen noch mehr Zeit.",
        "dont_worry_title": "Keine Sorge",
        "spike_has_your_back": "Spike AI hat deinen Rücken",
        "solution_desc": "Wir helfen dir, deine Produktivität zu maximieren, deinen Zielen näher zu kommen und die Gewohnheiten aufzubauen, die dich zur besten Version deiner selbst machen.",
        "screen_time_access_title": "Bildschirmzeit-Zugriff",
        "grant_access": "Zugriff Gewähren",
        "which_apps": "Wähle deine\nablenkenden Apps",
        "choose_apps_protect": "Wähle die Apps, die deine Zeit verschwenden. Wir sperren sie während der Fokusmodi.",
        "apple_screen_time_required": "Apple erfordert Bildschirmzeit-Zugriff, bevor Spike AI deine App-Liste anzeigen kann.",
        "save_apps": "Speichern und Fortfahren",
        "change_selected_apps": "Ausgewählte Apps ändern",
        "ready_change_life": "Bereit, dein\nLeben zu ändern?",
        "ready_change_desc": "Erstelle dein Konto, um deine Auswahl zu speichern und deine Reise zu beginnen.",
        "benefit_no_distraction": "Ablenkende Apps werden dich nicht mehr stören",
        "benefit_discover_modes": "Entdecke 4 verschiedene Arten von Fokusmodi",
        "benefit_track_progress": "Verfolge deinen Fortschritt und komm deinen Zielen näher",
        "create_account": "Konto Erstellen",
        "protect_focus": "Fokus Schützen",
        "block_feeds": "Feeds blockieren",
        "finish_tasks": "Aufgaben erledigen",
        "energy_plus_three": "+3 Energie",
        "selected_count": "%d ausgewählt",
        "no_apps_selected": "Noch keine Apps ausgewählt",
        "saved_for_modes": "Für Schutzmodi gespeichert",
        "select_apps_to_control": "Wähle die Apps, die du kontrollieren möchtest",
        "clean_room": "Zimmer Aufräumen",
        "snap_proof": "Foto als Beweis nach Abschluss",
        "ai_verifies_task": "KI verifiziert die Aufgabe",
        "energy_earned": "+3 Energie verdient",
        "on_track": "Auf Kurs",
        "energy": "Energie",
        "tasks_completed": "Aufgaben erledigt",
        "focus_protected": "Fokus geschützt",
        "scrolling_avoided": "Scrollen vermieden",
        "continue_apple": "Weiter mit Apple",
        "continue_google": "Weiter mit Google",
        "continue_email": "Weiter mit E-Mail",
        "enter_email": "E-Mail eingeben",
        "send_sign_in_link": "Wir senden dir einen Anmeldelink",
        "check_email": "Überprüfe deine E-Mail",
        "sent_link_to": "Wir haben einen Anmeldelink gesendet an",
        "tap_link": "Tippe auf den Link, um dich automatisch anzumelden.",
        "open_mail": "Mail-App Öffnen",
        "open_with": "Öffnen mit",
        "didnt_get_email": "Keine E-Mail erhalten?",
        "resend": "Erneut Senden",
        "resend_in": "Erneut senden in %ds",
        "new_link_sent": "Ein neuer Link wurde gesendet!",
        "valid_email": "Gib eine gültige E-Mail-Adresse ein.",
        "by_continuing": "Durch Fortfahren stimmst du den",
        "and_word": "und",

        // Screen Time Onboarding
        "screen_time_title": "Bildschirmzeit",
        "screen_time_permission_desc": "Spike AI benötigt die Bildschirmzeit-Berechtigung für den Fokus-, Sperr- und Schweiß-Modus. Damit können App-Hinweise und -Sperren für die von dir gewählten Apps angezeigt werden.",
        "screen_time_denied": "Berechtigung wurde abgelehnt. Du kannst sie in den Einstellungen aktivieren.",
        "ask_before_opening": "Vor dem Öffnen Fragen",
        "block_apps_completely": "Apps Vollständig Sperren",
        "stay_accountable": "Bleib Verantwortlich",
        "stay_accountable_desc": "Verfolge den Fortschritt und halte deine Fokus-Gewohnheiten sichtbar.",
        "skip_for_now": "Vorerst Überspringen",

        // Live Activity
        "daily_goals_title": "Tagesziele",
        "of_done": "von %d erledigt",
        "more_to_go": "+%d noch offen",

        // Chill morning
        "good_morning": "Guten Morgen! Bleib heute bewusst. Überprüfe deine Aufgaben und bleib fokussiert.",

        // General
        "error": "Fehler", "ok": "OK", "yes": "Ja", "no": "Nein",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Zum Chill-Modus wechseln?",
        "stay_focused_btn": "Fokussiert bleiben",
        "switch_anyway_btn": "Trotzdem wechseln",
        "switch_to_chill_msg": "Du hast noch unerledigte Ziele. Der Wechsel zum Chill-Modus hebt die App-Sperre auf, was das Risiko erhöht, deine Ziele heute nicht zu erreichen.",
        "task_notification": "Aufgabenbenachrichtigung",
        "missed_alarm": "Verpasster Alarm",
        "quote_of_day": "Zitat des Tages",
        "new_quotes_daily": "Neue Zitate erscheinen täglich um 5:00 Uhr",
        "focus_day_label": "Fokustag",
        "missed_label": "Verpasst",
        "access_granted": "Zugriff gewährt",
        "goal_reminder": "Zielerinnerung",
        "spike_ai_focus": "Spike AI Fokus",
        "goals_required_title": "Ziele erforderlich",
        "goals_required_desc_focus": "Der Fokusmodus blockiert ausgewählte Apps nur, wenn du unerledigte Ziele hast. Füge Ziele im Start-Tab hinzu, um die App-Sperre zu aktivieren.",
        "goals_required_desc_lockin": "Der Sperrmodus blockiert ausgewählte Apps nur, wenn du unerledigte Ziele hast. Füge Ziele im Start-Tab hinzu, um die App-Sperre zu aktivieren.",
        "save": "Speichern",
        "no_goals_reminder_body": "Du hast noch keine Ziele für heute gesetzt. Nimm dir einen Moment, um deinen Tag zu planen!",
        "dont_forget": "Nicht vergessen",
        "chill_morning_body": "Guten Morgen! Bleib heute bewusst. Überprüfe deine Aufgaben und bleib fokussiert.",
        "every_day": "Jeden Tag",
        "weekdays": "Wochentage",
        "weekends": "Wochenenden",
        "time_to_focus": "Zeit, sich zu konzentrieren!",

        // Additional UI strings
        "next_quote_in": "Nächstes Zitat in %@",
        "enable_notif_chill": "Aktiviere Benachrichtigungen, bevor du den Chill-Modus startest.",
        "enable_screen_time_mode": "Aktiviere den Bildschirmzeit-Zugriff, bevor du diesen Modus startest.",
        "select_app_before_mode": "Wähle mindestens eine App, Kategorie oder Website, bevor du diesen Modus startest.",
        "mode_not_ready": "Dieser Modus ist noch nicht startbereit.",
        "protection_stopped_no_apps": "Der Schutz wurde gestoppt, da keine Apps ausgewählt sind.",
        "protection_stopped_screen_time": "Der Schutz wurde gestoppt, da sich der Bildschirmzeit-Zugriff geändert hat.",
        "max_reminders": "Du kannst bis zu %d Fokus-Erinnerungen haben.",
        "front_camera_unavailable": "Die Frontkamera ist nicht verfügbar.",
        "task_title_empty": "Der Aufgabentitel darf nicht leer sein.",
        "goal_title_empty": "Der Zieltitel darf nicht leer sein.",
        "rate_limit_wait": "Bitte warte %d Sekunden, bevor du eine weitere Zusammenfassung erstellst.",
        "missed_alarm_for": "Du hast den Alarm verpasst für: %@",
        "stay_with_plan": "Bleib beim Plan.",
        "motivation_small_wins": "Kleine Erfolge summieren sich.",
        "motivation_next_step": "Erledige den nächsten Schritt.",
        "motivation_protect_hour": "Schütze die Stunde vor dir.",
        "motivation_consistency": "Beständigkeit schlägt Intensität.",
        "monthly_scope_btn": "Monatlich",
        "yearly_scope_btn": "Jährlich",
        "restoring_session": "Sitzung wird wiederhergestellt...",

        // Milestones
        "milestone_3day_streak": "3-Tage-Serie",
        "milestone_3day_desc": "Ein stetiger Rhythmus hat begonnen.",
        "milestone_7day_streak": "7-Tage-Serie",
        "milestone_7day_desc": "Eine ganze fokussierte Woche.",
        "milestone_10h_protected": "10 Stunden geschützt",
        "milestone_10h_desc": "Zeit geschützt für das Wesentliche.",
        "milestone_30_focus": "30 Fokustage",
        "milestone_30_desc": "Beständigkeit mit echtem Gewicht.",

        // Narratives
        "narrative_improved": "Deine Bildschirmzeit hat sich im Vergleich zur letzten Woche verbessert.",
        "narrative_consistent": "Du warst diese Woche konstant und hast deinen Fokus geschützt.",
        "narrative_more_days": "Du hast mehr Fokustage als üblich abgeschlossen.",
        "narrative_building": "Du baust den Rhythmus einen fokussierten Tag nach dem anderen auf.",

        // Screen time
        "screen_time_trend_pending": "Der Bildschirmzeit-Trend erscheint, sobald mehr Nutzungsdaten vorliegen.",
        "screen_time_improved": "Bildschirmzeit verbessert um %d%%",
        "screen_time_higher": "Bildschirmzeit ist etwas höher als üblich",
        "screen_time_steady": "Bildschirmzeit ist diese Woche stabil",

        // Benchmarks
        "benchmark_pending": "Die durchschnittliche Bildschirmzeit wird angezeigt, sobald die App Nutzungsdaten erfasst. Der globale Referenzwert liegt bei etwa 7 Stunden pro Tag.",
        "benchmark_below": "Dein 7-Tage-Durchschnitt liegt bei %@, unter dem globalen Durchschnitt von 7 Stunden. Das ist eine starke Richtung.",
        "benchmark_above": "Dein 7-Tage-Durchschnitt liegt bei %@, über dem globalen Durchschnitt von 7 Stunden. Eine kleine Reduzierung heute kann den Trend ändern.",
        "benchmark_matching": "Dein 7-Tage-Durchschnitt liegt bei %@, gleich dem globalen Durchschnitt von 7 Stunden.",

        // Task editing
        "edit_task": "Aufgabe bearbeiten",
        "task_name_placeholder": "Aufgabenname",
        "task_reminder_default": "Aufgabenerinnerung",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Portuguese
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let pt: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Sobre os modos de foco",
        "no_active_goals_title": "Nenhum objetivo ativo",
        "no_active_goals_btn": "Entendi",
        "no_active_goals_msg": "Os modos Foco e Bloqueio só funcionam enquanto você tem um objetivo não concluído para alcançar. Adicione um objetivo — ou reative um — e depois inicie sua sessão.",
        // Tab bar
        "tab_home": "Início", "tab_progress": "Progresso", "tab_mode": "Modo", "tab_profile": "Perfil",

        // Home
        "today": "Hoje", "tomorrow": "Amanhã", "yesterday": "Ontem",
        "back_to_today": "Voltar para Hoje",
        "add_first_task": "Toque em + para adicionar sua primeira tarefa",
        "no_tasks_this_day": "Sem tarefas neste dia",
        "new_task": "Nova Tarefa",
        "what_to_do": "O que você precisa fazer?",
        "task": "Tarefa", "schedule": "Agendar",
        "pick_date_hint": "Escolha qualquer data futura — hoje, na próxima semana ou meses à frente.",
        "priority": "Prioridade", "low": "Baixa", "medium": "Média", "high": "Alta",
        "notification": "Notificação",
        "silent_push": "Notificação silenciosa",
        "notification_desc": "Envia uma notificação única no horário agendado. Ela aparece silenciosamente na tela de bloqueio e na Central de Notificações.",
        "reminder": "Lembrete",
        "alarm_sound": "Alarme com som e vibração",
        "reminder_desc": "Funciona como um alarme — um som especial tocará e seu telefone vibrará continuamente até que você pressione o botão Dispensar na tela. Ótimo para reuniões e prazos.",
        "cancel": "Cancelar", "add": "Adicionar", "edit": "Editar", "delete": "Excluir",
        "jump_to_date": "Ir para Data", "done": "Pronto",
        "task_limit": "Você atingiu o limite de 25 tarefas para esta data.",
        "time": "Hora", "date": "Data", "select_date": "Selecionar Data",

        // Alarm
        "reminder_title": "Lembrete", "dismiss": "Dispensar",

        // Progress
        "daily_progress": "Progresso Diário", "streaks": "sequências", "focus_days": "dias de foco",
        "consistency": "consistência",
        "set_first_goal": "Defina sua primeira meta para hoje",
        "all_goals_completed": "Todas as metas diárias concluídas",
        "goals_completed": "de", "daily_goals_completed": "metas diárias concluídas",
        "daily_goals": "Metas Diárias", "remaining": "restantes",
        "no_goals_planned": "Sem metas planejadas",
        "complete_to_focus": "Complete todas as tarefas para marcar hoje como dia de foco.",
        "add_task_to_start": "Adicione uma tarefa em Início para começar a acompanhar metas diárias.",
        "daily_plan_complete": "Plano diário concluído",
        "ai_weekly_summary": "Resumo Semanal IA",
        "creating_summary": "Criando seu resumo semanal...",
        "generate_summary": "Gerar Resumo", "refresh_summary": "Atualizar Resumo",
        "first_summary_coming": "Seu primeiro resumo semanal de IA está a caminho.",
        "first_summary_desc": "Estará pronto em %@ às 21h. Inclui insights sobre seu progresso, tarefas perdidas e o melhor modo de foco para você.",
        "next_update": "Próxima atualização: %@",
        "weekly_recap": "Seu resumo semanal de dias de foco, tarefas e tendências de produtividade está pronto.",
        "screen_time_7day": "Tempo de Tela 7 Dias", "best_streak": "Melhor Sequência",
        "days": "dias", "milestones": "Conquistas", "milestone_unlocked": "Conquista Desbloqueada",
        "continue_btn": "Continuar", "history_calendar": "Calendário de Histórico",
        "mode_used": "Modo Usado", "completed": "Concluído", "not_completed": "Não Concluído",
        "no_completed_tasks": "Nenhuma tarefa concluída registrada para este dia.",
        "everything_completed": "Tudo foi concluído.",
        "no_missed_tasks": "Nenhuma tarefa perdida registrada para este dia.",
        "streak_day": "Dia de Sequência", "missed_day": "Dia Perdido",
        "first_name": "Nome", "last_name": "Sobrenome",
        "avatar_color": "Cor do Avatar",
        "whats_your_name": "Qual é o seu nome?",
        "name_helps": "Isso ajuda a personalizar sua experiência.",
        "name_save_failed": "Não conseguimos salvar seu nome. Verifique sua conexão e tente novamente.",
        "continue_btn_name": "Continuar",
        "wins": "Vitórias", "next_action": "Próxima Ação", "average": "média",
        "todays_completion": "Conclusão de hoje",
        "streaks_this_month": "sequências neste mês",
        "streak_days": "dias de sequência", "non_streak_days": "dias sem sequência",
        "monthly_streak_summary": "%d sequências neste mês • %d dias de sequência, %d dias sem sequência",
        "duration_average": "%@ de média",

        // Profile
        "personal_details": "Dados Pessoais",
        "personal_info": "Informações Pessoais",
        "update_email_name": "Atualize seu e-mail e nome completo.",
        "and_username": "e nome de usuário",
        "invite_friends": "Convidar Amigos",
        "refer_friend_title": "Indique um amigo e ganhe $10",
        "refer_friend_desc": "Ganhe $10 por amigo que se cadastrar com seu código promocional.",
        "upgrade_family_plan": "Atualizar para Plano Família",
        "goals_tracking": "Metas e Acompanhamento",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Editar Metas de Nutrição",
        "tracking_reminders": "Lembretes de Acompanhamento",
        "email_not_editable": "Seu e-mail está vinculado ao seu login e não pode ser editado aqui.",
        "theme": "Tema",
        "theme_desc": "Use a aparência do sistema ou escolha um modo claro/escuro fixo.",
        "appearance": "Aparência",
        "appearance_desc": "Escolha aparência clara, escura ou do sistema",
        "live_activity_profile_desc": "Mostre seu progresso diário na tela de bloqueio e na Dynamic Island",
        "system": "Sistema", "light": "Claro", "dark": "Escuro",
        "live_activity": "Atividade ao Vivo",
        "live_activity_desc": "Mostre as metas de hoje, sequência e uma motivação fresca na tela de bloqueio.",
        "privacy_policy": "Política de Privacidade",
        "privacy_desc": "Veja como os dados do app e as permissões do dispositivo são usados.",
        "terms_of_service": "Termos e Condições",
        "terms_desc": "Leia as regras de uso do app e suas ferramentas de foco.",
        "follow_us": "Siga-nos",
        "sign_out": "Sair",
        "sign_out_desc": "Encerrar esta sessão no dispositivo atual.",
        "delete_account": "Excluir Conta",
        "delete_account_desc": "Excluir permanentemente sua conta e dados sincronizados do app.",
        "delete_account_title": "Excluir Conta",
        "delete_account_msg": "Esta ação é permanente. Todos os seus dados serão excluídos e não poderão ser recuperados.",
        "delete_account_continue": "Continuar",
        "delete_account_final_title": "Excluir Permanentemente?",
        "delete_account_final_msg": "Por favor confirme mais uma vez. Se você excluir sua conta, Spike AI encerrará sua sessão e o levará de volta à página de login.",
        "deleting_account": "Excluindo conta...",
        "delete_failed": "Falha ao excluir a conta. Tente novamente ou entre em contato com o suporte.",
        "language": "Idioma",
        "language_desc": "Escolha o idioma para todo o conteúdo do app.",
        "set_name": "Defina seu nome",
        "profile_name_prompt": "Como devemos te chamar?",
        "profile_name_desc": "Adicione o nome que Spike AI deve usar em seu perfil e experiência de produtividade.",
        "full_name": "Nome Completo", "display_name": "Nome de Exibição",
        "email": "E-mail",
        "save_changes": "Salvar Alterações",
        "save_footer": "As alterações são salvas em seu perfil e usadas em qualquer lugar onde sua identidade aparece no app.",
        "signed_in": "Conectado",
        "account": "Conta", "preferences": "Preferências",
        "support_legal": "Suporte e Jurídico", "account_actions": "Ações da Conta",
        "pref_show_completed": "Mostrar Tarefas Concluídas",
        "pref_show_completed_desc": "Manter tarefas concluídas visíveis na sua lista diária.",
        "pref_quotes": "Citações Motivacionais",
        "pref_quotes_desc": "Mostrar uma citação inspiradora na sua tela de progresso.",
        "legal_updated": "Última atualização: 25 de maio de 2026",
        "privacy_body": """
        Última atualização: 25 de maio de 2026

        Spike AI é um aplicativo de produtividade e foco. Esta Política de Privacidade explica como Spike AI lida com as informações usadas para fornecer contas, planejamento de tarefas, lembretes, modos de foco, controles de Tempo de Tela, acompanhamento de progresso e resumos de produtividade gerados por IA.

        Informações que coletamos: identificadores de conta como seu endereço de e-mail e ID de usuário; detalhes de perfil que você escolhe fornecer, como nome de exibição e nome completo; tarefas, metas, lembretes, histórico de conclusão, configurações de modo de foco, tokens de seleção de apps e métricas de progresso. Também podemos armazenar registros técnicos necessários para manter o serviço confiável e seguro.

        Tempo de Tela e seleção de apps: as seleções de apps, categorias e domínios web são gerenciadas pelos frameworks FamilyControls e ManagedSettings da Apple. Spike AI armazena os tokens fornecidos pela Apple necessários para aplicar seus modos de foco selecionados. Não usamos essas seleções para publicidade.

        Uso da câmera no Modo Suor: o acesso à câmera é usado para verificações de postura corporal no dispositivo para que você possa obter acesso temporário a apps por meio de movimento. Spike AI não carrega quadros de vídeo para este recurso e não usa dados da câmera para publicidade.

        Notificações e lembretes: Spike AI usa a permissão de notificações para enviar lembretes de tarefas, alarmes e dicas de foco que você configura. Você pode alterar o acesso a notificações nos Ajustes do iOS a qualquer momento.

        Resumos de IA: se você gerar um resumo de progresso, métricas recentes de tarefas, metas, foco e produtividade podem ser processadas pelo servidor de Spike AI para produzir o resumo. Evite inserir informações pessoais sensíveis em nomes de tarefas ou metas se não quiser que sejam processadas para recursos de produtividade.

        Como usamos as informações: para autenticar você, sincronizar sua conta, fornecer ferramentas de foco, agendar lembretes, mostrar o progresso, personalizar insights de produtividade, proteger contra uso indevido, solucionar problemas e cumprir obrigações legais. Spike AI não vende suas informações pessoais.

        Exclusão de dados: você pode sair ou solicitar a exclusão permanente da conta em Perfil. A exclusão da conta remove sua conta de autenticação e os dados sincronizados do app associados a essa conta, sujeito a retenção limitada exigida para segurança, prevenção de fraude, resolução de disputas ou conformidade legal.

        Suas escolhas: você pode editar detalhes do perfil, alterar preferências de idioma e aparência, desativar a Atividade ao Vivo, revogar permissões do dispositivo nos Ajustes, parar de usar modos de foco específicos ou excluir sua conta.

        Contato: para questões de privacidade ou problemas com exclusão de conta, entre em contato com o suporte de Spike AI pelo canal de suporte fornecido pelo app ou pela listagem na App Store.
        """,
        "terms_body": """
        Última atualização: 25 de maio de 2026

        Estes Termos e Condições regem seu uso de Spike AI, incluindo tarefas, lembretes, modos de foco, avisos e bloqueios de apps do Tempo de Tela, verificações de movimento do Modo Suor, acompanhamento de progresso e resumos gerados por IA.

        Elegibilidade e conta: você é responsável pela conta que cria e por manter o acesso ao seu e-mail e dispositivo seguros. Use informações precisas quando o app solicitar detalhes do perfil.

        Propósito de produtividade: Spike AI foi projetado para apoiar a produtividade pessoal e o uso intencional do dispositivo. Não é um serviço médico, de saúde mental, de emergência, de segurança, de controle parental, de monitoramento de emprego ou de gerenciamento de dispositivos. Não dependa de Spike AI quando a falha de um lembrete, bloqueio, aviso, verificação de câmera, notificação, solicitação de rede ou permissão da Apple possa causar dano.

        Suas responsabilidades: escolha configurações de foco apropriadas para sua situação; revise as seleções de apps antes de ativar um modo; desative os modos quando eles não atenderem mais às suas necessidades; obedeça à lei aplicável e aos termos da plataforma Apple; e evite inserir informações sensíveis em tarefas ou metas, a menos que esteja confortável em usá-las no app.

        Uso aceitável: não faça mau uso de Spike AI, não interfira com o dispositivo ou conta de outra pessoa, não tente contornar restrições de segurança ou da plataforma, não faça engenharia reversa de partes protegidas do serviço, não sobrecarregue o servidor nem use o app para atividades ilegais, abusivas, enganosas ou prejudiciais.

        Permissões e disponibilidade: alguns recursos requerem permissões do iOS como Tempo de Tela, notificações, câmera, Atividades ao Vivo e acesso à rede. Apple, configurações do dispositivo, comportamento do sistema operacional, conectividade e disponibilidade do servidor podem afetar se os recursos funcionam conforme esperado.

        Conteúdo gerado por IA: resumos de progresso podem ser gerados usando sistemas automatizados. Eles são apenas para reflexão e orientação de produtividade. Avalie-os com seu próprio julgamento antes de confiar neles.

        Exclusão de conta e encerramento: você pode solicitar a exclusão da conta em Perfil. Spike AI pode suspender ou encerrar o acesso se exigido por lei, regras da plataforma, preocupações de segurança ou uso indevido grave.

        Alterações: Spike AI pode atualizar estes Termos conforme o app evolui. O uso continuado após uma atualização significa que você aceita os Termos atualizados.

        Contato: para perguntas sobre estes Termos, entre em contato com o suporte de Spike AI pelo canal de suporte fornecido pelo app ou pela listagem na App Store.
        """,

        // Focus Mode
        "focus_title": "Foco", "select_mode": "Selecionar Modo",
        "chill": "Tranquilo", "focus": "Foco", "lock_in": "Bloqueio", "sweat": "Atleta",
        "gentle_nudges": "Lembretes suaves", "confirm_intent": "Confirmar intenção",
        "no_bypass": "Sem contorno", "move_to_unlock": "Mova-se para desbloquear",
        "activate_focus": "Ativar Modo Foco", "deactivate_focus": "Desativar Modo Foco",
        "mode_active": "Modo Ativo",
        "reminders_scheduled": "Lembretes agendados",
        "apps_prompt_active": "app(s) — aviso \"Tem certeza?\" ativo",
        "apps_blocked": "app(s) bloqueados",
        "temp_access_active": "Acesso temporário ativo",
        "apps_require_movement": "app(s) requerem movimento para desbloquear",
        "notifications_label": "Notificações",
        "notifications_enabled": "Notificações ativadas",
        "notifications_denied": "Notificações negadas",
        "enable_notif_settings": "Ative as notificações nos Ajustes.",
        "allow_notif_desc": "Permita notificações para que Spike AI possa enviar lembretes de foco.",
        "enable_notifications": "Ativar Notificações",
        "screen_time_access": "Acesso ao Tempo de Tela",
        "screen_time_authorized": "Tempo de Tela autorizado",
        "allow_screen_time": "Permitir Tempo de Tela",
        "tap_to_allow": "Toque abaixo para permitir o acesso ao Tempo de Tela.",
        "open_settings_manual": "Ou abra os Ajustes para ativar manualmente",
        "open_settings": "Abrir Ajustes",
        "app_selection": "Seleção de Apps", "selections": "seleção(ões)",
        "choose_apps_confirm": "Escolha quais apps confirmar antes de abrir.",
        "choose_apps_block": "Escolha quais apps bloquear.",
        "choose_apps_movement": "Escolha quais apps desbloquear com movimento.",
        "change_selection": "Alterar Seleção", "select_apps": "Selecionar Apps",
        "movement_unlock": "Desbloqueio por Movimento",
        "movement_desc": "Flexões e agachamentos são rastreados com detecção corporal por IA. Cada repetição verificada adiciona 1 minuto de acesso aos apps selecionados.",
        "access_available": "Acesso disponível por %@",
        "open_camera": "Abrir Verificação da Câmera",
        "lock_in_mode": "Modo Bloqueio",
        "lock_in_warning": "Apps mostram uma tela vermelha sem contorno. Você deve voltar aqui para desativar o Modo Bloqueio.",
        "sweat_mode": "Modo Atleta",
        "do_exercises": "Faça flexões ou agachamentos para ganhar tempo",
        "add_minutes": "Adicionar %d Minuto(s)",
        "keep_in_view": "Mantenha seus ombros, braços ou quadris visíveis",
        "camera_required": "Acesso à câmera é necessário para verificações de movimento.",
        "camera_disabled": "O acesso à câmera está desativado. Ative-o nos Ajustes para usar o Modo Suor.",
        "camera_unavailable": "O acesso à câmera não está disponível.",
        "starting_camera": "Iniciando câmera...",
        "camera_active": "Câmera ativa",
        "allow_camera": "Permitir Acesso à Câmera",
        "focus_mode_title": "Modo Foco",
        "focus_mode_desc": "Assuma o controle dos seus hábitos digitais com modos focados e profissionais.",
        "about_permissions": "Sobre Permissões",
        "permissions_desc": "O Modo Tranquilo requer permissão de notificações. Os Modos Foco, Bloqueio e Suor requerem autorização de Tempo de Tela. O Modo Suor também usa acesso à câmera para verificações de movimento.",
        "get_started": "Começar", "skip": "Pular",
        "unlocked_for": "Desbloqueado por %@",

        // Chill mode descriptions
        "chill_desc": "Lembretes diários via notificações. Sem controle de apps — apenas lembretes suaves para manter a intenção.",
        "focus_desc": "Ao abrir um app selecionado, Spike AI pergunta \"Tem certeza?\" Você pode abri-lo normalmente ou voltar às suas tarefas. Os apps não são bloqueados.",
        "lock_in_desc": "Os apps selecionados ficam bloqueados enquanto o Bloqueio está ativo. Você pode desativar o modo pelo Spike AI.",
        "sweat_desc": "Os apps selecionados permanecem bloqueados até que você complete uma flexão ou agachamento verificado por câmera. Cada repetição verificada desbloqueia 1 minuto.",

        // Motivational (deactivation)
        "giving_up_title": "Você está progredindo — não pare agora",
        "giving_up_msg": "Você ainda tem metas não concluídas para hoje. Cada tarefa finalizada constrói impulso. Continue comprometido — seu eu futuro vai agradecer.",
        "giving_up_continue": "Manter Foco", "giving_up_stop": "Desativar Mesmo Assim",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Seu sistema pessoal de produtividade",
        "start_setup": "Iniciar Configuração",
        "make_phone_work": "Faça seu celular trabalhar\npara seus objetivos.",
        "onboarding_welcome_desc": "Reduza a rolagem sem propósito, proteja o tempo de foco e transforme tarefas reais em progresso visível.",
        "did_you_know": "Você sabia?",
        "did_you_know_subtitle": "Uma pessoa passa em média 7 horas por dia no celular. Isso são",
        "hours_per_day": "horas por dia",
        "days_per_month": "dias por mês",
        "days_per_year": "dias por ano",
        "years_of_life": "anos da sua vida",
        "screen_time_reality": "E algumas pessoas passam ainda mais.",
        "dont_worry_title": "Não se preocupe",
        "spike_has_your_back": "Spike AI está com você",
        "solution_desc": "Vamos ajudá-lo a maximizar sua produtividade, chegar mais perto dos seus objetivos e construir os hábitos que o transformam na melhor versão de si mesmo.",
        "screen_time_access_title": "Acesso ao Tempo de Tela",
        "grant_access": "Conceder Acesso",
        "which_apps": "Escolha seus\napps que distraem",
        "choose_apps_protect": "Selecione os apps que desperdiçam seu tempo. Vamos bloqueá-los durante os modos de foco.",
        "apple_screen_time_required": "A Apple exige acesso ao Tempo de Tela antes que Spike AI possa mostrar sua lista de apps.",
        "save_apps": "Salvar e Continuar",
        "change_selected_apps": "Alterar apps selecionados",
        "ready_change_life": "Pronto para mudar\nsua vida?",
        "ready_change_desc": "Crie sua conta para salvar suas escolhas e começar sua jornada.",
        "benefit_no_distraction": "Apps que distraem não vão mais te incomodar",
        "benefit_discover_modes": "Descubra 4 tipos diferentes de modos de foco",
        "benefit_track_progress": "Acompanhe seu progresso e chegue mais perto dos seus objetivos",
        "create_account": "Criar Conta",
        "protect_focus": "Proteger Foco",
        "block_feeds": "Bloquear feeds",
        "finish_tasks": "Concluir tarefas",
        "energy_plus_three": "+3 Energia",
        "selected_count": "%d selecionados",
        "no_apps_selected": "Nenhum app selecionado ainda",
        "saved_for_modes": "Salvos para modos de proteção",
        "select_apps_to_control": "Selecione os apps que deseja controlar",
        "clean_room": "Arrumar o Quarto",
        "snap_proof": "Tire foto como prova ao terminar",
        "ai_verifies_task": "A IA verifica a tarefa",
        "energy_earned": "+3 Energia ganha",
        "on_track": "No caminho certo",
        "energy": "Energia",
        "tasks_completed": "Tarefas concluídas",
        "focus_protected": "Foco protegido",
        "scrolling_avoided": "Rolagem evitada",
        "continue_apple": "Continuar com Apple",
        "continue_google": "Continuar com Google",
        "continue_email": "Continuar com e-mail",
        "enter_email": "Digite seu e-mail",
        "send_sign_in_link": "Enviaremos um link de login",
        "check_email": "Verifique seu e-mail",
        "sent_link_to": "Enviamos um link de login para",
        "tap_link": "Toque no link para entrar automaticamente.",
        "open_mail": "Abrir App de E-mail",
        "open_with": "Abrir com",
        "didnt_get_email": "Não recebeu o e-mail?",
        "resend": "Reenviar",
        "resend_in": "Reenviar em %ds",
        "new_link_sent": "Um novo link foi enviado!",
        "valid_email": "Digite um endereço de e-mail válido.",
        "by_continuing": "Ao continuar, você concorda com os",
        "and_word": "e",

        // Screen Time Onboarding
        "screen_time_title": "Tempo de Tela",
        "screen_time_permission_desc": "Spike AI precisa da permissão de Tempo de Tela para os modos Foco, Bloqueio e Suor. Isso permite mostrar avisos e bloqueios para os apps que você escolher.",
        "screen_time_denied": "A permissão foi negada. Você pode ativá-la nos Ajustes.",
        "ask_before_opening": "Perguntar Antes de Abrir",
        "block_apps_completely": "Bloquear Apps Completamente",
        "stay_accountable": "Mantenha-se Responsável",
        "stay_accountable_desc": "Acompanhe o progresso e mantenha seus hábitos de foco visíveis.",
        "skip_for_now": "Pular por Enquanto",

        // Live Activity
        "daily_goals_title": "Metas Diárias",
        "of_done": "de %d concluídas",
        "more_to_go": "+%d a fazer",

        // Chill morning
        "good_morning": "Bom dia! Mantenha a intenção hoje. Revise suas tarefas e mantenha o foco.",

        // General
        "error": "Erro", "ok": "OK", "yes": "Sim", "no": "Não",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Mudar para Modo Tranquilo?",
        "stay_focused_btn": "Manter Foco",
        "switch_anyway_btn": "Mudar Mesmo Assim",
        "switch_to_chill_msg": "Você ainda tem metas não concluídas. Mudar para o Modo Tranquilo remove o bloqueio de apps, o que aumenta o risco de não concluir suas metas hoje.",
        "task_notification": "Notificação de Tarefa",
        "missed_alarm": "Alarme Perdido",
        "quote_of_day": "Frase do Dia",
        "new_quotes_daily": "Novas frases chegam diariamente às 5:00",
        "focus_day_label": "Dia de Foco",
        "missed_label": "Perdido",
        "access_granted": "Acesso concedido",
        "goal_reminder": "Lembrete de Meta",
        "spike_ai_focus": "Spike AI Foco",
        "goals_required_title": "Metas Necessárias",
        "goals_required_desc_focus": "O modo Foco bloqueia apps selecionados apenas quando você tem metas não concluídas. Adicione metas na aba Início para ativar o bloqueio de apps.",
        "goals_required_desc_lockin": "O modo Concentração bloqueia apps selecionados apenas quando você tem metas não concluídas. Adicione metas na aba Início para ativar o bloqueio de apps.",
        "save": "Salvar",
        "no_goals_reminder_body": "Você não definiu nenhuma meta para hoje. Reserve um momento para planejar seu dia!",
        "dont_forget": "Não esqueça",
        "chill_morning_body": "Bom dia! Seja intencional hoje. Revise suas tarefas e mantenha o foco.",
        "every_day": "Todos os dias",
        "weekdays": "Dias úteis",
        "weekends": "Fins de semana",
        "time_to_focus": "Hora de se concentrar!",

        // Additional UI strings
        "next_quote_in": "Próxima citação em %@",
        "enable_notif_chill": "Ative as notificações antes de iniciar o modo Tranquilo.",
        "enable_screen_time_mode": "Ative o acesso ao Tempo de Ecrã antes de iniciar este modo.",
        "select_app_before_mode": "Selecione pelo menos uma app, categoria ou site antes de iniciar este modo.",
        "mode_not_ready": "Este modo não está pronto para iniciar.",
        "protection_stopped_no_apps": "A proteção parou porque nenhuma app está selecionada.",
        "protection_stopped_screen_time": "A proteção parou porque o acesso ao Tempo de Ecrã mudou.",
        "max_reminders": "Pode ter até %d lembretes de foco.",
        "front_camera_unavailable": "A câmera frontal não está disponível.",
        "task_title_empty": "O título da tarefa não pode estar vazio.",
        "goal_title_empty": "O título da meta não pode estar vazio.",
        "rate_limit_wait": "Aguarde %d segundos antes de gerar outro resumo.",
        "missed_alarm_for": "Você perdeu o alarme de: %@",
        "stay_with_plan": "Siga o plano.",
        "motivation_small_wins": "Pequenas vitórias se acumulam.",
        "motivation_next_step": "Conclua o próximo passo.",
        "motivation_protect_hour": "Proteja a hora à sua frente.",
        "motivation_consistency": "Consistência supera intensidade.",
        "monthly_scope_btn": "Mensal",
        "yearly_scope_btn": "Anual",
        "restoring_session": "Restaurando sua sessão...",

        // Milestones
        "milestone_3day_streak": "Sequência de 3 dias",
        "milestone_3day_desc": "Um ritmo constante começou.",
        "milestone_7day_streak": "Sequência de 7 dias",
        "milestone_7day_desc": "Uma semana focada completa.",
        "milestone_10h_protected": "10 horas protegidas",
        "milestone_10h_desc": "Tempo protegido para o que importa.",
        "milestone_30_focus": "30 dias de foco",
        "milestone_30_desc": "Consistência com peso real.",

        // Narratives
        "narrative_improved": "Seu tempo de tela melhorou em comparação com a semana passada.",
        "narrative_consistent": "Você manteve a consistência esta semana e protegeu seu foco.",
        "narrative_more_days": "Você completou mais dias de foco do que o habitual.",
        "narrative_building": "Você está construindo o ritmo um dia focado de cada vez.",

        // Screen time
        "screen_time_trend_pending": "A tendência de tempo de tela aparecerá conforme o histórico de uso cresce.",
        "screen_time_improved": "Tempo de tela melhorou em %d%%",
        "screen_time_higher": "Tempo de tela está ligeiramente acima do normal",
        "screen_time_steady": "Tempo de tela está estável esta semana",

        // Benchmarks
        "benchmark_pending": "O tempo médio de tela aparecerá conforme o app registra o histórico de uso. O ponto de referência global é de cerca de 7 horas por dia.",
        "benchmark_below": "Sua média de 7 dias é %@, abaixo da média global de 7 horas. Essa é uma direção forte.",
        "benchmark_above": "Sua média de 7 dias é %@, acima da média global de 7 horas. Uma pequena redução hoje pode mudar a tendência.",
        "benchmark_matching": "Sua média de 7 dias é %@, igual à média global de 7 horas.",

        // Task editing
        "edit_task": "Editar Tarefa",
        "task_name_placeholder": "Nome da tarefa",
        "task_reminder_default": "Lembrete de tarefa",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Russian
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let ru: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "О режимах фокусировки",
        "no_active_goals_title": "Нет активных целей",
        "no_active_goals_btn": "Понятно",
        "no_active_goals_msg": "Режимы «Фокус» и «Блокировка» работают, только пока у вас есть незавершённая цель. Добавьте цель — или активируйте её снова — и затем начните сессию.",
        // Tab bar
        "tab_home": "Главная", "tab_progress": "Прогресс", "tab_mode": "Режим", "tab_profile": "Профиль",

        // Home
        "today": "Сегодня", "tomorrow": "Завтра", "yesterday": "Вчера",
        "back_to_today": "Вернуться к сегодня",
        "add_first_task": "Нажмите +, чтобы добавить первую задачу",
        "no_tasks_this_day": "На этот день задач нет",
        "new_task": "Новая задача",
        "what_to_do": "Что вам нужно сделать?",
        "task": "Задача", "schedule": "Расписание",
        "pick_date_hint": "Выберите любую дату — сегодня, на следующей неделе или через несколько месяцев.",
        "priority": "Приоритет", "low": "Низкий", "medium": "Средний", "high": "Высокий",
        "notification": "Уведомление",
        "silent_push": "Беззвучное push-уведомление",
        "notification_desc": "Отправляет однократное push-уведомление в назначенное время. Оно появится на экране блокировки и в Центре уведомлений.",
        "reminder": "Напоминание",
        "alarm_sound": "Будильник со звуком и вибрацией",
        "reminder_desc": "Работает как будильник — прозвучит специальный сигнал, и телефон будет вибрировать, пока вы не нажмёте кнопку «Отклонить». Идеально для встреч и дедлайнов.",
        "cancel": "Отмена", "add": "Добавить", "edit": "Изменить", "delete": "Удалить",
        "jump_to_date": "Перейти к дате", "done": "Готово",
        "task_limit": "Вы достигли лимита в 25 задач на эту дату.",
        "time": "Время", "date": "Дата", "select_date": "Выбрать дату",

        // Alarm
        "reminder_title": "Напоминание", "dismiss": "Отклонить",

        // Progress
        "daily_progress": "Дневной прогресс", "streaks": "серии", "focus_days": "дни фокуса",
        "consistency": "стабильность",
        "set_first_goal": "Установите свою первую цель на сегодня",
        "all_goals_completed": "Все дневные цели выполнены",
        "goals_completed": "из",
        "daily_goals_completed": "дневных целей выполнено",
        "daily_goals": "Дневные цели", "remaining": "осталось",
        "no_goals_planned": "Цели не запланированы",
        "complete_to_focus": "Выполните все задачи, чтобы отметить сегодня как день фокуса.",
        "add_task_to_start": "Добавьте задачу с главного экрана, чтобы начать отслеживание дневных целей.",
        "daily_plan_complete": "Дневной план выполнен",
        "ai_weekly_summary": "Еженедельный отчёт ИИ",
        "creating_summary": "Формируется ваш еженедельный отчёт...",
        "generate_summary": "Сформировать отчёт",
        "refresh_summary": "Обновить отчёт",
        "first_summary_coming": "Ваш первый еженедельный отчёт ИИ уже в пути.",
        "first_summary_desc": "Он будет готов %@ в 21:00. В нём будут выводы о вашем прогрессе, пропущенных задачах и лучшем режиме фокуса для вас.",
        "next_update": "Следующее обновление: %@",
        "weekly_recap": "Ваш еженедельный обзор дней фокуса, задач и тенденций продуктивности готов.",
        "screen_time_7day": "Экранное время за 7 дней",
        "best_streak": "Лучшая серия", "days": "дней",
        "milestones": "Достижения", "milestone_unlocked": "Достижение разблокировано",
        "continue_btn": "Продолжить",
        "history_calendar": "Календарь истории",
        "mode_used": "Использованный режим",
        "completed": "Выполнено", "not_completed": "Не выполнено",
        "no_completed_tasks": "За этот день нет записей о выполненных задачах.",
        "everything_completed": "Всё было выполнено.",
        "no_missed_tasks": "За этот день нет записей о пропущенных задачах.",
        "streak_day": "День серии", "missed_day": "Пропущенный день",
        "first_name": "Имя", "last_name": "Фамилия",
        "avatar_color": "Цвет аватара",
        "whats_your_name": "Как вас зовут?",
        "name_helps": "Это поможет персонализировать ваш опыт.",
        "name_save_failed": "Не удалось сохранить ваше имя. Проверьте подключение и попробуйте ещё раз.",
        "continue_btn_name": "Продолжить",
        "wins": "Победы", "next_action": "Следующее действие",
        "average": "в среднем",
        "todays_completion": "Выполнение за сегодня",
        "streaks_this_month": "серий в этом месяце",
        "streak_days": "дней серии", "non_streak_days": "дней без серии",
        "monthly_streak_summary": "%d серий в этом месяце • %d дней серии, %d дней без серии",
        "duration_average": "%@ в среднем",

        // Profile
        "personal_details": "Личные данные",
        "personal_info": "Личная информация",
        "update_email_name": "Обновите адрес электронной почты и полное имя.",
        "and_username": "и имя пользователя",
        "invite_friends": "Пригласить друзей",
        "refer_friend_title": "Пригласите друга и получите $10",
        "refer_friend_desc": "Получайте $10 за каждого друга, зарегистрировавшегося по вашему промокоду.",
        "upgrade_family_plan": "Перейти на семейный план",
        "goals_tracking": "Цели и отслеживание",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Редактировать цели питания",
        "tracking_reminders": "Напоминания об отслеживании",
        "email_not_editable": "Ваш адрес электронной почты привязан к учётной записи и не может быть изменён здесь.",
        "theme": "Тема",
        "theme_desc": "Используйте системное оформление или выберите постоянный светлый/тёмный режим.",
        "appearance": "Оформление",
        "appearance_desc": "Выберите светлое, тёмное или системное оформление",
        "live_activity_profile_desc": "Показывать дневной прогресс на экране блокировки и Dynamic Island",
        "system": "Системная", "light": "Светлая", "dark": "Тёмная",
        "live_activity": "Живая активность",
        "live_activity_desc": "Показывать цели, серию и мотивацию на экране блокировки.",
        "privacy_policy": "Политика конфиденциальности",
        "privacy_desc": "Узнайте, как используются данные приложения и разрешения устройства.",
        "terms_of_service": "Условия использования",
        "terms_desc": "Ознакомьтесь с правилами использования приложения и его инструментов фокуса.",
        "follow_us": "Подписывайтесь",
        "sign_out": "Выйти",
        "sign_out_desc": "Завершить сеанс на текущем устройстве.",
        "delete_account": "Удалить аккаунт",
        "delete_account_desc": "Безвозвратно удалить ваш аккаунт и синхронизированные данные приложения.",
        "delete_account_title": "Удалить аккаунт",
        "delete_account_msg": "Это действие необратимо. Все ваши данные будут удалены без возможности восстановления.",
        "delete_account_continue": "Продолжить",
        "delete_account_final_title": "Удалить навсегда?",
        "delete_account_final_msg": "Пожалуйста, подтвердите ещё раз. Если вы удалите аккаунт, Spike AI завершит ваш сеанс и вернёт вас на страницу входа.",
        "deleting_account": "Удаление аккаунта...",
        "delete_failed": "Не удалось удалить аккаунт. Повторите попытку или обратитесь в службу поддержки.",
        "language": "Язык",
        "language_desc": "Выберите язык для всего контента приложения.",
        "set_name": "Укажите ваше имя",
        "profile_name_prompt": "Как к вам обращаться?",
        "profile_name_desc": "Укажите имя, которое Spike AI будет использовать в вашем профиле и для персонализации.",
        "full_name": "Полное имя",
        "display_name": "Отображаемое имя",
        "email": "Электронная почта",
        "save_changes": "Сохранить изменения",
        "save_footer": "Изменения сохраняются в вашем профиле и используются везде, где в приложении отображается ваша личность.",
        "signed_in": "Вход выполнен",
        "account": "Аккаунт", "preferences": "Настройки",
        "support_legal": "Поддержка и правовая информация",
        "account_actions": "Действия с аккаунтом",
        "pref_show_completed": "Показывать выполненные задачи",
        "pref_show_completed_desc": "Оставлять выполненные задачи видимыми в дневном списке.",
        "pref_quotes": "Мотивационные цитаты",
        "pref_quotes_desc": "Показывать вдохновляющую цитату на экране прогресса.",
        "legal_updated": "Последнее обновление: 25 мая 2026 г.",
        "privacy_body": """
        Последнее обновление: 25 мая 2026 г.

        Spike AI — приложение для продуктивности и фокусировки. Настоящая Политика конфиденциальности описывает, как Spike AI обрабатывает информацию, используемую для предоставления учётных записей, планирования задач, напоминаний, режимов фокуса, управления экранным временем, отслеживания прогресса и формирования ИИ-отчётов о продуктивности.

        Собираемая информация: идентификаторы учётной записи, такие как адрес электронной почты и идентификатор пользователя; данные профиля, которые вы решите указать, такие как отображаемое имя и полное имя; задачи, цели, напоминания, история выполнения, настройки режимов фокуса, токены выбора приложений и метрики прогресса. Мы также можем хранить технические записи, необходимые для обеспечения надёжности и безопасности сервиса.

        Экранное время и выбор приложений: выбор приложений, категорий и веб-доменов осуществляется через фреймворки Apple FamilyControls и ManagedSettings. Spike AI сохраняет токены, предоставленные Apple, для применения выбранных вами режимов фокуса. Мы не используем эти данные для рекламы.

        Использование камеры в режиме «Пот»: доступ к камере используется для проверки положения тела на устройстве, чтобы вы могли получить временный доступ к приложениям через движение. Spike AI не загружает видеокадры для этой функции и не использует данные камеры в рекламных целях.

        Уведомления и напоминания: Spike AI использует разрешение на уведомления для отправки напоминаний о задачах, будильников и подсказок фокуса, которые вы настраиваете. Вы можете изменить доступ к уведомлениям в настройках iOS в любое время.

        ИИ-отчёты: если вы формируете отчёт о прогрессе, данные о последних задачах, целях, режимах фокуса и метриках продуктивности могут обрабатываться серверной частью Spike AI для создания отчёта. Не вводите конфиденциальную информацию в названия задач или целей, если не хотите, чтобы она обрабатывалась для функций продуктивности.

        Как мы используем информацию: для аутентификации, синхронизации вашей учётной записи, предоставления инструментов фокуса, планирования напоминаний, отображения прогресса, персонализации аналитики продуктивности, защиты от злоупотреблений, устранения неполадок и соблюдения правовых обязательств. Spike AI не продаёт вашу персональную информацию.

        Удаление данных: вы можете выйти из системы или запросить безвозвратное удаление аккаунта в разделе «Профиль». При удалении аккаунта удаляется ваша учётная запись и синхронизированные данные приложения, за исключением ограниченного хранения, необходимого для обеспечения безопасности, предотвращения мошенничества, разрешения споров или соблюдения законодательства.

        Ваш выбор: вы можете редактировать данные профиля, менять языковые и оформительские настройки, отключать живую активность, отзывать разрешения устройства в настройках, прекращать использование определённых режимов фокуса или удалить свой аккаунт.

        Контакт: по вопросам конфиденциальности или удаления аккаунта обращайтесь в службу поддержки Spike AI через канал поддержки, указанный в приложении или на странице App Store.
        """,
        "terms_body": """
        Последнее обновление: 25 мая 2026 г.

        Настоящие Условия использования регулируют ваше использование Spike AI, включая задачи, напоминания, режимы фокуса, подсказки и экраны блокировки приложений через экранное время, проверки движения в режиме «Пот», отслеживание прогресса и ИИ-отчёты.

        Право доступа и учётная запись: вы несёте ответственность за созданную учётную запись и за сохранность доступа к вашей электронной почте и устройству. Указывайте точную информацию там, где приложение запрашивает данные профиля.

        Назначение для продуктивности: Spike AI создан для поддержки личной продуктивности и осознанного использования устройства. Это не медицинская, психологическая, экстренная, защитная, родительского контроля, мониторинга занятости или управления устройством служба. Не полагайтесь на Spike AI в ситуациях, где сбой напоминания, блокировки, подсказки, проверки камерой, уведомления, сетевого запроса или разрешения Apple может причинить вред.

        Ваши обязанности: выбирайте настройки фокуса, соответствующие вашей ситуации; проверяйте выбор приложений перед активацией режима; отключайте режимы, когда они больше не соответствуют вашим потребностям; соблюдайте применимое законодательство и условия платформы Apple; не вводите конфиденциальную информацию в задачи или цели, если вам некомфортно использовать её в приложении.

        Допустимое использование: не злоупотребляйте Spike AI, не вмешивайтесь в работу устройства или аккаунта другого пользователя, не пытайтесь обойти защиту или ограничения платформы, не реверс-инженируйте защищённые части сервиса, не перегружайте серверную часть и не используйте приложение для незаконной, оскорбительной, обманной или вредоносной деятельности.

        Разрешения и доступность: для некоторых функций требуются разрешения iOS, такие как экранное время, уведомления, камера, живые активности и сетевой доступ. Apple, настройки устройства, поведение операционной системы, подключение к сети и доступность серверной части могут влиять на корректную работу функций.

        Контент, созданный ИИ: отчёты о прогрессе могут формироваться автоматизированными системами. Они предназначены исключительно для самоанализа и повышения продуктивности. Оценивайте их на основе собственного суждения, прежде чем на них опираться.

        Удаление аккаунта и прекращение доступа: вы можете запросить удаление аккаунта в разделе «Профиль». Spike AI может приостановить или прекратить доступ, если это требуется по закону, правилам платформы, соображениям безопасности или в случае серьёзных злоупотреблений.

        Изменения: Spike AI может обновлять настоящие Условия по мере развития приложения. Продолжение использования после обновления означает ваше согласие с обновлёнными Условиями.

        Контакт: по вопросам, связанным с настоящими Условиями, обращайтесь в службу поддержки Spike AI через канал поддержки, указанный в приложении или на странице App Store.
        """,

        // Focus Mode
        "focus_title": "Фокус", "select_mode": "Выбрать режим",
        "chill": "Лёгкий", "focus": "Фокус", "lock_in": "Блокировка", "sweat": "Атлет",
        "gentle_nudges": "Мягкие напоминания", "confirm_intent": "Подтвердить намерение",
        "no_bypass": "Без обхода", "move_to_unlock": "Двигайтесь для разблокировки",
        "activate_focus": "Включить режим фокуса",
        "deactivate_focus": "Выключить режим фокуса",
        "mode_active": "Режим активен",
        "reminders_scheduled": "Напоминания запланированы",
        "apps_prompt_active": "приложение(-я) — запрос «Вы уверены?» активен",
        "apps_blocked": "приложение(-я) заблокировано(-ы)",
        "temp_access_active": "Временный доступ активен",
        "apps_require_movement": "приложение(-я) требуют движения для разблокировки",
        "notifications_label": "Уведомления",
        "notifications_enabled": "Уведомления включены",
        "notifications_denied": "Уведомления отклонены",
        "enable_notif_settings": "Включите уведомления в настройках.",
        "allow_notif_desc": "Разрешите уведомления, чтобы Spike AI мог отправлять вам напоминания о фокусе.",
        "enable_notifications": "Включить уведомления",
        "screen_time_access": "Доступ к экранному времени",
        "screen_time_authorized": "Экранное время разрешено",
        "allow_screen_time": "Разрешить экранное время",
        "tap_to_allow": "Нажмите ниже, чтобы разрешить доступ к экранному времени.",
        "open_settings_manual": "Или откройте Настройки для включения вручную",
        "open_settings": "Открыть настройки",
        "app_selection": "Выбор приложений",
        "selections": "выбрано",
        "choose_apps_confirm": "Выберите приложения, перед открытием которых требуется подтверждение.",
        "choose_apps_block": "Выберите приложения для блокировки.",
        "choose_apps_movement": "Выберите приложения, которые разблокируются движением.",
        "change_selection": "Изменить выбор",
        "select_apps": "Выбрать приложения",
        "movement_unlock": "Разблокировка движением",
        "movement_desc": "Отжимания и приседания отслеживаются с помощью ИИ-обнаружения тела. Каждое подтверждённое повторение добавляет 1 минуту доступа к выбранным приложениям.",
        "access_available": "Доступ доступен на %@",
        "open_camera": "Открыть проверку камерой",
        "lock_in_mode": "Режим блокировки",
        "lock_in_warning": "Приложения показывают красный экран без обхода. Вы должны вернуться сюда, чтобы отключить режим блокировки.",
        "sweat_mode": "Режим «Атлет»",
        "do_exercises": "Делайте отжимания или приседания, чтобы заработать время",
        "add_minutes": "Добавить %d минут(у/ы)",
        "keep_in_view": "Держите плечи, руки или бёдра в поле зрения камеры",
        "camera_required": "Для проверки движения требуется доступ к камере.",
        "camera_disabled": "Доступ к камере отключён. Включите его в настройках для использования режима «Пот».",
        "camera_unavailable": "Доступ к камере недоступен.",
        "starting_camera": "Запуск камеры...",
        "camera_active": "Камера активна",
        "allow_camera": "Разрешить доступ к камере",
        "focus_mode_title": "Режим фокуса",
        "focus_mode_desc": "Возьмите под контроль свои цифровые привычки с помощью продуманных профессиональных режимов.",
        "about_permissions": "О разрешениях",
        "permissions_desc": "Для режима «Лёгкий» требуются уведомления. Для режимов «Фокус», «Блокировка» и «Пот» требуется разрешение экранного времени. Режим «Пот» также использует камеру для проверки движения.",
        "get_started": "Начать", "skip": "Пропустить",
        "unlocked_for": "Разблокировано на %@",

        // Chill mode descriptions
        "chill_desc": "Ежедневные напоминания через уведомления. Без контроля приложений — только мягкие подсказки для осознанности.",
        "focus_desc": "При открытии выбранного приложения Spike AI спрашивает: «Вы уверены?» Вы можете открыть его как обычно или вернуться к задачам. Приложения не блокируются.",
        "lock_in_desc": "Выбранные приложения заблокированы, пока режим блокировки активен. Вы можете отключить его из Spike AI.",
        "sweat_desc": "Выбранные приложения остаются заблокированными, пока вы не выполните отжимание или приседание с проверкой камерой. Каждое подтверждённое повторение разблокирует 1 минуту.",

        // Motivational (deactivation)
        "giving_up_title": "Вы делаете успехи — не останавливайтесь",
        "giving_up_msg": "У вас ещё есть невыполненные цели на сегодня. Каждая завершённая задача создаёт импульс. Оставайтесь верны цели — ваше будущее «я» скажет вам спасибо.",
        "giving_up_continue": "Сохранить фокус",
        "giving_up_stop": "Всё равно выключить",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Ваша персональная система продуктивности",
        "start_setup": "Начать настройку",
        "make_phone_work": "Пусть ваш телефон работает\nна ваши цели.",
        "onboarding_welcome_desc": "Сократите бездумную прокрутку, защитите время фокуса и превратите реальные задачи в видимый прогресс.",
        "did_you_know": "Знаете ли вы?",
        "did_you_know_subtitle": "В среднем человек проводит 7 часов в день в телефоне. Это",
        "hours_per_day": "часов в день",
        "days_per_month": "дней в месяц",
        "days_per_year": "дней в год",
        "years_of_life": "лет вашей жизни",
        "screen_time_reality": "А некоторые проводят ещё больше.",
        "dont_worry_title": "Не переживайте",
        "spike_has_your_back": "Spike AI поддержит вас",
        "solution_desc": "Мы поможем вам максимизировать продуктивность, приблизиться к целям и выработать привычки, которые превратят вас в лучшую версию себя.",
        "screen_time_access_title": "Доступ к экранному времени",
        "grant_access": "Предоставить доступ",
        "which_apps": "Выберите ваши\nотвлекающие приложения",
        "choose_apps_protect": "Выберите приложения, которые отнимают ваше время. Мы заблокируем их во время режимов фокуса.",
        "apple_screen_time_required": "Apple требует доступ к экранному времени, прежде чем Spike AI сможет показать список приложений.",
        "save_apps": "Сохранить и продолжить",
        "change_selected_apps": "Изменить выбранные приложения",
        "ready_change_life": "Готовы изменить\nсвою жизнь?",
        "ready_change_desc": "Создайте аккаунт, чтобы сохранить свой выбор и начать путь.",
        "benefit_no_distraction": "Отвлекающие приложения больше не будут вам мешать",
        "benefit_discover_modes": "Откройте 4 различных типа режимов фокуса",
        "benefit_track_progress": "Отслеживайте прогресс и приближайтесь к целям",
        "create_account": "Создать аккаунт",
        "protect_focus": "Защитить фокус",
        "block_feeds": "Заблокировать ленты",
        "finish_tasks": "Завершить задачи",
        "energy_plus_three": "+3 Энергия",
        "selected_count": "%d выбрано",
        "no_apps_selected": "Приложения ещё не выбраны",
        "saved_for_modes": "Сохранено для режимов защиты",
        "select_apps_to_control": "Выберите приложения, которые хотите контролировать",
        "clean_room": "Уборка комнаты",
        "snap_proof": "Сфотографируйте результат по завершении",
        "ai_verifies_task": "ИИ проверяет задачу",
        "energy_earned": "+3 Энергия получена",
        "on_track": "В графике",
        "energy": "Энергия",
        "tasks_completed": "Задач выполнено",
        "focus_protected": "Фокус защищён",
        "scrolling_avoided": "Прокрутка предотвращена",
        "continue_apple": "Продолжить с Apple",
        "continue_google": "Продолжить с Google",
        "continue_email": "Продолжить по электронной почте",
        "enter_email": "Введите вашу почту",
        "send_sign_in_link": "Мы отправим вам ссылку для входа",
        "check_email": "Проверьте почту",
        "sent_link_to": "Мы отправили ссылку для входа на",
        "tap_link": "Нажмите на ссылку для автоматического входа.",
        "open_mail": "Открыть почтовое приложение",
        "open_with": "Открыть через",
        "didnt_get_email": "Не получили письмо?",
        "resend": "Отправить повторно",
        "resend_in": "Повторная отправка через %ds",
        "new_link_sent": "Новая ссылка отправлена!",
        "valid_email": "Введите корректный адрес электронной почты.",
        "by_continuing": "Продолжая, вы соглашаетесь с",
        "and_word": "и",

        // Screen Time Onboarding
        "screen_time_title": "Экранное время",
        "screen_time_permission_desc": "Spike AI необходимо разрешение экранного времени для режимов «Фокус», «Блокировка» и «Пот». Это позволяет показывать подсказки и блокировки для выбранных вами приложений.",
        "screen_time_denied": "Разрешение было отклонено. Вы можете включить его в настройках.",
        "ask_before_opening": "Спрашивать перед открытием",
        "block_apps_completely": "Полностью блокировать приложения",
        "stay_accountable": "Сохраняйте ответственность",
        "stay_accountable_desc": "Отслеживайте прогресс и держите свои привычки фокуса на виду.",
        "skip_for_now": "Пропустить пока",

        // Live Activity
        "daily_goals_title": "Дневные цели",
        "of_done": "из %d выполнено",
        "more_to_go": "ещё %d осталось",

        // Chill morning
        "good_morning": "Доброе утро! Будьте осознанны сегодня. Просмотрите свои задачи и сохраняйте фокус.",

        // General
        "error": "Ошибка", "ok": "ОК", "yes": "Да", "no": "Нет",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Переключиться на Режим Отдыха?",
        "stay_focused_btn": "Остаться в фокусе",
        "switch_anyway_btn": "Всё равно переключить",
        "switch_to_chill_msg": "У вас ещё есть незавершённые цели. Переключение на Режим Отдыха снимает блокировку приложений, что увеличивает риск не выполнить ваши цели сегодня.",
        "task_notification": "Уведомление о задаче",
        "missed_alarm": "Пропущенный будильник",
        "quote_of_day": "Цитата дня",
        "new_quotes_daily": "Новые цитаты появляются ежедневно в 5:00",
        "focus_day_label": "День фокуса",
        "missed_label": "Пропущено",
        "access_granted": "Доступ предоставлен",
        "goal_reminder": "Напоминание о цели",
        "spike_ai_focus": "Spike AI Фокус",
        "goals_required_title": "Необходимы цели",
        "goals_required_desc_focus": "Режим Фокус блокирует выбранные приложения только при наличии незавершённых целей. Добавьте цели на вкладке Главная, чтобы активировать блокировку приложений.",
        "goals_required_desc_lockin": "Режим Концентрации блокирует выбранные приложения только при наличии незавершённых целей. Добавьте цели на вкладке Главная, чтобы активировать блокировку приложений.",
        "save": "Сохранить",
        "no_goals_reminder_body": "Вы не поставили ни одной цели на сегодня. Уделите минутку, чтобы спланировать свой день!",
        "dont_forget": "Не забудьте",
        "chill_morning_body": "Доброе утро! Будьте целеустремлённы сегодня. Просмотрите свои задачи и сохраняйте фокус.",
        "every_day": "Каждый день",
        "weekdays": "Будние дни",
        "weekends": "Выходные",
        "time_to_focus": "Время сосредоточиться!",

        // Additional UI strings
        "next_quote_in": "Следующая цитата через %@",
        "enable_notif_chill": "Включите уведомления перед запуском режима «Лёгкий».",
        "enable_screen_time_mode": "Включите доступ к экранному времени перед запуском этого режима.",
        "select_app_before_mode": "Выберите хотя бы одно приложение, категорию или сайт перед запуском этого режима.",
        "mode_not_ready": "Этот режим ещё не готов к запуску.",
        "protection_stopped_no_apps": "Защита остановлена: приложения не выбраны.",
        "protection_stopped_screen_time": "Защита остановлена: доступ к экранному времени изменился.",
        "max_reminders": "Можно создать не более %d напоминаний о фокусе.",
        "front_camera_unavailable": "Фронтальная камера недоступна.",
        "task_title_empty": "Название задачи не может быть пустым.",
        "goal_title_empty": "Название цели не может быть пустым.",
        "rate_limit_wait": "Подождите %d секунд перед созданием нового отчёта.",
        "missed_alarm_for": "Вы пропустили будильник: %@",
        "stay_with_plan": "Придерживайтесь плана.",
        "motivation_small_wins": "Маленькие победы складываются.",
        "motivation_next_step": "Завершите следующий шаг.",
        "motivation_protect_hour": "Защитите час перед вами.",
        "motivation_consistency": "Постоянство побеждает интенсивность.",
        "monthly_scope_btn": "Месяц",
        "yearly_scope_btn": "Год",
        "restoring_session": "Восстановление сеанса...",

        // Milestones
        "milestone_3day_streak": "Серия 3 дня",
        "milestone_3day_desc": "Стабильный ритм начат.",
        "milestone_7day_streak": "Серия 7 дней",
        "milestone_7day_desc": "Полная сфокусированная неделя.",
        "milestone_10h_protected": "10 часов защищено",
        "milestone_10h_desc": "Время защищено для важного.",
        "milestone_30_focus": "30 дней фокуса",
        "milestone_30_desc": "Стабильность с реальным весом.",

        // Narratives
        "narrative_improved": "Ваше экранное время улучшилось по сравнению с прошлой неделей.",
        "narrative_consistent": "Вы были последовательны на этой неделе и защитили свой фокус.",
        "narrative_more_days": "Вы завершили больше дней фокуса, чем обычно.",
        "narrative_building": "Вы выстраиваете ритм — по одному сфокусированному дню.",

        // Screen time
        "screen_time_trend_pending": "Тенденция экранного времени появится по мере накопления истории использования.",
        "screen_time_improved": "Экранное время улучшилось на %d%%",
        "screen_time_higher": "Экранное время немного выше обычного",
        "screen_time_steady": "Экранное время стабильно на этой неделе",

        // Benchmarks
        "benchmark_pending": "Среднее экранное время появится по мере записи истории использования. Глобальный ориентир — около 7 часов в день.",
        "benchmark_below": "Ваш 7-дневный средний показатель — %@, ниже мирового среднего в 7 часов. Это сильное направление.",
        "benchmark_above": "Ваш 7-дневный средний показатель — %@, выше мирового среднего в 7 часов. Небольшое сокращение сегодня может изменить тенденцию.",
        "benchmark_matching": "Ваш 7-дневный средний показатель — %@, совпадает с мировым средним в 7 часов.",

        // Task editing
        "edit_task": "Редактировать задачу",
        "task_name_placeholder": "Название задачи",
        "task_reminder_default": "Напоминание о задаче",
        "time_h_m": "%dч %dм",
        "time_m": "%dм",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Uzbek (Latin script)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let uz: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Diqqat rejimlari haqida",
        "no_active_goals_title": "Faol maqsadlar yoʻq",
        "no_active_goals_btn": "Tushunarli",
        "no_active_goals_msg": "«Diqqat» va «Qulflash» rejimlari faqat bajarilmagan maqsadingiz boʻlganda ishlaydi. Maqsad qoʻshing — yoki uni qayta faollashtiring — soʻng sessiyani boshlang.",
        // Tab bar
        "tab_home": "Bosh sahifa", "tab_progress": "Taraqqiyot", "tab_mode": "Rejim", "tab_profile": "Profil",

        // Home
        "today": "Bugun", "tomorrow": "Ertaga", "yesterday": "Kecha",
        "back_to_today": "Bugunga qaytish",
        "add_first_task": "Birinchi vazifangizni qo'shish uchun + bosing",
        "no_tasks_this_day": "Bu kunda vazifa yo'q",
        "new_task": "Yangi Vazifa",
        "what_to_do": "Nima qilishingiz kerak?",
        "task": "Vazifa", "schedule": "Jadval",
        "pick_date_hint": "Har qanday kelajak sanani tanlang — bugun, keyingi hafta yoki oylar keyin.",
        "priority": "Muhimlik", "low": "Past", "medium": "O'rta", "high": "Yuqori",
        "notification": "Bildirishnoma", "silent_push": "Sokin push bildirishnoma",
        "notification_desc": "Belgilangan vaqtda bir martalik push bildirishnoma yuboradi. U qulflash ekrani va Bildirishnomalar markazida sokin ko'rinadi.",
        "reminder": "Eslatma", "alarm_sound": "Ovoz va tebranishli signal",
        "reminder_desc": "Signal kabi ishlaydi — maxsus ovoz yangraydi va telefoningiz ekrandagi Yopish tugmasini bosguningizcha doimiy tebranadi. Uchrashuvlar va muddatlar uchun ajoyib.",
        "cancel": "Bekor qilish", "add": "Qo'shish", "edit": "Tahrirlash", "delete": "O'chirish",
        "jump_to_date": "Sanaga o'tish", "done": "Tayyor",
        "task_limit": "Bu sana uchun 25 vazifa chegarasiga yetdingiz.",
        "time": "Vaqt", "date": "Sana", "select_date": "Sanani tanlash",

        // Alarm
        "reminder_title": "Eslatma", "dismiss": "Yopish",

        // Progress
        "daily_progress": "Kunlik Taraqqiyot", "streaks": "seriyalar", "focus_days": "diqqat kunlari",
        "consistency": "barqarorlik",
        "set_first_goal": "Bugun uchun birinchi maqsadingizni belgilang",
        "all_goals_completed": "Barcha kunlik maqsadlar bajarildi",
        "goals_completed": "dan", "daily_goals_completed": "kunlik maqsad bajarildi",
        "daily_goals": "Kunlik Maqsadlar", "remaining": "qoldi",
        "no_goals_planned": "Maqsadlar rejalashtirilmagan",
        "complete_to_focus": "Bugunni diqqat kuni deb belgilash uchun barcha vazifalarni bajaring.",
        "add_task_to_start": "Kunlik maqsadlarni kuzatishni boshlash uchun Bosh sahifadan vazifa qo'shing.",
        "daily_plan_complete": "Kunlik reja bajarildi",
        "ai_weekly_summary": "SI Haftalik Hisobot",
        "creating_summary": "Haftalik hisobotingiz yaratilmoqda...",
        "generate_summary": "Hisobot yaratish", "refresh_summary": "Hisobotni yangilash",
        "first_summary_coming": "Birinchi SI haftalik hisobotingiz tayyorlanmoqda.",
        "first_summary_desc": "U %@ kuni soat 21:00 da tayyor bo'ladi. Unda taraqqiyotingiz, o'tkazib yuborilgan vazifalar va siz uchun eng yaxshi diqqat rejimi haqida fikrlar bo'ladi.",
        "next_update": "Keyingi yangilanish: %@",
        "weekly_recap": "Diqqat kunlari, vazifalar va samaradorlik tendensiyalari bo'yicha haftalik xulosa tayyor.",
        "screen_time_7day": "7 kunlik ekran vaqti", "best_streak": "Eng yaxshi seriya",
        "days": "kun", "milestones": "Yutuqlar", "milestone_unlocked": "Yutuq ochildi",
        "continue_btn": "Davom etish", "history_calendar": "Tarix kalendari",
        "mode_used": "Ishlatilgan rejim", "completed": "Bajarildi", "not_completed": "Bajarilmadi",
        "no_completed_tasks": "Bu kun uchun bajarilgan vazifalar yozilmagan.",
        "everything_completed": "Hammasi bajarildi.",
        "no_missed_tasks": "Bu kun uchun o'tkazib yuborilgan vazifalar yozilmagan.",
        "streak_day": "Seriya kuni", "missed_day": "O'tkazib yuborilgan kun",
        "first_name": "Ism", "last_name": "Familiya",
        "avatar_color": "Avatar rangi",
        "whats_your_name": "Ismingiz nima?",
        "name_helps": "Bu tajribangizni shaxsiylashtirishga yordam beradi.",
        "name_save_failed": "Ismingiz saqlanmadi. Ulanishingizni tekshiring va qayta urinib ko'ring.",
        "continue_btn_name": "Davom etish",
        "wins": "Yutuqlar", "next_action": "Keyingi qadam", "average": "o'rtacha",
        "todays_completion": "Bugungi bajarilish",
        "streaks_this_month": "bu oy seriyalar",
        "streak_days": "seriya kunlari", "non_streak_days": "seriyasiz kunlar",
        "monthly_streak_summary": "%d ta seriya bu oy • %d seriya kuni, %d seriyasiz kun",
        "duration_average": "%@ o'rtacha",

        // Profile
        "personal_details": "Shaxsiy ma'lumotlar", "personal_info": "Shaxsiy ma'lumot",
        "update_email_name": "Email va to'liq ismingizni yangilang.",
        "and_username": "va foydalanuvchi nomi",
        "invite_friends": "Do'stlarni taklif qilish",
        "refer_friend_title": "Do'stingizni tavsiya qiling va $10 oling",
        "refer_friend_desc": "Promo kodingiz bilan ro'yxatdan o'tgan har bir do'st uchun $10 oling.",
        "upgrade_family_plan": "Oilaviy rejaga o'tish",
        "goals_tracking": "Maqsadlar va kuzatuv",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Ovqatlanish maqsadlarini tahrirlash",
        "tracking_reminders": "Kuzatuv eslatmalari",
        "email_not_editable": "Emailingiz kirish ma'lumotlaringizga bog'langan va bu yerda tahrirlanmaydi.",
        "theme": "Mavzu", "theme_desc": "Tizim ko'rinishidan foydalaning yoki yorug'/qorong'u rejimni tanlang.",
        "appearance": "Ko'rinish", "appearance_desc": "Yorug', qorong'u yoki tizim ko'rinishini tanlang",
        "live_activity_profile_desc": "Kunlik taraqqiyotingizni qulflash ekrani va Dynamic Island'da ko'rsating",
        "system": "Tizim", "light": "Yorug'", "dark": "Qorong'u",
        "live_activity": "Jonli faoliyat",
        "live_activity_desc": "Bugungi maqsadlar, seriya va motivatsiyani blok ekranida ko'rsating.",
        "privacy_policy": "Maxfiylik siyosati",
        "privacy_desc": "Ilova ma'lumotlari va qurilma ruxsatlari qanday ishlatilishini ko'rib chiqing.",
        "terms_of_service": "Foydalanish shartlari",
        "terms_desc": "Ilova va diqqat vositalaridan foydalanish qoidalarini o'qing.",
        "follow_us": "Bizni kuzating",
        "sign_out": "Chiqish", "sign_out_desc": "Joriy qurilmadagi seansni tugatish.",
        "delete_account": "Hisobni o'chirish",
        "delete_account_desc": "Hisobingiz va sinxronlangan ilova ma'lumotlarini butunlay o'chirish.",
        "delete_account_title": "Hisobni o'chirish",
        "delete_account_msg": "Bu amal doimiy. Barcha ma'lumotlaringiz o'chiriladi va tiklab bo'lmaydi.",
        "delete_account_continue": "Davom etish",
        "delete_account_final_title": "Doimiy o'chirilsinmi?",
        "delete_account_final_msg": "Iltimos, yana bir bor tasdiqlang. Hisobingizni o'chirsangiz, Spike AI sizni tizimdan chiqaradi va kirish sahifasiga qaytaradi.",
        "deleting_account": "Hisob o'chirilmoqda...",
        "delete_failed": "Hisobni o'chirish amalga oshmadi. Qayta urinib ko'ring yoki yordam xizmatiga murojaat qiling.",
        "language": "Til", "language_desc": "Barcha ilova matnlari uchun tilni tanlang.",
        "set_name": "Ismingizni kiriting",
        "profile_name_prompt": "Sizni qanday ataylik?",
        "profile_name_desc": "Spike AI profil va samaradorlik tajribasida ishlatadigan ismingizni kiriting.",
        "full_name": "To'liq ism", "display_name": "Ko'rsatiladigan ism",
        "email": "Elektron pochta",
        "save_changes": "Saqlash",
        "save_footer": "O'zgarishlar profilingizga saqlanadi va ilovada shaxsingiz ko'rsatiladigan joylarda ishlatiladi.",
        "signed_in": "Kirish bajarilgan",
        "account": "Hisob", "preferences": "Sozlamalar",
        "support_legal": "Yordam va huquqiy ma'lumotlar",
        "account_actions": "Hisob amallari",
        "pref_show_completed": "Bajarilganlarni ko'rsatish",
        "pref_show_completed_desc": "Bajarilgan vazifalarni kunlik ro'yxatda ko'rinishda qoldirish.",
        "pref_quotes": "Motivatsion iqtiboslar",
        "pref_quotes_desc": "Progress ekranida ilhomlantiruvchi iqtibos ko'rsatish.",
        "legal_updated": "So'nggi yangilanish: 2026-yil 25-may",
        "privacy_body": """
        So'nggi yangilanish: 2026-yil 25-may

        Spike AI samaradorlik va diqqat ilovasi. Ushbu Maxfiylik siyosati Spike AI hisoblar, vazifalarni rejalashtirish, eslatmalar, diqqat rejimlari, Ekran vaqti boshqaruvlari, taraqqiyotni kuzatish va sun'iy intellekt tomonidan yaratilgan samaradorlik hisobotlarini taqdim etish uchun ishlatiladigan ma'lumotlarni qanday boshqarishini tushuntiradi.

        Biz to'playdigan ma'lumotlar: hisob identifikatorlari, masalan, elektron pochta manzilingiz va foydalanuvchi ID; siz taqdim etishni tanlagan profil tafsilotlari, masalan, ko'rsatiladigan ism va to'liq ism; vazifalar, maqsadlar, eslatmalar, bajarilish tarixi, diqqat rejimi sozlamalari, ilova tanlash tokenlari va taraqqiyot ko'rsatkichlari. Shuningdek, xizmatni ishonchli va xavfsiz saqlash uchun zarur texnik yozuvlarni saqlashimiz mumkin.

        Ekran vaqti va ilova tanlovlari: ilova, turkum va veb-domen tanlovlari Apple'ning FamilyControls va ManagedSettings ramkalari orqali qayta ishlanadi. Spike AI tanlangan diqqat rejimlarini qo'llash uchun zarur Apple tomonidan taqdim etilgan tokenlarni saqlaydi. Biz ushbu tanlovlarni reklama uchun ishlatmaymiz.

        Ter rejimida kameradan foydalanish: kamera ruxsati qurilmada tana holatini tekshirish uchun ishlatiladi, shunda siz harakat orqali ilovalarga vaqtinchalik kirish imkoniyatiga ega bo'lasiz. Spike AI bu xususiyat uchun video kadrlarni yuklamaydi va kamera ma'lumotlarini reklama uchun ishlatmaydi.

        Bildirishnomalar va eslatmalar: Spike AI siz sozlagan vazifa eslatmalari, signallar va diqqat turtkilarini yuborish uchun bildirishnoma ruxsatidan foydalanadi. Bildirishnoma kirishini istalgan vaqtda iOS Sozlamalarida o'zgartirishingiz mumkin.

        SI xulosa: agar taraqqiyot hisoboti yaratsangiz, so'nggi vazifa, maqsad, diqqat va samaradorlik ko'rsatkichlari hisobotni yaratish uchun Spike AI serverida qayta ishlanishi mumkin. Agar samaradorlik xususiyatlari uchun qayta ishlanishini xohlamasangiz, vazifa nomlari yoki maqsadlarga maxfiy shaxsiy ma'lumotlarni kiritishdan saqlaning.

        Ma'lumotlarni qanday ishlatamiz: sizni tasdiqlash, hisobingizni sinxronlashtirish, diqqat vositalarini taqdim etish, eslatmalarni rejalashtirish, taraqqiyotni ko'rsatish, samaradorlik tushunchalarini shaxsiylashtirish, suiiste'moldan himoya qilish, muammolarni bartaraf etish va qonuniy majburiyatlarga rioya qilish uchun. Spike AI shaxsiy ma'lumotlaringizni sotmaydi.

        Ma'lumotlarni o'chirish: Profildan chiqishingiz yoki hisobni doimiy o'chirishni so'rashingiz mumkin. Hisobni o'chirish sizning autentifikatsiya hisobingizni va o'sha hisob bilan bog'liq sinxronlangan ilova ma'lumotlarini olib tashlaydi, xavfsizlik, firibgarlikni oldini olish, nizolarni hal qilish yoki qonuniy muvofiqlik uchun zarur bo'lgan cheklangan saqlashdan tashqari.

        Sizning tanlovlaringiz: profil tafsilotlarini tahrirlash, til va ko'rinish afzalliklarini o'zgartirish, jonli faoliyatni o'chirish, Sozlamalarda qurilma ruxsatlarini bekor qilish, ma'lum diqqat rejimlaridan foydalanishni to'xtatish yoki hisobingizni o'chirish mumkin.

        Aloqa: maxfiylik savollari yoki hisob o'chirish muammolari uchun ilova yoki App Store sahifasida ko'rsatilgan yordam kanali orqali Spike AI yordamiga murojaat qiling.
        """,
        "terms_body": """
        So'nggi yangilanish: 2026-yil 25-may

        Ushbu Foydalanish shartlari Spike AI'dan foydalanishingizni boshqaradi, jumladan vazifalar, eslatmalar, diqqat rejimlari, Ekran vaqti ilova ogohlantirishlari va himoyalari, Ter rejimi harakat tekshiruvlari, taraqqiyotni kuzatish va sun'iy intellekt tomonidan yaratilgan hisobotlar.

        Muvofiqligi va hisob: siz yaratgan hisob va elektron pochta hamda qurilmangizga kirishni xavfsiz saqlash uchun javobgarsiz. Ilova profil tafsilotlarini so'raganda aniq ma'lumotlardan foydalaning.

        Samaradorlik maqsadi: Spike AI shaxsiy samaradorlik va maqsadli qurilma foydalanishni qo'llab-quvvatlash uchun mo'ljallangan. Bu tibbiy, ruhiy salomatlik, favqulodda vaziyat, xavfsizlik, ota-ona nazorati, ish monitoringi yoki qurilma boshqaruv xizmati emas. Eslatma, bloklash, ogohlantirish, kamera tekshiruvi, bildirishnoma, tarmoq so'rovi yoki Apple ruxsatining ishlamay qolishi zarar yetkazishi mumkin bo'lgan hollarda Spike AI'ga tayanmang.

        Sizning javobgarliklaringiz: vaziyatingizga mos diqqat sozlamalarini tanlang; rejimni faollashtirishdan oldin ilova tanlovlarini ko'rib chiqing; rejimlar ehtiyojlaringizga mos kelmasa, o'chiring; amaldagi qonun va Apple platformasi shartlariga rioya qiling; va ilovada ishlatishdan qulay bo'lmasangiz, vazifalar yoki maqsadlarga maxfiy ma'lumot kiritishdan saqlaning.

        Maqbul foydalanish: Spike AI'ni suiiste'mol qilmang, boshqa shaxsning qurilmasi yoki hisobiga aralashmang, xavfsizlik yoki platforma cheklovlarini chetlab o'tishga urinmang, xizmatning himoyalangan qismlarini teskari muhandislik qilmang, serverni ortiqcha yuklamang yoki ilovani noqonuniy, haqoratli, aldov yoki zararli faoliyat uchun ishlatmang.

        Ruxsatlar va mavjudlik: ba'zi xususiyatlar Ekran vaqti, bildirishnomalar, kamera, Jonli faoliyatlar va tarmoq kirishi kabi iOS ruxsatlarini talab qiladi. Apple, qurilma sozlamalari, operatsion tizim xatti-harakati, ulanish va server mavjudligi xususiyatlarning kutilganidek ishlashiga ta'sir qilishi mumkin.

        SI tomonidan yaratilgan kontent: taraqqiyot hisobotlari avtomatlashtirilgan tizimlar yordamida yaratilishi mumkin. Ular faqat fikrlash va samaradorlik yo'l-yo'riqlanishi uchundir. Ularga tayanishdan oldin o'z mulohazangiz bilan ko'rib chiqing.

        Hisobni o'chirish va tugatish: Profildan hisobni o'chirishni so'rashingiz mumkin. Qonun, platforma qoidalari, xavfsizlik xavotirlari yoki jiddiy suiiste'mol talab qilsa, Spike AI kirishni to'xtatishi yoki tugatishi mumkin.

        O'zgarishlar: ilova rivojlangan sari Spike AI ushbu Shartlarni yangilashi mumkin. Yangilanishdan keyin foydalanishni davom ettirish yangilangan Shartlarni qabul qilganligingizni bildiradi.

        Aloqa: ushbu Shartlar haqidagi savollar uchun ilova yoki App Store sahifasida ko'rsatilgan yordam kanali orqali Spike AI yordamiga murojaat qiling.
        """,

        // Focus Mode
        "focus_title": "Diqqat", "select_mode": "Rejimni Tanlang",
        "chill": "Tinch", "focus": "Diqqat", "lock_in": "Qulflash", "sweat": "Sportchi",
        "gentle_nudges": "Yengil eslatmalar", "confirm_intent": "Niyatni tasdiqlash",
        "no_bypass": "Aylanib o'tish yo'q", "move_to_unlock": "Ochish uchun harakat",
        "activate_focus": "Diqqat Rejimini Yoqish", "deactivate_focus": "Diqqat Rejimini O'chirish",
        "mode_active": "Rejim faol", "reminders_scheduled": "Eslatmalar rejalashtirilgan",
        "apps_prompt_active": "ilova - \"Ishonchingiz komilmi?\" so'rovi faol",
        "apps_blocked": "ilova bloklangan", "temp_access_active": "Vaqtinchalik kirish faol",
        "apps_require_movement": "ilovani ochish uchun harakat kerak",
        "notifications_label": "Bildirishnomalar", "notifications_enabled": "Bildirishnomalar yoqilgan",
        "notifications_denied": "Bildirishnomalarga ruxsat berilmagan",
        "enable_notif_settings": "Sozlamalarda bildirishnomalarni yoqing.",
        "allow_notif_desc": "Spike AI diqqat eslatmalarini yuborishi uchun bildirishnomalarga ruxsat bering.",
        "enable_notifications": "Bildirishnomalarni yoqish",
        "screen_time_access": "Ekran vaqti ruxsati",
        "screen_time_authorized": "Ekran vaqti ruxsati berilgan",
        "allow_screen_time": "Ekran vaqtiga ruxsat berish",
        "tap_to_allow": "Ekran vaqtiga ruxsat berish uchun pastdagi tugmani bosing.",
        "open_settings_manual": "Yoki qo'lda yoqish uchun Sozlamalarni oching",
        "open_settings": "Sozlamalarni ochish",
        "app_selection": "Ilova tanlovi", "selections": "tanlov",
        "choose_apps_confirm": "Ochishdan oldin tasdiqlanadigan ilovalarni tanlang.",
        "choose_apps_block": "Bloklanadigan ilovalarni tanlang.",
        "choose_apps_movement": "Harakat bilan ochiladigan ilovalarni tanlang.",
        "change_selection": "Tanlovni o'zgartirish", "select_apps": "Ilovalarni tanlash",
        "movement_unlock": "Harakat bilan ochish",
        "movement_desc": "Push-up va stand-up harakatlari SI tana aniqlashi bilan kuzatiladi. Har bir tasdiqlangan takror tanlangan ilovalarga 1 daqiqa kirish beradi.",
        "access_available": "%@ uchun kirish mavjud",
        "open_camera": "Kamera tekshiruvini ochish",
        "lock_in_mode": "Qulflash rejimi",
        "lock_in_warning": "Ilovalar aylanib o'tib bo'lmaydigan qizil ekran ko'rsatadi. Qulflash rejimini o'chirish uchun shu yerga qaytishingiz kerak.",
        "sweat_mode": "Sportchi rejimi",
        "do_exercises": "Vaqt olish uchun push-up yoki stand-up qiling",
        "add_minutes": "%d daqiqa qo'shish",
        "keep_in_view": "Yelka, qo'l yoki sonlaringiz kadrda tursin",
        "camera_required": "Harakat tekshiruvlari uchun kamera ruxsati kerak.",
        "camera_disabled": "Kamera ruxsati o'chirilgan. Ter rejimidan foydalanish uchun Sozlamalarda uni yoqing.",
        "camera_unavailable": "Kamera mavjud emas.",
        "starting_camera": "Kamera ishga tushmoqda...",
        "camera_active": "Kamera faol",
        "allow_camera": "Kameraga ruxsat berish",
        "focus_mode_title": "Diqqat rejimi",
        "focus_mode_desc": "Diqqatli, professional rejimlar orqali raqamli odatlaringizni nazorat qiling.",
        "about_permissions": "Ruxsatlar haqida",
        "permissions_desc": "Tinch rejimiga bildirishnoma ruxsati kerak. Diqqat, Qulflash va Ter rejimlariga Ekran vaqti ruxsati kerak. Ter rejimi harakat tekshiruvlari uchun kameradan ham foydalanadi.",
        "get_started": "Boshlash", "skip": "O'tkazib yuborish",
        "unlocked_for": "%@ uchun ochilgan",

        // Chill mode descriptions
        "chill_desc": "Kunlik eslatmalar bildirishnomalar orqali keladi. Ilovalar nazorat qilinmaydi - faqat maqsadli qolish uchun yengil eslatmalar.",
        "focus_desc": "Tanlangan ilovani ochganingizda, Spike AI \"Ishonchingiz komilmi?\" deb so'raydi. Uni odatdagidek ochishingiz yoki vazifalaringizga qaytishingiz mumkin. Ilovalar bloklanmaydi.",
        "lock_in_desc": "Qulflash faol bo'lganda tanlangan ilovalar bloklanadi. Rejimni Spike AI ichidan o'chirishingiz mumkin.",
        "sweat_desc": "Kamera tekshirgan push-up yoki stand-up bajarmaguningizcha tanlangan ilovalar bloklangan holda qoladi. Har bir tasdiqlangan takror 1 daqiqani ochadi.",

        // Motivational (deactivation)
        "giving_up_title": "Siz oldinga borayapsiz — to'xtamang",
        "giving_up_msg": "Sizda hali bajarilmagan maqsadlar bor. Har bir tugallangan vazifa impuls yaratadi. Sodiq bo'ling — kelajakdagi o'zingiz minnatdor bo'ladi.",
        "giving_up_continue": "Diqqatni Saqlash", "giving_up_stop": "Baribir O'chirish",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Shaxsiy samaradorlik tizimingiz",
        "start_setup": "Sozlashni boshlash",
        "make_phone_work": "Telefoningiz maqsadlaringiz\nuchun ishlasin.",
        "onboarding_welcome_desc": "Behuda aylantirishni kamaytiring, diqqat vaqtini himoya qiling va haqiqiy vazifalarni ko'rinadigan taraqqiyotga aylantiring.",
        "scrolling_adds_up": "Aylantirish kichik ko'rinadi,\nammo yig'ilib ketadi.",
        "per_day": "kuniga",
        "per_month": "oyiga",
        "per_year": "yiliga",
        "thirty_days": "30 kun",
        "lost_to_checking": "avtomatik tekshirishga ketadi",
        "scrolling_cost_desc": "Spike AI bu lahzalar butun oqshomni egallab olishidan oldin ularni payqashingizga yordam beradi.",
        "did_you_know": "Bilasizmi?",
        "did_you_know_subtitle": "Odam kuniga o'rtacha 7 soat telefonida vaqt o'tkazadi. Bu",
        "hours_per_day": "soat kuniga",
        "days_per_month": "kun oyiga",
        "days_per_year": "kun yiliga",
        "years_of_life": "umringizdan yillar",
        "screen_time_reality": "Va ba'zi odamlar bundan ham ko'proq vaqt sarflaydi.",
        "dont_worry_title": "Tashvishlanmang",
        "spike_has_your_back": "Spike AI sizni qo'llab-quvvatlaydi",
        "solution_desc": "Samaradorligingizni oshirishga, maqsadlaringizga yaqinlashishga va o'zingizning eng yaxshi versiyasiga aylantiradigan odatlarni shakllantirishga yordam beramiz.",
        "screen_time_access_title": "Ekran vaqti ruxsati",
        "grant_access": "Ruxsat berish",
        "which_apps": "Qaysi ilovalar\nko'p vaqtingizni oladi?",
        "choose_apps_protect": "Spike AI Focus, Lock-in va Sportchi rejimlarida himoya qilishi kerak bo'lgan ilovalarni tanlang.",
        "apple_screen_time_required": "Spike AI ilovalar ro'yxatini ko'rsatishi uchun Apple Screen Time ruxsati kerak.",
        "save_apps": "Ilovalarni saqlash",
        "change_selected_apps": "Tanlangan ilovalarni o'zgartirish",
        "your_modes_target": "Rejimlaringizda endi\naniq nishon bor.",
        "app_selections_will_be_used": "%d ta ilova tanlovi himoya rejimini boshlaganingizda ishlatiladi.",
        "select_apps_after_login": "Kirgandan keyin ilovalarni bir marta tanlang, barcha himoya rejimlari shu ro'yxatdan foydalanadi.",
        "focus_mode_marketing_detail": "Chalg'ituvchi ilovalarni ochishdan oldin qisqa pauza.",
        "lock_in_marketing_detail": "Chuqur ishlash kerak bo'lganda kuchliroq chegaralar.",
        "sweat_marketing_detail": "Avval harakat qilib, kirish vaqtini qo'lga kiriting.",
        "replace_scroll": "Aylantirish o'rniga\nhaqiqiy yutuq qiling.",
        "habit_desc": "Foydali harakatlarni energiyaga aylantiring: xonani yig'ishtiring, uy vazifasini topshiring, yuring, cho'ziling yoki bitta vazifani tugating.",
        "see_behavior_changing": "Xatti-harakatlaringiz\no'zgarayotganini ko'ring.",
        "progress_desc": "Diqqat vaqti, vazifalar bajarilishi va seriyalarni kuzating, shunda taraqqiyot aniq seziladi.",
        "ready_change_life": "Hayotingizni o'zgartirishga\ntayyormisiz?",
        "ready_change_desc": "Tanlovlaringizni saqlash va sayohatingizni boshlash uchun hisob yarating.",
        "benefit_no_distraction": "Chalg'ituvchi ilovalar endi sizni bezovta qilmaydi",
        "benefit_discover_modes": "4 xil turdagi diqqat rejimlarini kashf eting",
        "benefit_track_progress": "Taraqqiyotingizni kuzating va maqsadlaringizga yaqinlashing",
        "create_account": "Hisob yaratish",
        "ready_protected_day": "Birinchi himoyalangan\nkuningizga tayyormisiz?",
        "create_account_desc": "Ilova tanlovlari, diqqat rejimlari, vazifalar va taraqqiyotni saqlash uchun hisob yarating.",
        "benefit_apps_saved": "Chalg'ituvchi ilovalaringiz rejimlar uchun saqlanadi",
        "benefit_start_modes": "Focus, Lock-in yoki Sportchi rejimini boshlang",
        "benefit_progress_synced": "Taraqqiyotingiz sinxron saqlanadi",
        "protect_focus": "Diqqatni himoya qiling", "block_feeds": "Lentalarni bloklash",
        "finish_tasks": "Vazifalarni tugatish", "energy_plus_three": "+3 Energiya",
        "selected_count": "%d tanlangan", "no_apps_selected": "Hali ilova tanlanmagan",
        "saved_for_modes": "Himoya rejimlari uchun saqlandi",
        "select_apps_to_control": "Nazorat qilmoqchi bo'lgan ilovalarni tanlang",
        "clean_room": "Xonani yig'ishtirish", "snap_proof": "Tugatgach tasdiq rasm oling",
        "ai_verifies_task": "SI vazifani tekshiradi",
        "energy_earned": "+3 Energiya olindi",
        "on_track": "Rejada", "energy": "Energiya",
        "tasks_completed": "Bajarilgan vazifalar", "focus_protected": "Himoyalangan diqqat",
        "scrolling_avoided": "Oldi olingan aylantirish",
        "continue_apple": "Apple bilan davom etish",
        "continue_google": "Google bilan davom etish", "continue_email": "Pochta bilan davom etish",
        "enter_email": "Pochtangizni kiriting",
        "send_sign_in_link": "Sizga kirish havolasini yuboramiz",
        "check_email": "Pochtangizni tekshiring",
        "sent_link_to": "Kirish havolasi yuborildi:",
        "tap_link": "Avtomatik kirish uchun havolani bosing.",
        "open_mail": "Pochta ilovasini ochish",
        "open_with": "Qaysi ilovada ochilsin",
        "didnt_get_email": "Xat kelmadimi?",
        "resend": "Qayta yuborish",
        "resend_in": "%ds soniyadan keyin qayta yuborish",
        "new_link_sent": "Yangi havola yuborildi!",
        "valid_email": "To'g'ri elektron pochta manzilini kiriting.",
        "by_continuing": "Davom etish orqali siz Spike AI'ning",
        "and_word": "va",

        // Screen Time Onboarding
        "screen_time_title": "Ekran vaqti",
        "screen_time_permission_desc": "Spike AI Diqqat, Qulflash va Ter rejimlari uchun Ekran vaqti ruxsatiga muhtoj. Bu tanlangan ilovalar uchun ogohlantirishlar va bloklashlarni ko'rsatishga imkon beradi.",
        "screen_time_denied": "Ruxsat rad etildi. Sozlamalarda yoqishingiz mumkin.",
        "ask_before_opening": "Ochishdan oldin so'rash",
        "block_apps_completely": "Ilovalarni to'liq bloklash",
        "stay_accountable": "Mas'uliyatli bo'ling",
        "stay_accountable_desc": "Taraqqiyotni kuzating va diqqat odatlaringizni ko'rinadigan qiling.",
        "skip_for_now": "Hozircha o'tkazib yuborish",

        // Live Activity
        "daily_goals_title": "Kunlik maqsadlar",
        "of_done": "%d dan bajarildi",
        "more_to_go": "+%d ta qoldi",

        // Chill morning
        "good_morning": "Xayrli tong! Bugun maqsadli bo'ling. Vazifalaringizni ko'rib chiqing va diqqatni jamang.",

        // General
        "error": "Xato", "ok": "OK", "yes": "Ha", "no": "Yo'q",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Dam olish rejimiga o'tish?",
        "stay_focused_btn": "Diqqatda qolish",
        "switch_anyway_btn": "Baribir o'tish",
        "switch_to_chill_msg": "Sizda hali bajarilmagan maqsadlar bor. Dam olish rejimiga o'tish ilova blokirovkasini olib tashlaydi, bu esa bugungi maqsadlaringizni tugatmaslik xavfini oshiradi.",
        "task_notification": "Vazifa bildirishnomasi",
        "missed_alarm": "O'tkazib yuborilgan signal",
        "quote_of_day": "Kunning iqtibosi",
        "new_quotes_daily": "Yangi iqtiboslar har kuni soat 5:00 da keladi",
        "focus_day_label": "Diqqat kuni",
        "missed_label": "O'tkazilgan",
        "access_granted": "Ruxsat berildi",
        "goal_reminder": "Maqsad eslatmasi",
        "spike_ai_focus": "Spike AI Fokus",
        "goals_required_title": "Maqsadlar talab qilinadi",
        "goals_required_desc_focus": "Fokus rejimi tanlangan ilovalarni faqat bajarilmagan maqsadlar mavjud bo'lganda bloklaydi. Ilova blokirovkasini faollashtirish uchun Bosh sahifa bo'limiga maqsadlar qo'shing.",
        "goals_required_desc_lockin": "Qulflash rejimi tanlangan ilovalarni faqat bajarilmagan maqsadlar mavjud bo'lganda bloklaydi. Ilova blokirovkasini faollashtirish uchun Bosh sahifa bo'limiga maqsadlar qo'shing.",
        "save": "Saqlash",
        "no_goals_reminder_body": "Siz bugun uchun hech qanday maqsad belgilamadingiz. Kuningizni rejalashtirish uchun bir lahza vaqt ajrating!",
        "dont_forget": "Unutmang",
        "chill_morning_body": "Xayrli tong! Bugun maqsadli bo'ling. Vazifalaringizni ko'rib chiqing va diqqatingizni jamlang.",
        "every_day": "Har kun",
        "weekdays": "Ish kunlari",
        "weekends": "Dam olish kunlari",
        "time_to_focus": "Diqqatni jamlash vaqti!",

        // Additional UI strings
        "next_quote_in": "Keyingi iqtibos %@ dan keyin",
        "enable_notif_chill": "Yengil rejimni boshlashdan oldin bildirishnomalarni yoqing.",
        "enable_screen_time_mode": "Ushbu rejimni boshlashdan oldin Ekran vaqtiga ruxsat bering.",
        "select_app_before_mode": "Ushbu rejimni boshlashdan oldin kamida bitta ilova, toifa yoki veb-saytni tanlang.",
        "mode_not_ready": "Bu rejim hali boshlashga tayyor emas.",
        "protection_stopped_no_apps": "Himoya to'xtatildi: ilovalar tanlanmagan.",
        "protection_stopped_screen_time": "Himoya to'xtatildi: Ekran vaqtiga ruxsat o'zgargan.",
        "max_reminders": "Siz %d tagacha fokus eslatmasi yaratishingiz mumkin.",
        "front_camera_unavailable": "Old kamera mavjud emas.",
        "task_title_empty": "Vazifa sarlavhasi bo'sh bo'lishi mumkin emas.",
        "goal_title_empty": "Maqsad sarlavhasi bo'sh bo'lishi mumkin emas.",
        "rate_limit_wait": "Yangi hisobot yaratishdan oldin %d soniya kuting.",
        "missed_alarm_for": "Siz budilnikni o'tkazib yubordingiz: %@",
        "stay_with_plan": "Rejaga amal qiling.",
        "motivation_small_wins": "Kichik g'alabalar to'planadi.",
        "motivation_next_step": "Keyingi qadamni yakunlang.",
        "motivation_protect_hour": "Oldingizdagi soatni himoya qiling.",
        "motivation_consistency": "Doimiylik kuchdan ustun.",
        "monthly_scope_btn": "Oylik",
        "yearly_scope_btn": "Yillik",
        "restoring_session": "Sessiya tiklanmoqda...",

        // Milestones
        "milestone_3day_streak": "3 kunlik seriya",
        "milestone_3day_desc": "Barqaror ritm boshlandi.",
        "milestone_7day_streak": "7 kunlik seriya",
        "milestone_7day_desc": "To'liq diqqatli hafta.",
        "milestone_10h_protected": "10 soat himoyalangan",
        "milestone_10h_desc": "Muhim narsalar uchun himoyalangan vaqt.",
        "milestone_30_focus": "30 fokus kuni",
        "milestone_30_desc": "Haqiqiy og'irlikdagi izchillik.",

        // Narratives
        "narrative_improved": "Ekran vaqtingiz o'tgan haftaga nisbatan yaxshilandi.",
        "narrative_consistent": "Siz bu hafta izchil bo'ldingiz va fokusingizni himoya qildingiz.",
        "narrative_more_days": "Siz odatdagidan ko'proq fokus kunlarini yakunladingiz.",
        "narrative_building": "Siz ritmni birma-bir diqqatli kun bilan quryapsiz.",

        // Screen time
        "screen_time_trend_pending": "Ekran vaqti tendensiyasi foydalanish tarixi o'sgach paydo bo'ladi.",
        "screen_time_improved": "Ekran vaqti %d%% yaxshilandi",
        "screen_time_higher": "Ekran vaqti odatdagidan biroz yuqori",
        "screen_time_steady": "Ekran vaqti bu hafta barqaror",

        // Benchmarks
        "benchmark_pending": "O'rtacha ekran vaqti ilova foydalanish tarixini yozgandan so'ng paydo bo'ladi. Global ko'rsatkich kuniga taxminan 7 soat.",
        "benchmark_below": "Sizning 7 kunlik o'rtachangiz %@, 7 soatlik global o'rtachadan past. Bu kuchli yo'nalish.",
        "benchmark_above": "Sizning 7 kunlik o'rtachangiz %@, 7 soatlik global o'rtachadan yuqori. Bugun kichik qisqartirish tendensiyani o'zgartirishi mumkin.",
        "benchmark_matching": "Sizning 7 kunlik o'rtachangiz %@, 7 soatlik global o'rtachaga teng.",

        // Task editing
        "edit_task": "Vazifani tahrirlash",
        "task_name_placeholder": "Vazifa nomi",
        "task_reminder_default": "Vazifa eslatmasi",
        "time_h_m": "%ds %dd",
        "time_m": "%dd",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Chinese (Simplified)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let zh: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "关于专注模式",
        "no_active_goals_title": "没有活动目标",
        "no_active_goals_btn": "知道了",
        "no_active_goals_msg": "专注和锁定模式仅在你有未完成的目标时才会运行。请添加一个目标，或重新激活一个，然后开始你的专注时段。",
        // Tab bar
        "tab_home": "首页", "tab_progress": "进度", "tab_mode": "模式", "tab_profile": "个人",

        // Home
        "today": "今天", "tomorrow": "明天", "yesterday": "昨天",
        "back_to_today": "返回今天",
        "add_first_task": "点击 + 添加第一个任务",
        "no_tasks_this_day": "今天没有任务",
        "new_task": "新任务",
        "what_to_do": "你需要做什么？",
        "task": "任务", "schedule": "日程",
        "pick_date_hint": "选择任意日期——今天、下周或几个月后。",
        "priority": "优先级", "low": "低", "medium": "中", "high": "高",
        "notification": "通知",
        "silent_push": "静默推送通知",
        "notification_desc": "在预定时间发送一次性推送通知。它会安静地出现在锁屏和通知中心。",
        "reminder": "提醒",
        "alarm_sound": "带声音和振动的闹钟",
        "reminder_desc": "像闹钟一样工作——会播放特殊声音并持续振动，直到你按下屏幕上的关闭按钮。非常适合会议和截止日期。",
        "cancel": "取消", "add": "添加", "edit": "编辑", "delete": "删除",
        "jump_to_date": "跳转到日期", "done": "完成",
        "task_limit": "此日期已达到25个任务的上限。",
        "time": "时间", "date": "日期", "select_date": "选择日期",

        // Alarm
        "reminder_title": "提醒", "dismiss": "关闭",

        // Progress
        "daily_progress": "每日进度", "streaks": "连续天数", "focus_days": "专注天数",
        "consistency": "一致性",
        "set_first_goal": "设定你今天的第一个目标",
        "all_goals_completed": "所有每日目标已完成",
        "goals_completed": "/", "daily_goals_completed": "个每日目标已完成",
        "daily_goals": "每日目标", "remaining": "剩余",
        "no_goals_planned": "暂无计划目标",
        "complete_to_focus": "完成所有任务即可将今天标记为专注日。",
        "add_task_to_start": "从首页添加任务开始追踪每日目标。",
        "daily_plan_complete": "每日计划已完成",
        "ai_weekly_summary": "AI 周报",
        "creating_summary": "正在生成你的周报……",
        "generate_summary": "生成周报",
        "refresh_summary": "刷新周报",
        "first_summary_coming": "你的第一份 AI 周报即将送达。",
        "first_summary_desc": "周报将于 %@ 晚上9点准备就绪。其中包含你的进度分析、未完成的任务以及最适合你的专注模式建议。",
        "next_update": "下次更新：%@",
        "weekly_recap": "你的专注日、任务和效率趋势周报已准备就绪。",
        "screen_time_7day": "7天屏幕使用时间",
        "best_streak": "最佳连续", "days": "天",
        "milestones": "里程碑", "milestone_unlocked": "里程碑已解锁",
        "continue_btn": "继续",
        "history_calendar": "历史日历",
        "mode_used": "使用的模式",
        "completed": "已完成", "not_completed": "未完成",
        "no_completed_tasks": "当天没有已完成的任务记录。",
        "everything_completed": "所有任务均已完成。",
        "no_missed_tasks": "当天没有未完成的任务记录。",
        "streak_day": "连续日", "missed_day": "中断日",
        "first_name": "名", "last_name": "姓",
        "avatar_color": "头像颜色",
        "whats_your_name": "你叫什么名字？",
        "name_helps": "这有助于个性化你的体验。",
        "name_save_failed": "无法保存你的姓名。请检查网络连接后重试。",
        "continue_btn_name": "继续",
        "wins": "成就", "next_action": "下一步",
        "average": "平均",
        "todays_completion": "今日完成情况",
        "streaks_this_month": "本月连续天数",
        "streak_days": "连续天数", "non_streak_days": "非连续天数",
        "monthly_streak_summary": "本月 %d 次连续 • %d 个连续日，%d 个非连续日",
        "duration_average": "平均 %@",

        // Profile
        "personal_details": "个人信息",
        "personal_info": "个人资料",
        "update_email_name": "更新你的邮箱和全名。",
        "and_username": "和用户名",
        "invite_friends": "邀请好友",
        "refer_friend_title": "推荐好友赚取 $10",
        "refer_friend_desc": "每位通过你的推广码注册的好友可获得 $10 奖励。",
        "upgrade_family_plan": "升级到家庭计划",
        "goals_tracking": "目标与追踪",
        "apple_health": "Apple 健康",
        "edit_nutrition_goals": "编辑营养目标",
        "tracking_reminders": "追踪提醒",
        "email_not_editable": "你的邮箱与登录账号关联，无法在此处编辑。",
        "theme": "主题",
        "theme_desc": "使用系统外观或选择固定的浅色/深色模式。",
        "appearance": "外观",
        "appearance_desc": "选择浅色、深色或跟随系统外观",
        "live_activity_profile_desc": "在锁屏和灵动岛上显示你的每日进度",
        "system": "系统", "light": "浅色", "dark": "深色",
        "live_activity": "实时活动",
        "live_activity_desc": "在锁屏上显示今日目标、连续天数和激励语。",
        "privacy_policy": "隐私政策",
        "privacy_desc": "查看应用数据和设备权限的使用方式。",
        "terms_of_service": "服务条款",
        "terms_desc": "阅读应用及其专注工具的使用规则。",
        "follow_us": "关注我们",
        "sign_out": "退出登录",
        "sign_out_desc": "在当前设备上结束此会话。",
        "delete_account": "删除账户",
        "delete_account_desc": "永久删除你的账户和同步的应用数据。",
        "delete_account_title": "删除账户",
        "delete_account_msg": "此操作不可撤销。你的所有数据将被删除且无法恢复。",
        "delete_account_continue": "继续",
        "delete_account_final_title": "确认永久删除？",
        "delete_account_final_msg": "请再次确认。如果你删除账户，Spike AI 将退出登录并返回到登录页面。",
        "deleting_account": "正在删除账户……",
        "delete_failed": "账户删除失败。请重试或联系客服。",
        "language": "语言",
        "language_desc": "选择应用内所有内容的语言。",
        "set_name": "设置你的姓名",
        "profile_name_prompt": "你希望我们怎么称呼你？",
        "profile_name_desc": "添加 Spike AI 在你的个人资料和效率体验中使用的名称。",
        "full_name": "全名", "display_name": "显示名称", "email": "电子邮件",
        "save_changes": "保存更改",
        "save_footer": "更改会保存到你的个人资料中，并在应用中显示你身份的任何位置使用。",
        "signed_in": "已登录",
        "account": "账户", "preferences": "偏好设置",
        "support_legal": "支持与法律",
        "account_actions": "账户操作",
        "pref_show_completed": "显示已完成的任务",
        "pref_show_completed_desc": "在每日列表中保持已完成任务可见。",
        "pref_quotes": "激励名言",
        "pref_quotes_desc": "在进度页面显示一句激励名言。",
        "legal_updated": "最后更新：2026年5月25日",
        "privacy_body": """
        最后更新：2026年5月25日

        Spike AI 是一款效率与专注应用。本隐私政策说明 Spike AI 如何处理用于提供账户、任务规划、提醒、专注模式、屏幕使用时间控制、进度追踪和 AI 生成的效率摘要所涉及的信息。

        我们收集的信息：账户标识符，如你的电子邮件地址和用户 ID；你选择提供的个人资料信息，如显示名称和全名；任务、目标、提醒、完成记录、专注模式设置、应用选择令牌和进度指标。我们还可能存储维护服务可靠性和安全性所需的技术记录。

        屏幕使用时间和应用选择：应用、类别和网页域名选择通过 Apple 的 FamilyControls 和 ManagedSettings 框架处理。Spike AI 存储 Apple 提供的令牌，用于应用你选择的专注模式。我们不会将这些选择用于广告目的。

        运动模式中的摄像头使用：摄像头访问用于设备端的身体姿势检测，以便你可以通过运动获取临时应用访问权限。Spike AI 不会为此功能上传视频画面，也不会将摄像头数据用于广告目的。

        通知和提醒：Spike AI 使用通知权限发送你配置的任务提醒、闹钟和专注提示。你可以随时在 iOS 设置中更改通知访问权限。

        AI 摘要：如果你生成进度摘要，近期的任务、目标、专注和效率指标可能会由 Spike AI 的后端处理以生成摘要。如果你不希望某些信息被用于效率功能的处理，请避免在任务名称或目标中输入敏感个人信息。

        我们如何使用信息：用于验证你的身份、同步你的账户、提供专注工具、安排提醒、展示进度、个性化效率洞察、防止滥用、排查问题以及遵守法律义务。Spike AI 不会出售你的个人信息。

        数据删除：你可以从"个人"页面退出登录或请求永久删除账户。账户删除将移除你的认证账户和与该账户关联的已同步应用数据，但须遵守因安全、欺诈预防、争议解决或法律合规所需的有限保留期。

        你的选择：你可以编辑个人资料、更改语言和外观偏好、禁用实时活动、在设置中撤销设备权限、停止使用特定专注模式或删除你的账户。

        联系方式：如有隐私问题或账户删除问题，请通过应用或 App Store 列表提供的支持渠道联系 Spike AI 客服。
        """,
        "terms_body": """
        最后更新：2026年5月25日

        本服务条款规范你对 Spike AI 的使用，包括任务、提醒、专注模式、屏幕使用时间应用提示和屏蔽、运动模式动作检测、进度追踪和 AI 生成的摘要。

        资格与账户：你对你创建的账户负责，并有义务确保你的电子邮件和设备访问安全。在应用要求提供个人资料信息时，请使用准确的信息。

        效率工具用途：Spike AI 旨在支持个人效率和有意识的设备使用。它不是医疗、心理健康、紧急情况、安全、家长控制、雇佣监控或设备管理服务。请不要在提醒、屏蔽、提示、摄像头检测、通知、网络请求或 Apple 权限失败可能造成伤害的情况下依赖 Spike AI。

        你的责任：选择适合你情况的专注设置；在激活模式前检查应用选择；在不再需要时关闭模式；遵守适用法律和 Apple 平台条款；除非你愿意在应用中使用敏感信息，否则请避免在任务或目标中输入此类信息。

        可接受的使用：请勿滥用 Spike AI、干扰他人的设备或账户、试图绕过安全或平台限制、对服务的受保护部分进行逆向工程、使后端过载或将应用用于非法、滥用、欺骗或有害的活动。

        权限与可用性：部分功能需要 iOS 权限，如屏幕使用时间、通知、摄像头、实时活动和网络访问。Apple、设备设置、操作系统行为、网络连接和后端可用性可能影响功能是否按预期工作。

        AI 生成的内容：进度摘要可能由自动化系统生成。它们仅用于反思和效率辅导。在依赖这些内容之前，请结合你自己的判断进行审查。

        账户删除与终止：你可以从"个人"页面请求删除账户。如果法律、平台规则、安全问题或严重滥用要求，Spike AI 可能会暂停或终止访问权限。

        变更：随着应用的发展，Spike AI 可能会更新这些条款。更新后继续使用即表示你接受更新后的条款。

        联系方式：如对本条款有疑问，请通过应用或 App Store 列表提供的支持渠道联系 Spike AI 客服。
        """,

        // Focus Mode
        "focus_title": "专注", "select_mode": "选择模式",
        "chill": "轻松", "focus": "专注", "lock_in": "锁定", "sweat": "运动员",
        "gentle_nudges": "温和提醒", "confirm_intent": "确认意图",
        "no_bypass": "无法绕过", "move_to_unlock": "运动解锁",
        "activate_focus": "启用专注模式", "deactivate_focus": "关闭专注模式",
        "mode_active": "模式已激活",
        "reminders_scheduled": "提醒已安排",
        "apps_prompt_active": "个应用——\"你确定吗？\"提示已激活",
        "apps_blocked": "个应用已屏蔽",
        "temp_access_active": "临时访问已激活",
        "apps_require_movement": "个应用需要运动才能解锁",
        "notifications_label": "通知",
        "notifications_enabled": "通知已开启",
        "notifications_denied": "通知被拒绝",
        "enable_notif_settings": "请在设置中开启通知。",
        "allow_notif_desc": "允许通知以便 Spike AI 向你发送专注提醒。",
        "enable_notifications": "开启通知",
        "screen_time_access": "屏幕使用时间访问",
        "screen_time_authorized": "屏幕使用时间已授权",
        "allow_screen_time": "允许屏幕使用时间访问",
        "tap_to_allow": "点击下方允许屏幕使用时间访问。",
        "open_settings_manual": "或打开设置手动启用",
        "open_settings": "打开设置",
        "app_selection": "应用选择",
        "selections": "项选择",
        "choose_apps_confirm": "选择打开前需要确认的应用。",
        "choose_apps_block": "选择要屏蔽的应用。",
        "choose_apps_movement": "选择需要运动才能解锁的应用。",
        "change_selection": "更改选择",
        "select_apps": "选择应用",
        "movement_unlock": "运动解锁",
        "movement_desc": "俯卧撑和起立运动通过 AI 身体检测进行追踪。每次确认的动作可为所选应用增加1分钟使用时间。",
        "access_available": "可用时间：%@",
        "open_camera": "打开摄像头检测",
        "lock_in_mode": "锁定模式",
        "lock_in_warning": "应用将显示无法绕过的红色屏幕。你必须回到这里才能关闭锁定模式。",
        "sweat_mode": "运动员模式",
        "do_exercises": "做俯卧撑或起立来赚取时间",
        "add_minutes": "添加 %d 分钟",
        "keep_in_view": "请保持肩膀、手臂或臀部在画面中",
        "camera_required": "运动检测需要摄像头访问权限。",
        "camera_disabled": "摄像头访问已禁用。请在设置中启用以使用运动模式。",
        "camera_unavailable": "摄像头不可用。",
        "starting_camera": "正在启动摄像头……",
        "camera_active": "摄像头已激活",
        "allow_camera": "允许摄像头访问",
        "focus_mode_title": "专注模式",
        "focus_mode_desc": "通过专业的专注模式掌控你的数字习惯。",
        "about_permissions": "关于权限",
        "permissions_desc": "轻松模式需要通知权限。专注、锁定和运动模式需要屏幕使用时间授权。运动模式还需要摄像头用于动作检测。",
        "get_started": "开始使用", "skip": "跳过",
        "unlocked_for": "已解锁 %@",

        // Chill mode descriptions
        "chill_desc": "通过通知发送每日提醒。不控制应用——只是温和地提醒你保持专注。",
        "focus_desc": "当你打开选定的应用时，Spike AI 会询问\"你确定吗？\"你可以正常打开或返回任务。应用不会被屏蔽。",
        "lock_in_desc": "锁定模式激活时，选定的应用会被屏蔽。你可以从 Spike AI 中关闭此模式。",
        "sweat_desc": "选定的应用将保持屏蔽状态，直到你完成摄像头验证的俯卧撑或起立动作。每次确认的动作解锁1分钟。",

        // Motivational (deactivation)
        "giving_up_title": "你正在进步——不要停下",
        "giving_up_msg": "你今天还有未完成的目标。每完成一个任务都在积累动力。坚持下去——未来的你会感谢现在的自己。",
        "giving_up_continue": "保持专注", "giving_up_stop": "仍然关闭",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "你的个人效率系统",
        "start_setup": "开始设置",
        "make_phone_work": "让你的手机\n为你的目标服务。",
        "onboarding_welcome_desc": "减少无意义的刷屏，保护专注时间，将真实任务转化为可见的进步。",
        "did_you_know": "你知道吗？",
        "did_you_know_subtitle": "一个人平均每天花7个小时在手机上。这相当于",
        "hours_per_day": "小时/天",
        "days_per_month": "天/月",
        "days_per_year": "天/年",
        "years_of_life": "年的人生",
        "screen_time_reality": "有些人花的时间甚至更多。",
        "dont_worry_title": "别担心",
        "spike_has_your_back": "Spike AI 为你保驾护航",
        "solution_desc": "我们将帮助你最大化效率，更接近你的目标，培养让你成为最好版本的习惯。",
        "screen_time_access_title": "屏幕使用时间访问",
        "grant_access": "授予权限",
        "which_apps": "选择你的\n干扰应用",
        "choose_apps_protect": "选择浪费你时间的应用。我们将在专注模式中屏蔽它们。",
        "apple_screen_time_required": "Apple 需要屏幕使用时间权限才能让 Spike AI 显示你的应用列表。",
        "save_apps": "保存并继续",
        "change_selected_apps": "更改已选应用",
        "ready_change_life": "准备好改变\n你的生活了吗？",
        "ready_change_desc": "创建你的账户以保存你的选择并开始你的旅程。",
        "benefit_no_distraction": "干扰应用将不再打扰你",
        "benefit_discover_modes": "探索4种不同类型的专注模式",
        "benefit_track_progress": "追踪你的进度并更接近你的目标",
        "create_account": "创建账户",
        "protect_focus": "保护专注",
        "block_feeds": "屏蔽信息流",
        "finish_tasks": "完成任务",
        "energy_plus_three": "+3 能量",
        "selected_count": "已选 %d 个",
        "no_apps_selected": "尚未选择任何应用",
        "saved_for_modes": "已保存用于保护模式",
        "select_apps_to_control": "选择你想要控制的应用",
        "clean_room": "打扫房间",
        "snap_proof": "完成后拍照证明",
        "ai_verifies_task": "AI 验证任务",
        "energy_earned": "获得 +3 能量",
        "on_track": "按计划进行",
        "energy": "能量",
        "tasks_completed": "已完成任务",
        "focus_protected": "专注已保护",
        "scrolling_avoided": "已避免刷屏",
        "continue_apple": "使用 Apple 继续",
        "continue_google": "使用 Google 继续",
        "continue_email": "使用邮箱继续",
        "enter_email": "输入你的邮箱",
        "send_sign_in_link": "我们将发送登录链接给你",
        "check_email": "检查你的邮箱",
        "sent_link_to": "我们已将登录链接发送至",
        "tap_link": "点击链接自动登录。",
        "open_mail": "打开邮件应用",
        "open_with": "打开方式",
        "didnt_get_email": "没有收到邮件？",
        "resend": "重新发送",
        "resend_in": "%d秒后重新发送",
        "new_link_sent": "新链接已发送！",
        "valid_email": "请输入有效的邮箱地址。",
        "by_continuing": "继续即表示你同意 Spike AI 的",
        "and_word": "和",

        // Screen Time Onboarding
        "screen_time_title": "屏幕使用时间",
        "screen_time_permission_desc": "Spike AI 需要屏幕使用时间权限以支持专注、锁定和运动模式。这使其能够为你选择的应用显示提示和屏蔽。",
        "screen_time_denied": "权限被拒绝。你可以在设置中启用。",
        "ask_before_opening": "打开前询问",
        "block_apps_completely": "完全屏蔽应用",
        "stay_accountable": "保持自律",
        "stay_accountable_desc": "追踪进度并保持你的专注习惯可见。",
        "skip_for_now": "暂时跳过",

        // Live Activity
        "daily_goals_title": "每日目标",
        "of_done": "已完成 %d 个",
        "more_to_go": "还剩 +%d 个",

        // Chill morning
        "good_morning": "早上好！今天保持专注。查看你的任务，集中精力。",

        // General
        "error": "错误", "ok": "确定", "yes": "是", "no": "否",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "切换到休闲模式？",
        "stay_focused_btn": "保持专注",
        "switch_anyway_btn": "仍然切换",
        "switch_to_chill_msg": "你还有未完成的目标。切换到休闲模式会解除应用拦截，这会增加今天无法完成目标的风险。",
        "task_notification": "任务通知",
        "missed_alarm": "错过的闹钟",
        "quote_of_day": "每日一言",
        "new_quotes_daily": "新语录每天凌晨5:00更新",
        "focus_day_label": "专注日",
        "missed_label": "已错过",
        "access_granted": "已授权访问",
        "goal_reminder": "目标提醒",
        "spike_ai_focus": "Spike AI 专注",
        "goals_required_title": "需要设定目标",
        "goals_required_desc_focus": "专注模式仅在您有未完成的目标时拦截所选应用。请在首页标签中添加目标以激活应用拦截。",
        "goals_required_desc_lockin": "锁定模式仅在您有未完成的目标时拦截所选应用。请在首页标签中添加目标以激活应用拦截。",
        "save": "保存",
        "no_goals_reminder_body": "您今天还没有设定任何目标。花点时间规划您的一天吧！",
        "dont_forget": "别忘了",
        "chill_morning_body": "早上好！今天保持专注。查看您的任务，保持集中注意力。",
        "every_day": "每天",
        "weekdays": "工作日",
        "weekends": "周末",
        "time_to_focus": "专注时间到！",

        // Additional UI strings
        "next_quote_in": "下一条语录 %@ 后",
        "enable_notif_chill": "启动轻松模式前请启用通知。",
        "enable_screen_time_mode": "启动此模式前请启用屏幕使用时间权限。",
        "select_app_before_mode": "启动此模式前请至少选择一个应用、类别或网站。",
        "mode_not_ready": "此模式尚未准备就绪。",
        "protection_stopped_no_apps": "保护已停止：未选择任何应用。",
        "protection_stopped_screen_time": "保护已停止：屏幕使用时间权限已更改。",
        "max_reminders": "最多可创建 %d 个专注提醒。",
        "front_camera_unavailable": "前置摄像头不可用。",
        "task_title_empty": "任务标题不能为空。",
        "goal_title_empty": "目标标题不能为空。",
        "rate_limit_wait": "请等待 %d 秒后再生成新报告。",
        "missed_alarm_for": "您错过了闹钟：%@",
        "stay_with_plan": "坚持计划。",
        "motivation_small_wins": "小胜利终将汇聚。",
        "motivation_next_step": "完成下一步。",
        "motivation_protect_hour": "守护眼前这一小时。",
        "motivation_consistency": "持之以恒胜过一时冲劲。",
        "monthly_scope_btn": "月度",
        "yearly_scope_btn": "年度",
        "restoring_session": "正在恢复您的会话...",

        // Milestones
        "milestone_3day_streak": "连续3天",
        "milestone_3day_desc": "稳定的节奏已经开始。",
        "milestone_7day_streak": "连续7天",
        "milestone_7day_desc": "完整的专注一周。",
        "milestone_10h_protected": "10小时已保护",
        "milestone_10h_desc": "为重要的事保护的时间。",
        "milestone_30_focus": "30个专注日",
        "milestone_30_desc": "实实在在的坚持。",

        // Narratives
        "narrative_improved": "您的屏幕使用时间比上周有所改善。",
        "narrative_consistent": "您本周保持了一致性并保护了专注力。",
        "narrative_more_days": "您完成了比平时更多的专注日。",
        "narrative_building": "您正在一天一天地建立节奏。",

        // Screen time
        "screen_time_trend_pending": "屏幕使用趋势将随着使用记录的积累而显示。",
        "screen_time_improved": "屏幕使用时间改善了 %d%%",
        "screen_time_higher": "屏幕使用时间略高于平时",
        "screen_time_steady": "本周屏幕使用时间稳定",

        // Benchmarks
        "benchmark_pending": "平均屏幕使用时间将在应用记录使用历史后显示。全球参考值约为每天7小时。",
        "benchmark_below": "您的7天平均值为 %@，低于7小时的全球平均值。这是一个好方向。",
        "benchmark_above": "您的7天平均值为 %@，高于7小时的全球平均值。今天稍微减少一点就能改变趋势。",
        "benchmark_matching": "您的7天平均值为 %@，与7小时的全球平均值持平。",

        // Task editing
        "edit_task": "编辑任务",
        "task_name_placeholder": "任务名称",
        "task_reminder_default": "任务提醒",
        "time_h_m": "%d小时 %d分钟",
        "time_m": "%d分钟",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Japanese
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let ja: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "フォーカスモードについて",
        "no_active_goals_title": "アクティブな目標がありません",
        "no_active_goals_btn": "わかりました",
        "no_active_goals_msg": "集中モードとロックインモードは、未完了の目標があるときのみ動作します。目標を追加するか、再度有効にしてから、セッションを開始してください。",
        // Tab bar
        "tab_home": "ホーム", "tab_progress": "進捗", "tab_mode": "モード", "tab_profile": "プロフィール",

        // Home
        "today": "今日", "tomorrow": "明日", "yesterday": "昨日",
        "back_to_today": "今日に戻る",
        "add_first_task": "+ をタップして最初のタスクを追加しましょう",
        "no_tasks_this_day": "この日にはタスクがありません",
        "new_task": "新しいタスク",
        "what_to_do": "何をする必要がありますか？",
        "task": "タスク", "schedule": "スケジュール",
        "pick_date_hint": "任意の日付を選択してください——今日、来週、または数か月先。",
        "priority": "優先度", "low": "低", "medium": "中", "high": "高",
        "notification": "通知",
        "silent_push": "サイレントプッシュ通知",
        "notification_desc": "予定時刻に一度だけプッシュ通知を送信します。ロック画面と通知センターに静かに表示されます。",
        "reminder": "リマインダー",
        "alarm_sound": "サウンドとバイブレーション付きアラーム",
        "reminder_desc": "アラームのように機能します——特別なサウンドが再生され、画面の「停止」ボタンを押すまで端末が振動し続けます。会議や締め切りに最適です。",
        "cancel": "キャンセル", "add": "追加", "edit": "編集", "delete": "削除",
        "jump_to_date": "日付に移動", "done": "完了",
        "task_limit": "この日付のタスク上限（25件）に達しました。",
        "time": "時間", "date": "日付", "select_date": "日付を選択",

        // Alarm
        "reminder_title": "リマインダー", "dismiss": "停止",

        // Progress
        "daily_progress": "今日の進捗", "streaks": "連続日数", "focus_days": "集中日数",
        "consistency": "継続率",
        "set_first_goal": "今日の最初の目標を設定しましょう",
        "all_goals_completed": "すべての日次目標を達成しました",
        "goals_completed": "/", "daily_goals_completed": "個の日次目標を達成",
        "daily_goals": "日次目標", "remaining": "残り",
        "no_goals_planned": "目標が設定されていません",
        "complete_to_focus": "すべてのタスクを完了すると、今日が集中日としてマークされます。",
        "add_task_to_start": "ホームからタスクを追加して日次目標の追跡を開始しましょう。",
        "daily_plan_complete": "デイリープラン完了",
        "ai_weekly_summary": "AI 週間サマリー",
        "creating_summary": "週間サマリーを作成中です…",
        "generate_summary": "サマリーを生成",
        "refresh_summary": "サマリーを更新",
        "first_summary_coming": "最初の AI 週間サマリーが準備中です。",
        "first_summary_desc": "%@ の午後9時に準備が整います。進捗状況、未完了のタスク、あなたに最適な集中モードに関するインサイトが含まれます。",
        "next_update": "次回更新：%@",
        "weekly_recap": "集中日、タスク、生産性トレンドの週間レポートが準備できました。",
        "screen_time_7day": "7日間のスクリーンタイム",
        "best_streak": "最長連続", "days": "日",
        "milestones": "マイルストーン", "milestone_unlocked": "マイルストーン達成",
        "continue_btn": "続ける",
        "history_calendar": "履歴カレンダー",
        "mode_used": "使用したモード",
        "completed": "完了", "not_completed": "未完了",
        "no_completed_tasks": "この日に完了したタスクの記録はありません。",
        "everything_completed": "すべて完了しました。",
        "no_missed_tasks": "この日に未完了のタスクの記録はありません。",
        "streak_day": "連続日", "missed_day": "中断日",
        "first_name": "名", "last_name": "姓",
        "avatar_color": "アバターの色",
        "whats_your_name": "お名前は何ですか？",
        "name_helps": "体験をパーソナライズするのに役立ちます。",
        "name_save_failed": "名前を保存できませんでした。接続を確認して再度お試しください。",
        "continue_btn_name": "続ける",
        "wins": "達成", "next_action": "次のアクション",
        "average": "平均",
        "todays_completion": "今日の達成状況",
        "streaks_this_month": "今月の連続日数",
        "streak_days": "連続日", "non_streak_days": "非連続日",
        "monthly_streak_summary": "今月 %d 回連続 • %d 連続日、%d 非連続日",
        "duration_average": "平均 %@",

        // Profile
        "personal_details": "個人情報",
        "personal_info": "個人情報",
        "update_email_name": "メールアドレスとフルネームを更新してください。",
        "and_username": "とユーザー名",
        "invite_friends": "友達を招待",
        "refer_friend_title": "友達を紹介して $10 獲得",
        "refer_friend_desc": "プロモコードで登録した友達1人につき $10 獲得できます。",
        "upgrade_family_plan": "ファミリープランにアップグレード",
        "goals_tracking": "目標とトラッキング",
        "apple_health": "Apple ヘルスケア",
        "edit_nutrition_goals": "栄養目標を編集",
        "tracking_reminders": "トラッキングリマインダー",
        "email_not_editable": "メールアドレスはログインに連携されているため、ここでは編集できません。",
        "theme": "テーマ",
        "theme_desc": "システムの外観を使用するか、ライト/ダークモードを固定で選択します。",
        "appearance": "外観",
        "appearance_desc": "ライト、ダーク、またはシステムの外観を選択してください",
        "live_activity_profile_desc": "ロック画面とダイナミックアイランドに日次進捗を表示します",
        "system": "システム", "light": "ライト", "dark": "ダーク",
        "live_activity": "ライブアクティビティ",
        "live_activity_desc": "ロック画面に今日の目標、連続日数、モチベーションを表示します。",
        "privacy_policy": "プライバシーポリシー",
        "privacy_desc": "アプリデータとデバイス権限の使用方法を確認してください。",
        "terms_of_service": "利用規約",
        "terms_desc": "アプリとその集中ツールの利用ルールをお読みください。",
        "follow_us": "フォローする",
        "sign_out": "ログアウト",
        "sign_out_desc": "このデバイスでのセッションを終了します。",
        "delete_account": "アカウントを削除",
        "delete_account_desc": "アカウントと同期されたアプリデータを完全に削除します。",
        "delete_account_title": "アカウントを削除",
        "delete_account_msg": "この操作は元に戻せません。すべてのデータが削除され、復元できなくなります。",
        "delete_account_continue": "続ける",
        "delete_account_final_title": "完全に削除しますか？",
        "delete_account_final_msg": "もう一度確認してください。アカウントを削除すると、Spike AI はログアウトし、ログインページに戻ります。",
        "deleting_account": "アカウントを削除中…",
        "delete_failed": "アカウントの削除に失敗しました。再度お試しいただくか、サポートにお問い合わせください。",
        "language": "言語",
        "language_desc": "すべてのアプリコンテンツの言語を選択してください。",
        "set_name": "名前を設定",
        "profile_name_prompt": "何とお呼びすればよいですか？",
        "profile_name_desc": "Spike AI がプロフィールと生産性体験で使用する名前を追加してください。",
        "full_name": "フルネーム", "display_name": "表示名", "email": "メールアドレス",
        "save_changes": "変更を保存",
        "save_footer": "変更はプロフィールに保存され、アプリ内であなたの情報が表示される場所で使用されます。",
        "signed_in": "ログイン済み",
        "account": "アカウント", "preferences": "設定",
        "support_legal": "サポートと法的情報",
        "account_actions": "アカウント操作",
        "pref_show_completed": "完了したタスクを表示",
        "pref_show_completed_desc": "完了したタスクを日次リストに表示し続けます。",
        "pref_quotes": "モチベーション名言",
        "pref_quotes_desc": "進捗画面にインスピレーションを与える名言を表示します。",
        "legal_updated": "最終更新日：2026年5月25日",
        "privacy_body": """
        最終更新日：2026年5月25日

        Spike AI は生産性と集中のためのアプリです。本プライバシーポリシーは、アカウント、タスク計画、リマインダー、集中モード、スクリーンタイム制御、進捗追跡、AI 生成の生産性サマリーを提供するために Spike AI が情報をどのように取り扱うかについて説明します。

        収集する情報：メールアドレスやユーザー ID などのアカウント識別子、表示名やフルネームなどお客様が提供することを選択したプロフィール情報、タスク、目標、リマインダー、完了履歴、集中モード設定、アプリ選択トークン、進捗指標。また、サービスの信頼性とセキュリティの維持に必要な技術的記録も保存する場合があります。

        スクリーンタイムとアプリ選択：アプリ、カテゴリ、ウェブドメインの選択は、Apple の FamilyControls および ManagedSettings フレームワークを通じて処理されます。Spike AI は、お客様が選択した集中モードを適用するために Apple が提供するトークンを保存します。これらの選択を広告目的で使用することはありません。

        スウェットモードでのカメラ使用：カメラアクセスは、デバイス上での身体姿勢チェックに使用され、動きを通じてアプリへの一時的なアクセスを獲得できます。Spike AI はこの機能のためにビデオフレームをアップロードせず、カメラデータを広告目的で使用しません。

        通知とリマインダー：Spike AI は、お客様が設定したタスクリマインダー、アラーム、集中のための通知を送信するために通知権限を使用します。iOS の設定からいつでも通知アクセスを変更できます。

        AI サマリー：進捗サマリーを生成する場合、最近のタスク、目標、集中、生産性指標が Spike AI のバックエンドで処理されてサマリーが作成される場合があります。生産性機能で処理されたくない情報がある場合は、タスク名や目標に機密性の高い個人情報を入力しないでください。

        情報の使用方法：認証、アカウントの同期、集中ツールの提供、リマインダーのスケジューリング、進捗の表示、生産性インサイトのパーソナライズ、不正利用の防止、問題のトラブルシューティング、法的義務の遵守のために使用します。Spike AI はお客様の個人情報を販売しません。

        データの削除：プロフィールからログアウトまたはアカウントの完全削除をリクエストできます。アカウントの削除により、お客様の認証アカウントおよびそのアカウントに関連する同期済みアプリデータが削除されます。ただし、セキュリティ、詐欺防止、紛争解決、法的遵守のために必要な限定的な保持期間が適用される場合があります。

        お客様の選択：プロフィールの詳細の編集、言語と外観設定の変更、ライブアクティビティの無効化、設定でのデバイス権限の取り消し、特定の集中モードの使用停止、またはアカウントの削除が可能です。

        お問い合わせ：プライバシーに関するご質問やアカウント削除の問題については、アプリまたは App Store リスティングで提供されるサポートチャネルを通じて Spike AI サポートにお問い合わせください。
        """,
        "terms_body": """
        最終更新日：2026年5月25日

        本利用規約は、タスク、リマインダー、集中モード、スクリーンタイムアプリのプロンプトとシールド、スウェットモードの動きチェック、進捗追跡、AI 生成のサマリーを含む、Spike AI の使用を規定します。

        資格とアカウント：お客様は作成したアカウントに責任を持ち、メールアドレスとデバイスへのアクセスを安全に保つ責任があります。アプリがプロフィール情報を求める場合は、正確な情報を使用してください。

        生産性目的：Spike AI は個人の生産性と意識的なデバイス使用を支援するために設計されています。医療、メンタルヘルス、緊急事態、安全、ペアレンタルコントロール、雇用監視、またはデバイス管理サービスではありません。リマインダー、ブロック、プロンプト、カメラチェック、通知、ネットワークリクエスト、または Apple の権限の障害が害を及ぼす可能性がある場合には、Spike AI に依存しないでください。

        お客様の責任：状況に適した集中設定を選択すること、モードを有効にする前にアプリの選択を確認すること、不要になったらモードをオフにすること、適用法および Apple のプラットフォーム規約を遵守すること、アプリでの使用に問題がない場合を除き、タスクや目標に機密情報を入力しないこと。

        適切な使用：Spike AI を悪用しないでください。他人のデバイスやアカウントを妨害したり、セキュリティやプラットフォームの制限を回避しようとしたり、サービスの保護された部分をリバースエンジニアリングしたり、バックエンドに過負荷をかけたり、違法、虐待的、欺瞞的、または有害な活動にアプリを使用したりしないでください。

        権限と可用性：一部の機能には、スクリーンタイム、通知、カメラ、ライブアクティビティ、ネットワークアクセスなどの iOS 権限が必要です。Apple、デバイスの設定、オペレーティングシステムの動作、接続性、バックエンドの可用性が、機能が期待どおりに動作するかどうかに影響する場合があります。

        AI 生成コンテンツ：進捗サマリーは自動化されたシステムを使用して生成される場合があります。これらは振り返りと生産性コーチングのみを目的としています。依存する前に、ご自身の判断で内容を確認してください。

        アカウントの削除と終了：プロフィールからアカウントの削除をリクエストできます。法律、プラットフォームルール、セキュリティ上の懸念、または重大な不正利用が要求する場合、Spike AI はアクセスを一時停止または終了する場合があります。

        変更：アプリの進化に伴い、Spike AI はこれらの規約を更新する場合があります。更新後の継続使用は、更新された規約への同意を意味します。

        お問い合わせ：本規約に関するご質問については、アプリまたは App Store リスティングで提供されるサポートチャネルを通じて Spike AI サポートにお問い合わせください。
        """,

        // Focus Mode
        "focus_title": "集中", "select_mode": "モード選択",
        "chill": "チル", "focus": "集中", "lock_in": "ロックイン", "sweat": "アスリート",
        "gentle_nudges": "やさしいリマインド", "confirm_intent": "意図を確認",
        "no_bypass": "回避不可", "move_to_unlock": "運動でロック解除",
        "activate_focus": "集中モードを有効にする", "deactivate_focus": "集中モードを無効にする",
        "mode_active": "モード有効中",
        "reminders_scheduled": "リマインダーがスケジュール済み",
        "apps_prompt_active": "個のアプリ——「本当に開きますか？」プロンプト有効",
        "apps_blocked": "個のアプリをブロック中",
        "temp_access_active": "一時アクセス有効",
        "apps_require_movement": "個のアプリは運動でロック解除が必要",
        "notifications_label": "通知",
        "notifications_enabled": "通知が有効",
        "notifications_denied": "通知が拒否されました",
        "enable_notif_settings": "設定で通知を有効にしてください。",
        "allow_notif_desc": "Spike AI が集中リマインダーを送信できるよう通知を許可してください。",
        "enable_notifications": "通知を有効にする",
        "screen_time_access": "スクリーンタイムへのアクセス",
        "screen_time_authorized": "スクリーンタイムが許可されています",
        "allow_screen_time": "スクリーンタイムへのアクセスを許可",
        "tap_to_allow": "下をタップしてスクリーンタイムへのアクセスを許可してください。",
        "open_settings_manual": "または設定を開いて手動で有効にしてください",
        "open_settings": "設定を開く",
        "app_selection": "アプリ選択",
        "selections": "個の選択",
        "choose_apps_confirm": "開く前に確認するアプリを選択してください。",
        "choose_apps_block": "ブロックするアプリを選択してください。",
        "choose_apps_movement": "運動でロック解除するアプリを選択してください。",
        "change_selection": "選択を変更",
        "select_apps": "アプリを選択",
        "movement_unlock": "運動でロック解除",
        "movement_desc": "腕立て伏せとスタンドアップは AI 身体検出で追跡されます。検証された1回の動作ごとに、選択したアプリに1分間のアクセスが追加されます。",
        "access_available": "%@ のアクセスが利用可能",
        "open_camera": "カメラチェックを開く",
        "lock_in_mode": "ロックインモード",
        "lock_in_warning": "アプリは回避できない赤い画面を表示します。ロックインモードをオフにするにはここに戻る必要があります。",
        "sweat_mode": "アスリートモード",
        "do_exercises": "腕立て伏せまたはスタンドアップで時間を獲得",
        "add_minutes": "%d 分を追加",
        "keep_in_view": "肩、腕、または腰を画面内に収めてください",
        "camera_required": "動きチェックにはカメラアクセスが必要です。",
        "camera_disabled": "カメラアクセスが無効です。スウェットモードを使用するには設定で有効にしてください。",
        "camera_unavailable": "カメラアクセスは利用できません。",
        "starting_camera": "カメラを起動中…",
        "camera_active": "カメラ動作中",
        "allow_camera": "カメラアクセスを許可",
        "focus_mode_title": "集中モード",
        "focus_mode_desc": "プロフェッショナルな集中モードでデジタル習慣をコントロールしましょう。",
        "about_permissions": "権限について",
        "permissions_desc": "チルモードは通知の許可が必要です。集中、ロックイン、スウェットモードはスクリーンタイムの許可が必要です。スウェットモードは動きチェックにカメラも使用します。",
        "get_started": "始める", "skip": "スキップ",
        "unlocked_for": "%@ ロック解除済み",

        // Chill mode descriptions
        "chill_desc": "通知によるデイリーリマインダー。アプリの制御はなく、意識的に過ごすためのやさしいリマインドだけです。",
        "focus_desc": "選択したアプリを開くと、Spike AI が「本当に開きますか？」と尋ねます。通常通り開くか、タスクに戻ることができます。アプリはブロックされません。",
        "lock_in_desc": "ロックインが有効な間、選択したアプリはブロックされます。Spike AI からモードをオフにできます。",
        "sweat_desc": "カメラで検証された腕立て伏せまたはスタンドアップを完了するまで、選択したアプリはブロックされたままです。検証された1回の動作で1分間ロック解除されます。",

        // Motivational (deactivation)
        "giving_up_title": "進歩しています——やめないでください",
        "giving_up_msg": "今日の未完了の目標がまだあります。タスクを1つ完了するたびにモチベーションが積み重なります。諦めないでください——未来のあなたが感謝するでしょう。",
        "giving_up_continue": "集中を維持", "giving_up_stop": "それでも無効にする",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "あなた専用の生産性システム",
        "start_setup": "セットアップを開始",
        "make_phone_work": "スマートフォンを\nあなたの目標のために活用しましょう。",
        "onboarding_welcome_desc": "無意識なスクロールを減らし、集中時間を守り、実際のタスクを目に見える進捗に変えましょう。",
        "did_you_know": "ご存知ですか？",
        "did_you_know_subtitle": "人は平均して1日7時間スマートフォンを使っています。これは",
        "hours_per_day": "時間/日",
        "days_per_month": "日/月",
        "days_per_year": "日/年",
        "years_of_life": "年分の人生",
        "screen_time_reality": "もっと多い人もいます。",
        "dont_worry_title": "ご安心ください",
        "spike_has_your_back": "Spike AI がサポートします",
        "solution_desc": "生産性を最大化し、目標に近づき、最高の自分へと変わる習慣を身につけるお手伝いをします。",
        "screen_time_access_title": "スクリーンタイムへのアクセス",
        "grant_access": "アクセスを許可",
        "which_apps": "気が散るアプリを\n選択してください",
        "choose_apps_protect": "時間を浪費するアプリを選択してください。集中モード中にブロックします。",
        "apple_screen_time_required": "Spike AI がアプリリストを表示するには、Apple のスクリーンタイムへのアクセスが必要です。",
        "save_apps": "保存して続ける",
        "change_selected_apps": "選択したアプリを変更",
        "ready_change_life": "人生を変える\n準備はできましたか？",
        "ready_change_desc": "アカウントを作成して選択を保存し、旅を始めましょう。",
        "benefit_no_distraction": "気が散るアプリに邪魔されなくなります",
        "benefit_discover_modes": "4種類の集中モードを発見しましょう",
        "benefit_track_progress": "進捗を追跡して目標に近づきましょう",
        "create_account": "アカウントを作成",
        "protect_focus": "集中を守る",
        "block_feeds": "フィードをブロック",
        "finish_tasks": "タスクを完了",
        "energy_plus_three": "+3 エネルギー",
        "selected_count": "%d 個選択済み",
        "no_apps_selected": "まだアプリが選択されていません",
        "saved_for_modes": "保護モード用に保存済み",
        "select_apps_to_control": "制御したいアプリを選択してください",
        "clean_room": "部屋の掃除",
        "snap_proof": "完了後に写真で証明",
        "ai_verifies_task": "AI がタスクを検証",
        "energy_earned": "+3 エネルギー獲得",
        "on_track": "順調",
        "energy": "エネルギー",
        "tasks_completed": "完了したタスク",
        "focus_protected": "集中を保護済み",
        "scrolling_avoided": "スクロールを回避",
        "continue_apple": "Apple で続ける",
        "continue_google": "Google で続ける",
        "continue_email": "メールで続ける",
        "enter_email": "メールアドレスを入力",
        "send_sign_in_link": "ログインリンクをお送りします",
        "check_email": "メールを確認してください",
        "sent_link_to": "ログインリンクを送信しました：",
        "tap_link": "リンクをタップすると自動的にログインします。",
        "open_mail": "メールアプリを開く",
        "open_with": "アプリで開く",
        "didnt_get_email": "メールが届きませんか？",
        "resend": "再送信",
        "resend_in": "%d秒後に再送信",
        "new_link_sent": "新しいリンクが送信されました！",
        "valid_email": "有効なメールアドレスを入力してください。",
        "by_continuing": "続けることで、Spike AI の",
        "and_word": "と",

        // Screen Time Onboarding
        "screen_time_title": "スクリーンタイム",
        "screen_time_permission_desc": "Spike AI は集中、ロックイン、スウェットモードのためにスクリーンタイムの許可が必要です。これにより、選択したアプリにプロンプトやブロックを表示できます。",
        "screen_time_denied": "許可が拒否されました。設定で有効にできます。",
        "ask_before_opening": "開く前に確認",
        "block_apps_completely": "アプリを完全にブロック",
        "stay_accountable": "自己管理を維持",
        "stay_accountable_desc": "進捗を追跡し、集中習慣を可視化しましょう。",
        "skip_for_now": "今はスキップ",

        // Live Activity
        "daily_goals_title": "日次目標",
        "of_done": "%d 個完了",
        "more_to_go": "残り +%d 個",

        // Chill morning
        "good_morning": "おはようございます！今日も意識的に過ごしましょう。タスクを確認して、集中を続けてください。",

        // General
        "error": "エラー", "ok": "OK", "yes": "はい", "no": "いいえ",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "チルモードに切り替えますか？",
        "stay_focused_btn": "集中を続ける",
        "switch_anyway_btn": "それでも切り替える",
        "switch_to_chill_msg": "まだ未完了の目標があります。チルモードに切り替えるとアプリのブロックが解除され、今日の目標を達成できないリスクが高まります。",
        "task_notification": "タスク通知",
        "missed_alarm": "未確認のアラーム",
        "quote_of_day": "今日の名言",
        "new_quotes_daily": "新しい名言は毎日午前5時に届きます",
        "focus_day_label": "フォーカスデー",
        "missed_label": "未達成",
        "access_granted": "アクセスが許可されました",
        "goal_reminder": "目標リマインダー",
        "spike_ai_focus": "Spike AI フォーカス",
        "goals_required_title": "目標の設定が必要です",
        "goals_required_desc_focus": "フォーカスモードは未完了の目標がある場合のみ選択したアプリをブロックします。アプリブロックを有効にするには、ホームタブで目標を追加してください。",
        "goals_required_desc_lockin": "ロックインモードは未完了の目標がある場合のみ選択したアプリをブロックします。アプリブロックを有効にするには、ホームタブで目標を追加してください。",
        "save": "保存",
        "no_goals_reminder_body": "今日の目標がまだ設定されていません。少し時間を取って一日を計画しましょう！",
        "dont_forget": "お忘れなく",
        "chill_morning_body": "おはようございます！今日も意識的に過ごしましょう。タスクを確認して集中を保ちましょう。",
        "every_day": "毎日",
        "weekdays": "平日",
        "weekends": "週末",
        "time_to_focus": "集中する時間です！",

        // Additional UI strings
        "next_quote_in": "次の名言まで %@",
        "enable_notif_chill": "チルモードを開始する前に通知を有効にしてください。",
        "enable_screen_time_mode": "このモードを開始する前にスクリーンタイムのアクセスを有効にしてください。",
        "select_app_before_mode": "このモードを開始する前に、少なくとも1つのアプリ、カテゴリ、またはウェブサイトを選択してください。",
        "mode_not_ready": "このモードはまだ開始できません。",
        "protection_stopped_no_apps": "保護が停止しました：アプリが選択されていません。",
        "protection_stopped_screen_time": "保護が停止しました：スクリーンタイムのアクセスが変更されました。",
        "max_reminders": "集中リマインダーは最大%d件まで作成できます。",
        "front_camera_unavailable": "フロントカメラが利用できません。",
        "task_title_empty": "タスクのタイトルは空にできません。",
        "goal_title_empty": "目標のタイトルは空にできません。",
        "rate_limit_wait": "次のレポートを作成するまで%d秒お待ちください。",
        "missed_alarm_for": "アラームを逃しました：%@",
        "stay_with_plan": "計画通りに進めましょう。",
        "motivation_small_wins": "小さな勝利が積み重なる。",
        "motivation_next_step": "次のステップを完了しよう。",
        "motivation_protect_hour": "目の前の一時間を守ろう。",
        "motivation_consistency": "継続は力なり。",
        "monthly_scope_btn": "月間",
        "yearly_scope_btn": "年間",
        "restoring_session": "セッションを復元中...",

        // Milestones
        "milestone_3day_streak": "3日連続",
        "milestone_3day_desc": "安定したリズムが始まりました。",
        "milestone_7day_streak": "7日連続",
        "milestone_7day_desc": "集中した1週間を達成。",
        "milestone_10h_protected": "10時間保護",
        "milestone_10h_desc": "大切なことのために守った時間。",
        "milestone_30_focus": "30日間の集中",
        "milestone_30_desc": "本物の重みのある継続。",

        // Narratives
        "narrative_improved": "先週と比べてスクリーンタイムが改善しました。",
        "narrative_consistent": "今週は一貫性を保ち集中を守りました。",
        "narrative_more_days": "通常より多くの集中日を達成しました。",
        "narrative_building": "一日一日集中してリズムを作っています。",

        // Screen time
        "screen_time_trend_pending": "使用履歴が蓄積されるとスクリーンタイムの傾向が表示されます。",
        "screen_time_improved": "スクリーンタイムが %d%% 改善",
        "screen_time_higher": "スクリーンタイムが通常より少し多い",
        "screen_time_steady": "今週のスクリーンタイムは安定",

        // Benchmarks
        "benchmark_pending": "アプリが使用履歴を記録すると平均スクリーンタイムが表示されます。世界の基準は1日約7時間です。",
        "benchmark_below": "7日間の平均は %@ で、世界平均の7時間を下回っています。良い方向です。",
        "benchmark_above": "7日間の平均は %@ で、世界平均の7時間を上回っています。今日少し減らせば傾向が変わります。",
        "benchmark_matching": "7日間の平均は %@ で、世界平均の7時間と一致しています。",

        // Task editing
        "edit_task": "タスクを編集",
        "task_name_placeholder": "タスク名",
        "task_reminder_default": "タスクリマインダー",
        "time_h_m": "%d時間 %d分",
        "time_m": "%d分",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Korean
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let ko: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "집중 모드 정보",
        "no_active_goals_title": "활성 목표 없음",
        "no_active_goals_btn": "확인",
        "no_active_goals_msg": "집중 모드와 잠금 모드는 완료하지 않은 목표가 있을 때만 작동합니다. 목표를 추가하거나 다시 활성화한 후 세션을 시작하세요.",
        // Tab bar
        "tab_home": "홈",
        "tab_progress": "진행",
        "tab_mode": "모드",
        "tab_profile": "프로필",

        // Home
        "today": "오늘",
        "tomorrow": "내일",
        "yesterday": "어제",
        "back_to_today": "오늘로 돌아가기",
        "add_first_task": "+ 를 눌러 첫 번째 할 일을 추가하세요",
        "no_tasks_this_day": "이 날에는 할 일이 없습니다",
        "new_task": "새 할 일",
        "what_to_do": "무엇을 해야 하나요?",
        "task": "할 일",
        "schedule": "일정",
        "pick_date_hint": "오늘, 다음 주, 또는 몇 달 후 등 원하는 날짜를 선택하세요.",
        "priority": "우선순위",
        "low": "낮음",
        "medium": "보통",
        "high": "높음",
        "notification": "알림",
        "silent_push": "무음 푸시 알림",
        "notification_desc": "예약된 시간에 일회성 푸시 알림을 보냅니다. 잠금 화면과 알림 센터에 조용히 표시됩니다.",
        "reminder": "리마인더",
        "alarm_sound": "소리 및 진동 알람",
        "reminder_desc": "알람처럼 작동합니다 — 화면의 해제 버튼을 누를 때까지 특별한 소리가 재생되고 휴대폰이 계속 진동합니다. 회의와 마감일에 유용합니다.",
        "cancel": "취소",
        "add": "추가",
        "edit": "편집",
        "delete": "삭제",
        "jump_to_date": "날짜로 이동",
        "done": "완료",
        "task_limit": "이 날짜의 25개 할 일 제한에 도달했습니다.",
        "time": "시간",
        "date": "날짜",
        "select_date": "날짜 선택",

        // Alarm
        "reminder_title": "리마인더",
        "dismiss": "해제",

        // Progress
        "daily_progress": "일일 진행",
        "streaks": "연속",
        "focus_days": "집중한 날",
        "consistency": "꾸준함",
        "set_first_goal": "오늘의 첫 번째 목표를 설정하세요",
        "all_goals_completed": "모든 일일 목표를 달성했습니다",
        "goals_completed": "중",
        "daily_goals_completed": "일일 목표 달성",
        "daily_goals": "일일 목표",
        "remaining": "남음",
        "no_goals_planned": "계획된 목표 없음",
        "complete_to_focus": "오늘을 집중의 날로 표시하려면 모든 할 일을 완료하세요.",
        "add_task_to_start": "일일 목표 추적을 시작하려면 홈에서 할 일을 추가하세요.",
        "daily_plan_complete": "일일 계획 완료",
        "ai_weekly_summary": "AI 주간 요약",
        "creating_summary": "주간 요약을 생성하고 있습니다...",
        "generate_summary": "요약 생성",
        "refresh_summary": "요약 새로고침",
        "first_summary_coming": "첫 번째 AI 주간 요약이 준비 중입니다.",
        "first_summary_desc": "%@ 오후 9시에 준비됩니다. 진행 상황, 미완료 할 일, 최적의 집중 모드에 대한 인사이트가 포함됩니다.",
        "next_update": "다음 업데이트: %@",
        "weekly_recap": "집중한 날, 할 일, 생산성 추이에 대한 주간 요약이 준비되었습니다.",
        "screen_time_7day": "7일 스크린 타임",
        "best_streak": "최고 연속",
        "days": "일",
        "milestones": "마일스톤",
        "milestone_unlocked": "마일스톤 달성",
        "continue_btn": "계속",
        "history_calendar": "기록 캘린더",
        "mode_used": "사용한 모드",
        "completed": "완료됨",
        "not_completed": "미완료",
        "no_completed_tasks": "이 날에 기록된 완료 할 일이 없습니다.",
        "everything_completed": "모든 것이 완료되었습니다.",
        "no_missed_tasks": "이 날에 기록된 미완료 할 일이 없습니다.",
        "streak_day": "연속 달성일",
        "missed_day": "미달성일",
        "first_name": "이름",
        "last_name": "성",
        "avatar_color": "아바타 색상",
        "whats_your_name": "이름이 무엇인가요?",
        "name_helps": "맞춤형 경험을 제공하는 데 도움이 됩니다.",
        "name_save_failed": "이름을 저장할 수 없습니다. 연결 상태를 확인하고 다시 시도해 주세요.",
        "continue_btn_name": "계속",
        "wins": "성과",
        "next_action": "다음 행동",
        "average": "평균",
        "todays_completion": "오늘의 완료율",
        "streaks_this_month": "이번 달 연속",
        "streak_days": "연속 달성일",
        "non_streak_days": "미달성일",
        "monthly_streak_summary": "이번 달 %d 연속 • %d 연속 달성일, %d 미달성일",
        "duration_average": "%@ 평균",

        // Profile
        "personal_details": "개인 정보",
        "personal_info": "개인 정보",
        "update_email_name": "이메일과 이름을 업데이트하세요.",
        "and_username": "및 사용자 이름",
        "invite_friends": "친구 초대",
        "refer_friend_title": "친구를 추천하고 $10를 받으세요",
        "refer_friend_desc": "프로모션 코드로 가입한 친구 한 명당 $10를 받으세요.",
        "upgrade_family_plan": "가족 플랜으로 업그레이드",
        "goals_tracking": "목표 및 추적",
        "apple_health": "Apple 건강",
        "edit_nutrition_goals": "영양 목표 편집",
        "tracking_reminders": "추적 리마인더",
        "email_not_editable": "이메일은 로그인에 연결되어 있어 여기서 편집할 수 없습니다.",
        "theme": "테마",
        "theme_desc": "시스템 외관을 사용하거나 고정 라이트/다크 모드를 선택하세요.",
        "appearance": "외관",
        "appearance_desc": "라이트, 다크 또는 시스템 외관을 선택하세요",
        "live_activity_profile_desc": "잠금 화면과 다이나믹 아일랜드에 일일 진행 상황을 표시합니다",
        "system": "시스템",
        "light": "라이트",
        "dark": "다크",
        "live_activity": "라이브 액티비티",
        "live_activity_desc": "잠금 화면에 오늘의 목표, 연속 기록, 새로운 동기 부여를 표시합니다.",
        "privacy_policy": "개인정보 처리방침",
        "privacy_desc": "앱 데이터 및 기기 권한이 어떻게 사용되는지 확인하세요.",
        "terms_of_service": "이용약관",
        "terms_desc": "앱과 집중 도구 사용 규칙을 읽어보세요.",
        "follow_us": "팔로우하기",
        "sign_out": "로그아웃",
        "sign_out_desc": "현재 기기에서 세션을 종료합니다.",
        "delete_account": "계정 삭제",
        "delete_account_desc": "계정 및 동기화된 앱 데이터를 영구 삭제합니다.",
        "delete_account_title": "계정 삭제",
        "delete_account_msg": "이 작업은 영구적입니다. 모든 데이터가 삭제되며 복구할 수 없습니다.",
        "delete_account_continue": "계속",
        "delete_account_final_title": "영구 삭제하시겠습니까?",
        "delete_account_final_msg": "한 번 더 확인해 주세요. 계정을 삭제하면 Spike AI에서 로그아웃되고 로그인 페이지로 돌아갑니다.",
        "deleting_account": "계정 삭제 중...",
        "delete_failed": "계정 삭제에 실패했습니다. 다시 시도하거나 고객 지원에 문의하세요.",
        "language": "언어",
        "language_desc": "모든 앱 콘텐츠의 언어를 선택하세요.",
        "set_name": "이름을 설정하세요",
        "profile_name_prompt": "어떻게 불러드릴까요?",
        "profile_name_desc": "Spike AI가 프로필과 생산성 경험에서 사용할 이름을 추가하세요.",
        "full_name": "전체 이름",
        "display_name": "표시 이름",
        "email": "이메일",
        "save_changes": "변경 사항 저장",
        "save_footer": "변경 사항은 프로필에 저장되며 앱에서 신원이 표시되는 모든 곳에 사용됩니다.",
        "signed_in": "로그인됨",
        "account": "계정",
        "preferences": "환경 설정",
        "support_legal": "지원 및 법적 정보",
        "account_actions": "계정 관리",
        "pref_show_completed": "완료된 할 일 표시",
        "pref_show_completed_desc": "일일 목록에서 완료된 할 일을 계속 표시합니다.",
        "pref_quotes": "동기 부여 명언",
        "pref_quotes_desc": "진행 화면에 영감을 주는 명언을 표시합니다.",
        "legal_updated": "최종 업데이트: 2026년 5월 25일",
        "privacy_body": """
        최종 업데이트: 2026년 5월 25일

        Spike AI는 생산성 및 집중 앱입니다. 본 개인정보 처리방침은 Spike AI가 계정, 할 일 계획, 리마인더, 집중 모드, 스크린 타임 제어, 진행 추적 및 AI 생성 생산성 요약을 제공하기 위해 정보를 어떻게 처리하는지 설명합니다.

        수집하는 정보: 이메일 주소 및 사용자 ID와 같은 계정 식별자; 표시 이름 및 전체 이름과 같이 사용자가 제공하기로 선택한 프로필 세부 정보; 할 일, 목표, 리마인더, 완료 기록, 집중 모드 설정, 앱 선택 토큰 및 진행 지표. 서비스를 안정적이고 안전하게 유지하는 데 필요한 기술 기록도 저장할 수 있습니다.

        스크린 타임 및 앱 선택: 앱, 카테고리 및 웹 도메인 선택은 Apple의 FamilyControls 및 ManagedSettings 프레임워크를 통해 처리됩니다. Spike AI는 선택한 집중 모드를 적용하는 데 필요한 Apple 제공 토큰을 저장합니다. 이러한 선택을 광고에 사용하지 않습니다.

        운동선수 모드에서의 카메라 사용: 카메라 접근 권한은 움직임을 통해 임시 앱 접근 권한을 획득할 수 있도록 기기 내 신체 자세 확인에 사용됩니다. Spike AI는 이 기능을 위해 비디오 프레임을 업로드하지 않으며 카메라 데이터를 광고에 사용하지 않습니다.

        알림 및 리마인더: Spike AI는 사용자가 구성한 할 일 리마인더, 알람 및 집중 알림을 보내기 위해 알림 권한을 사용합니다. iOS 설정에서 언제든지 알림 접근 권한을 변경할 수 있습니다.

        AI 요약: 진행 요약을 생성하면 최근 할 일, 목표, 집중 및 생산성 지표가 요약을 생성하기 위해 Spike AI 백엔드에서 처리될 수 있습니다. 생산성 기능에서 처리되기를 원하지 않는 민감한 개인 정보는 할 일 이름이나 목표에 입력하지 마세요.

        정보 사용 방법: 인증, 계정 동기화, 집중 도구 제공, 리마인더 예약, 진행 표시, 생산성 인사이트 개인화, 오용 방지, 문제 해결 및 법적 의무 준수를 위해 사용합니다. Spike AI는 개인 정보를 판매하지 않습니다.

        데이터 삭제: 프로필에서 로그아웃하거나 영구 계정 삭제를 요청할 수 있습니다. 계정 삭제 시 인증 계정 및 해당 계정과 연관된 동기화된 앱 데이터가 제거되며, 보안, 사기 방지, 분쟁 해결 또는 법적 준수를 위해 필요한 제한적 보존이 적용됩니다.

        사용자의 선택: 프로필 세부 정보 편집, 언어 및 외관 환경 설정 변경, 라이브 액티비티 비활성화, 설정에서 기기 권한 취소, 특정 집중 모드 사용 중지 또는 계정 삭제를 할 수 있습니다.

        연락처: 개인정보 관련 질문이나 계정 삭제 문제의 경우 앱 또는 App Store 목록에서 제공하는 지원 채널을 통해 Spike AI 지원팀에 문의하세요.
        """,
        "terms_body": """
        최종 업데이트: 2026년 5월 25일

        본 이용약관은 할 일, 리마인더, 집중 모드, 스크린 타임 앱 프롬프트 및 차단, 운동선수 모드 움직임 확인, 진행 추적 및 AI 생성 요약을 포함한 Spike AI 사용에 적용됩니다.

        자격 및 계정: 사용자는 생성한 계정과 이메일 및 기기에 대한 접근 권한을 안전하게 유지할 책임이 있습니다. 앱이 프로필 세부 정보를 요청하는 경우 정확한 정보를 사용하세요.

        생산성 목적: Spike AI는 개인 생산성과 의도적인 기기 사용을 지원하도록 설계되었습니다. 의료, 정신 건강, 응급, 안전, 자녀 보호, 고용 모니터링 또는 기기 관리 서비스가 아닙니다. 리마인더, 차단, 프롬프트, 카메라 확인, 알림, 네트워크 요청 또는 Apple 권한의 실패가 해를 끼칠 수 있는 경우 Spike AI에 의존하지 마세요.

        사용자의 책임: 상황에 적합한 집중 설정을 선택하세요; 모드를 활성화하기 전에 앱 선택을 검토하세요; 더 이상 필요하지 않을 때 모드를 끄세요; 관련 법률 및 Apple 플랫폼 약관을 준수하세요; 앱에서 사용하는 것이 편안하지 않은 경우 할 일이나 목표에 민감한 정보를 입력하지 마세요.

        허용되는 사용: Spike AI를 오용하거나, 다른 사람의 기기 또는 계정을 방해하거나, 보안 또는 플랫폼 제한을 우회하려 하거나, 서비스의 보호된 부분을 역설계하거나, 백엔드에 과부하를 걸거나, 불법적이거나 학대적이거나 기만적이거나 유해한 활동에 앱을 사용하지 마세요.

        권한 및 가용성: 일부 기능은 스크린 타임, 알림, 카메라, 라이브 액티비티 및 네트워크 접근과 같은 iOS 권한이 필요합니다. Apple, 기기 설정, 운영 체제 동작, 연결성 및 백엔드 가용성이 기능의 예상대로 작동 여부에 영향을 줄 수 있습니다.

        AI 생성 콘텐츠: 진행 요약은 자동화된 시스템을 사용하여 생성될 수 있습니다. 이는 성찰과 생산성 코칭만을 위한 것입니다. 의존하기 전에 자신의 판단으로 검토하세요.

        계정 삭제 및 종료: 프로필에서 계정 삭제를 요청할 수 있습니다. Spike AI는 법률, 플랫폼 규칙, 보안 우려 또는 심각한 오용에 의해 요구되는 경우 접근을 일시 중지하거나 종료할 수 있습니다.

        변경 사항: Spike AI는 앱이 발전함에 따라 본 약관을 업데이트할 수 있습니다. 업데이트 후 계속 사용하면 업데이트된 약관에 동의하는 것입니다.

        연락처: 본 약관에 관한 질문이 있으시면 앱 또는 App Store 목록에서 제공하는 지원 채널을 통해 Spike AI 지원팀에 문의하세요.
        """,

        // Focus Mode
        "focus_title": "집중",
        "select_mode": "모드 선택",
        "chill": "여유",
        "focus": "집중",
        "lock_in": "잠금",
        "sweat": "운동선수",
        "gentle_nudges": "부드러운 알림",
        "confirm_intent": "의도 확인",
        "no_bypass": "우회 불가",
        "move_to_unlock": "움직여서 잠금 해제",
        "activate_focus": "집중 모드 활성화",
        "deactivate_focus": "집중 모드 비활성화",
        "mode_active": "모드 활성 중",
        "reminders_scheduled": "리마인더 예약됨",
        "apps_prompt_active": "개 앱 — \"정말 여시겠습니까?\" 프롬프트 활성",
        "apps_blocked": "개 앱 차단됨",
        "temp_access_active": "임시 접근 활성",
        "apps_require_movement": "개 앱 잠금 해제에 움직임 필요",
        "notifications_label": "알림",
        "notifications_enabled": "알림 활성화됨",
        "notifications_denied": "알림 거부됨",
        "enable_notif_settings": "설정에서 알림을 활성화하세요.",
        "allow_notif_desc": "Spike AI가 집중 리마인더를 보낼 수 있도록 알림을 허용하세요.",
        "enable_notifications": "알림 활성화",
        "screen_time_access": "스크린 타임 접근",
        "screen_time_authorized": "스크린 타임 승인됨",
        "allow_screen_time": "스크린 타임 접근 허용",
        "tap_to_allow": "아래를 탭하여 스크린 타임 접근을 허용하세요.",
        "open_settings_manual": "또는 설정을 열어 수동으로 활성화하세요",
        "open_settings": "설정 열기",
        "app_selection": "앱 선택",
        "selections": "개 선택",
        "choose_apps_confirm": "열기 전에 확인할 앱을 선택하세요.",
        "choose_apps_block": "차단할 앱을 선택하세요.",
        "choose_apps_movement": "움직임으로 잠금 해제할 앱을 선택하세요.",
        "change_selection": "선택 변경",
        "select_apps": "앱 선택",
        "movement_unlock": "움직임 잠금 해제",
        "movement_desc": "팔굽혀펴기와 스탠드업은 AI 신체 감지로 추적됩니다. 인증된 반복 횟수마다 선택한 앱에 1분의 접근 권한이 추가됩니다.",
        "access_available": "%@ 동안 접근 가능",
        "open_camera": "카메라 확인 열기",
        "lock_in_mode": "잠금 모드",
        "lock_in_warning": "앱이 우회 불가능한 빨간 화면을 표시합니다. 잠금 모드를 끄려면 여기로 돌아와야 합니다.",
        "sweat_mode": "운동선수 모드",
        "do_exercises": "시간을 얻으려면 팔굽혀펴기 또는 스탠드업을 하세요",
        "add_minutes": "%d분 추가",
        "keep_in_view": "어깨, 팔 또는 엉덩이를 화면에 유지하세요",
        "camera_required": "움직임 확인을 위해 카메라 접근 권한이 필요합니다.",
        "camera_disabled": "카메라 접근이 비활성화되었습니다. 운동 모드를 사용하려면 설정에서 활성화하세요.",
        "camera_unavailable": "카메라 접근을 사용할 수 없습니다.",
        "starting_camera": "카메라 시작 중...",
        "camera_active": "카메라 활성",
        "allow_camera": "카메라 접근 허용",
        "focus_mode_title": "집중 모드",
        "focus_mode_desc": "집중적이고 전문적인 모드로 디지털 습관을 관리하세요.",
        "about_permissions": "권한 정보",
        "permissions_desc": "여유 모드는 알림 권한이 필요합니다. 집중, 잠금 및 운동 모드는 스크린 타임 승인이 필요합니다. 운동 모드는 움직임 확인을 위해 카메라 접근도 사용합니다.",
        "get_started": "시작하기",
        "skip": "건너뛰기",
        "unlocked_for": "%@ 동안 잠금 해제됨",

        // Chill mode descriptions
        "chill_desc": "알림을 통한 일일 리마인더. 앱 제어 없음 — 의도적으로 생활하도록 부드럽게 알려줍니다.",
        "focus_desc": "선택한 앱을 열면 Spike AI가 \"정말 여시겠습니까?\"라고 묻습니다. 정상적으로 열거나 할 일로 돌아갈 수 있습니다. 앱이 차단되지 않습니다.",
        "lock_in_desc": "잠금이 활성화된 동안 선택한 앱이 차단됩니다. Spike AI에서 모드를 끌 수 있습니다.",
        "sweat_desc": "카메라로 확인된 팔굽혀펴기 또는 스탠드업을 완료할 때까지 선택한 앱이 차단됩니다. 인증된 반복 횟수당 1분이 잠금 해제됩니다.",

        // Motivational (deactivation)
        "giving_up_title": "성장 중입니다 — 멈추지 마세요",
        "giving_up_msg": "오늘 아직 미완료 목표가 있습니다. 완료된 모든 할 일이 추진력을 만듭니다. 끝까지 함께하세요 — 미래의 자신이 감사할 것입니다.",
        "giving_up_continue": "집중 유지",
        "giving_up_stop": "그래도 끄기",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "당신의 개인 생산성 시스템",
        "start_setup": "설정 시작",
        "make_phone_work": "휴대폰이 목표를 위해\n작동하도록 하세요.",
        "onboarding_welcome_desc": "무의미한 스크롤을 줄이고, 집중 시간을 보호하며, 실제 할 일을 눈에 보이는 진행으로 전환하세요.",
        "did_you_know": "알고 계셨나요?",
        "did_you_know_subtitle": "사람들은 하루 평균 7시간을 휴대폰에 사용합니다. 이는",
        "hours_per_day": "시간/일",
        "days_per_month": "일/월",
        "days_per_year": "일/년",
        "years_of_life": "년의 인생",
        "screen_time_reality": "일부 사람들은 더 많이 사용합니다.",
        "dont_worry_title": "걱정하지 마세요",
        "spike_has_your_back": "Spike AI가 도와드립니다",
        "solution_desc": "생산성을 극대화하고, 목표에 더 가까이 다가가며, 최고의 자신으로 변화시키는 습관을 만들 수 있도록 도와드리겠습니다.",
        "screen_time_access_title": "스크린 타임 접근",
        "grant_access": "접근 허용",
        "which_apps": "방해가 되는\n앱을 선택하세요",
        "choose_apps_protect": "시간을 낭비하는 앱을 선택하세요. 집중 모드에서 차단해 드립니다.",
        "apple_screen_time_required": "Spike AI가 앱 목록을 표시하려면 Apple의 스크린 타임 접근 권한이 필요합니다.",
        "save_apps": "저장 및 계속",
        "change_selected_apps": "선택한 앱 변경",
        "ready_change_life": "삶을 바꿀\n준비가 되셨나요?",
        "ready_change_desc": "선택 사항을 저장하고 여정을 시작하려면 계정을 만드세요.",
        "benefit_no_distraction": "방해가 되는 앱이 더 이상 귀찮게 하지 않습니다",
        "benefit_discover_modes": "4가지 집중 모드를 발견하세요",
        "benefit_track_progress": "진행 상황을 추적하고 목표에 더 가까이 다가가세요",
        "create_account": "계정 만들기",
        "protect_focus": "집중 보호",
        "block_feeds": "피드 차단",
        "finish_tasks": "할 일 완료",
        "energy_plus_three": "+3 에너지",
        "selected_count": "%d개 선택됨",
        "no_apps_selected": "아직 선택된 앱 없음",
        "saved_for_modes": "보호 모드에 저장됨",
        "select_apps_to_control": "제어하고 싶은 앱을 선택하세요",
        "clean_room": "방 청소",
        "snap_proof": "완료 후 인증 사진 촬영",
        "ai_verifies_task": "AI가 할 일을 확인합니다",
        "energy_earned": "+3 에너지 획득",
        "on_track": "순조로움",
        "energy": "에너지",
        "tasks_completed": "완료된 할 일",
        "focus_protected": "집중 보호됨",
        "scrolling_avoided": "스크롤 방지됨",
        "continue_apple": "Apple로 계속",
        "continue_google": "Google로 계속",
        "continue_email": "이메일로 계속",
        "enter_email": "이메일을 입력하세요",
        "send_sign_in_link": "로그인 링크를 보내드립니다",
        "check_email": "이메일을 확인하세요",
        "sent_link_to": "로그인 링크를 보냈습니다",
        "tap_link": "링크를 탭하면 자동으로 로그인됩니다.",
        "open_mail": "메일 앱 열기",
        "open_with": "다음으로 열기",
        "didnt_get_email": "이메일을 받지 못하셨나요?",
        "resend": "재전송",
        "resend_in": "%d초 후 재전송",
        "new_link_sent": "새 링크가 전송되었습니다!",
        "valid_email": "유효한 이메일 주소를 입력하세요.",
        "by_continuing": "계속하면 Spike AI의",
        "and_word": "및",

        // Screen Time Onboarding
        "screen_time_title": "스크린 타임",
        "screen_time_permission_desc": "Spike AI는 집중, 잠금 및 운동 모드를 위해 스크린 타임 권한이 필요합니다. 이를 통해 선택한 앱에 대한 프롬프트와 차단을 표시할 수 있습니다.",
        "screen_time_denied": "권한이 거부되었습니다. 설정에서 활성화할 수 있습니다.",
        "ask_before_opening": "열기 전에 확인",
        "block_apps_completely": "앱 완전 차단",
        "stay_accountable": "책임감 유지",
        "stay_accountable_desc": "진행 상황을 추적하고 집중 습관을 눈에 보이게 유지하세요.",
        "skip_for_now": "지금은 건너뛰기",

        // Live Activity
        "daily_goals_title": "일일 목표",
        "of_done": "%d개 중 완료",
        "more_to_go": "+%d개 남음",

        // Chill morning
        "good_morning": "좋은 아침입니다! 오늘 의도적으로 생활하세요. 할 일을 검토하고 집중하세요.",

        // Onboarding (extended)
        "scrolling_adds_up": "스크롤은 작아 보이지만\n쌓이게 됩니다.",
        "per_day": "하루",
        "per_month": "한 달",
        "per_year": "일 년",
        "thirty_days": "30일",
        "lost_to_checking": "무의식적 확인에 소비됨",
        "scrolling_cost_desc": "Spike AI는 그 순간들이 저녁 전체를 차지하기 전에 인식할 수 있도록 도와줍니다.",
        "your_modes_target": "이제 모드에\n명확한 대상이 있습니다.",
        "app_selections_will_be_used": "%d개 앱 선택이 보호 모드를 시작할 때 사용됩니다.",
        "select_apps_after_login": "로그인 후 앱을 한 번 선택하면 모든 보호 모드가 해당 목록을 사용합니다.",
        "focus_mode_marketing_detail": "방해가 되는 앱을 열기 전에 잠시 멈춤.",
        "lock_in_marketing_detail": "깊은 작업이 필요할 때 더 강한 경계.",
        "sweat_marketing_detail": "먼저 움직여서 접근 시간을 획득하세요.",
        "replace_scroll": "스크롤 대신\n실제 성과를 만드세요.",
        "habit_desc": "유익한 행동을 에너지로 전환하세요: 방 청소, 과제 제출, 걷기, 스트레칭 또는 할 일 하나를 완료하세요.",
        "see_behavior_changing": "행동이 변하는 것을\n직접 확인하세요.",
        "progress_desc": "집중 시간, 할 일 완료 및 연속 기록을 추적하여 진행을 명확하게 느끼세요.",
        "ready_protected_day": "첫 보호된 하루를\n시작할 준비가 되셨나요?",
        "create_account_desc": "앱 선택, 집중 모드, 할 일 및 진행 상황을 저장하려면 계정을 만드세요.",
        "benefit_apps_saved": "방해가 되는 앱이 모드에 저장됩니다",
        "benefit_start_modes": "집중, 잠금 또는 운동 모드를 시작하세요",
        "benefit_progress_synced": "진행 상황이 동기화됩니다",

        // General
        "error": "오류",
        "ok": "확인",
        "yes": "예",
        "no": "아니요",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "휴식 모드로 전환할까요?",
        "stay_focused_btn": "집중 유지",
        "switch_anyway_btn": "그래도 전환",
        "switch_to_chill_msg": "아직 완료하지 못한 목표가 있습니다. 휴식 모드로 전환하면 앱 차단이 해제되어 오늘 목표를 달성하지 못할 위험이 높아집니다.",
        "task_notification": "작업 알림",
        "missed_alarm": "놓친 알람",
        "quote_of_day": "오늘의 명언",
        "new_quotes_daily": "새로운 명언이 매일 오전 5시에 도착합니다",
        "focus_day_label": "집중의 날",
        "missed_label": "놓침",
        "access_granted": "접근이 허용되었습니다",
        "goal_reminder": "목표 알림",
        "spike_ai_focus": "Spike AI 집중",
        "goals_required_title": "목표 설정 필요",
        "goals_required_desc_focus": "집중 모드는 미완료 목표가 있을 때만 선택한 앱을 차단합니다. 앱 차단을 활성화하려면 홈 탭에서 목표를 추가하세요.",
        "goals_required_desc_lockin": "잠금 모드는 미완료 목표가 있을 때만 선택한 앱을 차단합니다. 앱 차단을 활성화하려면 홈 탭에서 목표를 추가하세요.",
        "save": "저장",
        "no_goals_reminder_body": "오늘 목표를 아직 설정하지 않았습니다. 잠시 시간을 내어 하루를 계획하세요!",
        "dont_forget": "잊지 마세요",
        "chill_morning_body": "좋은 아침이에요! 오늘도 의도적으로 생활하세요. 할 일을 확인하고 집중을 유지하세요.",
        "every_day": "매일",
        "weekdays": "평일",
        "weekends": "주말",
        "time_to_focus": "집중할 시간이에요!",

        // Additional UI strings
        "next_quote_in": "다음 명언까지 %@",
        "enable_notif_chill": "칠 모드를 시작하기 전에 알림을 활성화하세요.",
        "enable_screen_time_mode": "이 모드를 시작하기 전에 스크린 타임 접근을 활성화하세요.",
        "select_app_before_mode": "이 모드를 시작하기 전에 앱, 카테고리 또는 웹사이트를 하나 이상 선택하세요.",
        "mode_not_ready": "이 모드는 아직 시작할 준비가 되지 않았습니다.",
        "protection_stopped_no_apps": "보호가 중지되었습니다: 선택된 앱이 없습니다.",
        "protection_stopped_screen_time": "보호가 중지되었습니다: 스크린 타임 접근이 변경되었습니다.",
        "max_reminders": "집중 알림은 최대 %d개까지 만들 수 있습니다.",
        "front_camera_unavailable": "전면 카메라를 사용할 수 없습니다.",
        "task_title_empty": "작업 제목은 비워둘 수 없습니다.",
        "goal_title_empty": "목표 제목은 비워둘 수 없습니다.",
        "rate_limit_wait": "다음 요약을 생성하려면 %d초 기다려 주세요.",
        "missed_alarm_for": "알람을 놓쳤습니다: %@",
        "stay_with_plan": "계획을 유지하세요.",
        "motivation_small_wins": "작은 승리가 쌓입니다.",
        "motivation_next_step": "다음 단계를 완료하세요.",
        "motivation_protect_hour": "눈앞의 한 시간을 지키세요.",
        "motivation_consistency": "꾸준함이 강도를 이깁니다.",
        "monthly_scope_btn": "월간",
        "yearly_scope_btn": "연간",
        "restoring_session": "세션 복원 중...",

        // Milestones
        "milestone_3day_streak": "3일 연속",
        "milestone_3day_desc": "꾸준한 리듬이 시작되었습니다.",
        "milestone_7day_streak": "7일 연속",
        "milestone_7day_desc": "집중한 한 주를 완성했습니다.",
        "milestone_10h_protected": "10시간 보호",
        "milestone_10h_desc": "중요한 것을 위해 보호한 시간.",
        "milestone_30_focus": "30일 집중",
        "milestone_30_desc": "실질적인 꾸준함.",

        // Narratives
        "narrative_improved": "지난주에 비해 화면 사용 시간이 개선되었습니다.",
        "narrative_consistent": "이번 주에 일관성을 유지하고 집중을 보호했습니다.",
        "narrative_more_days": "평소보다 더 많은 집중일을 완료했습니다.",
        "narrative_building": "하루하루 집중하며 리듬을 만들고 있습니다.",

        // Screen time
        "screen_time_trend_pending": "사용 기록이 쌓이면 화면 시간 추세가 나타납니다.",
        "screen_time_improved": "화면 사용 시간 %d%% 개선",
        "screen_time_higher": "화면 사용 시간이 평소보다 약간 높습니다",
        "screen_time_steady": "이번 주 화면 사용 시간이 안정적입니다",

        // Benchmarks
        "benchmark_pending": "앱이 사용 기록을 쌓으면 평균 화면 시간이 표시됩니다. 세계 기준은 하루 약 7시간입니다.",
        "benchmark_below": "7일 평균은 %@로 세계 평균 7시간보다 낮습니다. 좋은 방향입니다.",
        "benchmark_above": "7일 평균은 %@로 세계 평균 7시간보다 높습니다. 오늘 조금만 줄이면 추세가 바뀔 수 있습니다.",
        "benchmark_matching": "7일 평균은 %@로 세계 평균 7시간과 같습니다.",

        // Task editing
        "edit_task": "작업 편집",
        "task_name_placeholder": "작업 이름",
        "task_reminder_default": "작업 알림",
        "time_h_m": "%d시간 %d분",
        "time_m": "%d분",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Arabic
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let ar: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "حول أوضاع التركيز",
        "no_active_goals_title": "لا توجد أهداف نشطة",
        "no_active_goals_btn": "حسنًا",
        "no_active_goals_msg": "لا يعمل وضعا التركيز والإغلاق إلا عندما يكون لديك هدف غير مكتمل تسعى لتحقيقه. أضف هدفًا — أو أعد تنشيط هدف — ثم ابدأ جلستك.",
        // Tab bar
        "tab_home": "الرئيسية", "tab_progress": "التقدم", "tab_mode": "الوضع", "tab_profile": "الملف الشخصي",

        // Home
        "today": "اليوم", "tomorrow": "غداً", "yesterday": "أمس",
        "back_to_today": "العودة لليوم",
        "add_first_task": "اضغط + لإضافة مهمتك الأولى",
        "no_tasks_this_day": "لا توجد مهام في هذا اليوم",
        "new_task": "مهمة جديدة",
        "what_to_do": "ما الذي تحتاج إلى فعله؟",
        "task": "مهمة", "schedule": "جدولة",
        "pick_date_hint": "اختر أي تاريخ مستقبلي — اليوم، أو الأسبوع القادم، أو بعد أشهر.",
        "priority": "الأولوية", "low": "منخفضة", "medium": "متوسطة", "high": "عالية",
        "notification": "إشعار", "silent_push": "إشعار صامت",
        "notification_desc": "يُرسل إشعاراً لمرة واحدة في الوقت المحدد. يظهر بهدوء على شاشة القفل ومركز الإشعارات.",
        "reminder": "تذكير", "alarm_sound": "منبه مع صوت واهتزاز",
        "reminder_desc": "يعمل كمنبه — يصدر صوتاً خاصاً ويهتز هاتفك باستمرار حتى تضغط زر الإلغاء على الشاشة. مثالي للاجتماعات والمواعيد النهائية.",
        "cancel": "إلغاء", "add": "إضافة", "edit": "تعديل", "delete": "حذف",
        "jump_to_date": "الانتقال إلى تاريخ", "done": "تم",
        "task_limit": "لقد وصلت إلى حد 25 مهمة لهذا التاريخ.",
        "time": "الوقت", "date": "التاريخ", "select_date": "اختيار التاريخ",

        // Alarm
        "reminder_title": "تذكير", "dismiss": "إلغاء",

        // Progress
        "daily_progress": "التقدم اليومي", "streaks": "السلاسل", "focus_days": "أيام التركيز",
        "consistency": "الاستمرارية",
        "set_first_goal": "حدد هدفك الأول لهذا اليوم",
        "all_goals_completed": "تم إنجاز جميع الأهداف اليومية",
        "goals_completed": "من", "daily_goals_completed": "أهداف يومية مكتملة",
        "daily_goals": "الأهداف اليومية", "remaining": "متبقٍ",
        "no_goals_planned": "لا توجد أهداف مخططة",
        "complete_to_focus": "أكمل جميع المهام لتحديد اليوم كيوم تركيز.",
        "add_task_to_start": "أضف مهمة من الرئيسية لبدء تتبع الأهداف اليومية.",
        "daily_plan_complete": "الخطة اليومية مكتملة",
        "ai_weekly_summary": "الملخص الأسبوعي بالذكاء الاصطناعي",
        "creating_summary": "جارٍ إنشاء ملخصك الأسبوعي...",
        "generate_summary": "إنشاء الملخص", "refresh_summary": "تحديث الملخص",
        "first_summary_coming": "أول ملخص أسبوعي بالذكاء الاصطناعي في الطريق.",
        "first_summary_desc": "سيكون جاهزاً في %@ الساعة 9 مساءً. يتضمن رؤى حول تقدمك والمهام الفائتة وأفضل وضع تركيز لك.",
        "next_update": "التحديث القادم: %@",
        "weekly_recap": "ملخصك الأسبوعي لأيام التركيز والمهام واتجاهات الإنتاجية جاهز.",
        "screen_time_7day": "وقت الشاشة 7 أيام", "best_streak": "أفضل سلسلة",
        "days": "أيام", "milestones": "الإنجازات", "milestone_unlocked": "تم فتح إنجاز",
        "continue_btn": "متابعة", "history_calendar": "تقويم السجل",
        "mode_used": "الوضع المستخدم", "completed": "مكتمل", "not_completed": "غير مكتمل",
        "no_completed_tasks": "لا توجد مهام مكتملة مسجلة لهذا اليوم.",
        "everything_completed": "تم إنجاز كل شيء.",
        "no_missed_tasks": "لا توجد مهام فائتة مسجلة لهذا اليوم.",
        "streak_day": "يوم سلسلة", "missed_day": "يوم فائت",
        "first_name": "الاسم الأول", "last_name": "اسم العائلة",
        "avatar_color": "لون الصورة الرمزية",
        "whats_your_name": "ما اسمك؟",
        "name_helps": "هذا يساعد في تخصيص تجربتك.",
        "name_save_failed": "تعذر حفظ اسمك. تحقق من اتصالك وحاول مرة أخرى.",
        "continue_btn_name": "متابعة",
        "wins": "الإنجازات", "next_action": "الإجراء التالي", "average": "المتوسط",
        "todays_completion": "إنجاز اليوم",
        "streaks_this_month": "سلاسل هذا الشهر",
        "streak_days": "أيام السلاسل", "non_streak_days": "أيام بلا سلاسل",
        "monthly_streak_summary": "%d سلسلة هذا الشهر • %d يوم سلسلة، %d يوم بلا سلسلة",
        "duration_average": "%@ كمتوسط",

        // Profile
        "personal_details": "البيانات الشخصية", "personal_info": "المعلومات الشخصية",
        "update_email_name": "حدّث بريدك الإلكتروني واسمك الكامل.",
        "and_username": "واسم المستخدم",
        "invite_friends": "دعوة الأصدقاء",
        "refer_friend_title": "أحِل صديقاً واكسب 10 دولارات",
        "refer_friend_desc": "اكسب 10 دولارات عن كل صديق يسجل باستخدام رمزك الترويجي.",
        "upgrade_family_plan": "الترقية إلى خطة العائلة",
        "goals_tracking": "الأهداف والتتبع",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "تعديل أهداف التغذية",
        "tracking_reminders": "تذكيرات التتبع",
        "email_not_editable": "بريدك الإلكتروني مرتبط بتسجيل الدخول ولا يمكن تعديله هنا.",
        "theme": "المظهر", "theme_desc": "استخدم مظهر النظام أو اختر الوضع الفاتح/الداكن.",
        "appearance": "المظهر", "appearance_desc": "اختر المظهر الفاتح أو الداكن أو مظهر النظام",
        "live_activity_profile_desc": "اعرض تقدمك اليومي على شاشة القفل والجزيرة الديناميكية",
        "system": "النظام", "light": "فاتح", "dark": "داكن",
        "live_activity": "النشاط المباشر",
        "live_activity_desc": "اعرض أهداف اليوم والسلسلة وتحفيز جديد على شاشة القفل.",
        "privacy_policy": "سياسة الخصوصية",
        "privacy_desc": "راجع كيفية استخدام بيانات التطبيق وأذونات الجهاز.",
        "terms_of_service": "شروط الخدمة",
        "terms_desc": "اقرأ قواعد استخدام التطبيق وأدوات التركيز.",
        "follow_us": "تابعنا",
        "sign_out": "تسجيل الخروج", "sign_out_desc": "إنهاء هذه الجلسة على الجهاز الحالي.",
        "delete_account": "حذف الحساب",
        "delete_account_desc": "حذف حسابك نهائياً وبيانات التطبيق المُزامَنة.",
        "delete_account_title": "حذف الحساب",
        "delete_account_msg": "هذا الإجراء نهائي. ستُحذف جميع بياناتك ولا يمكن استردادها.",
        "delete_account_continue": "متابعة",
        "delete_account_final_title": "حذف نهائي؟",
        "delete_account_final_msg": "يرجى التأكيد مرة أخرى. إذا حذفت حسابك، سيقوم Spike AI بتسجيل خروجك وإعادتك إلى صفحة تسجيل الدخول.",
        "deleting_account": "جارٍ حذف الحساب...",
        "delete_failed": "فشل حذف الحساب. يرجى المحاولة مرة أخرى أو التواصل مع الدعم.",
        "language": "اللغة", "language_desc": "اختر لغة محتوى التطبيق بالكامل.",
        "set_name": "حدد اسمك",
        "profile_name_prompt": "ماذا نناديك؟",
        "profile_name_desc": "أضف الاسم الذي سيستخدمه Spike AI في ملفك الشخصي وتجربة الإنتاجية.",
        "full_name": "الاسم الكامل", "display_name": "الاسم المعروض",
        "email": "البريد الإلكتروني",
        "save_changes": "حفظ التغييرات",
        "save_footer": "تُحفظ التغييرات في ملفك الشخصي وتُستخدم أينما تظهر هويتك في التطبيق.",
        "signed_in": "تم تسجيل الدخول",
        "account": "الحساب", "preferences": "التفضيلات",
        "support_legal": "الدعم والشؤون القانونية",
        "account_actions": "إجراءات الحساب",
        "pref_show_completed": "إظهار المهام المكتملة",
        "pref_show_completed_desc": "إبقاء المهام المكتملة ظاهرة في قائمتك اليومية.",
        "pref_quotes": "اقتباسات تحفيزية",
        "pref_quotes_desc": "إظهار اقتباس ملهم على شاشة التقدم.",
        "legal_updated": "آخر تحديث: 25 مايو 2026",
        "privacy_body": """
        آخر تحديث: 25 مايو 2026

        Spike AI هو تطبيق للإنتاجية والتركيز. توضح سياسة الخصوصية هذه كيفية تعامل Spike AI مع المعلومات المستخدمة لتوفير الحسابات، وتخطيط المهام، والتذكيرات، وأوضاع التركيز، وعناصر تحكم وقت الشاشة، وتتبع التقدم، والملخصات الإنتاجية المُنشأة بالذكاء الاصطناعي.

        المعلومات التي نجمعها: معرّفات الحساب مثل عنوان بريدك الإلكتروني ومعرّف المستخدم؛ تفاصيل الملف الشخصي التي تختار تقديمها مثل الاسم المعروض والاسم الكامل؛ المهام والأهداف والتذكيرات وسجل الإنجاز وإعدادات وضع التركيز ورموز اختيار التطبيقات ومقاييس التقدم. قد نخزّن أيضاً سجلات تقنية ضرورية للحفاظ على موثوقية الخدمة وأمانها.

        وقت الشاشة واختيارات التطبيقات: يتم التعامل مع اختيارات التطبيقات والفئات ونطاقات الويب من خلال أُطر عمل FamilyControls وManagedSettings من Apple. يخزّن Spike AI الرموز المُقدمة من Apple اللازمة لتطبيق أوضاع التركيز المختارة. لا نستخدم هذه الاختيارات للإعلانات.

        استخدام الكاميرا في وضع التمرين: يُستخدم الوصول إلى الكاميرا لفحص وضعية الجسم على الجهاز حتى تتمكن من كسب وصول مؤقت للتطبيقات من خلال الحركة. لا يرفع Spike AI إطارات الفيديو لهذه الميزة ولا يستخدم بيانات الكاميرا للإعلانات.

        الإشعارات والتذكيرات: يستخدم Spike AI إذن الإشعارات لإرسال تذكيرات المهام والمنبهات وتنبيهات التركيز التي تقوم بتهيئتها. يمكنك تغيير الوصول إلى الإشعارات في إعدادات iOS في أي وقت.

        ملخصات الذكاء الاصطناعي: إذا أنشأت ملخص تقدم، فقد تُعالَج مقاييس المهام والأهداف والتركيز والإنتاجية الأخيرة بواسطة خادم Spike AI لإنتاج الملخص. تجنب إدخال معلومات شخصية حساسة في أسماء المهام أو الأهداف إذا كنت لا تريد معالجتها لميزات الإنتاجية.

        كيف نستخدم المعلومات: لمصادقتك، ومزامنة حسابك، وتوفير أدوات التركيز، وجدولة التذكيرات، وعرض التقدم، وتخصيص رؤى الإنتاجية، والحماية من سوء الاستخدام، واستكشاف المشكلات وإصلاحها، والامتثال للالتزامات القانونية. لا يبيع Spike AI معلوماتك الشخصية.

        حذف البيانات: يمكنك تسجيل الخروج أو طلب حذف الحساب نهائياً من الملف الشخصي. يؤدي حذف الحساب إلى إزالة حساب المصادقة الخاص بك وبيانات التطبيق المُزامَنة المرتبطة بهذا الحساب، مع مراعاة الاحتفاظ المحدود المطلوب للأمان ومنع الاحتيال وحل النزاعات أو الامتثال القانوني.

        خياراتك: يمكنك تعديل تفاصيل الملف الشخصي، وتغيير تفضيلات اللغة والمظهر، وتعطيل النشاط المباشر، وإلغاء أذونات الجهاز في الإعدادات، والتوقف عن استخدام أوضاع تركيز معينة، أو حذف حسابك.

        التواصل: لأسئلة الخصوصية أو مشكلات حذف الحساب، تواصل مع دعم Spike AI من خلال قناة الدعم المتوفرة في التطبيق أو صفحة App Store.
        """,
        "terms_body": """
        آخر تحديث: 25 مايو 2026

        تحكم شروط الخدمة هذه استخدامك لتطبيق Spike AI، بما في ذلك المهام والتذكيرات وأوضاع التركيز ومطالبات وحجب تطبيقات وقت الشاشة وفحوصات الحركة في وضع التمرين وتتبع التقدم والملخصات المُنشأة بالذكاء الاصطناعي.

        الأهلية والحساب: أنت مسؤول عن الحساب الذي تنشئه وعن الحفاظ على أمان الوصول إلى بريدك الإلكتروني وجهازك. استخدم معلومات دقيقة عندما يطلب التطبيق تفاصيل الملف الشخصي.

        الغرض الإنتاجي: صُمم Spike AI لدعم الإنتاجية الشخصية والاستخدام الواعي للجهاز. وهو ليس خدمة طبية أو صحية نفسية أو طوارئ أو سلامة أو رقابة أبوية أو مراقبة توظيف أو إدارة أجهزة. لا تعتمد على Spike AI في الحالات التي قد يتسبب فيها فشل تذكير أو حظر أو مطالبة أو فحص كاميرا أو إشعار أو طلب شبكة أو إذن Apple في ضرر.

        مسؤولياتك: اختر إعدادات التركيز المناسبة لوضعك؛ وراجع اختيارات التطبيقات قبل تفعيل الوضع؛ وأوقف الأوضاع عندما لم تعد تناسب احتياجاتك؛ والتزم بالقانون المعمول به وشروط منصة Apple؛ وتجنب إدخال معلومات حساسة في المهام أو الأهداف ما لم تكن مرتاحاً لاستخدامها في التطبيق.

        الاستخدام المقبول: لا تسئ استخدام Spike AI، أو تتدخل في جهاز أو حساب شخص آخر، أو تحاول تجاوز قيود الأمان أو المنصة، أو تقوم بهندسة عكسية لأجزاء محمية من الخدمة، أو تُثقل الخادم الخلفي، أو تستخدم التطبيق لنشاط غير قانوني أو مسيء أو مخادع أو ضار.

        الأذونات والتوفر: تتطلب بعض الميزات أذونات iOS مثل وقت الشاشة والإشعارات والكاميرا والأنشطة المباشرة والوصول إلى الشبكة. يمكن أن تؤثر Apple وإعدادات الجهاز وسلوك نظام التشغيل والاتصال وتوفر الخادم الخلفي على عمل الميزات كما هو متوقع.

        المحتوى المُنشأ بالذكاء الاصطناعي: قد يتم إنشاء ملخصات التقدم باستخدام أنظمة آلية. وهي للتأمل والتوجيه الإنتاجي فقط. راجعها بحكمك الشخصي قبل الاعتماد عليها.

        حذف الحساب والإنهاء: يمكنك طلب حذف الحساب من الملف الشخصي. قد يعلّق Spike AI أو ينهي الوصول إذا تطلب القانون أو قواعد المنصة أو المخاوف الأمنية أو سوء الاستخدام الجسيم ذلك.

        التغييرات: قد يحدّث Spike AI هذه الشروط مع تطور التطبيق. يعني الاستمرار في الاستخدام بعد التحديث قبولك للشروط المحدّثة.

        التواصل: لأسئلة حول هذه الشروط، تواصل مع دعم Spike AI من خلال قناة الدعم المتوفرة في التطبيق أو صفحة App Store.
        """,

        // Focus Mode
        "focus_title": "التركيز", "select_mode": "اختر الوضع",
        "chill": "هادئ", "focus": "تركيز", "lock_in": "إغلاق", "sweat": "رياضي",
        "gentle_nudges": "تنبيهات لطيفة", "confirm_intent": "تأكيد النية",
        "no_bypass": "بدون تجاوز", "move_to_unlock": "تحرك لفتح القفل",
        "activate_focus": "تفعيل وضع التركيز", "deactivate_focus": "إلغاء وضع التركيز",
        "mode_active": "الوضع نشط", "reminders_scheduled": "التذكيرات مجدولة",
        "apps_prompt_active": "تطبيق(ات) — رسالة \"هل أنت متأكد؟\" نشطة",
        "apps_blocked": "تطبيق(ات) محظورة", "temp_access_active": "الوصول المؤقت نشط",
        "apps_require_movement": "تطبيق(ات) تتطلب حركة للفتح",
        "notifications_label": "الإشعارات", "notifications_enabled": "الإشعارات مفعّلة",
        "notifications_denied": "تم رفض الإشعارات",
        "enable_notif_settings": "فعّل الإشعارات في الإعدادات.",
        "allow_notif_desc": "اسمح بالإشعارات ليتمكن Spike AI من إرسال تذكيرات التركيز.",
        "enable_notifications": "تفعيل الإشعارات",
        "screen_time_access": "الوصول إلى وقت الشاشة",
        "screen_time_authorized": "تم تفويض وقت الشاشة",
        "allow_screen_time": "السماح بوقت الشاشة",
        "tap_to_allow": "اضغط أدناه للسماح بالوصول إلى وقت الشاشة.",
        "open_settings_manual": "أو افتح الإعدادات للتفعيل يدوياً",
        "open_settings": "فتح الإعدادات",
        "app_selection": "اختيار التطبيقات", "selections": "اختيار(ات)",
        "choose_apps_confirm": "اختر التطبيقات التي تريد التأكيد قبل فتحها.",
        "choose_apps_block": "اختر التطبيقات التي تريد حظرها.",
        "choose_apps_movement": "اختر التطبيقات التي تريد فتحها بالحركة.",
        "change_selection": "تغيير الاختيار", "select_apps": "اختيار التطبيقات",
        "movement_unlock": "فتح القفل بالحركة",
        "movement_desc": "يتم تتبع تمارين الضغط والقيام بكشف الجسم بالذكاء الاصطناعي. كل تكرار مُتحقق يضيف دقيقة واحدة من الوصول للتطبيقات المختارة.",
        "access_available": "الوصول متاح لمدة %@",
        "open_camera": "فتح فحص الكاميرا",
        "lock_in_mode": "وضع الإغلاق",
        "lock_in_warning": "تعرض التطبيقات شاشة حمراء بدون تجاوز. يجب العودة هنا لإيقاف وضع الإغلاق.",
        "sweat_mode": "وضع الرياضي",
        "do_exercises": "قم بتمارين الضغط أو القيام لكسب وقت",
        "add_minutes": "إضافة %d دقيقة(دقائق)",
        "keep_in_view": "أبقِ كتفيك أو ذراعيك أو وركيك في الإطار",
        "camera_required": "مطلوب الوصول إلى الكاميرا لفحوصات الحركة.",
        "camera_disabled": "الوصول إلى الكاميرا معطّل. فعّله في الإعدادات لاستخدام وضع التمرين.",
        "camera_unavailable": "الوصول إلى الكاميرا غير متاح.",
        "starting_camera": "جارٍ تشغيل الكاميرا...",
        "camera_active": "الكاميرا نشطة",
        "allow_camera": "السماح بالوصول إلى الكاميرا",
        "focus_mode_title": "وضع التركيز",
        "focus_mode_desc": "تحكم في عاداتك الرقمية بأوضاع مركزة واحترافية.",
        "about_permissions": "حول الأذونات",
        "permissions_desc": "يتطلب الوضع الهادئ إذن الإشعارات. تتطلب أوضاع التركيز والإغلاق والتمرين تفويض وقت الشاشة. يستخدم وضع التمرين أيضاً الكاميرا لفحوصات الحركة.",
        "get_started": "ابدأ", "skip": "تخطي",
        "unlocked_for": "مفتوح لمدة %@",

        // Chill mode descriptions
        "chill_desc": "تذكيرات يومية عبر الإشعارات. بدون تحكم في التطبيقات — مجرد تنبيهات لطيفة للبقاء واعياً.",
        "focus_desc": "عند فتح تطبيق مختار، يسأل Spike AI \"هل أنت متأكد؟\" يمكنك فتحه كالمعتاد أو العودة لمهامك. لا يتم حظر التطبيقات.",
        "lock_in_desc": "التطبيقات المختارة محظورة أثناء تفعيل وضع الإغلاق. يمكنك إيقاف الوضع من Spike AI.",
        "sweat_desc": "تبقى التطبيقات المختارة محظورة حتى تكمل تمرين ضغط أو قيام مُتحقق بالكاميرا. كل تكرار مُتحقق يفتح دقيقة واحدة.",

        // Motivational (deactivation)
        "giving_up_title": "أنت تتقدم — لا تتوقف الآن",
        "giving_up_msg": "لا تزال لديك أهداف غير مكتملة لهذا اليوم. كل مهمة منجزة تبني زخماً. ابقَ ملتزماً — ذاتك المستقبلية ستشكرك.",
        "giving_up_continue": "البقاء مركّزاً", "giving_up_stop": "إيقاف على أي حال",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "نظامك الشخصي للإنتاجية",
        "start_setup": "بدء الإعداد",
        "make_phone_work": "اجعل هاتفك يعمل\nلأهدافك.",
        "onboarding_welcome_desc": "قلّل التمرير بلا هدف، واحمِ وقت التركيز، وحوّل المهام الحقيقية إلى تقدم ملموس.",
        "did_you_know": "هل تعلم؟",
        "did_you_know_subtitle": "يقضي الشخص في المتوسط 7 ساعات يومياً على هاتفه. هذا يعني",
        "hours_per_day": "ساعات يومياً",
        "days_per_month": "أيام شهرياً",
        "days_per_year": "أيام سنوياً",
        "years_of_life": "سنوات من عمرك",
        "screen_time_reality": "وبعض الناس يقضون وقتاً أكثر.",
        "dont_worry_title": "لا تقلق",
        "spike_has_your_back": "Spike AI يدعمك",
        "solution_desc": "سنساعدك على تعظيم إنتاجيتك، والاقتراب من أهدافك، وبناء العادات التي تحولك إلى أفضل نسخة من نفسك.",
        "screen_time_access_title": "الوصول إلى وقت الشاشة",
        "grant_access": "منح الوصول",
        "which_apps": "اختر تطبيقاتك\nالمشتتة",
        "choose_apps_protect": "اختر التطبيقات التي تضيع وقتك. سنحظرها أثناء أوضاع التركيز.",
        "apple_screen_time_required": "تتطلب Apple الوصول إلى وقت الشاشة قبل أن يتمكن Spike AI من عرض قائمة تطبيقاتك.",
        "save_apps": "حفظ والمتابعة",
        "change_selected_apps": "تغيير التطبيقات المختارة",
        "ready_change_life": "مستعد لتغيير\nحياتك؟",
        "ready_change_desc": "أنشئ حسابك لحفظ اختياراتك وبدء رحلتك.",
        "benefit_no_distraction": "لن تزعجك التطبيقات المشتتة بعد الآن",
        "benefit_discover_modes": "اكتشف 4 أنواع مختلفة من أوضاع التركيز",
        "benefit_track_progress": "تتبع تقدمك واقترب من أهدافك",
        "create_account": "إنشاء حساب",
        "protect_focus": "حماية التركيز", "block_feeds": "حظر الخلاصات",
        "finish_tasks": "إنهاء المهام", "energy_plus_three": "+3 طاقة",
        "selected_count": "%d مختار", "no_apps_selected": "لم يتم اختيار تطبيقات بعد",
        "saved_for_modes": "محفوظ لأوضاع الحماية",
        "select_apps_to_control": "اختر التطبيقات التي تريد التحكم بها",
        "clean_room": "نظّف الغرفة", "snap_proof": "التقط صورة إثبات عند الانتهاء",
        "ai_verifies_task": "الذكاء الاصطناعي يتحقق من المهمة",
        "energy_earned": "+3 طاقة مكتسبة",
        "on_track": "على المسار", "energy": "الطاقة",
        "tasks_completed": "المهام المكتملة", "focus_protected": "التركيز محمي",
        "scrolling_avoided": "تم تجنب التمرير",
        "continue_apple": "المتابعة بحساب Apple",
        "continue_google": "المتابعة بحساب Google", "continue_email": "المتابعة بالبريد الإلكتروني",
        "enter_email": "أدخل بريدك الإلكتروني",
        "send_sign_in_link": "سنرسل لك رابط تسجيل الدخول",
        "check_email": "تحقق من بريدك الإلكتروني",
        "sent_link_to": "أرسلنا رابط تسجيل الدخول إلى",
        "tap_link": "اضغط على الرابط لتسجيل الدخول تلقائياً.",
        "open_mail": "فتح تطبيق البريد",
        "open_with": "فتح باستخدام",
        "didnt_get_email": "لم تستلم البريد؟",
        "resend": "إعادة الإرسال",
        "resend_in": "إعادة الإرسال خلال %ds",
        "new_link_sent": "تم إرسال رابط جديد!",
        "valid_email": "أدخل عنوان بريد إلكتروني صالح.",
        "by_continuing": "بالمتابعة، فإنك توافق على",
        "and_word": "و",

        // Screen Time Onboarding
        "screen_time_title": "وقت الشاشة",
        "screen_time_permission_desc": "يحتاج Spike AI إلى إذن وقت الشاشة لأوضاع التركيز والإغلاق والتمرين. يتيح ذلك عرض مطالبات وحجب التطبيقات التي تختارها.",
        "screen_time_denied": "تم رفض الإذن. يمكنك تفعيله في الإعدادات.",
        "ask_before_opening": "السؤال قبل الفتح",
        "block_apps_completely": "حظر التطبيقات بالكامل",
        "stay_accountable": "ابقَ مسؤولاً",
        "stay_accountable_desc": "تتبع التقدم وحافظ على عادات تركيزك واضحة.",
        "skip_for_now": "تخطي الآن",

        // Live Activity
        "daily_goals_title": "الأهداف اليومية",
        "of_done": "من %d مكتملة",
        "more_to_go": "+%d إضافية للإنجاز",

        // Chill morning
        "good_morning": "صباح الخير! كن واعياً اليوم. راجع مهامك وحافظ على تركيزك.",

        // General
        "error": "خطأ", "ok": "حسناً", "yes": "نعم", "no": "لا",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "التبديل إلى وضع الاسترخاء؟",
        "stay_focused_btn": "البقاء مركّزاً",
        "switch_anyway_btn": "التبديل على أي حال",
        "switch_to_chill_msg": "لا تزال لديك أهداف غير مكتملة. التبديل إلى وضع الاسترخاء يزيل حظر التطبيقات، مما يزيد من خطر عدم إنهاء أهدافك اليوم.",
        "task_notification": "إشعار المهمة",
        "missed_alarm": "منبه فائت",
        "quote_of_day": "اقتباس اليوم",
        "new_quotes_daily": "اقتباسات جديدة تصل يومياً في الساعة 5:00 صباحاً",
        "focus_day_label": "يوم التركيز",
        "missed_label": "فائت",
        "access_granted": "تم منح الوصول",
        "goal_reminder": "تذكير بالهدف",
        "spike_ai_focus": "Spike AI تركيز",
        "goals_required_title": "الأهداف مطلوبة",
        "goals_required_desc_focus": "وضع التركيز يحظر التطبيقات المحددة فقط عندما تكون لديك أهداف غير مكتملة. أضف أهدافاً في علامة التبويب الرئيسية لتفعيل حظر التطبيقات.",
        "goals_required_desc_lockin": "وضع القفل يحظر التطبيقات المحددة فقط عندما تكون لديك أهداف غير مكتملة. أضف أهدافاً في علامة التبويب الرئيسية لتفعيل حظر التطبيقات.",
        "save": "حفظ",
        "no_goals_reminder_body": "لم تحدد أي أهداف لهذا اليوم. خذ لحظة لتخطيط يومك!",
        "dont_forget": "لا تنسَ",
        "chill_morning_body": "صباح الخير! كن مقصوداً اليوم. راجع مهامك وحافظ على تركيزك.",
        "every_day": "كل يوم",
        "weekdays": "أيام الأسبوع",
        "weekends": "عطلة نهاية الأسبوع",
        "time_to_focus": "حان وقت التركيز!",

        // Additional UI strings
        "next_quote_in": "الاقتباس التالي خلال %@",
        "enable_notif_chill": "فعّل الإشعارات قبل بدء وضع الاسترخاء.",
        "enable_screen_time_mode": "فعّل الوصول إلى وقت الشاشة قبل بدء هذا الوضع.",
        "select_app_before_mode": "اختر تطبيقًا واحدًا على الأقل أو فئة أو موقع ويب قبل بدء هذا الوضع.",
        "mode_not_ready": "هذا الوضع غير جاهز للبدء.",
        "protection_stopped_no_apps": "توقفت الحماية: لم يتم اختيار تطبيقات.",
        "protection_stopped_screen_time": "توقفت الحماية: تغيّر الوصول إلى وقت الشاشة.",
        "max_reminders": "يمكنك إنشاء حتى %d تذكيرات تركيز.",
        "front_camera_unavailable": "الكاميرا الأمامية غير متاحة.",
        "task_title_empty": "عنوان المهمة لا يمكن أن يكون فارغًا.",
        "goal_title_empty": "عنوان الهدف لا يمكن أن يكون فارغًا.",
        "rate_limit_wait": "يرجى الانتظار %d ثانية قبل إنشاء تقرير آخر.",
        "missed_alarm_for": "فاتك المنبه: %@",
        "stay_with_plan": "التزم بالخطة.",
        "motivation_small_wins": "الانتصارات الصغيرة تتراكم.",
        "motivation_next_step": "أكمل الخطوة التالية.",
        "motivation_protect_hour": "احمِ الساعة التي أمامك.",
        "motivation_consistency": "الاستمرارية تتفوق على الشدة.",
        "monthly_scope_btn": "شهري",
        "yearly_scope_btn": "سنوي",
        "restoring_session": "جارٍ استعادة جلستك...",

        // Milestones
        "milestone_3day_streak": "سلسلة 3 أيام",
        "milestone_3day_desc": "بدأ إيقاع ثابت.",
        "milestone_7day_streak": "سلسلة 7 أيام",
        "milestone_7day_desc": "أسبوع كامل من التركيز.",
        "milestone_10h_protected": "10 ساعات محمية",
        "milestone_10h_desc": "وقت محمي لما يهم.",
        "milestone_30_focus": "30 يوم تركيز",
        "milestone_30_desc": "ثبات بوزن حقيقي.",

        // Narratives
        "narrative_improved": "تحسّن وقت الشاشة مقارنة بالأسبوع الماضي.",
        "narrative_consistent": "حافظت على الاتساق هذا الأسبوع وحميت تركيزك.",
        "narrative_more_days": "أكملت أيام تركيز أكثر من المعتاد.",
        "narrative_building": "أنت تبني الإيقاع يومًا مركّزًا تلو الآخر.",

        // Screen time
        "screen_time_trend_pending": "سيظهر اتجاه وقت الشاشة مع تراكم سجل الاستخدام.",
        "screen_time_improved": "تحسّن وقت الشاشة بنسبة %d%%",
        "screen_time_higher": "وقت الشاشة أعلى قليلاً من المعتاد",
        "screen_time_steady": "وقت الشاشة مستقر هذا الأسبوع",

        // Benchmarks
        "benchmark_pending": "سيظهر متوسط وقت الشاشة عندما يسجل التطبيق سجل الاستخدام. المعدل العالمي حوالي 7 ساعات يوميًا.",
        "benchmark_below": "متوسطك لـ 7 أيام هو %@، أقل من المتوسط العالمي 7 ساعات. هذا اتجاه قوي.",
        "benchmark_above": "متوسطك لـ 7 أيام هو %@، أعلى من المتوسط العالمي 7 ساعات. تقليل بسيط اليوم يمكن أن يغير الاتجاه.",
        "benchmark_matching": "متوسطك لـ 7 أيام هو %@، يطابق المتوسط العالمي 7 ساعات.",

        // Task editing
        "edit_task": "تعديل المهمة",
        "task_name_placeholder": "اسم المهمة",
        "task_reminder_default": "تذكير بالمهمة",
        "time_h_m": "%d س %d د",
        "time_m": "%d د",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Hindi
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let hi: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "फ़ोकस मोड के बारे में",
        "no_active_goals_title": "कोई सक्रिय लक्ष्य नहीं",
        "no_active_goals_btn": "समझ गए",
        "no_active_goals_msg": "फ़ोकस और लॉक-इन मोड केवल तभी चलते हैं जब आपके पास पूरा करने के लिए कोई अधूरा लक्ष्य हो। एक लक्ष्य जोड़ें — या किसी को फिर से सक्रिय करें — फिर अपना सत्र शुरू करें।",
        // Tab bar
        "tab_home": "होम", "tab_progress": "प्रगति", "tab_mode": "मोड", "tab_profile": "प्रोफ़ाइल",

        // Home
        "today": "आज", "tomorrow": "कल", "yesterday": "कल (बीता)",
        "back_to_today": "आज पर वापस",
        "add_first_task": "अपना पहला कार्य जोड़ने के लिए + दबाएं",
        "no_tasks_this_day": "इस दिन कोई कार्य नहीं है",
        "new_task": "नया कार्य",
        "what_to_do": "आपको क्या करना है?",
        "task": "कार्य", "schedule": "शेड्यूल",
        "pick_date_hint": "कोई भी भविष्य की तारीख चुनें — आज, अगला सप्ताह, या महीनों बाद।",
        "priority": "प्राथमिकता", "low": "कम", "medium": "मध्यम", "high": "उच्च",
        "notification": "सूचना", "silent_push": "मूक पुश सूचना",
        "notification_desc": "निर्धारित समय पर एक बार पुश सूचना भेजता है। यह आपकी लॉक स्क्रीन और सूचना केंद्र पर चुपचाप दिखाई देती है।",
        "reminder": "रिमाइंडर", "alarm_sound": "ध्वनि और कंपन के साथ अलार्म",
        "reminder_desc": "अलार्म की तरह काम करता है — एक विशेष ध्वनि बजेगी और आपका फ़ोन लगातार कंपन करेगा जब तक आप स्क्रीन पर खारिज करें बटन नहीं दबाते। बैठकों और समय सीमाओं के लिए उत्तम।",
        "cancel": "रद्द करें", "add": "जोड़ें", "edit": "संपादित करें", "delete": "हटाएं",
        "jump_to_date": "तारीख पर जाएं", "done": "पूर्ण",
        "task_limit": "आपने इस तारीख के लिए 25 कार्यों की सीमा पूरी कर ली है।",
        "time": "समय", "date": "तारीख", "select_date": "तारीख चुनें",

        // Alarm
        "reminder_title": "रिमाइंडर", "dismiss": "खारिज करें",

        // Progress
        "daily_progress": "दैनिक प्रगति", "streaks": "स्ट्रीक", "focus_days": "फोकस दिन",
        "consistency": "निरंतरता",
        "set_first_goal": "आज के लिए अपना पहला लक्ष्य निर्धारित करें",
        "all_goals_completed": "सभी दैनिक लक्ष्य पूरे हुए",
        "goals_completed": "में से", "daily_goals_completed": "दैनिक लक्ष्य पूरे हुए",
        "daily_goals": "दैनिक लक्ष्य", "remaining": "शेष",
        "no_goals_planned": "कोई लक्ष्य नियोजित नहीं",
        "complete_to_focus": "आज को फोकस दिन बनाने के लिए सभी कार्य पूरे करें।",
        "add_task_to_start": "दैनिक लक्ष्यों की ट्रैकिंग शुरू करने के लिए होम से कार्य जोड़ें।",
        "daily_plan_complete": "दैनिक योजना पूरी",
        "ai_weekly_summary": "AI साप्ताहिक सारांश",
        "creating_summary": "आपका साप्ताहिक सारांश तैयार हो रहा है...",
        "generate_summary": "सारांश बनाएं", "refresh_summary": "सारांश रिफ़्रेश करें",
        "first_summary_coming": "आपका पहला AI साप्ताहिक सारांश आने वाला है।",
        "first_summary_desc": "यह %@ को रात 9 बजे तैयार होगा। इसमें आपकी प्रगति, छूटे कार्य, और आपके लिए सबसे अच्छे फोकस मोड के बारे में जानकारी होगी।",
        "next_update": "अगला अपडेट: %@",
        "weekly_recap": "फोकस दिनों, कार्यों और उत्पादकता प्रवृत्तियों का आपका साप्ताहिक सारांश तैयार है।",
        "screen_time_7day": "7 दिन का स्क्रीन टाइम", "best_streak": "सबसे अच्छी स्ट्रीक",
        "days": "दिन", "milestones": "मील के पत्थर", "milestone_unlocked": "मील का पत्थर अनलॉक",
        "continue_btn": "जारी रखें", "history_calendar": "इतिहास कैलेंडर",
        "mode_used": "उपयोग किया गया मोड", "completed": "पूर्ण", "not_completed": "अपूर्ण",
        "no_completed_tasks": "इस दिन कोई पूर्ण कार्य दर्ज नहीं है।",
        "everything_completed": "सब कुछ पूरा हो गया।",
        "no_missed_tasks": "इस दिन कोई छूटा कार्य दर्ज नहीं है।",
        "streak_day": "स्ट्रीक दिन", "missed_day": "छूटा दिन",
        "first_name": "पहला नाम", "last_name": "अंतिम नाम",
        "avatar_color": "अवतार रंग",
        "whats_your_name": "आपका नाम क्या है?",
        "name_helps": "यह आपके अनुभव को व्यक्तिगत बनाने में मदद करता है।",
        "name_save_failed": "आपका नाम सहेजा नहीं जा सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।",
        "continue_btn_name": "जारी रखें",
        "wins": "जीत", "next_action": "अगला कदम", "average": "औसत",
        "todays_completion": "आज की पूर्णता",
        "streaks_this_month": "इस माह स्ट्रीक",
        "streak_days": "स्ट्रीक दिन", "non_streak_days": "गैर-स्ट्रीक दिन",
        "monthly_streak_summary": "%d स्ट्रीक इस माह • %d स्ट्रीक दिन, %d गैर-स्ट्रीक दिन",
        "duration_average": "%@ औसत",

        // Profile
        "personal_details": "व्यक्तिगत विवरण", "personal_info": "व्यक्तिगत जानकारी",
        "update_email_name": "अपना ईमेल और पूरा नाम अपडेट करें।",
        "and_username": "और उपयोगकर्ता नाम",
        "invite_friends": "मित्रों को आमंत्रित करें",
        "refer_friend_title": "मित्र को रेफ़र करें और $10 कमाएं",
        "refer_friend_desc": "आपके प्रोमो कोड से साइन अप करने वाले प्रत्येक मित्र पर $10 कमाएं।",
        "upgrade_family_plan": "फ़ैमिली प्लान में अपग्रेड करें",
        "goals_tracking": "लक्ष्य और ट्रैकिंग",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "पोषण लक्ष्य संपादित करें",
        "tracking_reminders": "ट्रैकिंग रिमाइंडर",
        "email_not_editable": "आपका ईमेल आपके लॉगिन से जुड़ा है और यहां संपादित नहीं किया जा सकता।",
        "theme": "थीम", "theme_desc": "सिस्टम दिखावट का उपयोग करें या लाइट/डार्क मोड चुनें।",
        "appearance": "दिखावट", "appearance_desc": "लाइट, डार्क, या सिस्टम दिखावट चुनें",
        "live_activity_profile_desc": "अपनी दैनिक प्रगति लॉक स्क्रीन और डायनामिक आइलैंड पर दिखाएं",
        "system": "सिस्टम", "light": "लाइट", "dark": "डार्क",
        "live_activity": "लाइव गतिविधि",
        "live_activity_desc": "लॉक स्क्रीन पर आज के लक्ष्य, स्ट्रीक, और ताज़ा प्रेरणा दिखाएं।",
        "privacy_policy": "गोपनीयता नीति",
        "privacy_desc": "देखें कि ऐप डेटा और डिवाइस अनुमतियां कैसे उपयोग की जाती हैं।",
        "terms_of_service": "सेवा की शर्तें",
        "terms_desc": "ऐप और इसके फोकस टूल्स के उपयोग के नियम पढ़ें।",
        "follow_us": "हमें फॉलो करें",
        "sign_out": "लॉग आउट", "sign_out_desc": "इस डिवाइस पर यह सत्र समाप्त करें।",
        "delete_account": "खाता हटाएं",
        "delete_account_desc": "अपना खाता और सिंक किया गया ऐप डेटा स्थायी रूप से हटाएं।",
        "delete_account_title": "खाता हटाएं",
        "delete_account_msg": "यह कार्रवाई स्थायी है। आपका सारा डेटा हटा दिया जाएगा और पुनर्प्राप्त नहीं किया जा सकता।",
        "delete_account_continue": "जारी रखें",
        "delete_account_final_title": "स्थायी रूप से हटाएं?",
        "delete_account_final_msg": "कृपया एक बार और पुष्टि करें। यदि आप अपना खाता हटाते हैं, तो Spike AI आपको लॉग आउट कर देगा और लॉगिन पृष्ठ पर वापस भेज देगा।",
        "deleting_account": "खाता हटाया जा रहा है...",
        "delete_failed": "खाता हटाना विफल। कृपया पुनः प्रयास करें या सहायता से संपर्क करें।",
        "language": "भाषा", "language_desc": "सभी ऐप सामग्री के लिए भाषा चुनें।",
        "set_name": "अपना नाम सेट करें",
        "profile_name_prompt": "हम आपको क्या बुलाएं?",
        "profile_name_desc": "वह नाम जोड़ें जिसे Spike AI आपकी प्रोफ़ाइल और उत्पादकता अनुभव में उपयोग करेगा।",
        "full_name": "पूरा नाम", "display_name": "प्रदर्शन नाम",
        "email": "ईमेल",
        "save_changes": "परिवर्तन सहेजें",
        "save_footer": "परिवर्तन आपकी प्रोफ़ाइल में सहेजे जाते हैं और ऐप में जहां भी आपकी पहचान दिखती है वहां उपयोग किए जाते हैं।",
        "signed_in": "लॉग इन है",
        "account": "खाता", "preferences": "प्राथमिकताएं",
        "support_legal": "सहायता और कानूनी",
        "account_actions": "खाता क्रियाएं",
        "pref_show_completed": "पूर्ण कार्य दिखाएं",
        "pref_show_completed_desc": "पूर्ण कार्यों को अपनी दैनिक सूची में दृश्यमान रखें।",
        "pref_quotes": "प्रेरणादायक उद्धरण",
        "pref_quotes_desc": "प्रगति स्क्रीन पर एक प्रेरणादायक उद्धरण दिखाएं।",
        "legal_updated": "अंतिम अपडेट: 25 मई, 2026",
        "privacy_body": """
        अंतिम अपडेट: 25 मई, 2026

        Spike AI एक उत्पादकता और फोकस ऐप है। यह गोपनीयता नीति बताती है कि Spike AI खातों, कार्य नियोजन, रिमाइंडर, फोकस मोड, स्क्रीन टाइम नियंत्रण, प्रगति ट्रैकिंग, और AI-जनित उत्पादकता सारांश प्रदान करने के लिए उपयोग की जाने वाली जानकारी को कैसे संभालता है।

        हम जो जानकारी एकत्र करते हैं: खाता पहचानकर्ता जैसे आपका ईमेल पता और उपयोगकर्ता ID; प्रोफ़ाइल विवरण जो आप देना चुनते हैं, जैसे प्रदर्शन नाम और पूरा नाम; कार्य, लक्ष्य, रिमाइंडर, पूर्णता इतिहास, फोकस मोड सेटिंग्स, ऐप-चयन टोकन, और प्रगति मेट्रिक्स। हम सेवा को विश्वसनीय और सुरक्षित बनाए रखने के लिए आवश्यक तकनीकी रिकॉर्ड भी संग्रहीत कर सकते हैं।

        स्क्रीन टाइम और ऐप चयन: ऐप, श्रेणी, और वेब-डोमेन चयन Apple के FamilyControls और ManagedSettings फ्रेमवर्क के माध्यम से संभाले जाते हैं। Spike AI आपके चयनित फोकस मोड लागू करने के लिए आवश्यक Apple-प्रदत्त टोकन संग्रहीत करता है। हम इन चयनों का उपयोग विज्ञापन के लिए नहीं करते।

        स्वेट मोड में कैमरा उपयोग: कैमरा एक्सेस का उपयोग डिवाइस पर बॉडी-पोज़ जांच के लिए किया जाता है ताकि आप गति के माध्यम से अस्थायी ऐप एक्सेस कमा सकें। Spike AI इस सुविधा के लिए वीडियो फ्रेम अपलोड नहीं करता और कैमरा डेटा का उपयोग विज्ञापन के लिए नहीं करता।

        सूचनाएं और रिमाइंडर: Spike AI आपके द्वारा कॉन्फ़िगर किए गए कार्य रिमाइंडर, अलार्म, और फोकस नज भेजने के लिए सूचना अनुमति का उपयोग करता है। आप किसी भी समय iOS सेटिंग्स में सूचना एक्सेस बदल सकते हैं।

        AI सारांश: यदि आप प्रगति सारांश जनरेट करते हैं, तो हाल के कार्य, लक्ष्य, फोकस, और उत्पादकता मेट्रिक्स Spike AI के बैकएंड द्वारा सारांश तैयार करने के लिए प्रोसेस किए जा सकते हैं। यदि आप नहीं चाहते कि संवेदनशील व्यक्तिगत जानकारी उत्पादकता सुविधाओं के लिए प्रोसेस हो, तो कार्य नामों या लक्ष्यों में संवेदनशील व्यक्तिगत जानकारी दर्ज करने से बचें।

        हम जानकारी का उपयोग कैसे करते हैं: आपको प्रमाणित करने, आपका खाता सिंक करने, फोकस टूल प्रदान करने, रिमाइंडर शेड्यूल करने, प्रगति दिखाने, उत्पादकता अंतर्दृष्टि को वैयक्तिकृत करने, दुरुपयोग से बचाव, समस्या निवारण, और कानूनी दायित्वों का अनुपालन करने के लिए। Spike AI आपकी व्यक्तिगत जानकारी नहीं बेचता।

        डेटा विलोपन: आप प्रोफ़ाइल से लॉग आउट कर सकते हैं या स्थायी खाता विलोपन का अनुरोध कर सकते हैं। खाता विलोपन आपके प्रमाणीकरण खाते और उस खाते से जुड़े सिंक किए गए ऐप डेटा को हटा देता है, सुरक्षा, धोखाधड़ी रोकथाम, विवाद समाधान, या कानूनी अनुपालन के लिए आवश्यक सीमित प्रतिधारण के अधीन।

        आपकी पसंद: आप प्रोफ़ाइल विवरण संपादित कर सकते हैं, भाषा और दिखावट प्राथमिकताएं बदल सकते हैं, लाइव गतिविधि अक्षम कर सकते हैं, सेटिंग्स में डिवाइस अनुमतियां रद्द कर सकते हैं, विशिष्ट फोकस मोड का उपयोग बंद कर सकते हैं, या अपना खाता हटा सकते हैं।

        संपर्क: गोपनीयता प्रश्नों या खाता विलोपन समस्याओं के लिए, ऐप या App Store सूचीकरण द्वारा प्रदान किए गए सहायता चैनल के माध्यम से Spike AI सहायता से संपर्क करें।
        """,
        "terms_body": """
        अंतिम अपडेट: 25 मई, 2026

        ये सेवा की शर्तें Spike AI के आपके उपयोग को नियंत्रित करती हैं, जिसमें कार्य, रिमाइंडर, फोकस मोड, स्क्रीन टाइम ऐप प्रॉम्प्ट और शील्ड, स्वेट मोड मूवमेंट जांच, प्रगति ट्रैकिंग, और AI-जनित सारांश शामिल हैं।

        पात्रता और खाता: आप अपने द्वारा बनाए गए खाते और अपने ईमेल और डिवाइस तक पहुंच को सुरक्षित रखने के लिए जिम्मेदार हैं। जहां ऐप प्रोफ़ाइल विवरण मांगे, सटीक जानकारी का उपयोग करें।

        उत्पादकता उद्देश्य: Spike AI व्यक्तिगत उत्पादकता और जानबूझकर डिवाइस उपयोग का समर्थन करने के लिए डिज़ाइन किया गया है। यह चिकित्सा, मानसिक स्वास्थ्य, आपातकालीन, सुरक्षा, अभिभावक-नियंत्रण, रोजगार-निगरानी, या डिवाइस-प्रबंधन सेवा नहीं है। जहां रिमाइंडर, ब्लॉक, प्रॉम्प्ट, कैमरा जांच, सूचना, नेटवर्क अनुरोध, या Apple अनुमति की विफलता से नुकसान हो सकता है, वहां Spike AI पर निर्भर न रहें।

        आपकी जिम्मेदारियां: अपनी स्थिति के लिए उपयुक्त फोकस सेटिंग्स चुनें; मोड सक्रिय करने से पहले ऐप चयन की समीक्षा करें; जब मोड आपकी जरूरतों से मेल न खाएं तो उन्हें बंद करें; लागू कानून और Apple के प्लेटफ़ॉर्म नियमों का पालन करें; और कार्यों या लक्ष्यों में संवेदनशील जानकारी दर्ज करने से बचें जब तक कि आप ऐप में इसका उपयोग करने में सहज न हों।

        स्वीकार्य उपयोग: Spike AI का दुरुपयोग न करें, किसी अन्य व्यक्ति के डिवाइस या खाते में हस्तक्षेप न करें, सुरक्षा या प्लेटफ़ॉर्म प्रतिबंधों को बायपास करने का प्रयास न करें, सेवा के संरक्षित भागों की रिवर्स इंजीनियरिंग न करें, बैकएंड पर अधिक भार न डालें, या ऐप का उपयोग गैरकानूनी, अपमानजनक, भ्रामक, या हानिकारक गतिविधि के लिए न करें।

        अनुमतियां और उपलब्धता: कुछ सुविधाओं के लिए iOS अनुमतियां आवश्यक हैं जैसे स्क्रीन टाइम, सूचनाएं, कैमरा, लाइव गतिविधियां, और नेटवर्क एक्सेस। Apple, डिवाइस सेटिंग्स, ऑपरेटिंग सिस्टम व्यवहार, कनेक्टिविटी, और बैकएंड उपलब्धता सुविधाओं के अपेक्षित रूप से काम करने को प्रभावित कर सकते हैं।

        AI-जनित सामग्री: प्रगति सारांश स्वचालित प्रणालियों का उपयोग करके जनरेट किए जा सकते हैं। ये केवल आत्मचिंतन और उत्पादकता कोचिंग के लिए हैं। उन पर निर्भर होने से पहले अपने स्वयं के विवेक से उनकी समीक्षा करें।

        खाता विलोपन और समाप्ति: आप प्रोफ़ाइल से खाता विलोपन का अनुरोध कर सकते हैं। कानून, प्लेटफ़ॉर्म नियम, सुरक्षा चिंताओं, या गंभीर दुरुपयोग की आवश्यकता होने पर Spike AI एक्सेस को निलंबित या समाप्त कर सकता है।

        परिवर्तन: ऐप के विकसित होने पर Spike AI इन शर्तों को अपडेट कर सकता है। अपडेट के बाद निरंतर उपयोग का अर्थ है कि आप अपडेट की गई शर्तों को स्वीकार करते हैं।

        संपर्क: इन शर्तों के बारे में प्रश्नों के लिए, ऐप या App Store सूचीकरण द्वारा प्रदान किए गए सहायता चैनल के माध्यम से Spike AI सहायता से संपर्क करें।
        """,

        // Focus Mode
        "focus_title": "फोकस", "select_mode": "मोड चुनें",
        "chill": "आराम", "focus": "फोकस", "lock_in": "लॉक-इन", "sweat": "एथलीट",
        "gentle_nudges": "हल्के संकेत", "confirm_intent": "इरादा पुष्ट करें",
        "no_bypass": "बायपास नहीं", "move_to_unlock": "अनलॉक के लिए हिलें",
        "activate_focus": "फोकस मोड चालू करें", "deactivate_focus": "फोकस मोड बंद करें",
        "mode_active": "मोड सक्रिय", "reminders_scheduled": "रिमाइंडर शेड्यूल किए गए",
        "apps_prompt_active": "ऐप — \"क्या आप सुनिश्चित हैं?\" प्रॉम्प्ट सक्रिय",
        "apps_blocked": "ऐप ब्लॉक किए गए", "temp_access_active": "अस्थायी एक्सेस सक्रिय",
        "apps_require_movement": "ऐप को अनलॉक के लिए हिलना आवश्यक",
        "notifications_label": "सूचनाएं", "notifications_enabled": "सूचनाएं सक्षम",
        "notifications_denied": "सूचनाएं अस्वीकृत",
        "enable_notif_settings": "सेटिंग्स में सूचनाएं सक्षम करें।",
        "allow_notif_desc": "Spike AI को फोकस रिमाइंडर भेजने के लिए सूचनाओं की अनुमति दें।",
        "enable_notifications": "सूचनाएं सक्षम करें",
        "screen_time_access": "स्क्रीन टाइम एक्सेस",
        "screen_time_authorized": "स्क्रीन टाइम अधिकृत",
        "allow_screen_time": "स्क्रीन टाइम एक्सेस की अनुमति दें",
        "tap_to_allow": "स्क्रीन टाइम एक्सेस की अनुमति देने के लिए नीचे टैप करें।",
        "open_settings_manual": "या मैन्युअल रूप से सक्षम करने के लिए सेटिंग्स खोलें",
        "open_settings": "सेटिंग्स खोलें",
        "app_selection": "ऐप चयन", "selections": "चयन",
        "choose_apps_confirm": "खोलने से पहले पुष्टि करने वाले ऐप चुनें।",
        "choose_apps_block": "ब्लॉक करने वाले ऐप चुनें।",
        "choose_apps_movement": "मूवमेंट से अनलॉक करने वाले ऐप चुनें।",
        "change_selection": "चयन बदलें", "select_apps": "ऐप चुनें",
        "movement_unlock": "मूवमेंट अनलॉक",
        "movement_desc": "पुश-अप और स्टैंड-अप को AI बॉडी डिटेक्शन से ट्रैक किया जाता है। प्रत्येक सत्यापित रेप चयनित ऐप के लिए 1 मिनट का एक्सेस जोड़ता है।",
        "access_available": "%@ के लिए एक्सेस उपलब्ध",
        "open_camera": "कैमरा जांच खोलें",
        "lock_in_mode": "लॉक-इन मोड",
        "lock_in_warning": "ऐप बिना बायपास के लाल स्क्रीन दिखाते हैं। लॉक-इन मोड बंद करने के लिए आपको यहां वापस आना होगा।",
        "sweat_mode": "एथलीट मोड",
        "do_exercises": "समय कमाने के लिए पुश-अप या स्टैंड-अप करें",
        "add_minutes": "%d मिनट जोड़ें",
        "keep_in_view": "अपने कंधे, बाहें, या कूल्हे दृश्य में रखें",
        "camera_required": "मूवमेंट जांच के लिए कैमरा एक्सेस आवश्यक है।",
        "camera_disabled": "कैमरा एक्सेस अक्षम है। स्वेट मोड का उपयोग करने के लिए सेटिंग्स में इसे सक्षम करें।",
        "camera_unavailable": "कैमरा एक्सेस अनुपलब्ध है।",
        "starting_camera": "कैमरा शुरू हो रहा है...",
        "camera_active": "कैमरा सक्रिय",
        "allow_camera": "कैमरा एक्सेस की अनुमति दें",
        "focus_mode_title": "फोकस मोड",
        "focus_mode_desc": "केंद्रित, पेशेवर मोड से अपनी डिजिटल आदतों पर नियंत्रण रखें।",
        "about_permissions": "अनुमतियों के बारे में",
        "permissions_desc": "चिल मोड को सूचना अनुमति चाहिए। फोकस, लॉक-इन, और स्वेट मोड को स्क्रीन टाइम अधिकरण चाहिए। स्वेट मोड मूवमेंट जांच के लिए कैमरा एक्सेस भी उपयोग करता है।",
        "get_started": "शुरू करें", "skip": "छोड़ें",
        "unlocked_for": "%@ के लिए अनलॉक",

        // Chill mode descriptions
        "chill_desc": "सूचनाओं द्वारा दैनिक रिमाइंडर। कोई ऐप नियंत्रण नहीं — बस सजग रहने के लिए हल्के संकेत।",
        "focus_desc": "जब आप कोई चयनित ऐप खोलते हैं, Spike AI पूछता है \"क्या आप सुनिश्चित हैं?\" आप इसे सामान्य रूप से खोल सकते हैं या अपने कार्यों पर वापस जा सकते हैं। ऐप ब्लॉक नहीं होते।",
        "lock_in_desc": "लॉक-इन सक्रिय होने पर चयनित ऐप ब्लॉक हो जाते हैं। आप Spike AI से मोड बंद कर सकते हैं।",
        "sweat_desc": "चयनित ऐप तब तक ब्लॉक रहते हैं जब तक आप कैमरा-सत्यापित पुश-अप या स्टैंड-अप पूरा नहीं कर लेते। प्रत्येक सत्यापित रेप 1 मिनट अनलॉक करता है।",

        // Motivational (deactivation)
        "giving_up_title": "आप प्रगति कर रहे हैं — अभी मत रुकिए",
        "giving_up_msg": "आज के लिए आपके अभी भी अधूरे लक्ष्य हैं। हर पूरा किया गया कार्य गति बनाता है। प्रतिबद्ध रहें — आपका भविष्य का आप आपको धन्यवाद देगा।",
        "giving_up_continue": "फोकस बनाए रखें", "giving_up_stop": "फिर भी बंद करें",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "आपकी व्यक्तिगत उत्पादकता प्रणाली",
        "start_setup": "सेटअप शुरू करें",
        "make_phone_work": "अपने फ़ोन को अपने\nलक्ष्यों के लिए काम पर लगाएं।",
        "onboarding_welcome_desc": "बेमतलब स्क्रॉलिंग कम करें, फोकस समय की रक्षा करें, और वास्तविक कार्यों को दृश्य प्रगति में बदलें।",
        "did_you_know": "क्या आप जानते हैं?",
        "did_you_know_subtitle": "एक व्यक्ति औसतन प्रतिदिन 7 घंटे अपने फ़ोन पर बिताता है। यानी",
        "hours_per_day": "घंटे प्रतिदिन",
        "days_per_month": "दिन प्रतिमाह",
        "days_per_year": "दिन प्रतिवर्ष",
        "years_of_life": "आपके जीवन के वर्ष",
        "screen_time_reality": "और कुछ लोग इससे भी अधिक समय बिताते हैं।",
        "dont_worry_title": "चिंता न करें",
        "spike_has_your_back": "Spike AI आपके साथ है",
        "solution_desc": "हम आपकी उत्पादकता को अधिकतम करने, आपके लक्ष्यों के करीब पहुंचने, और उन आदतों को बनाने में मदद करेंगे जो आपको अपने सबसे अच्छे संस्करण में बदल देंगी।",
        "screen_time_access_title": "स्क्रीन टाइम एक्सेस",
        "grant_access": "एक्सेस दें",
        "which_apps": "अपने विचलित करने\nवाले ऐप चुनें",
        "choose_apps_protect": "वे ऐप चुनें जो आपका समय बर्बाद करते हैं। हम उन्हें फोकस मोड के दौरान ब्लॉक करेंगे।",
        "apple_screen_time_required": "Spike AI द्वारा आपकी ऐप सूची दिखाने से पहले Apple को स्क्रीन टाइम एक्सेस की आवश्यकता है।",
        "save_apps": "सहेजें और जारी रखें",
        "change_selected_apps": "चयनित ऐप बदलें",
        "ready_change_life": "अपनी ज़िंदगी बदलने\nके लिए तैयार?",
        "ready_change_desc": "अपनी पसंद सहेजने और अपनी यात्रा शुरू करने के लिए खाता बनाएं।",
        "benefit_no_distraction": "विचलित करने वाले ऐप अब आपको परेशान नहीं करेंगे",
        "benefit_discover_modes": "4 विभिन्न प्रकार के फोकस मोड खोजें",
        "benefit_track_progress": "अपनी प्रगति ट्रैक करें और अपने लक्ष्यों के करीब पहुंचें",
        "create_account": "खाता बनाएं",
        "protect_focus": "फोकस सुरक्षित रखें", "block_feeds": "फ़ीड ब्लॉक करें",
        "finish_tasks": "कार्य पूरे करें", "energy_plus_three": "+3 ऊर्जा",
        "selected_count": "%d चयनित", "no_apps_selected": "अभी तक कोई ऐप नहीं चुना गया",
        "saved_for_modes": "सुरक्षा मोड के लिए सहेजा गया",
        "select_apps_to_control": "वे ऐप चुनें जिन्हें आप नियंत्रित करना चाहते हैं",
        "clean_room": "कमरा साफ़ करें", "snap_proof": "पूरा होने पर सबूत स्नैप करें",
        "ai_verifies_task": "AI कार्य सत्यापित करता है",
        "energy_earned": "+3 ऊर्जा अर्जित",
        "on_track": "सही रास्ते पर", "energy": "ऊर्जा",
        "tasks_completed": "पूरे किए गए कार्य", "focus_protected": "फोकस सुरक्षित",
        "scrolling_avoided": "स्क्रॉलिंग से बचा गया",
        "continue_apple": "Apple से जारी रखें",
        "continue_google": "Google से जारी रखें", "continue_email": "ईमेल से जारी रखें",
        "enter_email": "अपना ईमेल दर्ज करें",
        "send_sign_in_link": "हम आपको साइन-इन लिंक भेजेंगे",
        "check_email": "अपना ईमेल जांचें",
        "sent_link_to": "हमने साइन-इन लिंक भेजा",
        "tap_link": "स्वचालित रूप से साइन इन करने के लिए लिंक पर टैप करें।",
        "open_mail": "मेल ऐप खोलें",
        "open_with": "इसके साथ खोलें",
        "didnt_get_email": "ईमेल नहीं मिला?",
        "resend": "पुनः भेजें",
        "resend_in": "%ds में पुनः भेजें",
        "new_link_sent": "एक नया लिंक भेजा गया है!",
        "valid_email": "एक मान्य ईमेल पता दर्ज करें।",
        "by_continuing": "जारी रखकर, आप Spike AI की",
        "and_word": "और",

        // Screen Time Onboarding
        "screen_time_title": "स्क्रीन टाइम",
        "screen_time_permission_desc": "Spike AI को फोकस, लॉक-इन, और स्वेट मोड के लिए स्क्रीन टाइम अनुमति चाहिए। यह आपके चुने हुए ऐप के लिए प्रॉम्प्ट और ब्लॉक दिखाने देता है।",
        "screen_time_denied": "अनुमति अस्वीकृत की गई। आप इसे सेटिंग्स में सक्षम कर सकते हैं।",
        "ask_before_opening": "खोलने से पहले पूछें",
        "block_apps_completely": "ऐप पूरी तरह ब्लॉक करें",
        "stay_accountable": "जवाबदेह बने रहें",
        "stay_accountable_desc": "प्रगति ट्रैक करें और अपनी फोकस आदतों को दृश्य बनाए रखें।",
        "skip_for_now": "अभी के लिए छोड़ें",

        // Live Activity
        "daily_goals_title": "दैनिक लक्ष्य",
        "of_done": "%d में से पूर्ण",
        "more_to_go": "+%d और शेष",

        // Chill morning
        "good_morning": "सुप्रभात! आज सजग रहें। अपने कार्यों की समीक्षा करें और केंद्रित रहें।",

        // General
        "error": "त्रुटि", "ok": "ठीक", "yes": "हां", "no": "नहीं",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "आराम मोड पर स्विच करें?",
        "stay_focused_btn": "केंद्रित रहें",
        "switch_anyway_btn": "फिर भी स्विच करें",
        "switch_to_chill_msg": "आपके अभी भी अपूर्ण लक्ष्य हैं। आराम मोड पर स्विच करने से ऐप ब्लॉकिंग हट जाती है, जिससे आज आपके लक्ष्य पूरे न होने का जोखिम बढ़ जाता है।",
        "task_notification": "कार्य सूचना",
        "missed_alarm": "छूटा हुआ अलार्म",
        "quote_of_day": "आज का विचार",
        "new_quotes_daily": "नए विचार प्रतिदिन सुबह 5:00 बजे आते हैं",
        "focus_day_label": "फोकस दिवस",
        "missed_label": "छूटा",
        "access_granted": "एक्सेस प्रदान किया गया",
        "goal_reminder": "लक्ष्य अनुस्मारक",
        "spike_ai_focus": "Spike AI फोकस",
        "goals_required_title": "लक्ष्य आवश्यक",
        "goals_required_desc_focus": "फोकस मोड चयनित ऐप्स को केवल तभी ब्लॉक करता है जब आपके अपूर्ण लक्ष्य हों। ऐप ब्लॉकिंग सक्रिय करने के लिए होम टैब में लक्ष्य जोड़ें।",
        "goals_required_desc_lockin": "लॉक-इन मोड चयनित ऐप्स को केवल तभी ब्लॉक करता है जब आपके अपूर्ण लक्ष्य हों। ऐप ब्लॉकिंग सक्रिय करने के लिए होम टैब में लक्ष्य जोड़ें।",
        "save": "सहेजें",
        "no_goals_reminder_body": "आपने आज के लिए कोई लक्ष्य निर्धारित नहीं किया है। अपने दिन की योजना बनाने के लिए एक पल निकालें!",
        "dont_forget": "मत भूलिए",
        "chill_morning_body": "सुप्रभात! आज सोच-समझकर काम करें। अपने कार्यों की समीक्षा करें और ध्यान केंद्रित रखें।",
        "every_day": "हर दिन",
        "weekdays": "कार्यदिवस",
        "weekends": "सप्ताहांत",
        "time_to_focus": "ध्यान केंद्रित करने का समय!",

        // Additional UI strings
        "next_quote_in": "अगला उद्धरण %@ में",
        "enable_notif_chill": "चिल मोड शुरू करने से पहले सूचनाएँ सक्षम करें।",
        "enable_screen_time_mode": "इस मोड को शुरू करने से पहले स्क्रीन टाइम एक्सेस सक्षम करें।",
        "select_app_before_mode": "इस मोड को शुरू करने से पहले कम से कम एक ऐप, श्रेणी या वेबसाइट चुनें।",
        "mode_not_ready": "यह मोड शुरू होने के लिए तैयार नहीं है।",
        "protection_stopped_no_apps": "सुरक्षा रुक गई: कोई ऐप चयनित नहीं है।",
        "protection_stopped_screen_time": "सुरक्षा रुक गई: स्क्रीन टाइम एक्सेस बदल गया।",
        "max_reminders": "आप अधिकतम %d फोकस रिमाइंडर बना सकते हैं।",
        "front_camera_unavailable": "फ्रंट कैमरा उपलब्ध नहीं है।",
        "task_title_empty": "कार्य का शीर्षक खाली नहीं हो सकता।",
        "goal_title_empty": "लक्ष्य का शीर्षक खाली नहीं हो सकता।",
        "rate_limit_wait": "कृपया अगली रिपोर्ट बनाने से पहले %d सेकंड प्रतीक्षा करें।",
        "missed_alarm_for": "आपने अलार्म मिस कर दिया: %@",
        "stay_with_plan": "योजना पर बने रहें।",
        "motivation_small_wins": "छोटी जीतें जमा होती हैं।",
        "motivation_next_step": "अगला कदम पूरा करें।",
        "motivation_protect_hour": "अपने सामने के घंटे की रक्षा करें।",
        "motivation_consistency": "निरंतरता तीव्रता को हराती है।",
        "monthly_scope_btn": "मासिक",
        "yearly_scope_btn": "वार्षिक",
        "restoring_session": "आपका सत्र पुनर्स्थापित हो रहा है...",

        // Milestones
        "milestone_3day_streak": "3 दिन की श्रृंखला",
        "milestone_3day_desc": "एक स्थिर लय शुरू हुई।",
        "milestone_7day_streak": "7 दिन की श्रृंखला",
        "milestone_7day_desc": "एक पूरा केंद्रित सप्ताह।",
        "milestone_10h_protected": "10 घंटे सुरक्षित",
        "milestone_10h_desc": "महत्वपूर्ण चीज़ों के लिए सुरक्षित समय।",
        "milestone_30_focus": "30 फोकस दिन",
        "milestone_30_desc": "वास्तविक भार के साथ निरंतरता।",

        // Narratives
        "narrative_improved": "पिछले सप्ताह की तुलना में आपका स्क्रीन टाइम सुधरा।",
        "narrative_consistent": "आप इस सप्ताह सुसंगत रहे और अपना फोकस सुरक्षित रखा।",
        "narrative_more_days": "आपने सामान्य से अधिक फोकस दिन पूरे किए।",
        "narrative_building": "आप एक-एक केंद्रित दिन से लय बना रहे हैं।",

        // Screen time
        "screen_time_trend_pending": "उपयोग इतिहास बढ़ने पर स्क्रीन टाइम रुझान दिखाई देगा।",
        "screen_time_improved": "स्क्रीन टाइम %d%% सुधरा",
        "screen_time_higher": "स्क्रीन टाइम सामान्य से थोड़ा अधिक है",
        "screen_time_steady": "इस सप्ताह स्क्रीन टाइम स्थिर है",

        // Benchmarks
        "benchmark_pending": "ऐप द्वारा उपयोग इतिहास रिकॉर्ड करने पर औसत स्क्रीन टाइम दिखाई देगा। वैश्विक संदर्भ बिंदु प्रतिदिन लगभग 7 घंटे है।",
        "benchmark_below": "आपका 7 दिन का औसत %@ है, 7 घंटे के वैश्विक औसत से नीचे। यह एक मजबूत दिशा है।",
        "benchmark_above": "आपका 7 दिन का औसत %@ है, 7 घंटे के वैश्विक औसत से ऊपर। आज एक छोटी कमी रुझान बदल सकती है।",
        "benchmark_matching": "आपका 7 दिन का औसत %@ है, 7 घंटे के वैश्विक औसत के बराबर।",

        // Task editing
        "edit_task": "कार्य संपादित करें",
        "task_name_placeholder": "कार्य का नाम",
        "task_reminder_default": "कार्य अनुस्मारक",
        "time_h_m": "%d घं %d मि",
        "time_m": "%d मि",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Turkish
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let tr: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Odak modları hakkında",
        "no_active_goals_title": "Etkin hedef yok",
        "no_active_goals_btn": "Anladım",
        "no_active_goals_msg": "Odak ve Kilitle modları yalnızca üzerinde çalışacağın tamamlanmamış bir hedefin varken çalışır. Bir hedef ekle — ya da birini yeniden etkinleştir — ardından oturumunu başlat.",
        // Tab bar
        "tab_home": "Ana Sayfa", "tab_progress": "İlerleme", "tab_mode": "Mod", "tab_profile": "Profil",

        // Home
        "today": "Bugün", "tomorrow": "Yarın", "yesterday": "Dün",
        "back_to_today": "Bugüne Dön",
        "add_first_task": "İlk görevini eklemek için + simgesine dokun",
        "no_tasks_this_day": "Bu gün için görev yok",
        "new_task": "Yeni Görev",
        "what_to_do": "Ne yapman gerekiyor?",
        "task": "Görev", "schedule": "Zamanlama",
        "pick_date_hint": "Herhangi bir gelecek tarih seçin — bugün, gelecek hafta veya aylar sonra.",
        "priority": "Öncelik", "low": "Düşük", "medium": "Orta", "high": "Yüksek",
        "notification": "Bildirim", "silent_push": "Sessiz anlık bildirim",
        "notification_desc": "Planlanan saatte tek seferlik bir anlık bildirim gönderir. Kilit Ekranınızda ve Bildirim Merkezinde sessizce görünür.",
        "reminder": "Hatırlatıcı", "alarm_sound": "Sesli ve titreşimli alarm",
        "reminder_desc": "Alarm gibi çalışır — özel bir ses çalar ve telefonunuz ekrandaki Kapat düğmesine basana kadar sürekli titreşir. Toplantılar ve son tarihler için idealdir.",
        "cancel": "İptal", "add": "Ekle", "edit": "Düzenle", "delete": "Sil",
        "jump_to_date": "Tarihe Atla", "done": "Bitti",
        "task_limit": "Bu tarih için 25 görev sınırına ulaştınız.",
        "time": "Saat", "date": "Tarih", "select_date": "Tarih Seçin",

        // Alarm
        "reminder_title": "Hatırlatıcı", "dismiss": "Kapat",

        // Progress
        "daily_progress": "Günlük İlerleme", "streaks": "seriler", "focus_days": "odak günleri",
        "consistency": "tutarlılık",
        "set_first_goal": "Bugün için ilk hedefinizi belirleyin",
        "all_goals_completed": "Tüm günlük hedefler tamamlandı",
        "goals_completed": "tanesinden", "daily_goals_completed": "günlük hedef tamamlandı",
        "daily_goals": "Günlük Hedefler", "remaining": "kalan",
        "no_goals_planned": "Planlanmış hedef yok",
        "complete_to_focus": "Bugünü odak günü olarak işaretlemek için tüm görevleri tamamlayın.",
        "add_task_to_start": "Günlük hedef takibini başlatmak için Ana Sayfa'dan görev ekleyin.",
        "daily_plan_complete": "Günlük plan tamamlandı",
        "ai_weekly_summary": "Yapay Zeka Haftalık Özet",
        "creating_summary": "Haftalık özetiniz oluşturuluyor...",
        "generate_summary": "Özet Oluştur", "refresh_summary": "Özeti Yenile",
        "first_summary_coming": "İlk yapay zeka haftalık özetiniz yolda.",
        "first_summary_desc": "%@ tarihinde akşam 9'da hazır olacak. İlerlemeniz, kaçırılan görevler ve sizin için en iyi odak modu hakkında bilgiler içerir.",
        "next_update": "Sonraki güncelleme: %@",
        "weekly_recap": "Odak günleri, görevler ve verimlilik trendleri hakkındaki haftalık özetiniz hazır.",
        "screen_time_7day": "7 Günlük Ekran Süresi", "best_streak": "En İyi Seri",
        "days": "gün", "milestones": "Kilometre Taşları", "milestone_unlocked": "Kilometre Taşı Açıldı",
        "continue_btn": "Devam", "history_calendar": "Geçmiş Takvimi",
        "mode_used": "Kullanılan Mod", "completed": "Tamamlandı", "not_completed": "Tamamlanmadı",
        "no_completed_tasks": "Bu gün için tamamlanmış görev kaydı yok.",
        "everything_completed": "Her şey tamamlandı.",
        "no_missed_tasks": "Bu gün için kaçırılmış görev kaydı yok.",
        "streak_day": "Seri Günü", "missed_day": "Kaçırılan Gün",
        "first_name": "Ad", "last_name": "Soyad",
        "avatar_color": "Avatar Rengi",
        "whats_your_name": "Adınız nedir?",
        "name_helps": "Bu, deneyiminizi kişiselleştirmeye yardımcı olur.",
        "name_save_failed": "Adınız kaydedilemedi. Bağlantınızı kontrol edin ve tekrar deneyin.",
        "continue_btn_name": "Devam",
        "wins": "Başarılar", "next_action": "Sonraki Adım", "average": "ortalama",
        "todays_completion": "Bugünün tamamlanması",
        "streaks_this_month": "bu ay seriler",
        "streak_days": "seri günleri", "non_streak_days": "serisiz günler",
        "monthly_streak_summary": "%d seri bu ay • %d seri günü, %d serisiz gün",
        "duration_average": "%@ ortalama",

        // Profile
        "personal_details": "Kişisel Bilgiler", "personal_info": "Kişisel Bilgi",
        "update_email_name": "E-posta ve tam adınızı güncelleyin.",
        "and_username": "ve kullanıcı adı",
        "invite_friends": "Arkadaşlarını Davet Et",
        "refer_friend_title": "Bir arkadaşını yönlendir, 10$ kazan",
        "refer_friend_desc": "Promosyon kodunuzla kaydolan her arkadaş için 10$ kazanın.",
        "upgrade_family_plan": "Aile Planına Yükselt",
        "goals_tracking": "Hedefler ve Takip",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Beslenme Hedeflerini Düzenle",
        "tracking_reminders": "Takip Hatırlatıcıları",
        "email_not_editable": "E-postanız giriş bilgilerinizle bağlantılıdır ve burada düzenlenemez.",
        "theme": "Tema", "theme_desc": "Sistem görünümünü kullanın veya sabit açık/koyu mod seçin.",
        "appearance": "Görünüm", "appearance_desc": "Açık, koyu veya sistem görünümünü seçin",
        "live_activity_profile_desc": "Günlük ilerlemenizi Kilit Ekranınızda ve Dynamic Island'da gösterin",
        "system": "Sistem", "light": "Açık", "dark": "Koyu",
        "live_activity": "Canlı Etkinlik",
        "live_activity_desc": "Kilit Ekranında bugünün hedeflerini, seriyi ve yeni bir motivasyonu gösterin.",
        "privacy_policy": "Gizlilik Politikası",
        "privacy_desc": "Uygulama verileri ve cihaz izinlerinin nasıl kullanıldığını inceleyin.",
        "terms_of_service": "Kullanım Koşulları",
        "terms_desc": "Uygulama ve odak araçlarını kullanma kurallarını okuyun.",
        "follow_us": "Bizi takip edin",
        "sign_out": "Çıkış Yap", "sign_out_desc": "Bu cihazdaki oturumu sonlandırın.",
        "delete_account": "Hesabı Sil",
        "delete_account_desc": "Hesabınızı ve senkronize uygulama verilerinizi kalıcı olarak silin.",
        "delete_account_title": "Hesabı Sil",
        "delete_account_msg": "Bu işlem kalıcıdır. Tüm verileriniz silinecek ve geri alınamaz.",
        "delete_account_continue": "Devam",
        "delete_account_final_title": "Kalıcı Olarak Silinsin mi?",
        "delete_account_final_msg": "Lütfen bir kez daha onaylayın. Hesabınızı silerseniz, Spike AI sizi çıkış yapacak ve giriş sayfasına geri gönderecektir.",
        "deleting_account": "Hesap siliniyor...",
        "delete_failed": "Hesap silme başarısız. Lütfen tekrar deneyin veya destekle iletişime geçin.",
        "language": "Dil", "language_desc": "Tüm uygulama içeriği için dili seçin.",
        "set_name": "Adınızı ayarlayın",
        "profile_name_prompt": "Size ne diyelim?",
        "profile_name_desc": "Spike AI'ın profilinizde ve verimlilik deneyiminizde kullanacağı adı ekleyin.",
        "full_name": "Tam Ad", "display_name": "Görünen Ad",
        "email": "E-posta",
        "save_changes": "Değişiklikleri Kaydet",
        "save_footer": "Değişiklikler profilinize kaydedilir ve uygulamada kimliğinizin göründüğü her yerde kullanılır.",
        "signed_in": "Giriş yapıldı",
        "account": "Hesap", "preferences": "Tercihler",
        "support_legal": "Destek ve Yasal",
        "account_actions": "Hesap İşlemleri",
        "pref_show_completed": "Tamamlananları Göster",
        "pref_show_completed_desc": "Tamamlanan görevleri günlük listenizde görünür tutun.",
        "pref_quotes": "Motivasyon Sözleri",
        "pref_quotes_desc": "İlerleme ekranında ilham verici bir söz gösterin.",
        "legal_updated": "Son güncelleme: 25 Mayıs 2026",
        "privacy_body": """
        Son güncelleme: 25 Mayıs 2026

        Spike AI bir verimlilik ve odak uygulamasıdır. Bu Gizlilik Politikası, Spike AI'ın hesaplar, görev planlama, hatırlatıcılar, odak modları, Ekran Süresi kontrolleri, ilerleme takibi ve yapay zeka ile oluşturulan verimlilik özetleri sağlamak için kullandığı bilgileri nasıl işlediğini açıklar.

        Topladığımız bilgiler: e-posta adresiniz ve kullanıcı kimliğiniz gibi hesap tanımlayıcıları; görünen ad ve tam ad gibi sağlamayı tercih ettiğiniz profil bilgileri; görevler, hedefler, hatırlatıcılar, tamamlama geçmişi, odak modu ayarları, uygulama seçim belirteçleri ve ilerleme ölçümleri. Hizmetin güvenilir ve emniyetli kalması için gereken teknik kayıtları da saklayabiliriz.

        Ekran Süresi ve uygulama seçimleri: uygulama, kategori ve web alan adı seçimleri Apple'ın FamilyControls ve ManagedSettings çerçeveleri aracılığıyla işlenir. Spike AI, seçtiğiniz odak modlarını uygulamak için gereken Apple tarafından sağlanan belirteçleri saklar. Bu seçimleri reklamcılık için kullanmıyoruz.

        Ter Modunda kamera kullanımı: kamera erişimi, hareketle geçici uygulama erişimi kazanabilmeniz için cihaz üzerinde vücut duruşu kontrollerinde kullanılır. Spike AI bu özellik için video karelerini yüklemez ve kamera verilerini reklamcılık için kullanmaz.

        Bildirimler ve hatırlatıcılar: Spike AI, yapılandırdığınız görev hatırlatıcıları, alarmlar ve odak dürtülerini göndermek için bildirim iznini kullanır. Bildirim erişimini istediğiniz zaman iOS Ayarlarından değiştirebilirsiniz.

        Yapay zeka özetleri: bir ilerleme özeti oluşturursanız, son görev, hedef, odak ve verimlilik ölçümleri özeti üretmek için Spike AI'ın arka ucu tarafından işlenebilir. Verimlilik özellikleri için işlenmesini istemiyorsanız, görev adlarına veya hedeflere hassas kişisel bilgiler girmekten kaçının.

        Bilgileri nasıl kullanıyoruz: sizi doğrulamak, hesabınızı senkronize etmek, odak araçları sağlamak, hatırlatıcıları planlamak, ilerlemeyi göstermek, verimlilik içgörülerini kişiselleştirmek, kötüye kullanıma karşı korumak, sorunları gidermek ve yasal yükümlülüklere uymak için. Spike AI kişisel bilgilerinizi satmaz.

        Veri silme: Profilden çıkış yapabilir veya kalıcı hesap silme talebinde bulunabilirsiniz. Hesap silme, kimlik doğrulama hesabınızı ve bu hesapla ilişkili senkronize uygulama verilerini kaldırır; güvenlik, dolandırıcılık önleme, uyuşmazlık çözümü veya yasal uyum için gereken sınırlı saklama buna tabidir.

        Seçenekleriniz: profil bilgilerinizi düzenleyebilir, dil ve görünüm tercihlerini değiştirebilir, Canlı Etkinliği devre dışı bırakabilir, Ayarlarda cihaz izinlerini iptal edebilir, belirli odak modlarını kullanmayı bırakabilir veya hesabınızı silebilirsiniz.

        İletişim: gizlilik soruları veya hesap silme sorunları için uygulama veya App Store listesi tarafından sağlanan destek kanalı aracılığıyla Spike AI desteğiyle iletişime geçin.
        """,
        "terms_body": """
        Son güncelleme: 25 Mayıs 2026

        Bu Kullanım Koşulları, görevler, hatırlatıcılar, odak modları, Ekran Süresi uygulama uyarıları ve kalkanları, Ter Modu hareket kontrolleri, ilerleme takibi ve yapay zeka ile oluşturulan özetler dahil olmak üzere Spike AI kullanımınızı yönetir.

        Uygunluk ve hesap: oluşturduğunuz hesaptan ve e-posta ile cihazınıza erişimi güvende tutmaktan siz sorumlusunuz. Uygulama profil bilgisi istediğinde doğru bilgiler kullanın.

        Verimlilik amacı: Spike AI, kişisel verimlilik ve bilinçli cihaz kullanımını desteklemek için tasarlanmıştır. Tıbbi, ruh sağlığı, acil durum, güvenlik, ebeveyn kontrolü, istihdam izleme veya cihaz yönetimi hizmeti değildir. Bir hatırlatıcı, engelleme, uyarı, kamera kontrolü, bildirim, ağ isteği veya Apple izninin başarısız olmasının zarara yol açabileceği durumlarda Spike AI'a güvenmeyin.

        Sorumluluklarınız: durumunuza uygun odak ayarlarını seçin; bir modu etkinleştirmeden önce uygulama seçimlerini gözden geçirin; ihtiyaçlarınıza uymadığında modları kapatın; geçerli yasalara ve Apple'ın platform koşullarına uyun; ve uygulamada kullanmaktan rahatsız olmadıkça görevlere veya hedeflere hassas bilgiler girmekten kaçının.

        Kabul edilebilir kullanım: Spike AI'ı kötüye kullanmayın, başka birinin cihazına veya hesabına müdahale etmeyin, güvenlik veya platform kısıtlamalarını aşmaya çalışmayın, hizmetin korunan kısımlarını tersine mühendislik yapmayın, arka ucu aşırı yüklemeyin veya uygulamayı yasa dışı, tacizci, aldatıcı veya zararlı faaliyetler için kullanmayın.

        İzinler ve erişilebilirlik: bazı özellikler Ekran Süresi, bildirimler, kamera, Canlı Etkinlikler ve ağ erişimi gibi iOS izinleri gerektirir. Apple, cihaz ayarları, işletim sistemi davranışı, bağlantı ve arka uç erişilebilirliği özelliklerin beklendiği gibi çalışıp çalışmayacağını etkileyebilir.

        Yapay zeka ile oluşturulan içerik: ilerleme özetleri otomatik sistemler kullanılarak oluşturulabilir. Bunlar yalnızca yansıtma ve verimlilik koçluğu içindir. Güvenmeden önce kendi yargınızla gözden geçirin.

        Hesap silme ve fesih: Profilden hesap silme talebinde bulunabilirsiniz. Yasa, platform kuralları, güvenlik endişeleri veya ciddi kötüye kullanım gerektirdiğinde Spike AI erişimi askıya alabilir veya sonlandırabilir.

        Değişiklikler: uygulama geliştikçe Spike AI bu Koşulları güncelleyebilir. Bir güncellemeden sonra kullanmaya devam etmeniz, güncellenen Koşulları kabul ettiğiniz anlamına gelir.

        İletişim: bu Koşullar hakkında sorularınız için uygulama veya App Store listesi tarafından sağlanan destek kanalı aracılığıyla Spike AI desteğiyle iletişime geçin.
        """,

        // Focus Mode
        "focus_title": "Odak", "select_mode": "Mod Seçin",
        "chill": "Sakin", "focus": "Odak", "lock_in": "Kilitle", "sweat": "Sporcu",
        "gentle_nudges": "Hafif hatırlatmalar", "confirm_intent": "Niyeti onayla",
        "no_bypass": "Atlama yok", "move_to_unlock": "Açmak için hareket et",
        "activate_focus": "Odak Modunu Etkinleştir", "deactivate_focus": "Odak Modunu Kapat",
        "mode_active": "Mod Aktif", "reminders_scheduled": "Hatırlatıcılar planlandı",
        "apps_prompt_active": "uygulama — \"Emin misiniz?\" uyarısı aktif",
        "apps_blocked": "uygulama engellendi", "temp_access_active": "Geçici erişim aktif",
        "apps_require_movement": "uygulama açmak için hareket gerektirir",
        "notifications_label": "Bildirimler", "notifications_enabled": "Bildirimler etkin",
        "notifications_denied": "Bildirimler reddedildi",
        "enable_notif_settings": "Ayarlarda bildirimleri etkinleştirin.",
        "allow_notif_desc": "Spike AI'ın odak hatırlatıcıları göndermesi için bildirimlere izin verin.",
        "enable_notifications": "Bildirimleri Etkinleştir",
        "screen_time_access": "Ekran Süresi Erişimi",
        "screen_time_authorized": "Ekran Süresi yetkilendirildi",
        "allow_screen_time": "Ekran Süresi Erişimine İzin Ver",
        "tap_to_allow": "Ekran Süresi erişimine izin vermek için aşağıya dokunun.",
        "open_settings_manual": "Veya manuel olarak etkinleştirmek için Ayarları açın",
        "open_settings": "Ayarları Aç",
        "app_selection": "Uygulama Seçimi", "selections": "seçim",
        "choose_apps_confirm": "Açmadan önce onaylanacak uygulamaları seçin.",
        "choose_apps_block": "Engellenecek uygulamaları seçin.",
        "choose_apps_movement": "Hareketle açılacak uygulamaları seçin.",
        "change_selection": "Seçimi Değiştir", "select_apps": "Uygulama Seç",
        "movement_unlock": "Hareketle Kilit Açma",
        "movement_desc": "Şınav ve kalkışlar yapay zeka vücut algılama ile takip edilir. Her doğrulanan tekrar seçili uygulamalara 1 dakika erişim ekler.",
        "access_available": "%@ için erişim mevcut",
        "open_camera": "Kamera Kontrolünü Aç",
        "lock_in_mode": "Kilitleme modu",
        "lock_in_warning": "Uygulamalar atlama olmadan kırmızı ekran gösterir. Kilitleme Modunu kapatmak için buraya geri gelmelisiniz.",
        "sweat_mode": "Sporcu Modu",
        "do_exercises": "Süre kazanmak için şınav veya kalkış yapın",
        "add_minutes": "%d Dakika Ekle",
        "keep_in_view": "Omuzlarınızı, kollarınızı veya kalçalarınızı görünür tutun",
        "camera_required": "Hareket kontrolleri için kamera erişimi gereklidir.",
        "camera_disabled": "Kamera erişimi devre dışı. Ter Modunu kullanmak için Ayarlarda etkinleştirin.",
        "camera_unavailable": "Kamera erişimi mevcut değil.",
        "starting_camera": "Kamera başlatılıyor...",
        "camera_active": "Kamera aktif",
        "allow_camera": "Kamera Erişimine İzin Ver",
        "focus_mode_title": "Odak Modu",
        "focus_mode_desc": "Odaklı, profesyonel modlarla dijital alışkanlıklarınızın kontrolünü elinize alın.",
        "about_permissions": "İzinler Hakkında",
        "permissions_desc": "Sakin Modu bildirim izni gerektirir. Odak, Kilitleme ve Ter Modları Ekran Süresi yetkilendirmesi gerektirir. Ter Modu ayrıca hareket kontrolleri için kamera erişimi kullanır.",
        "get_started": "Başla", "skip": "Atla",
        "unlocked_for": "%@ süreyle açık",

        // Chill mode descriptions
        "chill_desc": "Bildirimlerle günlük hatırlatmalar. Uygulama kontrolü yok — sadece bilinçli kalmak için hafif dokunuşlar.",
        "focus_desc": "Seçili bir uygulamayı açtığınızda Spike AI \"Emin misiniz?\" diye sorar. Normal şekilde açabilir veya görevlerinize dönebilirsiniz. Uygulamalar engellenmez.",
        "lock_in_desc": "Kilitleme aktifken seçili uygulamalar engellenir. Modu Spike AI'dan kapatabilirsiniz.",
        "sweat_desc": "Kamera ile doğrulanmış şınav veya kalkış tamamlayana kadar seçili uygulamalar engelli kalır. Her doğrulanan tekrar 1 dakikayı açar.",

        // Motivational (deactivation)
        "giving_up_title": "İlerliyorsunuz — şimdi durmayın",
        "giving_up_msg": "Bugün için hâlâ tamamlanmamış hedefleriniz var. Her bitirilen görev ivme kazandırır. Kararlı kalın — gelecekteki kendiniz size teşekkür edecek.",
        "giving_up_continue": "Odakta Kal", "giving_up_stop": "Yine de Kapat",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Kişisel verimlilik sisteminiz",
        "start_setup": "Kuruluma Başla",
        "make_phone_work": "Telefonunuzu hedefleriniz\niçin çalıştırın.",
        "onboarding_welcome_desc": "Amaçsız kaydırmayı azaltın, odak zamanını koruyun ve gerçek görevleri görünür ilerlemeye dönüştürün.",
        "did_you_know": "Biliyor muydunuz?",
        "did_you_know_subtitle": "Bir kişi günde ortalama 7 saatini telefonunda geçiriyor. Bu da",
        "hours_per_day": "saat/gün",
        "days_per_month": "gün/ay",
        "days_per_year": "gün/yıl",
        "years_of_life": "ömrünüzden yıl",
        "screen_time_reality": "Ve bazı insanlar daha da fazla zaman harcıyor.",
        "dont_worry_title": "Endişelenmeyin",
        "spike_has_your_back": "Spike AI arkanızda",
        "solution_desc": "Verimliliğinizi en üst düzeye çıkarmanıza, hedeflerinize yaklaşmanıza ve sizi kendinizin en iyi versiyonuna dönüştüren alışkanlıklar oluşturmanıza yardımcı olacağız.",
        "screen_time_access_title": "Ekran Süresi Erişimi",
        "grant_access": "Erişim Ver",
        "which_apps": "Dikkatinizi dağıtan\nuygulamalarınızı seçin",
        "choose_apps_protect": "Zamanınızı boşa harcayan uygulamaları seçin. Odak modları sırasında onları engelleyeceğiz.",
        "apple_screen_time_required": "Spike AI uygulama listenizi gösterebilmesi için Apple Ekran Süresi erişimi gerektirir.",
        "save_apps": "Kaydet ve Devam Et",
        "change_selected_apps": "Seçili uygulamaları değiştir",
        "ready_change_life": "Hayatınızı değiştirmeye\nhazır mısınız?",
        "ready_change_desc": "Seçimlerinizi kaydetmek ve yolculuğunuza başlamak için hesabınızı oluşturun.",
        "benefit_no_distraction": "Dikkat dağıtıcı uygulamalar sizi artık rahatsız etmeyecek",
        "benefit_discover_modes": "4 farklı odak modu türünü keşfedin",
        "benefit_track_progress": "İlerlemenizi takip edin ve hedeflerinize yaklaşın",
        "create_account": "Hesap Oluştur",
        "protect_focus": "Odağı Koru", "block_feeds": "Akışları Engelle",
        "finish_tasks": "Görevleri Bitir", "energy_plus_three": "+3 Enerji",
        "selected_count": "%d seçili", "no_apps_selected": "Henüz uygulama seçilmedi",
        "saved_for_modes": "Koruma modları için kaydedildi",
        "select_apps_to_control": "Kontrol etmek istediğiniz uygulamaları seçin",
        "clean_room": "Oda Temizle", "snap_proof": "Bitirdiğinizde kanıt fotoğrafı çekin",
        "ai_verifies_task": "Yapay zeka görevi doğrular",
        "energy_earned": "+3 Enerji kazanıldı",
        "on_track": "Yolunda", "energy": "Enerji",
        "tasks_completed": "Tamamlanan görevler", "focus_protected": "Odak korundu",
        "scrolling_avoided": "Kaydırmadan kaçınıldı",
        "continue_apple": "Apple ile Devam Et",
        "continue_google": "Google ile Devam Et", "continue_email": "E-posta ile Devam Et",
        "enter_email": "E-postanızı girin",
        "send_sign_in_link": "Size bir giriş bağlantısı göndereceğiz",
        "check_email": "E-postanızı kontrol edin",
        "sent_link_to": "Giriş bağlantısı gönderildi:",
        "tap_link": "Otomatik giriş yapmak için bağlantıya dokunun.",
        "open_mail": "Posta Uygulamasını Aç",
        "open_with": "Şununla aç",
        "didnt_get_email": "E-postayı almadınız mı?",
        "resend": "Tekrar Gönder",
        "resend_in": "%ds sonra tekrar gönder",
        "new_link_sent": "Yeni bir bağlantı gönderildi!",
        "valid_email": "Geçerli bir e-posta adresi girin.",
        "by_continuing": "Devam ederek, Spike AI'ın",
        "and_word": "ve",

        // Screen Time Onboarding
        "screen_time_title": "Ekran Süresi",
        "screen_time_permission_desc": "Spike AI, Odak, Kilitleme ve Ter modları için Ekran Süresi iznine ihtiyaç duyar. Bu, seçtiğiniz uygulamalar için uygulama uyarıları ve engellemeler göstermesini sağlar.",
        "screen_time_denied": "İzin reddedildi. Ayarlardan etkinleştirebilirsiniz.",
        "ask_before_opening": "Açmadan Önce Sor",
        "block_apps_completely": "Uygulamaları Tamamen Engelle",
        "stay_accountable": "Sorumlu Kalın",
        "stay_accountable_desc": "İlerlemeyi takip edin ve odak alışkanlıklarınızı görünür tutun.",
        "skip_for_now": "Şimdilik Atla",

        // Live Activity
        "daily_goals_title": "Günlük Hedefler",
        "of_done": "%d tamamlandı",
        "more_to_go": "+%d daha var",

        // Chill morning
        "good_morning": "Günaydın! Bugün bilinçli olun. Görevlerinizi gözden geçirin ve odaklanın.",

        // General
        "error": "Hata", "ok": "Tamam", "yes": "Evet", "no": "Hayır",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Rahat Moda Geçilsin mi?",
        "stay_focused_btn": "Odakta Kal",
        "switch_anyway_btn": "Yine de Geç",
        "switch_to_chill_msg": "Hâlâ tamamlanmamış hedefleriniz var. Rahat Moda geçmek uygulama engellemesini kaldırır ve bugün hedeflerinizi tamamlayamama riskini artırır.",
        "task_notification": "Görev Bildirimi",
        "missed_alarm": "Kaçırılan Alarm",
        "quote_of_day": "Günün Sözü",
        "new_quotes_daily": "Yeni sözler her gün saat 05:00'te gelir",
        "focus_day_label": "Odak Günü",
        "missed_label": "Kaçırıldı",
        "access_granted": "Erişim verildi",
        "goal_reminder": "Hedef Hatırlatıcı",
        "spike_ai_focus": "Spike AI Odak",
        "goals_required_title": "Hedefler Gerekli",
        "goals_required_desc_focus": "Odak modu seçili uygulamaları yalnızca tamamlanmamış hedefleriniz olduğunda engeller. Uygulama engellemeyi etkinleştirmek için Ana Sayfa sekmesine hedef ekleyin.",
        "goals_required_desc_lockin": "Kilit modu seçili uygulamaları yalnızca tamamlanmamış hedefleriniz olduğunda engeller. Uygulama engellemeyi etkinleştirmek için Ana Sayfa sekmesine hedef ekleyin.",
        "save": "Kaydet",
        "no_goals_reminder_body": "Bugün için hiçbir hedef belirlemediniz. Gününüzü planlamak için bir dakikanızı ayırın!",
        "dont_forget": "Unutmayın",
        "chill_morning_body": "Günaydın! Bugün bilinçli olun. Görevlerinizi gözden geçirin ve odaklanın.",
        "every_day": "Her gün",
        "weekdays": "Hafta içi",
        "weekends": "Hafta sonu",
        "time_to_focus": "Odaklanma zamanı!",

        // Additional UI strings
        "next_quote_in": "Sonraki alıntı %@ sonra",
        "enable_notif_chill": "Rahat modu başlatmadan önce bildirimleri etkinleştirin.",
        "enable_screen_time_mode": "Bu modu başlatmadan önce Ekran Süresi erişimini etkinleştirin.",
        "select_app_before_mode": "Bu modu başlatmadan önce en az bir uygulama, kategori veya web sitesi seçin.",
        "mode_not_ready": "Bu mod henüz başlamaya hazır değil.",
        "protection_stopped_no_apps": "Koruma durduruldu: uygulama seçilmedi.",
        "protection_stopped_screen_time": "Koruma durduruldu: Ekran Süresi erişimi değişti.",
        "max_reminders": "En fazla %d odaklanma hatırlatıcısı oluşturabilirsiniz.",
        "front_camera_unavailable": "Ön kamera kullanılamıyor.",
        "task_title_empty": "Görev başlığı boş olamaz.",
        "goal_title_empty": "Hedef başlığı boş olamaz.",
        "rate_limit_wait": "Yeni bir özet oluşturmak için lütfen %d saniye bekleyin.",
        "missed_alarm_for": "Alarmı kaçırdınız: %@",
        "stay_with_plan": "Plana sadık kalın.",
        "motivation_small_wins": "Küçük zaferler birikim yapar.",
        "motivation_next_step": "Bir sonraki adımı tamamlayın.",
        "motivation_protect_hour": "Önünüzdeki saati koruyun.",
        "motivation_consistency": "Süreklilik yoğunluğu yener.",
        "monthly_scope_btn": "Aylık",
        "yearly_scope_btn": "Yıllık",
        "restoring_session": "Oturumunuz geri yükleniyor...",

        // Milestones
        "milestone_3day_streak": "3 günlük seri",
        "milestone_3day_desc": "İstikrarlı bir ritim başladı.",
        "milestone_7day_streak": "7 günlük seri",
        "milestone_7day_desc": "Tam bir odaklı hafta.",
        "milestone_10h_protected": "10 saat korundu",
        "milestone_10h_desc": "Önemli olan için korunan zaman.",
        "milestone_30_focus": "30 odak günü",
        "milestone_30_desc": "Gerçek ağırlıkta tutarlılık.",

        // Narratives
        "narrative_improved": "Ekran süreniz geçen haftaya göre iyileşti.",
        "narrative_consistent": "Bu hafta tutarlı kaldınız ve odağınızı korudunuz.",
        "narrative_more_days": "Her zamankinden daha fazla odak günü tamamladınız.",
        "narrative_building": "Ritmi tek tek odaklı günlerle oluşturuyorsunuz.",

        // Screen time
        "screen_time_trend_pending": "Kullanım geçmişi büyüdükçe ekran süresi trendi görünecek.",
        "screen_time_improved": "Ekran süresi %d%% iyileşti",
        "screen_time_higher": "Ekran süresi normalden biraz yüksek",
        "screen_time_steady": "Bu hafta ekran süresi stabil",

        // Benchmarks
        "benchmark_pending": "Uygulama kullanım geçmişini kaydettikçe ortalama ekran süresi görünecek. Küresel referans noktası günde yaklaşık 7 saattir.",
        "benchmark_below": "7 günlük ortalamanız %@, küresel 7 saatlik ortalamanın altında. Bu güçlü bir yön.",
        "benchmark_above": "7 günlük ortalamanız %@, küresel 7 saatlik ortalamanın üstünde. Bugün küçük bir azalma trendi değiştirebilir.",
        "benchmark_matching": "7 günlük ortalamanız %@, küresel 7 saatlik ortalamayla eşleşiyor.",

        // Task editing
        "edit_task": "Görevi Düzenle",
        "task_name_placeholder": "Görev adı",
        "task_reminder_default": "Görev hatırlatıcısı",
        "time_h_m": "%dsa %ddk",
        "time_m": "%ddk",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Italian
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let it: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Informazioni sulle modalità di concentrazione",
        "no_active_goals_title": "Nessun obiettivo attivo",
        "no_active_goals_btn": "Ho capito",
        "no_active_goals_msg": "Le modalità Focus e Blocco funzionano solo finché hai un obiettivo da completare. Aggiungi un obiettivo — o riattivane uno — poi avvia la tua sessione.",
        // Tab bar
        "tab_home": "Home", "tab_progress": "Progressi", "tab_mode": "Modalità", "tab_profile": "Profilo",

        // Home
        "today": "Oggi", "tomorrow": "Domani", "yesterday": "Ieri",
        "back_to_today": "Torna a Oggi",
        "add_first_task": "Tocca + per aggiungere il tuo primo compito",
        "no_tasks_this_day": "Nessun compito in questo giorno",
        "new_task": "Nuovo Compito",
        "what_to_do": "Cosa devi fare?",
        "task": "Compito", "schedule": "Pianifica",
        "pick_date_hint": "Scegli una data futura — oggi, la prossima settimana o tra qualche mese.",
        "priority": "Priorità", "low": "Bassa", "medium": "Media", "high": "Alta",
        "notification": "Notifica",
        "silent_push": "Notifica silenziosa",
        "notification_desc": "Invia una notifica una tantum all'orario programmato. Appare silenziosamente sulla schermata di blocco e nel Centro Notifiche.",
        "reminder": "Promemoria",
        "alarm_sound": "Sveglia con suono e vibrazione",
        "reminder_desc": "Funziona come una sveglia — un suono speciale verrà riprodotto e il tuo telefono vibrerà continuamente finché non premi il pulsante Ignora sullo schermo. Ideale per riunioni e scadenze.",
        "cancel": "Annulla", "add": "Aggiungi", "edit": "Modifica", "delete": "Elimina",
        "jump_to_date": "Vai a Data", "done": "Fatto",
        "task_limit": "Hai raggiunto il limite di 25 compiti per questa data.",
        "time": "Ora", "date": "Data", "select_date": "Seleziona Data",

        // Alarm
        "reminder_title": "Promemoria", "dismiss": "Ignora",

        // Progress
        "daily_progress": "Progresso Giornaliero", "streaks": "serie", "focus_days": "giorni di focus",
        "consistency": "costanza",
        "set_first_goal": "Imposta il tuo primo obiettivo per oggi",
        "all_goals_completed": "Tutti gli obiettivi giornalieri completati",
        "goals_completed": "di", "daily_goals_completed": "obiettivi giornalieri completati",
        "daily_goals": "Obiettivi Giornalieri", "remaining": "rimanenti",
        "no_goals_planned": "Nessun obiettivo pianificato",
        "complete_to_focus": "Completa ogni compito per segnare oggi come giorno di focus.",
        "add_task_to_start": "Aggiungi un compito da Home per iniziare a monitorare gli obiettivi giornalieri.",
        "daily_plan_complete": "Piano giornaliero completato",
        "ai_weekly_summary": "Riepilogo Settimanale IA",
        "creating_summary": "Creazione del riepilogo settimanale...",
        "generate_summary": "Genera Riepilogo", "refresh_summary": "Aggiorna Riepilogo",
        "first_summary_coming": "Il tuo primo riepilogo settimanale IA è in arrivo.",
        "first_summary_desc": "Sarà pronto il %@ alle 21. Include approfondimenti sui tuoi progressi, compiti mancati e la migliore modalità di focus per te.",
        "next_update": "Prossimo aggiornamento: %@",
        "weekly_recap": "Il tuo riepilogo settimanale di giorni di focus, compiti e tendenze di produttività è pronto.",
        "screen_time_7day": "Tempo Schermo 7 Giorni", "best_streak": "Miglior Serie",
        "days": "giorni", "milestones": "Traguardi", "milestone_unlocked": "Traguardo Sbloccato",
        "continue_btn": "Continua", "history_calendar": "Calendario Storico",
        "mode_used": "Modalità Usata", "completed": "Completato", "not_completed": "Non Completato",
        "no_completed_tasks": "Nessun compito completato registrato per questo giorno.",
        "everything_completed": "Tutto è stato completato.",
        "no_missed_tasks": "Nessun compito mancato registrato per questo giorno.",
        "streak_day": "Giorno di Serie", "missed_day": "Giorno Mancato",
        "first_name": "Nome", "last_name": "Cognome",
        "avatar_color": "Colore Avatar",
        "whats_your_name": "Come ti chiami?",
        "name_helps": "Questo aiuta a personalizzare la tua esperienza.",
        "name_save_failed": "Non siamo riusciti a salvare il tuo nome. Controlla la connessione e riprova.",
        "continue_btn_name": "Continua",
        "wins": "Vittorie", "next_action": "Prossima Azione", "average": "media",
        "todays_completion": "Completamento di oggi",
        "streaks_this_month": "serie questo mese",
        "streak_days": "giorni di serie", "non_streak_days": "giorni senza serie",
        "monthly_streak_summary": "%d serie questo mese • %d giorni di serie, %d giorni senza serie",
        "duration_average": "%@ di media",

        // Profile
        "personal_details": "Dati Personali",
        "personal_info": "Informazioni Personali",
        "update_email_name": "Aggiorna la tua e-mail e il nome completo.",
        "and_username": "e nome utente",
        "invite_friends": "Invita Amici",
        "refer_friend_title": "Presenta un amico e guadagna $10",
        "refer_friend_desc": "Guadagna $10 per ogni amico che si registra con il tuo codice promozionale.",
        "upgrade_family_plan": "Passa al Piano Famiglia",
        "goals_tracking": "Obiettivi e Monitoraggio",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Modifica Obiettivi Nutrizionali",
        "tracking_reminders": "Promemoria di Monitoraggio",
        "email_not_editable": "La tua e-mail è collegata al tuo login e non può essere modificata qui.",
        "theme": "Tema",
        "theme_desc": "Usa l'aspetto del sistema o scegli una modalità chiara/scura fissa.",
        "appearance": "Aspetto",
        "appearance_desc": "Scegli aspetto chiaro, scuro o di sistema",
        "live_activity_profile_desc": "Mostra i tuoi progressi giornalieri sulla schermata di blocco e sulla Dynamic Island",
        "system": "Sistema", "light": "Chiaro", "dark": "Scuro",
        "live_activity": "Attività in Tempo Reale",
        "live_activity_desc": "Mostra gli obiettivi di oggi, la serie e una motivazione fresca sulla schermata di blocco.",
        "privacy_policy": "Informativa sulla Privacy",
        "privacy_desc": "Consulta come vengono utilizzati i dati dell'app e i permessi del dispositivo.",
        "terms_of_service": "Termini e Condizioni",
        "terms_desc": "Leggi le regole per l'utilizzo dell'app e dei suoi strumenti di focus.",
        "follow_us": "Seguici",
        "sign_out": "Esci",
        "sign_out_desc": "Termina questa sessione sul dispositivo attuale.",
        "delete_account": "Elimina Account",
        "delete_account_desc": "Elimina permanentemente il tuo account e i dati sincronizzati dell'app.",
        "delete_account_title": "Elimina Account",
        "delete_account_msg": "Questa azione è permanente. Tutti i tuoi dati verranno eliminati e non potranno essere recuperati.",
        "delete_account_continue": "Continua",
        "delete_account_final_title": "Eliminare Permanentemente?",
        "delete_account_final_msg": "Per favore conferma ancora una volta. Se elimini il tuo account, Spike AI ti disconnetterà e ti rimanderà alla pagina di accesso.",
        "deleting_account": "Eliminazione account...",
        "delete_failed": "Eliminazione dell'account non riuscita. Riprova o contatta il supporto.",
        "language": "Lingua",
        "language_desc": "Scegli la lingua per tutti i contenuti dell'app.",
        "set_name": "Imposta il tuo nome",
        "profile_name_prompt": "Come dobbiamo chiamarti?",
        "profile_name_desc": "Aggiungi il nome che Spike AI dovrebbe usare nel tuo profilo e nell'esperienza di produttività.",
        "full_name": "Nome Completo", "display_name": "Nome Visualizzato",
        "email": "E-mail",
        "save_changes": "Salva Modifiche",
        "save_footer": "Le modifiche vengono salvate nel tuo profilo e utilizzate ovunque la tua identità appaia nell'app.",
        "signed_in": "Connesso",
        "account": "Account", "preferences": "Preferenze",
        "support_legal": "Supporto e Legale", "account_actions": "Azioni Account",
        "pref_show_completed": "Mostra Compiti Completati",
        "pref_show_completed_desc": "Mantieni i compiti completati visibili nella tua lista giornaliera.",
        "pref_quotes": "Citazioni Motivazionali",
        "pref_quotes_desc": "Mostra una citazione ispiratrice nella schermata dei progressi.",
        "legal_updated": "Ultimo aggiornamento: 25 maggio 2026",
        "privacy_body": """
        Ultimo aggiornamento: 25 maggio 2026

        Spike AI è un'applicazione di produttività e concentrazione. Questa Informativa sulla Privacy spiega come Spike AI gestisce le informazioni utilizzate per fornire account, pianificazione di compiti, promemoria, modalità di focus, controlli del Tempo Schermo, monitoraggio dei progressi e riepiloghi di produttività generati dall'IA.

        Informazioni che raccogliamo: identificatori dell'account come il tuo indirizzo e-mail e ID utente; dettagli del profilo che scegli di fornire, come nome visualizzato e nome completo; compiti, obiettivi, promemoria, cronologia di completamento, impostazioni delle modalità di focus, token di selezione app e metriche di progresso. Possiamo inoltre conservare registri tecnici necessari per mantenere il servizio affidabile e sicuro.

        Tempo Schermo e selezione app: le selezioni di app, categorie e domini web sono gestite tramite i framework FamilyControls e ManagedSettings di Apple. Spike AI archivia i token forniti da Apple necessari per applicare le modalità di focus selezionate. Non utilizziamo queste selezioni per scopi pubblicitari.

        Uso della fotocamera nella Modalità Sudore: l'accesso alla fotocamera viene utilizzato per verifiche della postura corporea sul dispositivo affinché tu possa ottenere accesso temporaneo alle app tramite movimento. Spike AI non carica fotogrammi video per questa funzione e non utilizza i dati della fotocamera per scopi pubblicitari.

        Notifiche e promemoria: Spike AI utilizza il permesso di notifica per inviare promemoria di compiti, sveglie e suggerimenti di focus che configuri. Puoi modificare l'accesso alle notifiche nelle Impostazioni di iOS in qualsiasi momento.

        Riepiloghi IA: se generi un riepilogo dei progressi, le metriche recenti di compiti, obiettivi, focus e produttività possono essere elaborate dal server di Spike AI per produrre il riepilogo. Evita di inserire informazioni personali sensibili nei nomi dei compiti o degli obiettivi se non desideri che vengano elaborate per le funzionalità di produttività.

        Come utilizziamo le informazioni: per autenticarti, sincronizzare il tuo account, fornire strumenti di focus, pianificare promemoria, mostrare i progressi, personalizzare gli approfondimenti sulla produttività, proteggere dall'uso improprio, risolvere problemi e rispettare gli obblighi legali. Spike AI non vende le tue informazioni personali.

        Cancellazione dei dati: puoi disconnetterti o richiedere l'eliminazione permanente dell'account dal Profilo. L'eliminazione dell'account rimuove il tuo account di autenticazione e i dati sincronizzati dell'app associati a tale account, fatta salva una conservazione limitata richiesta per sicurezza, prevenzione delle frodi, risoluzione delle controversie o conformità legale.

        Le tue scelte: puoi modificare i dettagli del profilo, cambiare le preferenze di lingua e aspetto, disattivare l'Attività in Tempo Reale, revocare i permessi del dispositivo nelle Impostazioni, smettere di usare modalità di focus specifiche o eliminare il tuo account.

        Contatti: per domande sulla privacy o problemi con l'eliminazione dell'account, contatta il supporto di Spike AI tramite il canale di supporto fornito dall'app o dalla pagina dell'App Store.
        """,
        "terms_body": """
        Ultimo aggiornamento: 25 maggio 2026

        Questi Termini e Condizioni regolano l'utilizzo di Spike AI, inclusi compiti, promemoria, modalità di focus, avvisi e blocchi di app del Tempo Schermo, verifiche di movimento della Modalità Sudore, monitoraggio dei progressi e riepiloghi generati dall'IA.

        Idoneità e account: sei responsabile dell'account che crei e della sicurezza dell'accesso alla tua e-mail e al tuo dispositivo. Utilizza informazioni accurate quando l'app richiede dettagli del profilo.

        Scopo di produttività: Spike AI è progettato per supportare la produttività personale e l'uso intenzionale del dispositivo. Non è un servizio medico, di salute mentale, di emergenza, di sicurezza, di controllo parentale, di monitoraggio lavorativo o di gestione del dispositivo. Non fare affidamento su Spike AI laddove il malfunzionamento di un promemoria, blocco, avviso, verifica della fotocamera, notifica, richiesta di rete o permesso Apple possa causare danni.

        Le tue responsabilità: scegli impostazioni di focus appropriate alla tua situazione; controlla le selezioni di app prima di attivare una modalità; disattiva le modalità quando non corrispondono più alle tue esigenze; rispetta la legge applicabile e i termini della piattaforma Apple; ed evita di inserire informazioni sensibili nei compiti o negli obiettivi a meno che tu non sia a tuo agio nell'utilizzarle nell'app.

        Uso accettabile: non abusare di Spike AI, non interferire con il dispositivo o l'account di un'altra persona, non tentare di aggirare le restrizioni di sicurezza o della piattaforma, non effettuare reverse engineering di parti protette del servizio, non sovraccaricare il server e non utilizzare l'app per attività illegali, abusive, ingannevoli o dannose.

        Permessi e disponibilità: alcune funzionalità richiedono permessi iOS come Tempo Schermo, notifiche, fotocamera, Attività in Tempo Reale e accesso alla rete. Apple, le impostazioni del dispositivo, il comportamento del sistema operativo, la connettività e la disponibilità del server possono influire sul funzionamento previsto delle funzionalità.

        Contenuti generati dall'IA: i riepiloghi dei progressi possono essere generati utilizzando sistemi automatizzati. Sono destinati esclusivamente alla riflessione e all'orientamento sulla produttività. Valutali con il tuo giudizio prima di fare affidamento su di essi.

        Eliminazione dell'account e cessazione: puoi richiedere l'eliminazione dell'account dal Profilo. Spike AI può sospendere o cessare l'accesso se richiesto dalla legge, dalle regole della piattaforma, da preoccupazioni di sicurezza o da grave uso improprio.

        Modifiche: Spike AI può aggiornare questi Termini man mano che l'app si evolve. L'uso continuato dopo un aggiornamento significa che accetti i Termini aggiornati.

        Contatti: per domande su questi Termini, contatta il supporto di Spike AI tramite il canale di supporto fornito dall'app o dalla pagina dell'App Store.
        """,

        // Focus Mode
        "focus_title": "Focus", "select_mode": "Seleziona Modalità",
        "chill": "Relax", "focus": "Focus", "lock_in": "Blocco", "sweat": "Atleta",
        "gentle_nudges": "Promemoria delicati", "confirm_intent": "Conferma l'intenzione",
        "no_bypass": "Nessun aggiramento", "move_to_unlock": "Muoviti per sbloccare",
        "activate_focus": "Attiva Modalità Focus", "deactivate_focus": "Disattiva Modalità Focus",
        "mode_active": "Modalità Attiva",
        "reminders_scheduled": "Promemoria programmati",
        "apps_prompt_active": "app — avviso \"Sei sicuro?\" attivo",
        "apps_blocked": "app bloccate",
        "temp_access_active": "Accesso temporaneo attivo",
        "apps_require_movement": "app richiedono movimento per sbloccare",
        "notifications_label": "Notifiche",
        "notifications_enabled": "Notifiche attivate",
        "notifications_denied": "Notifiche negate",
        "enable_notif_settings": "Attiva le notifiche nelle Impostazioni.",
        "allow_notif_desc": "Consenti le notifiche affinché Spike AI possa inviarti promemoria di focus.",
        "enable_notifications": "Attiva Notifiche",
        "screen_time_access": "Accesso Tempo Schermo",
        "screen_time_authorized": "Tempo Schermo autorizzato",
        "allow_screen_time": "Consenti Tempo Schermo",
        "tap_to_allow": "Tocca in basso per consentire l'accesso al Tempo Schermo.",
        "open_settings_manual": "Oppure apri le Impostazioni per attivarlo manualmente",
        "open_settings": "Apri Impostazioni",
        "app_selection": "Selezione App", "selections": "selezione/i",
        "choose_apps_confirm": "Scegli quali app confermare prima dell'apertura.",
        "choose_apps_block": "Scegli quali app bloccare.",
        "choose_apps_movement": "Scegli quali app sbloccare con il movimento.",
        "change_selection": "Modifica Selezione", "select_apps": "Seleziona App",
        "movement_unlock": "Sblocco con Movimento",
        "movement_desc": "Flessioni e alzate vengono monitorate con rilevamento corporeo IA. Ogni ripetizione verificata aggiunge 1 minuto di accesso alle app selezionate.",
        "access_available": "Accesso disponibile per %@",
        "open_camera": "Apri Verifica Fotocamera",
        "lock_in_mode": "Modalità Blocco",
        "lock_in_warning": "Le app mostrano una schermata rossa senza aggiramento. Devi tornare qui per disattivare la Modalità Blocco.",
        "sweat_mode": "Modalità Atleta",
        "do_exercises": "Fai flessioni o alzate per guadagnare tempo",
        "add_minutes": "Aggiungi %d Minuto/i",
        "keep_in_view": "Mantieni spalle, braccia o fianchi visibili",
        "camera_required": "L'accesso alla fotocamera è necessario per le verifiche di movimento.",
        "camera_disabled": "L'accesso alla fotocamera è disattivato. Attivalo nelle Impostazioni per usare la Modalità Sudore.",
        "camera_unavailable": "L'accesso alla fotocamera non è disponibile.",
        "starting_camera": "Avvio fotocamera...",
        "camera_active": "Fotocamera attiva",
        "allow_camera": "Consenti Accesso alla Fotocamera",
        "focus_mode_title": "Modalità Focus",
        "focus_mode_desc": "Prendi il controllo delle tue abitudini digitali con modalità concentrate e professionali.",
        "about_permissions": "Informazioni sui Permessi",
        "permissions_desc": "La Modalità Relax richiede il permesso di notifica. Le Modalità Focus, Blocco e Sudore richiedono l'autorizzazione del Tempo Schermo. La Modalità Sudore usa anche l'accesso alla fotocamera per le verifiche di movimento.",
        "get_started": "Inizia", "skip": "Salta",
        "unlocked_for": "Sbloccato per %@",

        // Chill mode descriptions
        "chill_desc": "Promemoria giornalieri tramite notifiche. Nessun controllo sulle app — solo suggerimenti delicati per restare intenzionali.",
        "focus_desc": "Quando apri un'app selezionata, Spike AI chiede \"Sei sicuro?\" Puoi aprirla normalmente o tornare ai tuoi compiti. Le app non vengono bloccate.",
        "lock_in_desc": "Le app selezionate vengono bloccate mentre il Blocco è attivo. Puoi disattivare la modalità da Spike AI.",
        "sweat_desc": "Le app selezionate restano bloccate finché non completi una flessione o un'alzata verificata dalla fotocamera. Ogni ripetizione verificata sblocca 1 minuto.",

        // Motivational (deactivation)
        "giving_up_title": "Stai facendo progressi — non fermarti ora",
        "giving_up_msg": "Hai ancora obiettivi non completati per oggi. Ogni compito concluso crea slancio. Resta impegnato — il tuo futuro te ne sarà grato.",
        "giving_up_continue": "Resta Concentrato", "giving_up_stop": "Disattiva Comunque",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Il tuo sistema personale di produttività",
        "start_setup": "Inizia Configurazione",
        "make_phone_work": "Fai lavorare il tuo telefono\nper i tuoi obiettivi.",
        "onboarding_welcome_desc": "Riduci lo scrolling senza senso, proteggi il tempo di concentrazione e trasforma compiti reali in progressi visibili.",
        "did_you_know": "Lo sapevi?",
        "did_you_know_subtitle": "Una persona trascorre in media 7 ore al giorno sul telefono. Sono",
        "hours_per_day": "ore al giorno",
        "days_per_month": "giorni al mese",
        "days_per_year": "giorni all'anno",
        "years_of_life": "anni della tua vita",
        "screen_time_reality": "E alcune persone trascorrono ancora più tempo.",
        "dont_worry_title": "Non preoccuparti",
        "spike_has_your_back": "Spike AI è dalla tua parte",
        "solution_desc": "Ti aiuteremo a massimizzare la tua produttività, avvicinarti ai tuoi obiettivi e costruire le abitudini che ti trasformano nella versione migliore di te stesso.",
        "screen_time_access_title": "Accesso Tempo Schermo",
        "grant_access": "Concedi Accesso",
        "which_apps": "Scegli le tue\napp che distraggono",
        "choose_apps_protect": "Seleziona le app che ti fanno perdere tempo. Le bloccheremo durante le modalità di focus.",
        "apple_screen_time_required": "Apple richiede l'accesso al Tempo Schermo prima che Spike AI possa mostrare la tua lista di app.",
        "save_apps": "Salva e Continua",
        "change_selected_apps": "Modifica app selezionate",
        "ready_change_life": "Pronto a cambiare\nla tua vita?",
        "ready_change_desc": "Crea il tuo account per salvare le tue scelte e iniziare il tuo percorso.",
        "benefit_no_distraction": "Le app che distraggono non ti disturberanno più",
        "benefit_discover_modes": "Scopri 4 tipi diversi di modalità di focus",
        "benefit_track_progress": "Monitora i tuoi progressi e avvicinati ai tuoi obiettivi",
        "create_account": "Crea Account",
        "protect_focus": "Proteggi il Focus",
        "block_feeds": "Blocca i feed",
        "finish_tasks": "Completa i compiti",
        "energy_plus_three": "+3 Energia",
        "selected_count": "%d selezionate",
        "no_apps_selected": "Nessuna app selezionata ancora",
        "saved_for_modes": "Salvate per le modalità di protezione",
        "select_apps_to_control": "Seleziona le app che vuoi controllare",
        "clean_room": "Pulisci la Stanza",
        "snap_proof": "Scatta una foto come prova al termine",
        "ai_verifies_task": "L'IA verifica il compito",
        "energy_earned": "+3 Energia guadagnata",
        "on_track": "In carreggiata",
        "energy": "Energia",
        "tasks_completed": "Compiti completati",
        "focus_protected": "Focus protetto",
        "scrolling_avoided": "Scrolling evitato",
        "continue_apple": "Continua con Apple",
        "continue_google": "Continua con Google",
        "continue_email": "Continua con e-mail",
        "enter_email": "Inserisci la tua e-mail",
        "send_sign_in_link": "Ti invieremo un link di accesso",
        "check_email": "Controlla la tua e-mail",
        "sent_link_to": "Abbiamo inviato un link di accesso a",
        "tap_link": "Tocca il link per accedere automaticamente.",
        "open_mail": "Apri App Mail",
        "open_with": "Apri con",
        "didnt_get_email": "Non hai ricevuto l'e-mail?",
        "resend": "Rinvia",
        "resend_in": "Rinvia tra %ds",
        "new_link_sent": "Un nuovo link è stato inviato!",
        "valid_email": "Inserisci un indirizzo e-mail valido.",
        "by_continuing": "Continuando, accetti i",
        "and_word": "e",

        // Screen Time Onboarding
        "screen_time_title": "Tempo Schermo",
        "screen_time_permission_desc": "Spike AI ha bisogno del permesso Tempo Schermo per le modalità Focus, Blocco e Sudore. Questo permette di mostrare avvisi e blocchi per le app che scegli.",
        "screen_time_denied": "Il permesso è stato negato. Puoi attivarlo nelle Impostazioni.",
        "ask_before_opening": "Chiedi Prima di Aprire",
        "block_apps_completely": "Blocca le App Completamente",
        "stay_accountable": "Resta Responsabile",
        "stay_accountable_desc": "Monitora i progressi e mantieni visibili le tue abitudini di focus.",
        "skip_for_now": "Salta per Ora",

        // Live Activity
        "daily_goals_title": "Obiettivi Giornalieri",
        "of_done": "di %d completati",
        "more_to_go": "+%d ancora da fare",

        // Chill morning
        "good_morning": "Buongiorno! Resta intenzionale oggi. Rivedi i tuoi compiti e mantieni la concentrazione.",

        // General
        "error": "Errore", "ok": "OK", "yes": "Sì", "no": "No",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Passare alla Modalità Relax?",
        "stay_focused_btn": "Resta Concentrato",
        "switch_anyway_btn": "Cambia Comunque",
        "switch_to_chill_msg": "Hai ancora obiettivi non completati. Passare alla Modalità Relax rimuove il blocco delle app, aumentando il rischio di non raggiungere i tuoi obiettivi oggi.",
        "task_notification": "Notifica Attività",
        "missed_alarm": "Allarme Perso",
        "quote_of_day": "Citazione del Giorno",
        "new_quotes_daily": "Nuove citazioni arrivano ogni giorno alle 5:00",
        "focus_day_label": "Giorno di Focus",
        "missed_label": "Perso",
        "access_granted": "Accesso concesso",
        "goal_reminder": "Promemoria Obiettivo",
        "spike_ai_focus": "Spike AI Focus",
        "goals_required_title": "Obiettivi Richiesti",
        "goals_required_desc_focus": "La modalità Focus blocca le app selezionate solo quando hai obiettivi non completati. Aggiungi obiettivi nella scheda Home per attivare il blocco delle app.",
        "goals_required_desc_lockin": "La modalità Blocco blocca le app selezionate solo quando hai obiettivi non completati. Aggiungi obiettivi nella scheda Home per attivare il blocco delle app.",
        "save": "Salva",
        "no_goals_reminder_body": "Non hai impostato alcun obiettivo per oggi. Prenditi un momento per pianificare la tua giornata!",
        "dont_forget": "Non dimenticare",
        "chill_morning_body": "Buongiorno! Sii intenzionale oggi. Rivedi i tuoi compiti e resta concentrato.",
        "every_day": "Ogni giorno",
        "weekdays": "Giorni feriali",
        "weekends": "Fine settimana",
        "time_to_focus": "È ora di concentrarsi!",

        // Additional UI strings
        "next_quote_in": "Prossima citazione tra %@",
        "enable_notif_chill": "Attiva le notifiche prima di avviare la modalità Relax.",
        "enable_screen_time_mode": "Attiva l'accesso a Tempo di utilizzo prima di avviare questa modalità.",
        "select_app_before_mode": "Seleziona almeno un'app, categoria o sito web prima di avviare questa modalità.",
        "mode_not_ready": "Questa modalità non è pronta per l'avvio.",
        "protection_stopped_no_apps": "La protezione è stata interrotta: nessuna app selezionata.",
        "protection_stopped_screen_time": "La protezione è stata interrotta: l'accesso a Tempo di utilizzo è cambiato.",
        "max_reminders": "Puoi creare fino a %d promemoria di concentrazione.",
        "front_camera_unavailable": "La fotocamera frontale non è disponibile.",
        "task_title_empty": "Il titolo dell'attività non può essere vuoto.",
        "goal_title_empty": "Il titolo dell'obiettivo non può essere vuoto.",
        "rate_limit_wait": "Attendi %d secondi prima di generare un altro riepilogo.",
        "missed_alarm_for": "Hai perso la sveglia per: %@",
        "stay_with_plan": "Segui il piano.",
        "motivation_small_wins": "Le piccole vittorie si accumulano.",
        "motivation_next_step": "Completa il prossimo passo.",
        "motivation_protect_hour": "Proteggi l'ora davanti a te.",
        "motivation_consistency": "La costanza batte l'intensità.",
        "monthly_scope_btn": "Mensile",
        "yearly_scope_btn": "Annuale",
        "restoring_session": "Ripristino della sessione...",

        // Milestones
        "milestone_3day_streak": "Serie di 3 giorni",
        "milestone_3day_desc": "Un ritmo costante è iniziato.",
        "milestone_7day_streak": "Serie di 7 giorni",
        "milestone_7day_desc": "Una settimana concentrata completa.",
        "milestone_10h_protected": "10 ore protette",
        "milestone_10h_desc": "Tempo protetto per ciò che conta.",
        "milestone_30_focus": "30 giorni di concentrazione",
        "milestone_30_desc": "Costanza con peso reale.",

        // Narratives
        "narrative_improved": "Il tuo tempo di schermo è migliorato rispetto alla settimana scorsa.",
        "narrative_consistent": "Sei rimasto costante questa settimana e hai protetto la tua concentrazione.",
        "narrative_more_days": "Hai completato più giorni di concentrazione del solito.",
        "narrative_building": "Stai costruendo il ritmo un giorno concentrato alla volta.",

        // Screen time
        "screen_time_trend_pending": "La tendenza del tempo di schermo apparirà man mano che la cronologia d'uso cresce.",
        "screen_time_improved": "Tempo di schermo migliorato del %d%%",
        "screen_time_higher": "Il tempo di schermo è leggermente superiore al solito",
        "screen_time_steady": "Il tempo di schermo è stabile questa settimana",

        // Benchmarks
        "benchmark_pending": "Il tempo medio di schermo apparirà quando l'app avrà registrato la cronologia d'uso. Il riferimento globale è di circa 7 ore al giorno.",
        "benchmark_below": "La tua media di 7 giorni è %@, sotto la media globale di 7 ore. È una direzione forte.",
        "benchmark_above": "La tua media di 7 giorni è %@, sopra la media globale di 7 ore. Una piccola riduzione oggi può cambiare la tendenza.",
        "benchmark_matching": "La tua media di 7 giorni è %@, uguale alla media globale di 7 ore.",

        // Task editing
        "edit_task": "Modifica attività",
        "task_name_placeholder": "Nome dell'attività",
        "task_reminder_default": "Promemoria attività",
        "time_h_m": "%dh %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Polish
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let pl: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "O trybach skupienia",
        "no_active_goals_title": "Brak aktywnych celów",
        "no_active_goals_btn": "Rozumiem",
        "no_active_goals_msg": "Tryby Skupienie i Blokada działają tylko wtedy, gdy masz nieukończony cel do osiągnięcia. Dodaj cel — lub aktywuj go ponownie — a następnie rozpocznij sesję.",
        // Tab bar
        "tab_home": "Start", "tab_progress": "Postępy", "tab_mode": "Tryb", "tab_profile": "Profil",

        // Home
        "today": "Dziś", "tomorrow": "Jutro", "yesterday": "Wczoraj",
        "back_to_today": "Wróć do dziś",
        "add_first_task": "Stuknij +, aby dodać pierwsze zadanie",
        "no_tasks_this_day": "Brak zadań na ten dzień",
        "new_task": "Nowe zadanie",
        "what_to_do": "Co musisz zrobić?",
        "task": "Zadanie", "schedule": "Harmonogram",
        "pick_date_hint": "Wybierz dowolną datę — dziś, w przyszłym tygodniu lub za kilka miesięcy.",
        "priority": "Priorytet", "low": "Niski", "medium": "Średni", "high": "Wysoki",
        "notification": "Powiadomienie",
        "silent_push": "Ciche powiadomienie push",
        "notification_desc": "Wysyła jednorazowe powiadomienie push o zaplanowanej godzinie. Pojawi się dyskretnie na ekranie blokady i w Centrum powiadomień.",
        "reminder": "Przypomnienie",
        "alarm_sound": "Alarm z dźwiękiem i wibracjami",
        "reminder_desc": "Działa jak alarm — odtworzy specjalny dźwięk, a telefon będzie wibrował, aż naciśniesz przycisk Odrzuć. Idealny na spotkania i terminy.",
        "cancel": "Anuluj", "add": "Dodaj", "edit": "Edytuj", "delete": "Usuń",
        "jump_to_date": "Przejdź do daty", "done": "Gotowe",
        "task_limit": "Osiągnięto limit 25 zadań na tę datę.",
        "time": "Godzina", "date": "Data", "select_date": "Wybierz datę",

        // Alarm
        "reminder_title": "Przypomnienie", "dismiss": "Odrzuć",

        // Progress
        "daily_progress": "Dzienny postęp", "streaks": "serie", "focus_days": "dni skupienia",
        "consistency": "regularność",
        "set_first_goal": "Ustaw swój pierwszy cel na dziś",
        "all_goals_completed": "Wszystkie dzienne cele ukończone",
        "goals_completed": "z",
        "daily_goals_completed": "dziennych celów ukończonych",
        "daily_goals": "Dzienne cele", "remaining": "pozostało",
        "no_goals_planned": "Brak zaplanowanych celów",
        "complete_to_focus": "Ukończ wszystkie zadania, aby oznaczyć dziś jako dzień skupienia.",
        "add_task_to_start": "Dodaj zadanie ze strony głównej, aby rozpocząć śledzenie dziennych celów.",
        "daily_plan_complete": "Dzienny plan ukończony",
        "ai_weekly_summary": "Tygodniowe podsumowanie AI",
        "creating_summary": "Tworzenie tygodniowego podsumowania...",
        "generate_summary": "Wygeneruj podsumowanie",
        "refresh_summary": "Odśwież podsumowanie",
        "first_summary_coming": "Twoje pierwsze tygodniowe podsumowanie AI jest w drodze.",
        "first_summary_desc": "Będzie gotowe %@ o 21:00. Zawiera spostrzeżenia dotyczące postępów, pominiętych zadań i najlepszego trybu skupienia dla Ciebie.",
        "next_update": "Następna aktualizacja: %@",
        "weekly_recap": "Twój tygodniowy przegląd dni skupienia, zadań i trendów produktywności jest gotowy.",
        "screen_time_7day": "Czas ekranowy — 7 dni",
        "best_streak": "Najlepsza seria", "days": "dni",
        "milestones": "Kamienie milowe", "milestone_unlocked": "Kamień milowy odblokowany",
        "continue_btn": "Dalej",
        "history_calendar": "Kalendarz historii",
        "mode_used": "Użyty tryb",
        "completed": "Ukończone", "not_completed": "Nieukończone",
        "no_completed_tasks": "Brak zarejestrowanych ukończonych zadań na ten dzień.",
        "everything_completed": "Wszystko zostało ukończone.",
        "no_missed_tasks": "Brak zarejestrowanych pominiętych zadań na ten dzień.",
        "streak_day": "Dzień serii", "missed_day": "Pominięty dzień",
        "first_name": "Imię", "last_name": "Nazwisko",
        "avatar_color": "Kolor awatara",
        "whats_your_name": "Jak masz na imię?",
        "name_helps": "To pomoże spersonalizować Twoje doświadczenie.",
        "name_save_failed": "Nie udało się zapisać Twojego imienia. Sprawdź połączenie i spróbuj ponownie.",
        "continue_btn_name": "Dalej",
        "wins": "Wygrane", "next_action": "Następne działanie",
        "average": "średnio",
        "todays_completion": "Dzisiejsze ukończenie",
        "streaks_this_month": "serii w tym miesiącu",
        "streak_days": "dni serii", "non_streak_days": "dni bez serii",
        "monthly_streak_summary": "%d serii w tym miesiącu • %d dni serii, %d dni bez serii",
        "duration_average": "%@ średnio",

        // Profile
        "personal_details": "Dane osobowe",
        "personal_info": "Informacje osobiste",
        "update_email_name": "Zaktualizuj adres e-mail i pełne imię.",
        "and_username": "i nazwę użytkownika",
        "invite_friends": "Zaproś znajomych",
        "refer_friend_title": "Poleć znajomego i zyskaj $10",
        "refer_friend_desc": "Zyskaj $10 za każdego znajomego, który zarejestruje się z Twoim kodem promocyjnym.",
        "upgrade_family_plan": "Przejdź na plan rodzinny",
        "goals_tracking": "Cele i śledzenie",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Edytuj cele żywieniowe",
        "tracking_reminders": "Przypomnienia o śledzeniu",
        "email_not_editable": "Twój adres e-mail jest powiązany z logowaniem i nie można go tutaj edytować.",
        "theme": "Motyw",
        "theme_desc": "Użyj wyglądu systemowego lub wybierz stały tryb jasny/ciemny.",
        "appearance": "Wygląd",
        "appearance_desc": "Wybierz wygląd jasny, ciemny lub systemowy",
        "live_activity_profile_desc": "Pokazuj dzienny postęp na ekranie blokady i Dynamic Island",
        "system": "Systemowy", "light": "Jasny", "dark": "Ciemny",
        "live_activity": "Aktywność na żywo",
        "live_activity_desc": "Pokazuj dzisiejsze cele, serię i motywację na ekranie blokady.",
        "privacy_policy": "Polityka prywatności",
        "privacy_desc": "Sprawdź, jak używane są dane aplikacji i uprawnienia urządzenia.",
        "terms_of_service": "Regulamin",
        "terms_desc": "Przeczytaj zasady korzystania z aplikacji i jej narzędzi skupienia.",
        "follow_us": "Obserwuj nas",
        "sign_out": "Wyloguj",
        "sign_out_desc": "Zakończ tę sesję na bieżącym urządzeniu.",
        "delete_account": "Usuń konto",
        "delete_account_desc": "Trwale usuń swoje konto i zsynchronizowane dane aplikacji.",
        "delete_account_title": "Usuń konto",
        "delete_account_msg": "Ta czynność jest nieodwracalna. Wszystkie Twoje dane zostaną usunięte i nie będzie można ich odzyskać.",
        "delete_account_continue": "Dalej",
        "delete_account_final_title": "Usunąć na stałe?",
        "delete_account_final_msg": "Proszę potwierdzić jeszcze raz. Jeśli usuniesz konto, Spike AI wyloguje Cię i przeniesie na stronę logowania.",
        "deleting_account": "Usuwanie konta...",
        "delete_failed": "Usunięcie konta nie powiodło się. Spróbuj ponownie lub skontaktuj się ze wsparciem.",
        "language": "Język",
        "language_desc": "Wybierz język dla całej zawartości aplikacji.",
        "set_name": "Ustaw swoje imię",
        "profile_name_prompt": "Jak mamy się do Ciebie zwracać?",
        "profile_name_desc": "Podaj imię, którego Spike AI będzie używać w Twoim profilu i doświadczeniu produktywności.",
        "full_name": "Pełne imię",
        "display_name": "Wyświetlana nazwa",
        "email": "E-mail",
        "save_changes": "Zapisz zmiany",
        "save_footer": "Zmiany są zapisywane w Twoim profilu i używane wszędzie, gdzie w aplikacji pojawia się Twoja tożsamość.",
        "signed_in": "Zalogowano",
        "account": "Konto", "preferences": "Preferencje",
        "support_legal": "Wsparcie i informacje prawne",
        "account_actions": "Działania na koncie",
        "pref_show_completed": "Pokazuj ukończone zadania",
        "pref_show_completed_desc": "Pozostaw ukończone zadania widoczne na dziennej liście.",
        "pref_quotes": "Cytaty motywacyjne",
        "pref_quotes_desc": "Pokazuj inspirujący cytat na ekranie postępów.",
        "legal_updated": "Ostatnia aktualizacja: 25 maja 2026 r.",
        "privacy_body": """
        Ostatnia aktualizacja: 25 maja 2026 r.

        Spike AI to aplikacja do produktywności i skupienia. Niniejsza Polityka prywatności wyjaśnia, w jaki sposób Spike AI przetwarza informacje wykorzystywane do świadczenia usług kont, planowania zadań, przypomnień, trybów skupienia, kontroli czasu ekranowego, śledzenia postępów i generowania podsumowań produktywności przez AI.

        Zbierane informacje: identyfikatory konta, takie jak adres e-mail i identyfikator użytkownika; dane profilu, które zdecydujesz się podać, takie jak wyświetlana nazwa i pełne imię; zadania, cele, przypomnienia, historia ukończenia, ustawienia trybów skupienia, tokeny wyboru aplikacji i metryki postępu. Możemy również przechowywać zapisy techniczne niezbędne do zapewnienia niezawodności i bezpieczeństwa usługi.

        Czas ekranowy i wybór aplikacji: wybór aplikacji, kategorii i domen internetowych odbywa się za pośrednictwem frameworków Apple FamilyControls i ManagedSettings. Spike AI przechowuje tokeny dostarczone przez Apple, niezbędne do zastosowania wybranych trybów skupienia. Nie wykorzystujemy tych danych do celów reklamowych.

        Użycie kamery w trybie Pot: dostęp do kamery służy do sprawdzania pozycji ciała na urządzeniu, dzięki czemu możesz uzyskać tymczasowy dostęp do aplikacji poprzez ruch. Spike AI nie przesyła klatek wideo dla tej funkcji i nie wykorzystuje danych z kamery do celów reklamowych.

        Powiadomienia i przypomnienia: Spike AI korzysta z uprawnień do powiadomień, aby wysyłać przypomnienia o zadaniach, alarmy i podpowiedzi skupienia, które konfigurujesz. Dostęp do powiadomień możesz zmienić w ustawieniach iOS w dowolnym momencie.

        Podsumowania AI: jeśli wygenerujesz podsumowanie postępów, dane o ostatnich zadaniach, celach, trybach skupienia i metrykach produktywności mogą być przetwarzane przez serwer Spike AI w celu utworzenia podsumowania. Nie wprowadzaj poufnych informacji osobistych w nazwy zadań lub celów, jeśli nie chcesz, aby były przetwarzane na potrzeby funkcji produktywności.

        Jak wykorzystujemy informacje: do uwierzytelniania, synchronizacji konta, udostępniania narzędzi skupienia, planowania przypomnień, wyświetlania postępów, personalizacji analiz produktywności, ochrony przed nadużyciami, rozwiązywania problemów i wypełniania zobowiązań prawnych. Spike AI nie sprzedaje Twoich danych osobowych.

        Usuwanie danych: możesz się wylogować lub poprosić o trwałe usunięcie konta w sekcji Profil. Usunięcie konta powoduje usunięcie konta uwierzytelniania i zsynchronizowanych danych aplikacji powiązanych z tym kontem, z zastrzeżeniem ograniczonego przechowywania wymaganego w celu zapewnienia bezpieczeństwa, zapobiegania oszustwom, rozwiązywania sporów lub zgodności z prawem.

        Twoje wybory: możesz edytować dane profilu, zmieniać preferencje językowe i wyglądu, wyłączyć Aktywność na żywo, cofnąć uprawnienia urządzenia w Ustawieniach, przestać korzystać z określonych trybów skupienia lub usunąć konto.

        Kontakt: w sprawie pytań dotyczących prywatności lub usunięcia konta skontaktuj się ze wsparciem Spike AI za pośrednictwem kanału wsparcia dostępnego w aplikacji lub na stronie App Store.
        """,
        "terms_body": """
        Ostatnia aktualizacja: 25 maja 2026 r.

        Niniejszy Regulamin reguluje korzystanie z Spike AI, w tym zadania, przypomnienia, tryby skupienia, monity i ekrany blokady aplikacji przez czas ekranowy, sprawdzanie ruchu w trybie Pot, śledzenie postępów i podsumowania generowane przez AI.

        Uprawnienia i konto: ponosisz odpowiedzialność za utworzone konto oraz za zabezpieczenie dostępu do swojego adresu e-mail i urządzenia. Podawaj dokładne informacje tam, gdzie aplikacja prosi o dane profilowe.

        Cel produktywności: Spike AI został zaprojektowany w celu wspierania osobistej produktywności i świadomego korzystania z urządzenia. Nie jest to usługa medyczna, zdrowia psychicznego, awaryjna, bezpieczeństwa, kontroli rodzicielskiej, monitorowania zatrudnienia ani zarządzania urządzeniami. Nie polegaj na Spike AI w sytuacjach, w których awaria przypomnienia, blokady, monitu, sprawdzenia kamery, powiadomienia, żądania sieciowego lub uprawnienia Apple mogłaby spowodować szkodę.

        Twoje obowiązki: wybieraj ustawienia skupienia odpowiednie do Twojej sytuacji; sprawdzaj wybór aplikacji przed aktywacją trybu; wyłączaj tryby, gdy nie odpowiadają już Twoim potrzebom; przestrzegaj obowiązującego prawa i warunków platformy Apple; nie wprowadzaj poufnych informacji do zadań ani celów, chyba że czujesz się komfortowo, korzystając z nich w aplikacji.

        Dopuszczalne użytkowanie: nie nadużywaj Spike AI, nie ingeruj w urządzenie lub konto innej osoby, nie próbuj obchodzić zabezpieczeń ani ograniczeń platformy, nie dokonuj inżynierii wstecznej chronionych części usługi, nie przeciążaj serwera ani nie korzystaj z aplikacji w celach niezgodnych z prawem, obraźliwych, wprowadzających w błąd lub szkodliwych.

        Uprawnienia i dostępność: niektóre funkcje wymagają uprawnień iOS, takich jak czas ekranowy, powiadomienia, kamera, Aktywności na żywo i dostęp do sieci. Apple, ustawienia urządzenia, zachowanie systemu operacyjnego, łączność i dostępność serwera mogą wpływać na prawidłowe działanie funkcji.

        Treści generowane przez AI: podsumowania postępów mogą być generowane przez systemy automatyczne. Służą wyłącznie do refleksji i wsparcia produktywności. Oceniaj je na podstawie własnego osądu, zanim będziesz na nich polegać.

        Usunięcie konta i zakończenie: możesz poprosić o usunięcie konta w sekcji Profil. Spike AI może zawiesić lub zakończyć dostęp, jeśli wymagają tego przepisy prawa, zasady platformy, względy bezpieczeństwa lub poważne nadużycia.

        Zmiany: Spike AI może aktualizować niniejszy Regulamin w miarę rozwoju aplikacji. Dalsze korzystanie po aktualizacji oznacza akceptację zaktualizowanego Regulaminu.

        Kontakt: w sprawie pytań dotyczących niniejszego Regulaminu skontaktuj się ze wsparciem Spike AI za pośrednictwem kanału wsparcia dostępnego w aplikacji lub na stronie App Store.
        """,

        // Focus Mode
        "focus_title": "Skupienie", "select_mode": "Wybierz tryb",
        "chill": "Spokój", "focus": "Skupienie", "lock_in": "Blokada", "sweat": "Sportowiec",
        "gentle_nudges": "Delikatne przypomnienia", "confirm_intent": "Potwierdź zamiar",
        "no_bypass": "Bez obejścia", "move_to_unlock": "Ruszaj się, aby odblokować",
        "activate_focus": "Włącz tryb skupienia",
        "deactivate_focus": "Wyłącz tryb skupienia",
        "mode_active": "Tryb aktywny",
        "reminders_scheduled": "Przypomnienia zaplanowane",
        "apps_prompt_active": "aplikacja(-e) — monit „Jesteś pewien?” aktywny",
        "apps_blocked": "aplikacja(-e) zablokowana(-e)",
        "temp_access_active": "Tymczasowy dostęp aktywny",
        "apps_require_movement": "aplikacja(-e) wymagają ruchu do odblokowania",
        "notifications_label": "Powiadomienia",
        "notifications_enabled": "Powiadomienia włączone",
        "notifications_denied": "Powiadomienia odrzucone",
        "enable_notif_settings": "Włącz powiadomienia w Ustawieniach.",
        "allow_notif_desc": "Zezwól na powiadomienia, aby Spike AI mógł wysyłać Ci przypomnienia o skupieniu.",
        "enable_notifications": "Włącz powiadomienia",
        "screen_time_access": "Dostęp do czasu ekranowego",
        "screen_time_authorized": "Czas ekranowy autoryzowany",
        "allow_screen_time": "Zezwól na czas ekranowy",
        "tap_to_allow": "Stuknij poniżej, aby zezwolić na dostęp do czasu ekranowego.",
        "open_settings_manual": "Lub otwórz Ustawienia, aby włączyć ręcznie",
        "open_settings": "Otwórz Ustawienia",
        "app_selection": "Wybór aplikacji",
        "selections": "wybrano",
        "choose_apps_confirm": "Wybierz aplikacje, przed otwarciem których wymagane jest potwierdzenie.",
        "choose_apps_block": "Wybierz aplikacje do zablokowania.",
        "choose_apps_movement": "Wybierz aplikacje, które odblokujesz ruchem.",
        "change_selection": "Zmień wybór",
        "select_apps": "Wybierz aplikacje",
        "movement_unlock": "Odblokowanie ruchem",
        "movement_desc": "Pompki i przysiady są śledzone za pomocą wykrywania ciała przez AI. Każde zweryfikowane powtórzenie dodaje 1 minutę dostępu do wybranych aplikacji.",
        "access_available": "Dostęp dostępny na %@",
        "open_camera": "Otwórz sprawdzanie kamerą",
        "lock_in_mode": "Tryb blokady",
        "lock_in_warning": "Aplikacje pokazują czerwony ekran bez obejścia. Musisz wrócić tutaj, aby wyłączyć tryb blokady.",
        "sweat_mode": "Tryb Sportowca",
        "do_exercises": "Rób pompki lub przysiady, aby zdobyć czas",
        "add_minutes": "Dodaj %d minut(ę/y)",
        "keep_in_view": "Trzymaj ramiona, ręce lub biodra w polu widzenia kamery",
        "camera_required": "Do sprawdzania ruchu wymagany jest dostęp do kamery.",
        "camera_disabled": "Dostęp do kamery jest wyłączony. Włącz go w Ustawieniach, aby korzystać z trybu Pot.",
        "camera_unavailable": "Dostęp do kamery jest niedostępny.",
        "starting_camera": "Uruchamianie kamery...",
        "camera_active": "Kamera aktywna",
        "allow_camera": "Zezwól na dostęp do kamery",
        "focus_mode_title": "Tryb skupienia",
        "focus_mode_desc": "Przejmij kontrolę nad swoimi cyfrowymi nawykami dzięki przemyślanym, profesjonalnym trybom.",
        "about_permissions": "O uprawnieniach",
        "permissions_desc": "Tryb Spokój wymaga uprawnień do powiadomień. Tryby Skupienie, Blokada i Pot wymagają autoryzacji czasu ekranowego. Tryb Pot korzysta również z kamery do sprawdzania ruchu.",
        "get_started": "Zacznij", "skip": "Pomiń",
        "unlocked_for": "Odblokowano na %@",

        // Chill mode descriptions
        "chill_desc": "Codzienne przypomnienia przez powiadomienia. Bez kontroli aplikacji — tylko delikatne podpowiedzi, aby zachować świadomość.",
        "focus_desc": "Gdy otwierasz wybraną aplikację, Spike AI pyta: „Jesteś pewien?” Możesz ją otworzyć normalnie lub wrócić do zadań. Aplikacje nie są blokowane.",
        "lock_in_desc": "Wybrane aplikacje są zablokowane, gdy tryb blokady jest aktywny. Możesz go wyłączyć z poziomu Spike AI.",
        "sweat_desc": "Wybrane aplikacje pozostają zablokowane, dopóki nie wykonasz pompki lub przysiadu sprawdzonego kamerą. Każde zweryfikowane powtórzenie odblokowuje 1 minutę.",

        // Motivational (deactivation)
        "giving_up_title": "Robisz postępy — nie przestawaj",
        "giving_up_msg": "Masz jeszcze nieukończone cele na dziś. Każde ukończone zadanie buduje rozpęd. Bądź wytrwały — Twoje przyszłe ja Ci podziękuje.",
        "giving_up_continue": "Zachowaj skupienie",
        "giving_up_stop": "Wyłącz mimo wszystko",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Twój osobisty system produktywności",
        "start_setup": "Rozpocznij konfigurację",
        "make_phone_work": "Niech Twój telefon pracuje\nna Twoje cele.",
        "onboarding_welcome_desc": "Ogranicz bezcelowe przewijanie, chroń czas skupienia i zamień realne zadania w widoczny postęp.",
        "did_you_know": "Czy wiesz?",
        "did_you_know_subtitle": "Przeciętna osoba spędza 7 godzin dziennie z telefonem. To",
        "hours_per_day": "godzin dziennie",
        "days_per_month": "dni w miesiącu",
        "days_per_year": "dni w roku",
        "years_of_life": "lat Twojego życia",
        "screen_time_reality": "A niektórzy spędzają jeszcze więcej.",
        "dont_worry_title": "Nie martw się",
        "spike_has_your_back": "Spike AI Cię wesprze",
        "solution_desc": "Pomożemy Ci zmaksymalizować produktywność, zbliżyć się do celów i wyrobić nawyki, które przemienią Cię w najlepszą wersję siebie.",
        "screen_time_access_title": "Dostęp do czasu ekranowego",
        "grant_access": "Udziel dostępu",
        "which_apps": "Wybierz swoje\nrozpraszające aplikacje",
        "choose_apps_protect": "Wybierz aplikacje, które marnują Twój czas. Zablokujemy je podczas trybów skupienia.",
        "apple_screen_time_required": "Apple wymaga dostępu do czasu ekranowego, zanim Spike AI będzie mógł pokazać listę aplikacji.",
        "save_apps": "Zapisz i kontynuuj",
        "change_selected_apps": "Zmień wybrane aplikacje",
        "ready_change_life": "Gotowy zmienić\nswoje życie?",
        "ready_change_desc": "Utwórz konto, aby zapisać swoje wybory i rozpocząć drogę.",
        "benefit_no_distraction": "Rozpraszające aplikacje nie będą Ci już przeszkadzać",
        "benefit_discover_modes": "Odkryj 4 różne typy trybów skupienia",
        "benefit_track_progress": "Śledź postępy i zbliżaj się do celów",
        "create_account": "Utwórz konto",
        "protect_focus": "Chroń skupienie",
        "block_feeds": "Blokuj kanały",
        "finish_tasks": "Kończ zadania",
        "energy_plus_three": "+3 Energia",
        "selected_count": "%d wybranych",
        "no_apps_selected": "Nie wybrano jeszcze aplikacji",
        "saved_for_modes": "Zapisano dla trybów ochrony",
        "select_apps_to_control": "Wybierz aplikacje, które chcesz kontrolować",
        "clean_room": "Sprzątanie pokoju",
        "snap_proof": "Zrób zdjęcie dowodu po ukończeniu",
        "ai_verifies_task": "AI weryfikuje zadanie",
        "energy_earned": "+3 Energia zdobyta",
        "on_track": "Zgodnie z planem",
        "energy": "Energia",
        "tasks_completed": "Zadań ukończonych",
        "focus_protected": "Skupienie chronione",
        "scrolling_avoided": "Uniknięto przewijania",
        "continue_apple": "Kontynuuj z Apple",
        "continue_google": "Kontynuuj z Google",
        "continue_email": "Kontynuuj przez e-mail",
        "enter_email": "Wpisz swój e-mail",
        "send_sign_in_link": "Wyślemy Ci link do logowania",
        "check_email": "Sprawdź e-mail",
        "sent_link_to": "Wysłaliśmy link do logowania na",
        "tap_link": "Stuknij link, aby zalogować się automatycznie.",
        "open_mail": "Otwórz aplikację pocztową",
        "open_with": "Otwórz za pomocą",
        "didnt_get_email": "Nie otrzymałeś e-maila?",
        "resend": "Wyślij ponownie",
        "resend_in": "Ponowne wysłanie za %ds",
        "new_link_sent": "Nowy link został wysłany!",
        "valid_email": "Wprowadź prawidłowy adres e-mail.",
        "by_continuing": "Kontynuując, zgadzasz się z",
        "and_word": "i",

        // Screen Time Onboarding
        "screen_time_title": "Czas ekranowy",
        "screen_time_permission_desc": "Spike AI potrzebuje uprawnienia czasu ekranowego dla trybów Skupienie, Blokada i Pot. Umożliwia to wyświetlanie monitów i blokad dla wybranych aplikacji.",
        "screen_time_denied": "Uprawnienie zostało odrzucone. Możesz je włączyć w Ustawieniach.",
        "ask_before_opening": "Pytaj przed otwarciem",
        "block_apps_completely": "Całkowicie blokuj aplikacje",
        "stay_accountable": "Zachowaj odpowiedzialność",
        "stay_accountable_desc": "Śledź postępy i trzymaj nawyki skupienia na widoku.",
        "skip_for_now": "Pomiń na razie",

        // Live Activity
        "daily_goals_title": "Dzienne cele",
        "of_done": "z %d ukończono",
        "more_to_go": "jeszcze %d do zrobienia",

        // Chill morning
        "good_morning": "Dzień dobry! Bądź dziś świadomy. Przejrzyj swoje zadania i zachowaj skupienie.",

        // General
        "error": "Błąd", "ok": "OK", "yes": "Tak", "no": "Nie",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Przejść do Trybu Relaksu?",
        "stay_focused_btn": "Zostań skupiony",
        "switch_anyway_btn": "Przełącz mimo to",
        "switch_to_chill_msg": "Masz jeszcze nieukończone cele. Przejście do Trybu Relaksu usuwa blokadę aplikacji, co zwiększa ryzyko nieukończenia celów na dziś.",
        "task_notification": "Powiadomienie o zadaniu",
        "missed_alarm": "Pominięty alarm",
        "quote_of_day": "Cytat dnia",
        "new_quotes_daily": "Nowe cytaty pojawiają się codziennie o 5:00",
        "focus_day_label": "Dzień skupienia",
        "missed_label": "Pominięty",
        "access_granted": "Dostęp przyznany",
        "goal_reminder": "Przypomnienie o celu",
        "spike_ai_focus": "Spike AI Skupienie",
        "goals_required_title": "Wymagane cele",
        "goals_required_desc_focus": "Tryb skupienia blokuje wybrane aplikacje tylko wtedy, gdy masz nieukończone cele. Dodaj cele w zakładce Start, aby aktywować blokowanie aplikacji.",
        "goals_required_desc_lockin": "Tryb blokady blokuje wybrane aplikacje tylko wtedy, gdy masz nieukończone cele. Dodaj cele w zakładce Start, aby aktywować blokowanie aplikacji.",
        "save": "Zapisz",
        "no_goals_reminder_body": "Nie wyznaczyłeś żadnych celów na dziś. Poświęć chwilę na zaplanowanie dnia!",
        "dont_forget": "Nie zapomnij",
        "chill_morning_body": "Dzień dobry! Bądź dziś świadomy swoich działań. Przejrzyj zadania i zachowaj skupienie.",
        "every_day": "Codziennie",
        "weekdays": "Dni robocze",
        "weekends": "Weekendy",
        "time_to_focus": "Czas na skupienie!",

        // Additional UI strings
        "next_quote_in": "Następny cytat za %@",
        "enable_notif_chill": "Włącz powiadomienia przed uruchomieniem trybu Relaks.",
        "enable_screen_time_mode": "Włącz dostęp do Czasu przed ekranem przed uruchomieniem tego trybu.",
        "select_app_before_mode": "Wybierz co najmniej jedną aplikację, kategorię lub stronę przed uruchomieniem tego trybu.",
        "mode_not_ready": "Ten tryb nie jest jeszcze gotowy do uruchomienia.",
        "protection_stopped_no_apps": "Ochrona zatrzymana: nie wybrano żadnych aplikacji.",
        "protection_stopped_screen_time": "Ochrona zatrzymana: zmieniono dostęp do Czasu przed ekranem.",
        "max_reminders": "Możesz utworzyć maksymalnie %d przypomnień o skupieniu.",
        "front_camera_unavailable": "Przedni aparat jest niedostępny.",
        "task_title_empty": "Tytuł zadania nie może być pusty.",
        "goal_title_empty": "Tytuł celu nie może być pusty.",
        "rate_limit_wait": "Poczekaj %d sekund przed wygenerowaniem kolejnego podsumowania.",
        "missed_alarm_for": "Przegapiłeś alarm: %@",
        "stay_with_plan": "Trzymaj się planu.",
        "motivation_small_wins": "Małe zwycięstwa się kumulują.",
        "motivation_next_step": "Wykonaj następny krok.",
        "motivation_protect_hour": "Chroń godzinę przed sobą.",
        "motivation_consistency": "Regularność wygrywa z intensywnością.",
        "monthly_scope_btn": "Miesięczny",
        "yearly_scope_btn": "Roczny",
        "restoring_session": "Przywracanie sesji...",

        // Milestones
        "milestone_3day_streak": "Seria 3 dni",
        "milestone_3day_desc": "Stabilny rytm się zaczął.",
        "milestone_7day_streak": "Seria 7 dni",
        "milestone_7day_desc": "Pełny skupiony tydzień.",
        "milestone_10h_protected": "10 godzin chronionych",
        "milestone_10h_desc": "Czas chroniony dla ważnych rzeczy.",
        "milestone_30_focus": "30 dni skupienia",
        "milestone_30_desc": "Konsekwencja z prawdziwą wagą.",

        // Narratives
        "narrative_improved": "Twój czas ekranowy poprawił się w porównaniu z zeszłym tygodniem.",
        "narrative_consistent": "Byłeś konsekwentny w tym tygodniu i chroniłeś swoje skupienie.",
        "narrative_more_days": "Ukończyłeś więcej dni skupienia niż zwykle.",
        "narrative_building": "Budujesz rytm jeden skupiony dzień po drugim.",

        // Screen time
        "screen_time_trend_pending": "Trend czasu ekranowego pojawi się gdy historia użytkowania wzrośnie.",
        "screen_time_improved": "Czas ekranowy poprawił się o %d%%",
        "screen_time_higher": "Czas ekranowy jest nieco wyższy niż zwykle",
        "screen_time_steady": "Czas ekranowy jest stabilny w tym tygodniu",

        // Benchmarks
        "benchmark_pending": "Średni czas ekranowy pojawi się gdy aplikacja zarejestruje historię użytkowania. Globalny punkt odniesienia to około 7 godzin dziennie.",
        "benchmark_below": "Twoja 7-dniowa średnia to %@, poniżej globalnej średniej 7 godzin. To dobry kierunek.",
        "benchmark_above": "Twoja 7-dniowa średnia to %@, powyżej globalnej średniej 7 godzin. Mała redukcja dziś może zmienić trend.",
        "benchmark_matching": "Twoja 7-dniowa średnia to %@, równa globalnej średniej 7 godzin.",

        // Task editing
        "edit_task": "Edytuj zadanie",
        "task_name_placeholder": "Nazwa zadania",
        "task_reminder_default": "Przypomnienie o zadaniu",
        "time_h_m": "%dg %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Ukrainian
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let uk: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Про режими фокусування",
        "no_active_goals_title": "Немає активних цілей",
        "no_active_goals_btn": "Зрозуміло",
        "no_active_goals_msg": "Режими «Фокус» і «Блокування» працюють лише поки у вас є незавершена ціль. Додайте ціль — або активуйте її знову — а потім почніть сесію.",
        // Tab bar
        "tab_home": "Головна", "tab_progress": "Прогрес", "tab_mode": "Режим", "tab_profile": "Профіль",

        // Home
        "today": "Сьогодні", "tomorrow": "Завтра", "yesterday": "Вчора",
        "back_to_today": "Повернутись до сьогодні",
        "add_first_task": "Натисніть +, щоб додати перше завдання",
        "no_tasks_this_day": "На цей день завдань немає",
        "new_task": "Нове завдання",
        "what_to_do": "Що вам потрібно зробити?",
        "task": "Завдання", "schedule": "Розклад",
        "pick_date_hint": "Виберіть будь-яку дату — сьогодні, наступного тижня або за кілька місяців.",
        "priority": "Пріоритет", "low": "Низький", "medium": "Середній", "high": "Високий",
        "notification": "Сповіщення",
        "silent_push": "Беззвучне push-сповіщення",
        "notification_desc": "Надсилає одноразове push-сповіщення у запланований час. Воно з'явиться на екрані блокування та в Центрі сповіщень.",
        "reminder": "Нагадування",
        "alarm_sound": "Будильник зі звуком і вібрацією",
        "reminder_desc": "Працює як будильник — прозвучить спеціальний сигнал, і телефон вібруватиме, поки ви не натиснете кнопку «Відхилити». Чудово підходить для зустрічей та дедлайнів.",
        "cancel": "Скасувати", "add": "Додати", "edit": "Редагувати", "delete": "Видалити",
        "jump_to_date": "Перейти до дати", "done": "Готово",
        "task_limit": "Ви досягли ліміту в 25 завдань на цю дату.",
        "time": "Час", "date": "Дата", "select_date": "Вибрати дату",

        // Alarm
        "reminder_title": "Нагадування", "dismiss": "Відхилити",

        // Progress
        "daily_progress": "Денний прогрес", "streaks": "серії", "focus_days": "дні фокусу",
        "consistency": "стабільність",
        "set_first_goal": "Встановіть свою першу ціль на сьогодні",
        "all_goals_completed": "Усі денні цілі виконано",
        "goals_completed": "з",
        "daily_goals_completed": "денних цілей виконано",
        "daily_goals": "Денні цілі", "remaining": "залишилось",
        "no_goals_planned": "Цілей не заплановано",
        "complete_to_focus": "Виконайте всі завдання, щоб позначити сьогодні як день фокусу.",
        "add_task_to_start": "Додайте завдання з головного екрана, щоб почати відстеження денних цілей.",
        "daily_plan_complete": "Денний план виконано",
        "ai_weekly_summary": "Тижневий звіт ШІ",
        "creating_summary": "Формується ваш тижневий звіт...",
        "generate_summary": "Сформувати звіт",
        "refresh_summary": "Оновити звіт",
        "first_summary_coming": "Ваш перший тижневий звіт ШІ вже в дорозі.",
        "first_summary_desc": "Він буде готовий %@ о 21:00. Він містить висновки про ваш прогрес, пропущені завдання та найкращий режим фокусу для вас.",
        "next_update": "Наступне оновлення: %@",
        "weekly_recap": "Ваш тижневий огляд днів фокусу, завдань та тенденцій продуктивності готовий.",
        "screen_time_7day": "Екранний час за 7 днів",
        "best_streak": "Найкраща серія", "days": "днів",
        "milestones": "Досягнення", "milestone_unlocked": "Досягнення розблоковано",
        "continue_btn": "Продовжити",
        "history_calendar": "Календар історії",
        "mode_used": "Використаний режим",
        "completed": "Виконано", "not_completed": "Не виконано",
        "no_completed_tasks": "За цей день немає записів про виконані завдання.",
        "everything_completed": "Все було виконано.",
        "no_missed_tasks": "За цей день немає записів про пропущені завдання.",
        "streak_day": "День серії", "missed_day": "Пропущений день",
        "first_name": "Ім'я", "last_name": "Прізвище",
        "avatar_color": "Колір аватара",
        "whats_your_name": "Як вас звати?",
        "name_helps": "Це допоможе персоналізувати ваш досвід.",
        "name_save_failed": "Не вдалося зберегти ваше ім'я. Перевірте з'єднання та спробуйте ще раз.",
        "continue_btn_name": "Продовжити",
        "wins": "Перемоги", "next_action": "Наступна дія",
        "average": "в середньому",
        "todays_completion": "Виконання за сьогодні",
        "streaks_this_month": "серій цього місяця",
        "streak_days": "днів серії", "non_streak_days": "днів без серії",
        "monthly_streak_summary": "%d серій цього місяця • %d днів серії, %d днів без серії",
        "duration_average": "%@ в середньому",

        // Profile
        "personal_details": "Особисті дані",
        "personal_info": "Особиста інформація",
        "update_email_name": "Оновіть адресу електронної пошти та повне ім'я.",
        "and_username": "та ім'я користувача",
        "invite_friends": "Запросити друзів",
        "refer_friend_title": "Запросіть друга та отримайте $10",
        "refer_friend_desc": "Отримуйте $10 за кожного друга, який зареєструється за вашим промокодом.",
        "upgrade_family_plan": "Перейти на сімейний план",
        "goals_tracking": "Цілі та відстеження",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Редагувати цілі харчування",
        "tracking_reminders": "Нагадування про відстеження",
        "email_not_editable": "Ваша електронна пошта пов'язана з обліковим записом і не може бути змінена тут.",
        "theme": "Тема",
        "theme_desc": "Використовуйте системне оформлення або виберіть постійний світлий/темний режим.",
        "appearance": "Оформлення",
        "appearance_desc": "Виберіть світле, темне або системне оформлення",
        "live_activity_profile_desc": "Показувати денний прогрес на екрані блокування та Dynamic Island",
        "system": "Системна", "light": "Світла", "dark": "Темна",
        "live_activity": "Жива активність",
        "live_activity_desc": "Показувати цілі, серію та мотивацію на екрані блокування.",
        "privacy_policy": "Політика конфіденційності",
        "privacy_desc": "Дізнайтеся, як використовуються дані додатку та дозволи пристрою.",
        "terms_of_service": "Умови використання",
        "terms_desc": "Ознайомтеся з правилами використання додатку та його інструментів фокусу.",
        "follow_us": "Підписуйтесь",
        "sign_out": "Вийти",
        "sign_out_desc": "Завершити сеанс на поточному пристрої.",
        "delete_account": "Видалити обліковий запис",
        "delete_account_desc": "Безповоротно видалити ваш обліковий запис та синхронізовані дані додатку.",
        "delete_account_title": "Видалити обліковий запис",
        "delete_account_msg": "Ця дія є безповоротною. Усі ваші дані буде видалено без можливості відновлення.",
        "delete_account_continue": "Продовжити",
        "delete_account_final_title": "Видалити назавжди?",
        "delete_account_final_msg": "Будь ласка, підтвердіть ще раз. Якщо ви видалите обліковий запис, Spike AI завершить ваш сеанс і поверне вас на сторінку входу.",
        "deleting_account": "Видалення облікового запису...",
        "delete_failed": "Не вдалося видалити обліковий запис. Спробуйте ще раз або зверніться до служби підтримки.",
        "language": "Мова",
        "language_desc": "Оберіть мову для всього вмісту додатку.",
        "set_name": "Вкажіть ваше ім'я",
        "profile_name_prompt": "Як до вас звертатися?",
        "profile_name_desc": "Вкажіть ім'я, яке Spike AI використовуватиме у вашому профілі та для персоналізації.",
        "full_name": "Повне ім'я",
        "display_name": "Відображуване ім'я",
        "email": "Електронна пошта",
        "save_changes": "Зберегти зміни",
        "save_footer": "Зміни зберігаються у вашому профілі та використовуються всюди, де в додатку відображається ваша особа.",
        "signed_in": "Вхід виконано",
        "account": "Обліковий запис", "preferences": "Налаштування",
        "support_legal": "Підтримка та правова інформація",
        "account_actions": "Дії з обліковим записом",
        "pref_show_completed": "Показувати виконані завдання",
        "pref_show_completed_desc": "Залишати виконані завдання видимими у денному списку.",
        "pref_quotes": "Мотиваційні цитати",
        "pref_quotes_desc": "Показувати надихаючу цитату на екрані прогресу.",
        "legal_updated": "Останнє оновлення: 25 травня 2026 р.",
        "privacy_body": """
        Останнє оновлення: 25 травня 2026 р.

        Spike AI — додаток для продуктивності та фокусування. Ця Політика конфіденційності пояснює, як Spike AI обробляє інформацію, що використовується для надання облікових записів, планування завдань, нагадувань, режимів фокусу, керування екранним часом, відстеження прогресу та формування ШІ-звітів про продуктивність.

        Інформація, яку ми збираємо: ідентифікатори облікового запису, такі як адреса електронної пошти та ідентифікатор користувача; дані профілю, які ви вирішите надати, такі як відображуване ім'я та повне ім'я; завдання, цілі, нагадування, історія виконання, налаштування режимів фокусу, токени вибору додатків та метрики прогресу. Ми також можемо зберігати технічні записи, необхідні для забезпечення надійності та безпеки сервісу.

        Екранний час і вибір додатків: вибір додатків, категорій та веб-доменів здійснюється через фреймворки Apple FamilyControls та ManagedSettings. Spike AI зберігає токени, надані Apple, для застосування вибраних вами режимів фокусу. Ми не використовуємо ці дані для реклами.

        Використання камери в режимі «Піт»: доступ до камери використовується для перевірки положення тіла на пристрої, щоб ви могли отримати тимчасовий доступ до додатків через рух. Spike AI не завантажує відеокадри для цієї функції та не використовує дані камери в рекламних цілях.

        Сповіщення та нагадування: Spike AI використовує дозвіл на сповіщення для надсилання нагадувань про завдання, будильників та підказок фокусу, які ви налаштовуєте. Ви можете змінити доступ до сповіщень у налаштуваннях iOS будь-коли.

        ШІ-звіти: якщо ви формуєте звіт про прогрес, дані про останні завдання, цілі, режими фокусу та метрики продуктивності можуть оброблятися серверною частиною Spike AI для створення звіту. Не вводьте конфіденційну інформацію в назви завдань або цілей, якщо не хочете, щоб вона оброблялася для функцій продуктивності.

        Як ми використовуємо інформацію: для автентифікації, синхронізації вашого облікового запису, надання інструментів фокусу, планування нагадувань, відображення прогресу, персоналізації аналітики продуктивності, захисту від зловживань, усунення неполадок та дотримання правових зобов'язань. Spike AI не продає вашу персональну інформацію.

        Видалення даних: ви можете вийти з системи або запросити безповоротне видалення облікового запису в розділі «Профіль». При видаленні облікового запису видаляється ваш обліковий запис автентифікації та синхронізовані дані додатку, за винятком обмеженого зберігання, необхідного для безпеки, запобігання шахрайству, вирішення спорів або дотримання законодавства.

        Ваш вибір: ви можете редагувати дані профілю, змінювати мовні та оформлювальні налаштування, вимикати живу активність, відкликати дозволи пристрою в налаштуваннях, припиняти використання певних режимів фокусу або видалити свій обліковий запис.

        Контакт: з питань конфіденційності або видалення облікового запису зверніться до служби підтримки Spike AI через канал підтримки, зазначений у додатку або на сторінці App Store.
        """,
        "terms_body": """
        Останнє оновлення: 25 травня 2026 р.

        Ці Умови використання регулюють ваше використання Spike AI, включаючи завдання, нагадування, режими фокусу, підказки та екрани блокування додатків через екранний час, перевірки руху в режимі «Піт», відстеження прогресу та ШІ-звіти.

        Право доступу та обліковий запис: ви несете відповідальність за створений обліковий запис та за збереження доступу до вашої електронної пошти та пристрою. Вказуйте точну інформацію там, де додаток запитує дані профілю.

        Призначення для продуктивності: Spike AI створено для підтримки особистої продуктивності та усвідомленого використання пристрою. Це не медична, психологічна, екстрена, захисна служба, служба батьківського контролю, моніторингу зайнятості або управління пристроєм. Не покладайтеся на Spike AI в ситуаціях, де збій нагадування, блокування, підказки, перевірки камерою, сповіщення, мережевого запиту або дозволу Apple може завдати шкоди.

        Ваші обов'язки: обирайте налаштування фокусу, що відповідають вашій ситуації; перевіряйте вибір додатків перед активацією режиму; вимикайте режими, коли вони більше не відповідають вашим потребам; дотримуйтесь чинного законодавства та умов платформи Apple; не вводьте конфіденційну інформацію в завдання або цілі, якщо вам некомфортно використовувати її в додатку.

        Допустиме використання: не зловживайте Spike AI, не втручайтеся в роботу пристрою або облікового запису іншого користувача, не намагайтеся обійти захист або обмеження платформи, не здійснюйте зворотну інженерію захищених частин сервісу, не перевантажуйте серверну частину та не використовуйте додаток для незаконної, образливої, оманливої або шкідливої діяльності.

        Дозволи та доступність: для деяких функцій потрібні дозволи iOS, такі як екранний час, сповіщення, камера, живі активності та мережевий доступ. Apple, налаштування пристрою, поведінка операційної системи, з'єднання та доступність серверної частини можуть впливати на коректну роботу функцій.

        Контент, створений ШІ: звіти про прогрес можуть формуватися автоматизованими системами. Вони призначені виключно для самоаналізу та підвищення продуктивності. Оцінюйте їх на основі власного судження, перш ніж на них покладатися.

        Видалення облікового запису та припинення доступу: ви можете запросити видалення облікового запису в розділі «Профіль». Spike AI може призупинити або припинити доступ, якщо це вимагається за законом, правилами платформи, міркуваннями безпеки або у випадку серйозних зловживань.

        Зміни: Spike AI може оновлювати ці Умови в міру розвитку додатку. Продовження використання після оновлення означає вашу згоду з оновленими Умовами.

        Контакт: з питань щодо цих Умов зверніться до служби підтримки Spike AI через канал підтримки, зазначений у додатку або на сторінці App Store.
        """,

        // Focus Mode
        "focus_title": "Фокус", "select_mode": "Обрати режим",
        "chill": "Легкий", "focus": "Фокус", "lock_in": "Блокування", "sweat": "Атлет",
        "gentle_nudges": "М'які нагадування", "confirm_intent": "Підтвердити намір",
        "no_bypass": "Без обходу", "move_to_unlock": "Рухайтеся для розблокування",
        "activate_focus": "Увімкнути режим фокусу",
        "deactivate_focus": "Вимкнути режим фокусу",
        "mode_active": "Режим активний",
        "reminders_scheduled": "Нагадування заплановано",
        "apps_prompt_active": "додаток(-ки) — запит «Ви впевнені?» активний",
        "apps_blocked": "додаток(-ки) заблоковано",
        "temp_access_active": "Тимчасовий доступ активний",
        "apps_require_movement": "додаток(-ки) потребують руху для розблокування",
        "notifications_label": "Сповіщення",
        "notifications_enabled": "Сповіщення увімкнено",
        "notifications_denied": "Сповіщення відхилено",
        "enable_notif_settings": "Увімкніть сповіщення в налаштуваннях.",
        "allow_notif_desc": "Дозвольте сповіщення, щоб Spike AI міг надсилати вам нагадування про фокус.",
        "enable_notifications": "Увімкнути сповіщення",
        "screen_time_access": "Доступ до екранного часу",
        "screen_time_authorized": "Екранний час дозволено",
        "allow_screen_time": "Дозволити екранний час",
        "tap_to_allow": "Натисніть нижче, щоб дозволити доступ до екранного часу.",
        "open_settings_manual": "Або відкрийте Налаштування для увімкнення вручну",
        "open_settings": "Відкрити налаштування",
        "app_selection": "Вибір додатків",
        "selections": "вибрано",
        "choose_apps_confirm": "Виберіть додатки, перед відкриттям яких потрібне підтвердження.",
        "choose_apps_block": "Виберіть додатки для блокування.",
        "choose_apps_movement": "Виберіть додатки, які розблокуються рухом.",
        "change_selection": "Змінити вибір",
        "select_apps": "Вибрати додатки",
        "movement_unlock": "Розблокування рухом",
        "movement_desc": "Віджимання та присідання відстежуються за допомогою ШІ-розпізнавання тіла. Кожне підтверджене повторення додає 1 хвилину доступу до вибраних додатків.",
        "access_available": "Доступ доступний на %@",
        "open_camera": "Відкрити перевірку камерою",
        "lock_in_mode": "Режим блокування",
        "lock_in_warning": "Додатки показують червоний екран без обходу. Ви маєте повернутися сюди, щоб вимкнути режим блокування.",
        "sweat_mode": "Режим «Атлет»",
        "do_exercises": "Робіть віджимання або присідання, щоб заробити час",
        "add_minutes": "Додати %d хвилин(у/и)",
        "keep_in_view": "Тримайте плечі, руки або стегна в полі зору камери",
        "camera_required": "Для перевірки руху потрібен доступ до камери.",
        "camera_disabled": "Доступ до камери вимкнено. Увімкніть його в налаштуваннях для використання режиму «Піт».",
        "camera_unavailable": "Доступ до камери недоступний.",
        "starting_camera": "Запуск камери...",
        "camera_active": "Камера активна",
        "allow_camera": "Дозволити доступ до камери",
        "focus_mode_title": "Режим фокусу",
        "focus_mode_desc": "Візьміть під контроль свої цифрові звички за допомогою продуманих професійних режимів.",
        "about_permissions": "Про дозволи",
        "permissions_desc": "Для режиму «Легкий» потрібні сповіщення. Для режимів «Фокус», «Блокування» та «Піт» потрібен дозвіл екранного часу. Режим «Піт» також використовує камеру для перевірки руху.",
        "get_started": "Почати", "skip": "Пропустити",
        "unlocked_for": "Розблоковано на %@",

        // Chill mode descriptions
        "chill_desc": "Щоденні нагадування через сповіщення. Без контролю додатків — лише м'які підказки для усвідомленості.",
        "focus_desc": "При відкритті вибраного додатку Spike AI запитає: «Ви впевнені?» Ви можете відкрити його як зазвичай або повернутися до завдань. Додатки не блокуються.",
        "lock_in_desc": "Вибрані додатки заблоковані, поки режим блокування активний. Ви можете вимкнути його з Spike AI.",
        "sweat_desc": "Вибрані додатки залишаються заблокованими, поки ви не виконаєте віджимання або присідання з перевіркою камерою. Кожне підтверджене повторення розблоковує 1 хвилину.",

        // Motivational (deactivation)
        "giving_up_title": "Ви прогресуєте — не зупиняйтеся",
        "giving_up_msg": "У вас ще є невиконані цілі на сьогодні. Кожне завершене завдання створює імпульс. Залишайтеся відданими цілі — ваше майбутнє «я» подякує вам.",
        "giving_up_continue": "Залишитися у фокусі",
        "giving_up_stop": "Все одно вимкнути",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Ваша персональна система продуктивності",
        "start_setup": "Почати налаштування",
        "make_phone_work": "Нехай ваш телефон працює\nна ваші цілі.",
        "onboarding_welcome_desc": "Зменшіть бездумну прокрутку, захистіть час фокусу та перетворіть реальні завдання на видимий прогрес.",
        "did_you_know": "Чи знали ви?",
        "did_you_know_subtitle": "В середньому людина проводить 7 годин на день у телефоні. Це",
        "hours_per_day": "годин на день",
        "days_per_month": "днів на місяць",
        "days_per_year": "днів на рік",
        "years_of_life": "років вашого життя",
        "screen_time_reality": "А деякі проводять ще більше.",
        "dont_worry_title": "Не хвилюйтеся",
        "spike_has_your_back": "Spike AI підтримає вас",
        "solution_desc": "Ми допоможемо вам максимізувати продуктивність, наблизитися до цілей та виробити звички, які перетворять вас на кращу версію себе.",
        "screen_time_access_title": "Доступ до екранного часу",
        "grant_access": "Надати доступ",
        "which_apps": "Виберіть ваші\nвідволікаючі додатки",
        "choose_apps_protect": "Виберіть додатки, які витрачають ваш час. Ми заблокуємо їх під час режимів фокусу.",
        "apple_screen_time_required": "Apple вимагає доступ до екранного часу, перш ніж Spike AI зможе показати список додатків.",
        "save_apps": "Зберегти та продовжити",
        "change_selected_apps": "Змінити вибрані додатки",
        "ready_change_life": "Готові змінити\nсвоє життя?",
        "ready_change_desc": "Створіть обліковий запис, щоб зберегти свій вибір та розпочати шлях.",
        "benefit_no_distraction": "Відволікаючі додатки більше не будуть вам заважати",
        "benefit_discover_modes": "Відкрийте 4 різних типи режимів фокусу",
        "benefit_track_progress": "Відстежуйте прогрес та наближайтеся до цілей",
        "create_account": "Створити обліковий запис",
        "protect_focus": "Захистити фокус",
        "block_feeds": "Заблокувати стрічки",
        "finish_tasks": "Завершити завдання",
        "energy_plus_three": "+3 Енергія",
        "selected_count": "%d вибрано",
        "no_apps_selected": "Додатки ще не вибрані",
        "saved_for_modes": "Збережено для режимів захисту",
        "select_apps_to_control": "Виберіть додатки, які хочете контролювати",
        "clean_room": "Прибирання кімнати",
        "snap_proof": "Сфотографуйте результат по завершенні",
        "ai_verifies_task": "ШІ перевіряє завдання",
        "energy_earned": "+3 Енергія отримана",
        "on_track": "За графіком",
        "energy": "Енергія",
        "tasks_completed": "Завдань виконано",
        "focus_protected": "Фокус захищено",
        "scrolling_avoided": "Прокрутку уникнено",
        "continue_apple": "Продовжити з Apple",
        "continue_google": "Продовжити з Google",
        "continue_email": "Продовжити електронною поштою",
        "enter_email": "Введіть вашу пошту",
        "send_sign_in_link": "Ми надішлемо вам посилання для входу",
        "check_email": "Перевірте пошту",
        "sent_link_to": "Ми надіслали посилання для входу на",
        "tap_link": "Натисніть на посилання для автоматичного входу.",
        "open_mail": "Відкрити поштовий додаток",
        "open_with": "Відкрити через",
        "didnt_get_email": "Не отримали листа?",
        "resend": "Надіслати повторно",
        "resend_in": "Повторне надсилання через %ds",
        "new_link_sent": "Нове посилання надіслано!",
        "valid_email": "Введіть дійсну адресу електронної пошти.",
        "by_continuing": "Продовжуючи, ви погоджуєтесь з",
        "and_word": "та",

        // Screen Time Onboarding
        "screen_time_title": "Екранний час",
        "screen_time_permission_desc": "Spike AI потребує дозволу екранного часу для режимів «Фокус», «Блокування» та «Піт». Це дозволяє показувати підказки та блокування для вибраних вами додатків.",
        "screen_time_denied": "Дозвіл було відхилено. Ви можете увімкнути його в налаштуваннях.",
        "ask_before_opening": "Запитувати перед відкриттям",
        "block_apps_completely": "Повністю блокувати додатки",
        "stay_accountable": "Зберігайте відповідальність",
        "stay_accountable_desc": "Відстежуйте прогрес та тримайте свої звички фокусу на увазі.",
        "skip_for_now": "Поки що пропустити",

        // Live Activity
        "daily_goals_title": "Денні цілі",
        "of_done": "з %d виконано",
        "more_to_go": "ще %d залишилося",

        // Chill morning
        "good_morning": "Доброго ранку! Будьте усвідомленими сьогодні. Перегляньте свої завдання та зберігайте фокус.",

        // General
        "error": "Помилка", "ok": "ОК", "yes": "Так", "no": "Ні",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Перейти в Режим Відпочинку?",
        "stay_focused_btn": "Залишитися зосередженим",
        "switch_anyway_btn": "Все одно перейти",
        "switch_to_chill_msg": "У вас ще є незавершені цілі. Перехід у Режим Відпочинку знімає блокування додатків, що збільшує ризик невиконання ваших цілей сьогодні.",
        "task_notification": "Сповіщення про завдання",
        "missed_alarm": "Пропущений будильник",
        "quote_of_day": "Цитата дня",
        "new_quotes_daily": "Нові цитати з'являються щодня о 5:00",
        "focus_day_label": "День фокусу",
        "missed_label": "Пропущено",
        "access_granted": "Доступ надано",
        "goal_reminder": "Нагадування про ціль",
        "spike_ai_focus": "Spike AI Фокус",
        "goals_required_title": "Потрібні цілі",
        "goals_required_desc_focus": "Режим Фокус блокує вибрані додатки лише за наявності незавершених цілей. Додайте цілі на вкладці Головна, щоб активувати блокування додатків.",
        "goals_required_desc_lockin": "Режим Концентрації блокує вибрані додатки лише за наявності незавершених цілей. Додайте цілі на вкладці Головна, щоб активувати блокування додатків.",
        "save": "Зберегти",
        "no_goals_reminder_body": "Ви не встановили жодних цілей на сьогодні. Виділіть хвилинку, щоб спланувати свій день!",
        "dont_forget": "Не забудьте",
        "chill_morning_body": "Доброго ранку! Будьте цілеспрямовані сьогодні. Перегляньте свої завдання та зберігайте зосередженість.",
        "every_day": "Щодня",
        "weekdays": "Будні",
        "weekends": "Вихідні",
        "time_to_focus": "Час зосередитися!",

        // Additional UI strings
        "next_quote_in": "Наступна цитата через %@",
        "enable_notif_chill": "Увімкніть сповіщення перед запуском режиму Відпочинок.",
        "enable_screen_time_mode": "Увімкніть доступ до Екранного часу перед запуском цього режиму.",
        "select_app_before_mode": "Оберіть хоча б один додаток, категорію або сайт перед запуском цього режиму.",
        "mode_not_ready": "Цей режим ще не готовий до запуску.",
        "protection_stopped_no_apps": "Захист зупинено: додатки не обрано.",
        "protection_stopped_screen_time": "Захист зупинено: доступ до Екранного часу змінився.",
        "max_reminders": "Можна створити не більше %d нагадувань про фокус.",
        "front_camera_unavailable": "Фронтальна камера недоступна.",
        "task_title_empty": "Назва завдання не може бути порожньою.",
        "goal_title_empty": "Назва цілі не може бути порожньою.",
        "rate_limit_wait": "Зачекайте %d секунд перед створенням нового звіту.",
        "missed_alarm_for": "Ви пропустили будильник: %@",
        "stay_with_plan": "Дотримуйтесь плану.",
        "motivation_small_wins": "Малі перемоги накопичуються.",
        "motivation_next_step": "Завершіть наступний крок.",
        "motivation_protect_hour": "Захистіть годину попереду.",
        "motivation_consistency": "Сталість перемагає інтенсивність.",
        "monthly_scope_btn": "Місяць",
        "yearly_scope_btn": "Рік",
        "restoring_session": "Відновлення сеансу...",

        // Milestones
        "milestone_3day_streak": "Серія 3 дні",
        "milestone_3day_desc": "Стабільний ритм розпочато.",
        "milestone_7day_streak": "Серія 7 днів",
        "milestone_7day_desc": "Повний сфокусований тиждень.",
        "milestone_10h_protected": "10 годин захищено",
        "milestone_10h_desc": "Час захищено для важливого.",
        "milestone_30_focus": "30 днів фокусу",
        "milestone_30_desc": "Стабільність із реальною вагою.",

        // Narratives
        "narrative_improved": "Ваш екранний час покращився порівняно з минулим тижнем.",
        "narrative_consistent": "Ви були послідовні цього тижня та захистили свій фокус.",
        "narrative_more_days": "Ви завершили більше днів фокусу ніж зазвичай.",
        "narrative_building": "Ви будуєте ритм по одному сфокусованому дню.",

        // Screen time
        "screen_time_trend_pending": "Тенденція екранного часу з'явиться з накопиченням історії використання.",
        "screen_time_improved": "Екранний час покращився на %d%%",
        "screen_time_higher": "Екранний час трохи вищий за звичайний",
        "screen_time_steady": "Екранний час стабільний цього тижня",

        // Benchmarks
        "benchmark_pending": "Середній екранний час з'явиться коли додаток запише історію використання. Глобальний орієнтир — близько 7 годин на день.",
        "benchmark_below": "Ваш 7-денний середній показник — %@, нижче світового середнього в 7 годин. Це сильний напрямок.",
        "benchmark_above": "Ваш 7-денний середній показник — %@, вище світового середнього в 7 годин. Невелике скорочення сьогодні може змінити тенденцію.",
        "benchmark_matching": "Ваш 7-денний середній показник — %@, збігається зі світовим середнім в 7 годин.",

        // Task editing
        "edit_task": "Редагувати завдання",
        "task_name_placeholder": "Назва завдання",
        "task_reminder_default": "Нагадування про завдання",
        "time_h_m": "%dг %dхв",
        "time_m": "%dхв",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Dutch
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let nl: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Over de focusmodi",
        "no_active_goals_title": "Geen actieve doelen",
        "no_active_goals_btn": "Begrepen",
        "no_active_goals_msg": "Focus en Vergrendeling werken alleen zolang je een onvoltooid doel hebt om naartoe te werken. Voeg een doel toe — of activeer er een opnieuw — en start dan je sessie.",
        // Tab bar
        "tab_home": "Start", "tab_progress": "Voortgang", "tab_mode": "Modus", "tab_profile": "Profiel",

        // Home
        "today": "Vandaag", "tomorrow": "Morgen", "yesterday": "Gisteren",
        "back_to_today": "Terug naar vandaag",
        "add_first_task": "Tik op + om je eerste taak toe te voegen",
        "no_tasks_this_day": "Geen taken op deze dag",
        "new_task": "Nieuwe taak",
        "what_to_do": "Wat moet je doen?",
        "task": "Taak", "schedule": "Planning",
        "pick_date_hint": "Kies een datum — vandaag, volgende week of maanden vooruit.",
        "priority": "Prioriteit", "low": "Laag", "medium": "Gemiddeld", "high": "Hoog",
        "notification": "Melding",
        "silent_push": "Stille pushmelding",
        "notification_desc": "Verstuurt een eenmalige pushmelding op het geplande tijdstip. Deze verschijnt discreet op je vergrendelscherm en in het Berichtencentrum.",
        "reminder": "Herinnering",
        "alarm_sound": "Alarm met geluid en trillingen",
        "reminder_desc": "Werkt als een alarm — er klinkt een speciaal geluid en je telefoon trilt totdat je op de knop Negeren drukt. Ideaal voor vergaderingen en deadlines.",
        "cancel": "Annuleren", "add": "Toevoegen", "edit": "Bewerken", "delete": "Verwijderen",
        "jump_to_date": "Ga naar datum", "done": "Klaar",
        "task_limit": "Je hebt de limiet van 25 taken voor deze datum bereikt.",
        "time": "Tijd", "date": "Datum", "select_date": "Selecteer datum",

        // Alarm
        "reminder_title": "Herinnering", "dismiss": "Negeren",

        // Progress
        "daily_progress": "Dagelijkse voortgang", "streaks": "reeksen", "focus_days": "focusdagen",
        "consistency": "consistentie",
        "set_first_goal": "Stel je eerste doel voor vandaag in",
        "all_goals_completed": "Alle dagelijkse doelen behaald",
        "goals_completed": "van",
        "daily_goals_completed": "dagelijkse doelen behaald",
        "daily_goals": "Dagelijkse doelen", "remaining": "resterend",
        "no_goals_planned": "Geen doelen gepland",
        "complete_to_focus": "Voltooi alle taken om vandaag als focusdag te markeren.",
        "add_task_to_start": "Voeg een taak toe vanuit Start om dagelijkse doelen bij te houden.",
        "daily_plan_complete": "Dagelijks plan voltooid",
        "ai_weekly_summary": "Wekelijkse AI-samenvatting",
        "creating_summary": "Je wekelijkse samenvatting wordt gemaakt...",
        "generate_summary": "Samenvatting genereren",
        "refresh_summary": "Samenvatting vernieuwen",
        "first_summary_coming": "Je eerste wekelijkse AI-samenvatting is onderweg.",
        "first_summary_desc": "Deze is klaar op %@ om 21:00 uur. Het bevat inzichten over je voortgang, gemiste taken en de beste focusmodus voor jou.",
        "next_update": "Volgende update: %@",
        "weekly_recap": "Je wekelijkse overzicht van focusdagen, taken en productiviteitstrends is klaar.",
        "screen_time_7day": "Schermtijd — 7 dagen",
        "best_streak": "Beste reeks", "days": "dagen",
        "milestones": "Mijlpalen", "milestone_unlocked": "Mijlpaal ontgrendeld",
        "continue_btn": "Doorgaan",
        "history_calendar": "Geschiedeniskalender",
        "mode_used": "Gebruikte modus",
        "completed": "Voltooid", "not_completed": "Niet voltooid",
        "no_completed_tasks": "Geen voltooide taken geregistreerd voor deze dag.",
        "everything_completed": "Alles was voltooid.",
        "no_missed_tasks": "Geen gemiste taken geregistreerd voor deze dag.",
        "streak_day": "Reeksdag", "missed_day": "Gemiste dag",
        "first_name": "Voornaam", "last_name": "Achternaam",
        "avatar_color": "Avatarkleur",
        "whats_your_name": "Hoe heet je?",
        "name_helps": "Dit helpt om je ervaring te personaliseren.",
        "name_save_failed": "Je naam kon niet worden opgeslagen. Controleer je verbinding en probeer het opnieuw.",
        "continue_btn_name": "Doorgaan",
        "wins": "Overwinningen", "next_action": "Volgende actie",
        "average": "gemiddeld",
        "todays_completion": "Voltooiing van vandaag",
        "streaks_this_month": "reeksen deze maand",
        "streak_days": "reeksdagen", "non_streak_days": "dagen zonder reeks",
        "monthly_streak_summary": "%d reeksen deze maand • %d reeksdagen, %d dagen zonder reeks",
        "duration_average": "%@ gemiddeld",

        // Profile
        "personal_details": "Persoonlijke gegevens",
        "personal_info": "Persoonlijke informatie",
        "update_email_name": "Werk je e-mailadres en volledige naam bij.",
        "and_username": "en gebruikersnaam",
        "invite_friends": "Vrienden uitnodigen",
        "refer_friend_title": "Verwijs een vriend en verdien $10",
        "refer_friend_desc": "Verdien $10 per vriend die zich registreert met jouw promotiecode.",
        "upgrade_family_plan": "Upgraden naar gezinsabonnement",
        "goals_tracking": "Doelen en tracking",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Voedingsdoelen bewerken",
        "tracking_reminders": "Trackingherinneringen",
        "email_not_editable": "Je e-mailadres is gekoppeld aan je login en kan hier niet worden bewerkt.",
        "theme": "Thema",
        "theme_desc": "Gebruik het systeemweergave of kies een vast licht/donker thema.",
        "appearance": "Weergave",
        "appearance_desc": "Kies licht, donker of systeemweergave",
        "live_activity_profile_desc": "Toon je dagelijkse voortgang op het vergrendelscherm en Dynamic Island",
        "system": "Systeem", "light": "Licht", "dark": "Donker",
        "live_activity": "Live-activiteit",
        "live_activity_desc": "Toon de doelen, reeks en motivatie op het vergrendelscherm.",
        "privacy_policy": "Privacybeleid",
        "privacy_desc": "Bekijk hoe app-gegevens en apparaatmachtigingen worden gebruikt.",
        "terms_of_service": "Gebruiksvoorwaarden",
        "terms_desc": "Lees de regels voor het gebruik van de app en de focustools.",
        "follow_us": "Volg ons",
        "sign_out": "Uitloggen",
        "sign_out_desc": "Beëindig deze sessie op het huidige apparaat.",
        "delete_account": "Account verwijderen",
        "delete_account_desc": "Verwijder je account en gesynchroniseerde app-gegevens permanent.",
        "delete_account_title": "Account verwijderen",
        "delete_account_msg": "Deze actie is permanent. Al je gegevens worden verwijderd en kunnen niet worden hersteld.",
        "delete_account_continue": "Doorgaan",
        "delete_account_final_title": "Permanent verwijderen?",
        "delete_account_final_msg": "Bevestig alsjeblieft nog een keer. Als je je account verwijdert, logt Spike AI je uit en stuurt je terug naar de inlogpagina.",
        "deleting_account": "Account wordt verwijderd...",
        "delete_failed": "Account verwijderen mislukt. Probeer het opnieuw of neem contact op met ondersteuning.",
        "language": "Taal",
        "language_desc": "Kies de taal voor alle app-inhoud.",
        "set_name": "Stel je naam in",
        "profile_name_prompt": "Hoe moeten we je noemen?",
        "profile_name_desc": "Voeg de naam toe die Spike AI in je profiel en productiviteitservaring moet gebruiken.",
        "full_name": "Volledige naam",
        "display_name": "Weergavenaam",
        "email": "E-mail",
        "save_changes": "Wijzigingen opslaan",
        "save_footer": "Wijzigingen worden opgeslagen in je profiel en gebruikt overal waar je identiteit in de app verschijnt.",
        "signed_in": "Ingelogd",
        "account": "Account", "preferences": "Voorkeuren",
        "support_legal": "Ondersteuning en juridisch",
        "account_actions": "Accountacties",
        "pref_show_completed": "Voltooide taken tonen",
        "pref_show_completed_desc": "Houd voltooide taken zichtbaar in je dagelijkse lijst.",
        "pref_quotes": "Motiverende citaten",
        "pref_quotes_desc": "Toon een inspirerend citaat op je voortgangsscherm.",
        "legal_updated": "Laatst bijgewerkt: 25 mei 2026",
        "privacy_body": """
        Laatst bijgewerkt: 25 mei 2026

        Spike AI is een productiviteits- en focus-app. Dit Privacybeleid legt uit hoe Spike AI omgaat met informatie die wordt gebruikt voor het aanbieden van accounts, taakplanning, herinneringen, focusmodi, schermtijdcontroles, voortgangsregistratie en door AI gegenereerde productiviteitssamenva­ttingen.

        Informatie die we verzamelen: accountidentificatoren zoals je e-mailadres en gebruikers-ID; profielgegevens die je kiest te verstrekken, zoals weergavenaam en volledige naam; taken, doelen, herinneringen, voltooiingsgeschiedenis, instellingen voor focusmodi, app-selectietokens en voortgangsmetrieken. We kunnen ook technische records opslaan die nodig zijn om de service betrouwbaar en veilig te houden.

        Schermtijd en app-selecties: app-, categorie- en webdomeinselecties worden verwerkt via Apple's FamilyControls- en ManagedSettings-frameworks. Spike AI slaat de door Apple verstrekte tokens op die nodig zijn om je gekozen focusmodi toe te passen. We gebruiken deze selecties niet voor reclame.

        Cameragebruik in Zweetmodus: cameratoegang wordt gebruikt voor controles van de lichaamshouding op het apparaat, zodat je tijdelijke app-toegang kunt verdienen door beweging. Spike AI uploadt geen videoframes voor deze functie en gebruikt cameragegevens niet voor reclame.

        Meldingen en herinneringen: Spike AI gebruikt meldingsmachtiging om taakherinneringen, alarmen en focustips te versturen die je configureert. Je kunt de toegang tot meldingen op elk moment wijzigen in iOS-instellingen.

        AI-samenvattingen: als je een voortgangssamenvatting genereert, kunnen recente taak-, doel-, focus- en productiviteitsmetrieken worden verwerkt door de backend van Spike AI om de samenvatting te produceren. Voer geen gevoelige persoonlijke informatie in bij taaknamen of doelen als je niet wilt dat deze wordt verwerkt voor productiviteitsfuncties.

        Hoe we informatie gebruiken: om je te authenticeren, je account te synchroniseren, focustools aan te bieden, herinneringen te plannen, voortgang te tonen, productiviteitsinzichten te personaliseren, te beschermen tegen misbruik, problemen op te lossen en te voldoen aan wettelijke verplichtingen. Spike AI verkoopt je persoonlijke informatie niet.

        Gegevensverwijdering: je kunt uitloggen of permanent account verwijderen aanvragen via Profiel. Accountverwijdering verwijdert je authenticatieaccount en gesynchroniseerde app-gegevens die aan dat account zijn gekoppeld, onder voorbehoud van beperkte bewaring vereist voor beveiliging, fraudepreventie, geschillenbeslechting of naleving van de wet.

        Je keuzes: je kunt profielgegevens bewerken, taal- en weergavevoorkeuren wijzigen, Live-activiteit uitschakelen, apparaatmachtigingen intrekken in Instellingen, stoppen met het gebruik van specifieke focusmodi of je account verwijderen.

        Contact: neem voor privacyvragen of problemen met accountverwijdering contact op met Spike AI-ondersteuning via het ondersteuningskanaal in de app of de App Store-vermelding.
        """,
        "terms_body": """
        Laatst bijgewerkt: 25 mei 2026

        Deze Gebruiksvoorwaarden regelen je gebruik van Spike AI, inclusief taken, herinneringen, focusmodi, app-prompts en schermen via schermtijd, bewegingscontroles in Zweetmodus, voortgangsregistratie en door AI gegenereerde samenvattingen.

        Geschiktheid en account: je bent verantwoordelijk voor het account dat je aanmaakt en voor het beveiligen van de toegang tot je e-mail en apparaat. Gebruik nauwkeurige informatie waar de app om profielgegevens vraagt.

        Productiviteitsdoel: Spike AI is ontworpen om persoonlijke productiviteit en bewust apparaatgebruik te ondersteunen. Het is geen medische, geestelijke gezondheids-, nood-, veiligheids-, ouderlijk toezicht-, werknemersmonitoring- of apparaatbeheerdienst. Vertrouw niet op Spike AI wanneer het falen van een herinnering, blokkade, prompt, cameracontrole, melding, netwerkverzoek of Apple-machtiging schade kan veroorzaken.

        Je verantwoordelijkheden: kies focusinstellingen die passen bij je situatie; controleer app-selecties voordat je een modus activeert; schakel modi uit wanneer ze niet meer bij je behoeften passen; houd je aan de toepasselijke wetgeving en de platformvoorwaarden van Apple; voer geen gevoelige informatie in bij taken of doelen tenzij je er comfortabel mee bent deze in de app te gebruiken.

        Aanvaardbaar gebruik: misbruik Spike AI niet, verstoor niet het apparaat of account van een andere persoon, probeer geen beveiliging of platformbeperkingen te omzeilen, reverse engineer geen beschermde onderdelen van de service, overbelast de backend niet en gebruik de app niet voor onwettige, beledigende, misleidende of schadelijke activiteiten.

        Machtigingen en beschikbaarheid: sommige functies vereisen iOS-machtigingen zoals schermtijd, meldingen, camera, live-activiteiten en netwerktoegang. Apple, apparaatinstellingen, gedrag van het besturingssysteem, connectiviteit en beschikbaarheid van de backend kunnen van invloed zijn op de werking van functies.

        Door AI gegenereerde inhoud: voortgangssamenvattingen kunnen worden gegenereerd met geautomatiseerde systemen. Ze zijn uitsluitend bedoeld voor reflectie en productiviteitscoaching. Beoordeel ze op basis van je eigen oordeel voordat je erop vertrouwt.

        Accountverwijdering en beëindiging: je kunt accountverwijdering aanvragen via Profiel. Spike AI kan de toegang opschorten of beëindigen indien vereist door de wet, platformregels, beveiligingsproblemen of ernstig misbruik.

        Wijzigingen: Spike AI kan deze Voorwaarden bijwerken naarmate de app evolueert. Voortgezet gebruik na een update betekent dat je de bijgewerkte Voorwaarden accepteert.

        Contact: neem voor vragen over deze Voorwaarden contact op met Spike AI-ondersteuning via het ondersteuningskanaal in de app of de App Store-vermelding.
        """,

        // Focus Mode
        "focus_title": "Focus", "select_mode": "Kies modus",
        "chill": "Rustig", "focus": "Focus", "lock_in": "Vergrendeling", "sweat": "Atleet",
        "gentle_nudges": "Zachte herinneringen", "confirm_intent": "Bevestig intentie",
        "no_bypass": "Geen omzeiling", "move_to_unlock": "Beweeg om te ontgrendelen",
        "activate_focus": "Focusmodus activeren",
        "deactivate_focus": "Focusmodus deactiveren",
        "mode_active": "Modus actief",
        "reminders_scheduled": "Herinneringen gepland",
        "apps_prompt_active": "app(s) — \"Weet je het zeker?\"-prompt actief",
        "apps_blocked": "app(s) geblokkeerd",
        "temp_access_active": "Tijdelijke toegang actief",
        "apps_require_movement": "app(s) vereisen beweging om te ontgrendelen",
        "notifications_label": "Meldingen",
        "notifications_enabled": "Meldingen ingeschakeld",
        "notifications_denied": "Meldingen geweigerd",
        "enable_notif_settings": "Schakel meldingen in via Instellingen.",
        "allow_notif_desc": "Sta meldingen toe zodat Spike AI je focusherinneringen kan sturen.",
        "enable_notifications": "Meldingen inschakelen",
        "screen_time_access": "Schermtijdtoegang",
        "screen_time_authorized": "Schermtijd geautoriseerd",
        "allow_screen_time": "Schermtijd toestaan",
        "tap_to_allow": "Tik hieronder om schermtijdtoegang toe te staan.",
        "open_settings_manual": "Of open Instellingen om handmatig in te schakelen",
        "open_settings": "Open Instellingen",
        "app_selection": "App-selectie",
        "selections": "selectie(s)",
        "choose_apps_confirm": "Kies welke apps bevestiging vereisen voor het openen.",
        "choose_apps_block": "Kies welke apps je wilt blokkeren.",
        "choose_apps_movement": "Kies welke apps je met beweging ontgrendelt.",
        "change_selection": "Selectie wijzigen",
        "select_apps": "Apps selecteren",
        "movement_unlock": "Ontgrendeling door beweging",
        "movement_desc": "Push-ups en squats worden getrackt met AI-lichaamsdetectie. Elke geverifieerde herhaling voegt 1 minuut toegang toe tot geselecteerde apps.",
        "access_available": "Toegang beschikbaar voor %@",
        "open_camera": "Open cameracontrole",
        "lock_in_mode": "Vergrendelingsmodus",
        "lock_in_warning": "Apps tonen een rood scherm zonder omzeiling. Je moet hier terugkomen om de vergrendelingsmodus uit te schakelen.",
        "sweat_mode": "Atleetmodus",
        "do_exercises": "Doe push-ups of squats om tijd te verdienen",
        "add_minutes": "%d minu(u)t(en) toevoegen",
        "keep_in_view": "Houd je schouders, armen of heupen in beeld",
        "camera_required": "Cameratoegang is vereist voor bewegingscontroles.",
        "camera_disabled": "Cameratoegang is uitgeschakeld. Schakel deze in via Instellingen om Zweetmodus te gebruiken.",
        "camera_unavailable": "Cameratoegang is niet beschikbaar.",
        "starting_camera": "Camera wordt gestart...",
        "camera_active": "Camera actief",
        "allow_camera": "Cameratoegang toestaan",
        "focus_mode_title": "Focusmodus",
        "focus_mode_desc": "Neem controle over je digitale gewoonten met doordachte, professionele modi.",
        "about_permissions": "Over machtigingen",
        "permissions_desc": "Rustige modus vereist meldingsmachtiging. Focus-, Vergrendelings- en Zweetmodus vereisen schermtijdautorisatie. Zweetmodus gebruikt ook cameratoegang voor bewegingscontroles.",
        "get_started": "Beginnen", "skip": "Overslaan",
        "unlocked_for": "Ontgrendeld voor %@",

        // Chill mode descriptions
        "chill_desc": "Dagelijkse herinneringen via meldingen. Geen app-controle — alleen zachte aanwijzingen om bewust te blijven.",
        "focus_desc": "Wanneer je een geselecteerde app opent, vraagt Spike AI: \"Weet je het zeker?\" Je kunt de app normaal openen of teruggaan naar je taken. Apps worden niet geblokkeerd.",
        "lock_in_desc": "Geselecteerde apps zijn geblokkeerd terwijl de vergrendelingsmodus actief is. Je kunt deze uitschakelen vanuit Spike AI.",
        "sweat_desc": "Geselecteerde apps blijven geblokkeerd totdat je een door de camera gecontroleerde push-up of squat voltooit. Elke geverifieerde herhaling ontgrendelt 1 minuut.",

        // Motivational (deactivation)
        "giving_up_title": "Je maakt voortgang — stop niet",
        "giving_up_msg": "Je hebt nog onvoltooide doelen voor vandaag. Elke afgeronde taak bouwt momentum op. Blijf erbij — je toekomstige zelf zal je dankbaar zijn.",
        "giving_up_continue": "Gefocust blijven",
        "giving_up_stop": "Toch uitschakelen",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Jouw persoonlijke productiviteitssysteem",
        "start_setup": "Instelling starten",
        "make_phone_work": "Laat je telefoon werken\nvoor je doelen.",
        "onboarding_welcome_desc": "Verminder zinloos scrollen, bescherm focustijd en maak van echte taken zichtbare voortgang.",
        "did_you_know": "Wist je dat?",
        "did_you_know_subtitle": "Een persoon besteedt gemiddeld 7 uur per dag aan zijn telefoon. Dat is",
        "hours_per_day": "uur per dag",
        "days_per_month": "dagen per maand",
        "days_per_year": "dagen per jaar",
        "years_of_life": "jaar van je leven",
        "screen_time_reality": "En sommige mensen besteden nog meer.",
        "dont_worry_title": "Maak je geen zorgen",
        "spike_has_your_back": "Spike AI staat achter je",
        "solution_desc": "We helpen je om je productiviteit te maximaliseren, dichter bij je doelen te komen en gewoonten op te bouwen die je transformeren in de beste versie van jezelf.",
        "screen_time_access_title": "Schermtijdtoegang",
        "grant_access": "Toegang verlenen",
        "which_apps": "Kies je\nafleidende apps",
        "choose_apps_protect": "Selecteer de apps die je tijd verspillen. We blokkeren ze tijdens focusmodi.",
        "apple_screen_time_required": "Apple vereist schermtijdtoegang voordat Spike AI je app-lijst kan tonen.",
        "save_apps": "Opslaan en doorgaan",
        "change_selected_apps": "Geselecteerde apps wijzigen",
        "ready_change_life": "Klaar om je\nleven te veranderen?",
        "ready_change_desc": "Maak een account aan om je keuzes op te slaan en je reis te beginnen.",
        "benefit_no_distraction": "Afleidende apps zullen je niet meer storen",
        "benefit_discover_modes": "Ontdek 4 verschillende soorten focusmodi",
        "benefit_track_progress": "Volg je voortgang en kom dichter bij je doelen",
        "create_account": "Account aanmaken",
        "protect_focus": "Focus beschermen",
        "block_feeds": "Feeds blokkeren",
        "finish_tasks": "Taken afronden",
        "energy_plus_three": "+3 Energie",
        "selected_count": "%d geselecteerd",
        "no_apps_selected": "Nog geen apps geselecteerd",
        "saved_for_modes": "Opgeslagen voor beschermingsmodi",
        "select_apps_to_control": "Selecteer de apps die je wilt controleren",
        "clean_room": "Kamer opruimen",
        "snap_proof": "Maak een foto als bewijs na voltooiing",
        "ai_verifies_task": "AI verifieert de taak",
        "energy_earned": "+3 Energie verdiend",
        "on_track": "Op schema",
        "energy": "Energie",
        "tasks_completed": "Taken voltooid",
        "focus_protected": "Focus beschermd",
        "scrolling_avoided": "Scrollen vermeden",
        "continue_apple": "Doorgaan met Apple",
        "continue_google": "Doorgaan met Google",
        "continue_email": "Doorgaan met e-mail",
        "enter_email": "Voer je e-mailadres in",
        "send_sign_in_link": "We sturen je een inloglink",
        "check_email": "Controleer je e-mail",
        "sent_link_to": "We hebben een inloglink gestuurd naar",
        "tap_link": "Tik op de link om automatisch in te loggen.",
        "open_mail": "Open Mail-app",
        "open_with": "Openen met",
        "didnt_get_email": "E-mail niet ontvangen?",
        "resend": "Opnieuw versturen",
        "resend_in": "Opnieuw versturen over %ds",
        "new_link_sent": "Een nieuwe link is verstuurd!",
        "valid_email": "Voer een geldig e-mailadres in.",
        "by_continuing": "Door verder te gaan, ga je akkoord met de",
        "and_word": "en",

        // Screen Time Onboarding
        "screen_time_title": "Schermtijd",
        "screen_time_permission_desc": "Spike AI heeft schermtijdmachtiging nodig voor Focus-, Vergrendelings- en Zweetmodus. Hiermee kunnen app-prompts en blokkades worden getoond voor de apps die je kiest.",
        "screen_time_denied": "Machtiging is geweigerd. Je kunt deze inschakelen via Instellingen.",
        "ask_before_opening": "Vragen voor openen",
        "block_apps_completely": "Apps volledig blokkeren",
        "stay_accountable": "Blijf verantwoordelijk",
        "stay_accountable_desc": "Volg voortgang en houd je focusgewoonten zichtbaar.",
        "skip_for_now": "Voorlopig overslaan",

        // Live Activity
        "daily_goals_title": "Dagelijkse doelen",
        "of_done": "van %d voltooid",
        "more_to_go": "nog %d te gaan",

        // Chill morning
        "good_morning": "Goedemorgen! Wees vandaag bewust. Bekijk je taken en blijf gefocust.",

        // General
        "error": "Fout", "ok": "OK", "yes": "Ja", "no": "Nee",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Overschakelen naar Ontspanmodus?",
        "stay_focused_btn": "Gefocust blijven",
        "switch_anyway_btn": "Toch wisselen",
        "switch_to_chill_msg": "Je hebt nog onvoltooide doelen. Overschakelen naar Ontspanmodus verwijdert de app-blokkering, waardoor het risico toeneemt dat je je doelen vandaag niet haalt.",
        "task_notification": "Taakmelding",
        "missed_alarm": "Gemist alarm",
        "quote_of_day": "Citaat van de Dag",
        "new_quotes_daily": "Nieuwe citaten verschijnen dagelijks om 5:00 uur",
        "focus_day_label": "Focusdag",
        "missed_label": "Gemist",
        "access_granted": "Toegang verleend",
        "goal_reminder": "Doelherinnering",
        "spike_ai_focus": "Spike AI Focus",
        "goals_required_title": "Doelen vereist",
        "goals_required_desc_focus": "Focusmodus blokkeert geselecteerde apps alleen wanneer je onvoltooide doelen hebt. Voeg doelen toe in het Start-tabblad om app-blokkering te activeren.",
        "goals_required_desc_lockin": "Vergrendelmodus blokkeert geselecteerde apps alleen wanneer je onvoltooide doelen hebt. Voeg doelen toe in het Start-tabblad om app-blokkering te activeren.",
        "save": "Opslaan",
        "no_goals_reminder_body": "Je hebt nog geen doelen voor vandaag ingesteld. Neem even de tijd om je dag te plannen!",
        "dont_forget": "Vergeet niet",
        "chill_morning_body": "Goedemorgen! Wees vandaag bewust bezig. Bekijk je taken en blijf gefocust.",
        "every_day": "Elke dag",
        "weekdays": "Doordeweeks",
        "weekends": "Weekenden",
        "time_to_focus": "Tijd om te focussen!",

        // Additional UI strings
        "next_quote_in": "Volgend citaat over %@",
        "enable_notif_chill": "Schakel meldingen in voordat je de Relax-modus start.",
        "enable_screen_time_mode": "Schakel Schermtijd-toegang in voordat je deze modus start.",
        "select_app_before_mode": "Selecteer minstens één app, categorie of website voordat je deze modus start.",
        "mode_not_ready": "Deze modus is nog niet klaar om te starten.",
        "protection_stopped_no_apps": "Bescherming gestopt: er zijn geen apps geselecteerd.",
        "protection_stopped_screen_time": "Bescherming gestopt: Schermtijd-toegang is gewijzigd.",
        "max_reminders": "Je kunt maximaal %d focusherinneringen aanmaken.",
        "front_camera_unavailable": "De frontcamera is niet beschikbaar.",
        "task_title_empty": "De taaktitel mag niet leeg zijn.",
        "goal_title_empty": "De doeltitel mag niet leeg zijn.",
        "rate_limit_wait": "Wacht %d seconden voordat je een nieuwe samenvatting genereert.",
        "missed_alarm_for": "Je hebt het alarm gemist voor: %@",
        "stay_with_plan": "Houd je aan het plan.",
        "motivation_small_wins": "Kleine overwinningen tellen op.",
        "motivation_next_step": "Voltooi de volgende stap.",
        "motivation_protect_hour": "Bescherm het uur voor je.",
        "motivation_consistency": "Consistentie verslaat intensiteit.",
        "monthly_scope_btn": "Maandelijks",
        "yearly_scope_btn": "Jaarlijks",
        "restoring_session": "Sessie wordt hersteld...",

        // Milestones
        "milestone_3day_streak": "3-daagse reeks",
        "milestone_3day_desc": "Een stabiel ritme is begonnen.",
        "milestone_7day_streak": "7-daagse reeks",
        "milestone_7day_desc": "Een volledige gefocuste week.",
        "milestone_10h_protected": "10 uur beschermd",
        "milestone_10h_desc": "Tijd beschermd voor wat telt.",
        "milestone_30_focus": "30 focusdagen",
        "milestone_30_desc": "Consistentie met echt gewicht.",

        // Narratives
        "narrative_improved": "Je schermtijd is verbeterd ten opzichte van vorige week.",
        "narrative_consistent": "Je bleef consistent deze week en beschermde je focus.",
        "narrative_more_days": "Je hebt meer focusdagen voltooid dan gebruikelijk.",
        "narrative_building": "Je bouwt het ritme op, één gefocuste dag tegelijk.",

        // Screen time
        "screen_time_trend_pending": "De schermtijdtrend verschijnt naarmate de gebruiksgeschiedenis groeit.",
        "screen_time_improved": "Schermtijd verbeterd met %d%%",
        "screen_time_higher": "Schermtijd is iets hoger dan gebruikelijk",
        "screen_time_steady": "Schermtijd is stabiel deze week",

        // Benchmarks
        "benchmark_pending": "De gemiddelde schermtijd verschijnt als de app gebruiksgeschiedenis registreert. Het wereldwijde referentiepunt is ongeveer 7 uur per dag.",
        "benchmark_below": "Je 7-daags gemiddelde is %@, onder het wereldwijde gemiddelde van 7 uur. Dat is een sterke richting.",
        "benchmark_above": "Je 7-daags gemiddelde is %@, boven het wereldwijde gemiddelde van 7 uur. Een kleine vermindering vandaag kan de trend veranderen.",
        "benchmark_matching": "Je 7-daags gemiddelde is %@, gelijk aan het wereldwijde gemiddelde van 7 uur.",

        // Task editing
        "edit_task": "Taak bewerken",
        "task_name_placeholder": "Taaknaam",
        "task_reminder_default": "Taakherinnering",
        "time_h_m": "%du %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Swedish
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let sv: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Om fokuslägen",
        "no_active_goals_title": "Inga aktiva mål",
        "no_active_goals_btn": "Uppfattat",
        "no_active_goals_msg": "Fokus och Låsning fungerar bara så länge du har ett oavslutat mål att arbeta mot. Lägg till ett mål — eller återaktivera ett — och starta sedan din session.",
        // Tab bar
        "tab_home": "Hem", "tab_progress": "Framsteg", "tab_mode": "Läge", "tab_profile": "Profil",

        // Home
        "today": "Idag", "tomorrow": "Imorgon", "yesterday": "Igår",
        "back_to_today": "Tillbaka till idag",
        "add_first_task": "Tryck på + för att lägga till din första uppgift",
        "no_tasks_this_day": "Inga uppgifter denna dag",
        "new_task": "Ny uppgift",
        "what_to_do": "Vad behöver du göra?",
        "task": "Uppgift", "schedule": "Schema",
        "pick_date_hint": "Välj valfritt datum — idag, nästa vecka eller månader framåt.",
        "priority": "Prioritet", "low": "Låg", "medium": "Medel", "high": "Hög",
        "notification": "Avisering",
        "silent_push": "Tyst push-avisering",
        "notification_desc": "Skickar en engångs push-avisering vid den schemalagda tiden. Den visas diskret på din låsskärm och i Aviseringscentret.",
        "reminder": "Påminnelse",
        "alarm_sound": "Alarm med ljud och vibration",
        "reminder_desc": "Fungerar som ett alarm — ett speciellt ljud spelas upp och din telefon vibrerar tills du trycker på knappen Avfärda. Perfekt för möten och deadlines.",
        "cancel": "Avbryt", "add": "Lägg till", "edit": "Redigera", "delete": "Ta bort",
        "jump_to_date": "Hoppa till datum", "done": "Klar",
        "task_limit": "Du har nått gränsen på 25 uppgifter för detta datum.",
        "time": "Tid", "date": "Datum", "select_date": "Välj datum",

        // Alarm
        "reminder_title": "Påminnelse", "dismiss": "Avfärda",

        // Progress
        "daily_progress": "Dagliga framsteg", "streaks": "sviter", "focus_days": "fokusdagar",
        "consistency": "konsekvens",
        "set_first_goal": "Ställ in ditt första mål för idag",
        "all_goals_completed": "Alla dagliga mål uppnådda",
        "goals_completed": "av",
        "daily_goals_completed": "dagliga mål uppnådda",
        "daily_goals": "Dagliga mål", "remaining": "återstående",
        "no_goals_planned": "Inga mål planerade",
        "complete_to_focus": "Slutför alla uppgifter för att markera idag som en fokusdag.",
        "add_task_to_start": "Lägg till en uppgift från Hem för att börja spåra dagliga mål.",
        "daily_plan_complete": "Daglig plan slutförd",
        "ai_weekly_summary": "AI-veckosammanfattning",
        "creating_summary": "Din veckosammanfattning skapas...",
        "generate_summary": "Generera sammanfattning",
        "refresh_summary": "Uppdatera sammanfattning",
        "first_summary_coming": "Din första AI-veckosammanfattning är på väg.",
        "first_summary_desc": "Den kommer att vara klar %@ klockan 21:00. Den innehåller insikter om dina framsteg, missade uppgifter och det bästa fokusläget för dig.",
        "next_update": "Nästa uppdatering: %@",
        "weekly_recap": "Din veckoöversikt över fokusdagar, uppgifter och produktivitetstrender är klar.",
        "screen_time_7day": "Skärmtid — 7 dagar",
        "best_streak": "Bästa svit", "days": "dagar",
        "milestones": "Milstolpar", "milestone_unlocked": "Milstolpe upplåst",
        "continue_btn": "Fortsätt",
        "history_calendar": "Historikkalender",
        "mode_used": "Använt läge",
        "completed": "Slutfört", "not_completed": "Ej slutfört",
        "no_completed_tasks": "Inga slutförda uppgifter registrerade för denna dag.",
        "everything_completed": "Allt var slutfört.",
        "no_missed_tasks": "Inga missade uppgifter registrerade för denna dag.",
        "streak_day": "Svitdag", "missed_day": "Missad dag",
        "first_name": "Förnamn", "last_name": "Efternamn",
        "avatar_color": "Avatarfärg",
        "whats_your_name": "Vad heter du?",
        "name_helps": "Detta hjälper till att anpassa din upplevelse.",
        "name_save_failed": "Vi kunde inte spara ditt namn. Kontrollera din anslutning och försök igen.",
        "continue_btn_name": "Fortsätt",
        "wins": "Vinster", "next_action": "Nästa åtgärd",
        "average": "i genomsnitt",
        "todays_completion": "Dagens slutförande",
        "streaks_this_month": "sviter denna månad",
        "streak_days": "svitdagar", "non_streak_days": "dagar utan svit",
        "monthly_streak_summary": "%d sviter denna månad • %d svitdagar, %d dagar utan svit",
        "duration_average": "%@ i genomsnitt",

        // Profile
        "personal_details": "Personuppgifter",
        "personal_info": "Personlig information",
        "update_email_name": "Uppdatera din e-postadress och fullständiga namn.",
        "and_username": "och användarnamn",
        "invite_friends": "Bjud in vänner",
        "refer_friend_title": "Hänvisa en vän och tjäna $10",
        "refer_friend_desc": "Tjäna $10 per vän som registrerar sig med din kampanjkod.",
        "upgrade_family_plan": "Uppgradera till familjeabonnemang",
        "goals_tracking": "Mål och spårning",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Redigera näringmål",
        "tracking_reminders": "Spårningspåminnelser",
        "email_not_editable": "Din e-postadress är kopplad till din inloggning och kan inte redigeras här.",
        "theme": "Tema",
        "theme_desc": "Använd systemets utseende eller välj ett fast ljust/mörkt läge.",
        "appearance": "Utseende",
        "appearance_desc": "Välj ljust, mörkt eller systemutseende",
        "live_activity_profile_desc": "Visa dina dagliga framsteg på låsskärmen och Dynamic Island",
        "system": "System", "light": "Ljust", "dark": "Mörkt",
        "live_activity": "Live-aktivitet",
        "live_activity_desc": "Visa dagens mål, svit och motivation på låsskärmen.",
        "privacy_policy": "Integritetspolicy",
        "privacy_desc": "Granska hur appdata och enhetsbehörigheter används.",
        "terms_of_service": "Användarvillkor",
        "terms_desc": "Läs reglerna för att använda appen och dess fokusverktyg.",
        "follow_us": "Följ oss",
        "sign_out": "Logga ut",
        "sign_out_desc": "Avsluta denna session på den aktuella enheten.",
        "delete_account": "Radera konto",
        "delete_account_desc": "Radera permanent ditt konto och synkroniserad appdata.",
        "delete_account_title": "Radera konto",
        "delete_account_msg": "Denna åtgärd är permanent. All din data kommer att raderas och kan inte återställas.",
        "delete_account_continue": "Fortsätt",
        "delete_account_final_title": "Radera permanent?",
        "delete_account_final_msg": "Vänligen bekräfta en gång till. Om du raderar ditt konto loggar Spike AI ut dig och skickar dig tillbaka till inloggningssidan.",
        "deleting_account": "Raderar konto...",
        "delete_failed": "Kontoborttagningen misslyckades. Försök igen eller kontakta support.",
        "language": "Språk",
        "language_desc": "Välj språk för allt appinnehåll.",
        "set_name": "Ange ditt namn",
        "profile_name_prompt": "Vad ska vi kalla dig?",
        "profile_name_desc": "Lägg till det namn som Spike AI ska använda i din profil och produktivitetsupplevelse.",
        "full_name": "Fullständigt namn",
        "display_name": "Visningsnamn",
        "email": "E-post",
        "save_changes": "Spara ändringar",
        "save_footer": "Ändringar sparas i din profil och används överallt där din identitet visas i appen.",
        "signed_in": "Inloggad",
        "account": "Konto", "preferences": "Inställningar",
        "support_legal": "Support och juridik",
        "account_actions": "Kontoåtgärder",
        "pref_show_completed": "Visa slutförda uppgifter",
        "pref_show_completed_desc": "Behåll slutförda uppgifter synliga i din dagliga lista.",
        "pref_quotes": "Motiverande citat",
        "pref_quotes_desc": "Visa ett inspirerande citat på din framstegsskärm.",
        "legal_updated": "Senast uppdaterad: 25 maj 2026",
        "privacy_body": """
        Senast uppdaterad: 25 maj 2026

        Spike AI är en produktivitets- och fokusapp. Denna Integritetspolicy förklarar hur Spike AI hanterar information som används för att tillhandahålla konton, uppgiftsplanering, påminnelser, fokuslägen, skärmtidskontroller, framstegsspårning och AI-genererade produktivitetssammanfattningar.

        Information vi samlar in: kontoidentifierare såsom din e-postadress och användar-ID; profiluppgifter du väljer att ange, såsom visningsnamn och fullständigt namn; uppgifter, mål, påminnelser, slutförandehistorik, fokuslägesinställningar, appvalstokens och framstegsmetriker. Vi kan även lagra tekniska poster som behövs för att hålla tjänsten tillförlitlig och säker.

        Skärmtid och appval: app-, kategori- och webbdomänval hanteras genom Apples ramverk FamilyControls och ManagedSettings. Spike AI lagrar de Apple-tillhandahållna tokens som behövs för att tillämpa dina valda fokuslägen. Vi använder inte dessa val för reklam.

        Kameraanvändning i Svettläge: kameraåtkomst används för kroppshållningskontroller på enheten så att du kan tjäna tillfällig apptillgång genom rörelse. Spike AI laddar inte upp videorutor för denna funktion och använder inte kameradata för reklam.

        Aviseringar och påminnelser: Spike AI använder aviseringsbehörighet för att skicka uppgiftspåminnelser, alarm och fokustips som du konfigurerar. Du kan ändra aviseringsåtkomst i iOS-inställningar när som helst.

        AI-sammanfattningar: om du genererar en framstegssammanfattning kan nyliga uppgifts-, mål-, fokus- och produktivitetsmetriker behandlas av Spike AI:s backend för att producera sammanfattningen. Undvik att ange känslig personlig information i uppgiftsnamn eller mål om du inte vill att den behandlas för produktivitetsfunktioner.

        Hur vi använder information: för att autentisera dig, synkronisera ditt konto, tillhandahålla fokusverktyg, schemalägga påminnelser, visa framsteg, anpassa produktivitetsinsikter, skydda mot missbruk, felsöka problem och uppfylla rättsliga skyldigheter. Spike AI säljer inte din personliga information.

        Dataradering: du kan logga ut eller begära permanent kontoborttagning via Profil. Kontoborttagning tar bort ditt autentiseringskonto och synkroniserad appdata kopplad till det kontot, med förbehåll för begränsad lagring som krävs för säkerhet, bedrägeriförebyggande, tvistlösning eller efterlevnad av lag.

        Dina val: du kan redigera profiluppgifter, ändra språk- och utseendeinställningar, inaktivera Live-aktivitet, återkalla enhetsbehörigheter i Inställningar, sluta använda specifika fokuslägen eller radera ditt konto.

        Kontakt: för integritetsfrågor eller problem med kontoborttagning, kontakta Spike AI-support via supportkanalen i appen eller App Store-listan.
        """,
        "terms_body": """
        Senast uppdaterad: 25 maj 2026

        Dessa Användarvillkor reglerar din användning av Spike AI, inklusive uppgifter, påminnelser, fokuslägen, appprompter och skärmar via skärmtid, rörelsekontroller i Svettläge, framstegsspårning och AI-genererade sammanfattningar.

        Behörighet och konto: du ansvarar för det konto du skapar och för att hålla åtkomsten till din e-post och enhet säker. Använd korrekt information där appen ber om profiluppgifter.

        Produktivitetssyfte: Spike AI är utformat för att stödja personlig produktivitet och medveten enhetsanvändning. Det är inte en medicinsk, psykisk hälso-, nöd-, säkerhets-, föräldrakontroll-, anställningsövervaknings- eller enhetshanteringstjänst. Förlita dig inte på Spike AI i situationer där fel på en påminnelse, blockering, prompt, kamerakontroll, avisering, nätverksbegäran eller Apple-behörighet kan orsaka skada.

        Dina skyldigheter: välj fokusinställningar som passar din situation; granska appval innan du aktiverar ett läge; stäng av lägen när de inte längre passar dina behov; följ tillämplig lag och Apples plattformsvillkor; undvik att ange känslig information i uppgifter eller mål om du inte är bekväm med att använda den i appen.

        Godtagbar användning: missbruka inte Spike AI, stör inte en annan persons enhet eller konto, försök inte kringgå säkerhet eller plattformsbegränsningar, reverse-engineera inte skyddade delar av tjänsten, överbelasta inte backend eller använd appen för olaglig, kränkande, vilseledande eller skadlig verksamhet.

        Behörigheter och tillgänglighet: vissa funktioner kräver iOS-behörigheter som skärmtid, aviseringar, kamera, live-aktiviteter och nätverksåtkomst. Apple, enhetsinställningar, operativsystemets beteende, anslutning och backend-tillgänglighet kan påverka om funktioner fungerar som förväntat.

        AI-genererat innehåll: framstegssammanfattningar kan genereras med automatiserade system. De är avsedda enbart för reflektion och produktivitetscoaching. Bedöm dem med ditt eget omdöme innan du förlitar dig på dem.

        Kontoborttagning och avslutning: du kan begära kontoborttagning via Profil. Spike AI kan tillfälligt stänga av eller avsluta åtkomst om det krävs enligt lag, plattformsregler, säkerhetsproblem eller allvarligt missbruk.

        Ändringar: Spike AI kan uppdatera dessa Villkor i takt med att appen utvecklas. Fortsatt användning efter en uppdatering innebär att du accepterar de uppdaterade Villkoren.

        Kontakt: för frågor om dessa Villkor, kontakta Spike AI-support via supportkanalen i appen eller App Store-listan.
        """,

        // Focus Mode
        "focus_title": "Fokus", "select_mode": "Välj läge",
        "chill": "Lugn", "focus": "Fokus", "lock_in": "Låsning", "sweat": "Atlet",
        "gentle_nudges": "Milda påminnelser", "confirm_intent": "Bekräfta avsikt",
        "no_bypass": "Ingen omgång", "move_to_unlock": "Rör dig för att låsa upp",
        "activate_focus": "Aktivera fokusläge",
        "deactivate_focus": "Inaktivera fokusläge",
        "mode_active": "Läge aktivt",
        "reminders_scheduled": "Påminnelser schemalagda",
        "apps_prompt_active": "app(ar) — \"Är du säker?\"-prompt aktiv",
        "apps_blocked": "app(ar) blockerade",
        "temp_access_active": "Tillfällig åtkomst aktiv",
        "apps_require_movement": "app(ar) kräver rörelse för att låsa upp",
        "notifications_label": "Aviseringar",
        "notifications_enabled": "Aviseringar aktiverade",
        "notifications_denied": "Aviseringar nekade",
        "enable_notif_settings": "Aktivera aviseringar i Inställningar.",
        "allow_notif_desc": "Tillåt aviseringar så att Spike AI kan skicka fokuspåminnelser.",
        "enable_notifications": "Aktivera aviseringar",
        "screen_time_access": "Skärmtidsåtkomst",
        "screen_time_authorized": "Skärmtid auktoriserad",
        "allow_screen_time": "Tillåt skärmtid",
        "tap_to_allow": "Tryck nedan för att tillåta skärmtidsåtkomst.",
        "open_settings_manual": "Eller öppna Inställningar för att aktivera manuellt",
        "open_settings": "Öppna Inställningar",
        "app_selection": "Appval",
        "selections": "val",
        "choose_apps_confirm": "Välj vilka appar som kräver bekräftelse innan de öppnas.",
        "choose_apps_block": "Välj vilka appar som ska blockeras.",
        "choose_apps_movement": "Välj vilka appar som låses upp med rörelse.",
        "change_selection": "Ändra val",
        "select_apps": "Välj appar",
        "movement_unlock": "Upplåsning med rörelse",
        "movement_desc": "Armhävningar och knäböj spåras med AI-kroppsdetektering. Varje verifierad repetition lägger till 1 minuts åtkomst till valda appar.",
        "access_available": "Åtkomst tillgänglig i %@",
        "open_camera": "Öppna kamerakontroll",
        "lock_in_mode": "Låsningsläge",
        "lock_in_warning": "Appar visar en röd skärm utan omgång. Du måste komma tillbaka hit för att stänga av låsningsläget.",
        "sweat_mode": "Atletläge",
        "do_exercises": "Gör armhävningar eller knäböj för att tjäna tid",
        "add_minutes": "Lägg till %d minut(er)",
        "keep_in_view": "Håll axlar, armar eller höfter synliga",
        "camera_required": "Kameraåtkomst krävs för rörelsekontroller.",
        "camera_disabled": "Kameraåtkomst är inaktiverad. Aktivera den i Inställningar för att använda Svettläge.",
        "camera_unavailable": "Kameraåtkomst är inte tillgänglig.",
        "starting_camera": "Startar kamera...",
        "camera_active": "Kamera aktiv",
        "allow_camera": "Tillåt kameraåtkomst",
        "focus_mode_title": "Fokusläge",
        "focus_mode_desc": "Ta kontroll över dina digitala vanor med genomtänkta, professionella lägen.",
        "about_permissions": "Om behörigheter",
        "permissions_desc": "Lugnt läge kräver aviseringsbehörighet. Fokus-, Låsnings- och Svettläge kräver skärmtidsauktorisering. Svettläge använder även kameraåtkomst för rörelsekontroller.",
        "get_started": "Börja", "skip": "Hoppa över",
        "unlocked_for": "Upplåst i %@",

        // Chill mode descriptions
        "chill_desc": "Dagliga påminnelser via aviseringar. Ingen appkontroll — bara milda påstötningar för att förbli medveten.",
        "focus_desc": "När du öppnar en vald app frågar Spike AI: \"Är du säker?\" Du kan öppna den som vanligt eller gå tillbaka till dina uppgifter. Appar blockeras inte.",
        "lock_in_desc": "Valda appar är blockerade medan låsningsläget är aktivt. Du kan stänga av det från Spike AI.",
        "sweat_desc": "Valda appar förblir blockerade tills du slutför en kamerakontrollerad armhävning eller knäböj. Varje verifierad repetition låser upp 1 minut.",

        // Motivational (deactivation)
        "giving_up_title": "Du gör framsteg — sluta inte",
        "giving_up_msg": "Du har fortfarande ofullständiga mål för idag. Varje slutförd uppgift bygger momentum. Håll ut — ditt framtida jag kommer att tacka dig.",
        "giving_up_continue": "Behåll fokus",
        "giving_up_stop": "Stäng av ändå",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Ditt personliga produktivitetssystem",
        "start_setup": "Starta inställning",
        "make_phone_work": "Låt din telefon arbeta\nför dina mål.",
        "onboarding_welcome_desc": "Minska meningslöst scrollande, skydda fokustid och förvandla verkliga uppgifter till synliga framsteg.",
        "did_you_know": "Visste du?",
        "did_you_know_subtitle": "En person spenderar i genomsnitt 7 timmar per dag på sin telefon. Det är",
        "hours_per_day": "timmar per dag",
        "days_per_month": "dagar per månad",
        "days_per_year": "dagar per år",
        "years_of_life": "år av ditt liv",
        "screen_time_reality": "Och vissa spenderar ännu mer.",
        "dont_worry_title": "Oroa dig inte",
        "spike_has_your_back": "Spike AI har din rygg",
        "solution_desc": "Vi hjälper dig att maximera din produktivitet, komma närmare dina mål och bygga vanor som förvandlar dig till den bästa versionen av dig själv.",
        "screen_time_access_title": "Skärmtidsåtkomst",
        "grant_access": "Bevilja åtkomst",
        "which_apps": "Välj dina\ndistraherande appar",
        "choose_apps_protect": "Välj de appar som slösar din tid. Vi blockerar dem under fokuslägen.",
        "apple_screen_time_required": "Apple kräver skärmtidsåtkomst innan Spike AI kan visa din applista.",
        "save_apps": "Spara och fortsätt",
        "change_selected_apps": "Ändra valda appar",
        "ready_change_life": "Redo att förändra\nditt liv?",
        "ready_change_desc": "Skapa ett konto för att spara dina val och påbörja din resa.",
        "benefit_no_distraction": "Distraherande appar kommer inte längre störa dig",
        "benefit_discover_modes": "Upptäck 4 olika typer av fokuslägen",
        "benefit_track_progress": "Spåra dina framsteg och kom närmare dina mål",
        "create_account": "Skapa konto",
        "protect_focus": "Skydda fokus",
        "block_feeds": "Blockera flöden",
        "finish_tasks": "Slutför uppgifter",
        "energy_plus_three": "+3 Energi",
        "selected_count": "%d valda",
        "no_apps_selected": "Inga appar valda ännu",
        "saved_for_modes": "Sparat för skyddslägen",
        "select_apps_to_control": "Välj de appar du vill kontrollera",
        "clean_room": "Städa rummet",
        "snap_proof": "Ta ett foto som bevis när du är klar",
        "ai_verifies_task": "AI verifierar uppgiften",
        "energy_earned": "+3 Energi intjänad",
        "on_track": "På rätt spår",
        "energy": "Energi",
        "tasks_completed": "Uppgifter slutförda",
        "focus_protected": "Fokus skyddat",
        "scrolling_avoided": "Scrollande undvikit",
        "continue_apple": "Fortsätt med Apple",
        "continue_google": "Fortsätt med Google",
        "continue_email": "Fortsätt med e-post",
        "enter_email": "Ange din e-postadress",
        "send_sign_in_link": "Vi skickar en inloggningslänk",
        "check_email": "Kontrollera din e-post",
        "sent_link_to": "Vi skickade en inloggningslänk till",
        "tap_link": "Tryck på länken för att logga in automatiskt.",
        "open_mail": "Öppna e-postappen",
        "open_with": "Öppna med",
        "didnt_get_email": "Fick du inte e-postmeddelandet?",
        "resend": "Skicka igen",
        "resend_in": "Skicka igen om %ds",
        "new_link_sent": "En ny länk har skickats!",
        "valid_email": "Ange en giltig e-postadress.",
        "by_continuing": "Genom att fortsätta godkänner du Spike AI:s",
        "and_word": "och",

        // Screen Time Onboarding
        "screen_time_title": "Skärmtid",
        "screen_time_permission_desc": "Spike AI behöver skärmtidsbehörighet för Fokus-, Låsnings- och Svettläge. Detta gör det möjligt att visa appprompter och blockeringar för de appar du väljer.",
        "screen_time_denied": "Behörigheten nekades. Du kan aktivera den i Inställningar.",
        "ask_before_opening": "Fråga innan öppning",
        "block_apps_completely": "Blockera appar helt",
        "stay_accountable": "Håll dig ansvarig",
        "stay_accountable_desc": "Spåra framsteg och håll dina fokusvanor synliga.",
        "skip_for_now": "Hoppa över för nu",

        // Live Activity
        "daily_goals_title": "Dagliga mål",
        "of_done": "av %d klara",
        "more_to_go": "+%d kvar",

        // Chill morning
        "good_morning": "God morgon! Var medveten idag. Granska dina uppgifter och behåll fokus.",

        // General
        "error": "Fel", "ok": "OK", "yes": "Ja", "no": "Nej",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Byta till Avslappnat Läge?",
        "stay_focused_btn": "Förbli fokuserad",
        "switch_anyway_btn": "Byt ändå",
        "switch_to_chill_msg": "Du har fortfarande ofullständiga mål. Att byta till Avslappnat Läge tar bort appblockering, vilket ökar risken att inte nå dina mål idag.",
        "task_notification": "Uppgiftsavisering",
        "missed_alarm": "Missat alarm",
        "quote_of_day": "Dagens citat",
        "new_quotes_daily": "Nya citat kommer dagligen klockan 05:00",
        "focus_day_label": "Fokusdag",
        "missed_label": "Missad",
        "access_granted": "Åtkomst beviljad",
        "goal_reminder": "Målpåminnelse",
        "spike_ai_focus": "Spike AI Fokus",
        "goals_required_title": "Mål krävs",
        "goals_required_desc_focus": "Fokusläget blockerar valda appar bara när du har ofullständiga mål. Lägg till mål i fliken Hem för att aktivera appblockering.",
        "goals_required_desc_lockin": "Låsläget blockerar valda appar bara när du har ofullständiga mål. Lägg till mål i fliken Hem för att aktivera appblockering.",
        "save": "Spara",
        "no_goals_reminder_body": "Du har inte satt några mål för idag. Ta en stund att planera din dag!",
        "dont_forget": "Glöm inte",
        "chill_morning_body": "God morgon! Var medveten idag. Gå igenom dina uppgifter och håll fokus.",
        "every_day": "Varje dag",
        "weekdays": "Vardagar",
        "weekends": "Helger",
        "time_to_focus": "Dags att fokusera!",

        // Additional UI strings
        "next_quote_in": "Nästa citat om %@",
        "enable_notif_chill": "Aktivera aviseringar innan du startar Lugn-läge.",
        "enable_screen_time_mode": "Aktivera Skärmtid-åtkomst innan du startar detta läge.",
        "select_app_before_mode": "Välj minst en app, kategori eller webbplats innan du startar detta läge.",
        "mode_not_ready": "Detta läge är inte redo att starta.",
        "protection_stopped_no_apps": "Skyddet stoppades: inga appar är valda.",
        "protection_stopped_screen_time": "Skyddet stoppades: åtkomst till Skärmtid ändrades.",
        "max_reminders": "Du kan skapa upp till %d fokuspåminnelser.",
        "front_camera_unavailable": "Frontkameran är inte tillgänglig.",
        "task_title_empty": "Uppgiftstiteln kan inte vara tom.",
        "goal_title_empty": "Måltiteln kan inte vara tom.",
        "rate_limit_wait": "Vänta %d sekunder innan du skapar en ny sammanfattning.",
        "missed_alarm_for": "Du missade alarmet för: %@",
        "stay_with_plan": "Håll dig till planen.",
        "motivation_small_wins": "Små segrar ackumuleras.",
        "motivation_next_step": "Slutför nästa steg.",
        "motivation_protect_hour": "Skydda timmen framför dig.",
        "motivation_consistency": "Konsekvens slår intensitet.",
        "monthly_scope_btn": "Månad",
        "yearly_scope_btn": "År",
        "restoring_session": "Återställer din session...",

        // Milestones
        "milestone_3day_streak": "3-dagars svit",
        "milestone_3day_desc": "En stadig rytm har börjat.",
        "milestone_7day_streak": "7-dagars svit",
        "milestone_7day_desc": "En hel fokuserad vecka.",
        "milestone_10h_protected": "10 timmar skyddade",
        "milestone_10h_desc": "Tid skyddad för det viktiga.",
        "milestone_30_focus": "30 fokusdagar",
        "milestone_30_desc": "Konsekvens med verklig tyngd.",

        // Narratives
        "narrative_improved": "Din skärmtid förbättrades jämfört med förra veckan.",
        "narrative_consistent": "Du var konsekvent denna vecka och skyddade ditt fokus.",
        "narrative_more_days": "Du slutförde fler fokusdagar än vanligt.",
        "narrative_building": "Du bygger rytmen en fokuserad dag i taget.",

        // Screen time
        "screen_time_trend_pending": "Skärmtidstrenden visas när användningshistoriken växer.",
        "screen_time_improved": "Skärmtiden förbättrades med %d%%",
        "screen_time_higher": "Skärmtiden är något högre än vanligt",
        "screen_time_steady": "Skärmtiden är stabil denna vecka",

        // Benchmarks
        "benchmark_pending": "Genomsnittlig skärmtid visas när appen registrerar användningshistorik. Den globala referenspunkten är cirka 7 timmar per dag.",
        "benchmark_below": "Ditt 7-dagars genomsnitt är %@, under det globala genomsnittet på 7 timmar. Det är en stark riktning.",
        "benchmark_above": "Ditt 7-dagars genomsnitt är %@, över det globala genomsnittet på 7 timmar. En liten minskning idag kan ändra trenden.",
        "benchmark_matching": "Ditt 7-dagars genomsnitt är %@, lika med det globala genomsnittet på 7 timmar.",

        // Task editing
        "edit_task": "Redigera uppgift",
        "task_name_placeholder": "Uppgiftsnamn",
        "task_reminder_default": "Uppgiftspåminnelse",
        "time_h_m": "%dt %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Indonesian
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let id_: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Tentang mode fokus",
        "no_active_goals_title": "Tidak ada sasaran aktif",
        "no_active_goals_btn": "Mengerti",
        "no_active_goals_msg": "Mode Fokus dan Kunci hanya berjalan selama kamu memiliki sasaran yang belum selesai. Tambahkan sasaran — atau aktifkan kembali — lalu mulai sesimu.",
        // Tab bar
        "tab_home": "Beranda",
        "tab_progress": "Kemajuan",
        "tab_mode": "Mode",
        "tab_profile": "Profil",

        // Home
        "today": "Hari ini",
        "tomorrow": "Besok",
        "yesterday": "Kemarin",
        "back_to_today": "Kembali ke Hari ini",
        "add_first_task": "Ketuk + untuk menambahkan tugas pertamamu",
        "no_tasks_this_day": "Tidak ada tugas pada hari ini",
        "new_task": "Tugas Baru",
        "what_to_do": "Apa yang perlu kamu lakukan?",
        "task": "Tugas",
        "schedule": "Jadwal",
        "pick_date_hint": "Pilih tanggal mana pun — hari ini, minggu depan, atau beberapa bulan ke depan.",
        "priority": "Prioritas",
        "low": "Rendah",
        "medium": "Sedang",
        "high": "Tinggi",
        "notification": "Notifikasi",
        "silent_push": "Notifikasi push senyap",
        "notification_desc": "Mengirim notifikasi push satu kali pada waktu yang dijadwalkan. Muncul secara senyap di Layar Kunci dan Pusat Notifikasi.",
        "reminder": "Pengingat",
        "alarm_sound": "Alarm dengan suara & getaran",
        "reminder_desc": "Bekerja seperti alarm — suara khusus akan diputar dan ponselmu akan bergetar terus-menerus hingga kamu menekan tombol Tutup di layar. Cocok untuk rapat dan tenggat waktu.",
        "cancel": "Batal",
        "add": "Tambah",
        "edit": "Edit",
        "delete": "Hapus",
        "jump_to_date": "Lompat ke Tanggal",
        "done": "Selesai",
        "task_limit": "Kamu telah mencapai batas 25 tugas untuk tanggal ini.",
        "time": "Waktu",
        "date": "Tanggal",
        "select_date": "Pilih Tanggal",

        // Alarm
        "reminder_title": "Pengingat",
        "dismiss": "Tutup",

        // Progress
        "daily_progress": "Kemajuan Harian",
        "streaks": "streak",
        "focus_days": "hari fokus",
        "consistency": "konsistensi",
        "set_first_goal": "Tetapkan tujuan pertamamu untuk hari ini",
        "all_goals_completed": "Semua tujuan harian telah tercapai",
        "goals_completed": "dari",
        "daily_goals_completed": "tujuan harian tercapai",
        "daily_goals": "Tujuan Harian",
        "remaining": "tersisa",
        "no_goals_planned": "Tidak ada tujuan yang direncanakan",
        "complete_to_focus": "Selesaikan semua tugas untuk menandai hari ini sebagai hari fokus.",
        "add_task_to_start": "Tambahkan tugas dari Beranda untuk mulai melacak tujuan harian.",
        "daily_plan_complete": "Rencana harian selesai",
        "ai_weekly_summary": "Ringkasan Mingguan AI",
        "creating_summary": "Membuat ringkasan mingguanmu...",
        "generate_summary": "Buat Ringkasan",
        "refresh_summary": "Perbarui Ringkasan",
        "first_summary_coming": "Ringkasan mingguan AI pertamamu sedang dalam perjalanan.",
        "first_summary_desc": "Akan siap pada %@ pukul 21:00. Termasuk wawasan tentang kemajuanmu, tugas yang terlewat, dan mode fokus terbaik untukmu.",
        "next_update": "Pembaruan berikutnya: %@",
        "weekly_recap": "Rekap mingguan tentang hari fokus, tugas, dan tren produktivitas sudah siap.",
        "screen_time_7day": "Waktu Layar 7 Hari",
        "best_streak": "Streak Terbaik",
        "days": "hari",
        "milestones": "Pencapaian",
        "milestone_unlocked": "Pencapaian Terbuka",
        "continue_btn": "Lanjut",
        "history_calendar": "Kalender Riwayat",
        "mode_used": "Mode yang Digunakan",
        "completed": "Selesai",
        "not_completed": "Belum Selesai",
        "no_completed_tasks": "Tidak ada tugas yang diselesaikan tercatat untuk hari ini.",
        "everything_completed": "Semua telah diselesaikan.",
        "no_missed_tasks": "Tidak ada tugas yang terlewat tercatat untuk hari ini.",
        "streak_day": "Hari Streak",
        "missed_day": "Hari Terlewat",
        "first_name": "Nama Depan",
        "last_name": "Nama Belakang",
        "avatar_color": "Warna Avatar",
        "whats_your_name": "Siapa namamu?",
        "name_helps": "Ini membantu mempersonalisasi pengalamanmu.",
        "name_save_failed": "Kami tidak dapat menyimpan namamu. Periksa koneksi dan coba lagi.",
        "continue_btn_name": "Lanjut",
        "wins": "Kemenangan",
        "next_action": "Tindakan Selanjutnya",
        "average": "rata-rata",
        "todays_completion": "Penyelesaian hari ini",
        "streaks_this_month": "streak bulan ini",
        "streak_days": "hari streak",
        "non_streak_days": "hari tanpa streak",
        "monthly_streak_summary": "%d streak bulan ini • %d hari streak, %d hari tanpa streak",
        "duration_average": "%@ rata-rata",

        // Profile
        "personal_details": "Data Pribadi",
        "personal_info": "Informasi Pribadi",
        "update_email_name": "Perbarui email dan nama lengkapmu.",
        "and_username": "dan nama pengguna",
        "invite_friends": "Undang Teman",
        "refer_friend_title": "Referensikan teman dan dapatkan $10",
        "refer_friend_desc": "Dapatkan $10 untuk setiap teman yang mendaftar dengan kode promosimu.",
        "upgrade_family_plan": "Upgrade ke Paket Keluarga",
        "goals_tracking": "Tujuan & Pelacakan",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Edit Tujuan Nutrisi",
        "tracking_reminders": "Pengingat Pelacakan",
        "email_not_editable": "Emailmu terhubung dengan login dan tidak dapat diedit di sini.",
        "theme": "Tema",
        "theme_desc": "Gunakan tampilan sistem atau pilih mode terang/gelap tetap.",
        "appearance": "Tampilan",
        "appearance_desc": "Pilih tampilan terang, gelap, atau sistem",
        "live_activity_profile_desc": "Tampilkan kemajuan harianmu di Layar Kunci dan Dynamic Island",
        "system": "Sistem",
        "light": "Terang",
        "dark": "Gelap",
        "live_activity": "Live Activity",
        "live_activity_desc": "Tampilkan tujuan hari ini, streak, dan motivasi baru di Layar Kunci.",
        "privacy_policy": "Kebijakan Privasi",
        "privacy_desc": "Tinjau bagaimana data aplikasi dan izin perangkat digunakan.",
        "terms_of_service": "Ketentuan Layanan",
        "terms_desc": "Baca aturan penggunaan aplikasi dan alat fokusnya.",
        "follow_us": "Ikuti kami",
        "sign_out": "Keluar",
        "sign_out_desc": "Akhiri sesi ini pada perangkat saat ini.",
        "delete_account": "Hapus Akun",
        "delete_account_desc": "Hapus akunmu dan data aplikasi yang disinkronkan secara permanen.",
        "delete_account_title": "Hapus Akun",
        "delete_account_msg": "Tindakan ini bersifat permanen. Semua datamu akan dihapus dan tidak dapat dipulihkan.",
        "delete_account_continue": "Lanjut",
        "delete_account_final_title": "Hapus Permanen?",
        "delete_account_final_msg": "Mohon konfirmasi sekali lagi. Jika kamu menghapus akun, Spike AI akan mengeluarkanmu dan mengembalikanmu ke halaman login.",
        "deleting_account": "Menghapus akun...",
        "delete_failed": "Penghapusan akun gagal. Silakan coba lagi atau hubungi dukungan.",
        "language": "Bahasa",
        "language_desc": "Pilih bahasa untuk semua konten aplikasi.",
        "set_name": "Atur namamu",
        "profile_name_prompt": "Kami harus memanggilmu apa?",
        "profile_name_desc": "Tambahkan nama yang akan digunakan Spike AI di profil dan pengalaman produktivitasmu.",
        "full_name": "Nama Lengkap",
        "display_name": "Nama Tampilan",
        "email": "Email",
        "save_changes": "Simpan Perubahan",
        "save_footer": "Perubahan disimpan ke profilmu dan digunakan di mana pun identitasmu muncul di aplikasi.",
        "signed_in": "Sudah masuk",
        "account": "Akun",
        "preferences": "Preferensi",
        "support_legal": "Dukungan & Hukum",
        "account_actions": "Tindakan Akun",
        "pref_show_completed": "Tampilkan Tugas Selesai",
        "pref_show_completed_desc": "Tetap tampilkan tugas yang sudah selesai di daftar harianmu.",
        "pref_quotes": "Kutipan Motivasi",
        "pref_quotes_desc": "Tampilkan kutipan inspirasi di layar kemajuan.",
        "legal_updated": "Terakhir diperbarui: 25 Mei 2026",
        "privacy_body": """
        Terakhir diperbarui: 25 Mei 2026

        Spike AI adalah aplikasi produktivitas dan fokus. Kebijakan Privasi ini menjelaskan bagaimana Spike AI menangani informasi yang digunakan untuk menyediakan akun, perencanaan tugas, pengingat, mode fokus, kontrol Waktu Layar, pelacakan kemajuan, dan ringkasan produktivitas yang dihasilkan AI.

        Informasi yang kami kumpulkan: pengenal akun seperti alamat email dan ID pengguna; detail profil yang kamu pilih untuk diberikan, seperti nama tampilan dan nama lengkap; tugas, tujuan, pengingat, riwayat penyelesaian, pengaturan mode fokus, token pemilihan aplikasi, dan metrik kemajuan. Kami juga dapat menyimpan catatan teknis yang diperlukan untuk menjaga layanan tetap andal dan aman.

        Waktu Layar dan pemilihan aplikasi: pemilihan aplikasi, kategori, dan domain web ditangani melalui framework FamilyControls dan ManagedSettings Apple. Spike AI menyimpan token yang disediakan Apple yang diperlukan untuk menerapkan mode fokus pilihanmu. Kami tidak menggunakan pilihan ini untuk periklanan.

        Penggunaan kamera dalam Mode Atlet: akses kamera digunakan untuk pemeriksaan pose tubuh di perangkat agar kamu dapat memperoleh akses aplikasi sementara melalui gerakan. Spike AI tidak mengunggah frame video untuk fitur ini dan tidak menggunakan data kamera untuk periklanan.

        Notifikasi dan pengingat: Spike AI menggunakan izin notifikasi untuk mengirim pengingat tugas, alarm, dan dorongan fokus yang kamu konfigurasi. Kamu dapat mengubah akses notifikasi di Pengaturan iOS kapan saja.

        Ringkasan AI: jika kamu membuat ringkasan kemajuan, metrik tugas, tujuan, fokus, dan produktivitas terbaru dapat diproses oleh backend Spike AI untuk menghasilkan ringkasan. Hindari memasukkan informasi pribadi sensitif ke dalam nama tugas atau tujuan jika kamu tidak ingin diproses untuk fitur produktivitas.

        Bagaimana kami menggunakan informasi: untuk mengautentikasi kamu, menyinkronkan akun, menyediakan alat fokus, menjadwalkan pengingat, menampilkan kemajuan, mempersonalisasi wawasan produktivitas, melindungi dari penyalahgunaan, memecahkan masalah, dan mematuhi kewajiban hukum. Spike AI tidak menjual informasi pribadimu.

        Penghapusan data: kamu dapat keluar atau meminta penghapusan akun permanen dari Profil. Penghapusan akun menghapus akun autentikasi dan data aplikasi yang disinkronkan yang terkait dengan akun tersebut, dengan retensi terbatas yang diperlukan untuk keamanan, pencegahan penipuan, penyelesaian sengketa, atau kepatuhan hukum.

        Pilihanmu: kamu dapat mengedit detail profil, mengubah preferensi bahasa dan tampilan, menonaktifkan Live Activity, mencabut izin perangkat di Pengaturan, berhenti menggunakan mode fokus tertentu, atau menghapus akunmu.

        Kontak: untuk pertanyaan privasi atau masalah penghapusan akun, hubungi dukungan Spike AI melalui saluran dukungan yang disediakan oleh aplikasi atau daftar App Store.
        """,
        "terms_body": """
        Terakhir diperbarui: 25 Mei 2026

        Ketentuan Layanan ini mengatur penggunaanmu terhadap Spike AI, termasuk tugas, pengingat, mode fokus, prompt dan pemblokir aplikasi Waktu Layar, pemeriksaan gerakan Mode Atlet, pelacakan kemajuan, dan ringkasan yang dihasilkan AI.

        Kelayakan dan akun: kamu bertanggung jawab atas akun yang kamu buat dan menjaga keamanan akses ke email dan perangkatmu. Gunakan informasi yang akurat ketika aplikasi meminta detail profil.

        Tujuan produktivitas: Spike AI dirancang untuk mendukung produktivitas pribadi dan penggunaan perangkat yang disengaja. Ini bukan layanan medis, kesehatan mental, darurat, keselamatan, kontrol orang tua, pemantauan pekerjaan, atau manajemen perangkat. Jangan mengandalkan Spike AI di mana kegagalan pengingat, pemblokiran, prompt, pemeriksaan kamera, notifikasi, permintaan jaringan, atau izin Apple dapat menyebabkan bahaya.

        Tanggung jawabmu: pilih pengaturan fokus yang sesuai dengan situasimu; tinjau pemilihan aplikasi sebelum mengaktifkan mode; matikan mode ketika tidak lagi sesuai kebutuhanmu; patuhi hukum yang berlaku dan ketentuan platform Apple; dan hindari memasukkan informasi sensitif ke dalam tugas atau tujuan kecuali kamu nyaman menggunakannya dalam aplikasi.

        Penggunaan yang diterima: jangan menyalahgunakan Spike AI, mengganggu perangkat atau akun orang lain, mencoba melewati keamanan atau pembatasan platform, merekayasa balik bagian yang dilindungi dari layanan, membebani backend, atau menggunakan aplikasi untuk aktivitas yang melanggar hukum, kasar, menipu, atau berbahaya.

        Izin dan ketersediaan: beberapa fitur memerlukan izin iOS seperti Waktu Layar, notifikasi, kamera, Live Activities, dan akses jaringan. Apple, pengaturan perangkat, perilaku sistem operasi, konektivitas, dan ketersediaan backend dapat memengaruhi apakah fitur berfungsi seperti yang diharapkan.

        Konten yang dihasilkan AI: ringkasan kemajuan dapat dihasilkan menggunakan sistem otomatis. Ini hanya untuk refleksi dan pelatihan produktivitas. Tinjau dengan penilaianmu sendiri sebelum mengandalkannya.

        Penghapusan dan penghentian akun: kamu dapat meminta penghapusan akun dari Profil. Spike AI dapat menangguhkan atau menghentikan akses jika diwajibkan oleh hukum, aturan platform, masalah keamanan, atau penyalahgunaan serius.

        Perubahan: Spike AI dapat memperbarui Ketentuan ini seiring perkembangan aplikasi. Penggunaan berkelanjutan setelah pembaruan berarti kamu menerima Ketentuan yang diperbarui.

        Kontak: untuk pertanyaan tentang Ketentuan ini, hubungi dukungan Spike AI melalui saluran dukungan yang disediakan oleh aplikasi atau daftar App Store.
        """,

        // Focus Mode
        "focus_title": "Fokus",
        "select_mode": "Pilih Mode",
        "chill": "Santai",
        "focus": "Fokus",
        "lock_in": "Kunci",
        "sweat": "Atlet",
        "gentle_nudges": "Dorongan lembut",
        "confirm_intent": "Konfirmasi niat",
        "no_bypass": "Tidak bisa dilewati",
        "move_to_unlock": "Bergerak untuk membuka",
        "activate_focus": "Aktifkan Mode Fokus",
        "deactivate_focus": "Nonaktifkan Mode Fokus",
        "mode_active": "Mode Aktif",
        "reminders_scheduled": "Pengingat terjadwal",
        "apps_prompt_active": "aplikasi — prompt \"Apakah kamu yakin?\" aktif",
        "apps_blocked": "aplikasi diblokir",
        "temp_access_active": "Akses sementara aktif",
        "apps_require_movement": "aplikasi memerlukan gerakan untuk membuka",
        "notifications_label": "Notifikasi",
        "notifications_enabled": "Notifikasi diaktifkan",
        "notifications_denied": "Notifikasi ditolak",
        "enable_notif_settings": "Aktifkan notifikasi di Pengaturan.",
        "allow_notif_desc": "Izinkan notifikasi agar Spike AI dapat mengirim pengingat fokus.",
        "enable_notifications": "Aktifkan Notifikasi",
        "screen_time_access": "Akses Waktu Layar",
        "screen_time_authorized": "Waktu Layar diotorisasi",
        "allow_screen_time": "Izinkan Akses Waktu Layar",
        "tap_to_allow": "Ketuk di bawah untuk mengizinkan akses Waktu Layar.",
        "open_settings_manual": "Atau buka Pengaturan untuk mengaktifkan secara manual",
        "open_settings": "Buka Pengaturan",
        "app_selection": "Pemilihan Aplikasi",
        "selections": "pilihan",
        "choose_apps_confirm": "Pilih aplikasi yang perlu dikonfirmasi sebelum dibuka.",
        "choose_apps_block": "Pilih aplikasi yang akan diblokir.",
        "choose_apps_movement": "Pilih aplikasi yang dibuka dengan gerakan.",
        "change_selection": "Ubah Pilihan",
        "select_apps": "Pilih Aplikasi",
        "movement_unlock": "Buka dengan Gerakan",
        "movement_desc": "Push-up dan stand-up dilacak dengan deteksi tubuh AI. Setiap repetisi yang terverifikasi menambah 1 menit akses ke aplikasi yang dipilih.",
        "access_available": "Akses tersedia selama %@",
        "open_camera": "Buka Pemeriksaan Kamera",
        "lock_in_mode": "Mode Kunci",
        "lock_in_warning": "Aplikasi menampilkan layar merah tanpa jalan pintas. Kamu harus kembali ke sini untuk mematikan Mode Kunci.",
        "sweat_mode": "Mode Atlet",
        "do_exercises": "Lakukan push-up atau stand-up untuk mendapatkan waktu",
        "add_minutes": "Tambah %d Menit",
        "keep_in_view": "Pastikan bahu, lengan, atau pinggul terlihat",
        "camera_required": "Akses kamera diperlukan untuk pemeriksaan gerakan.",
        "camera_disabled": "Akses kamera dinonaktifkan. Aktifkan di Pengaturan untuk menggunakan Mode Olahraga.",
        "camera_unavailable": "Akses kamera tidak tersedia.",
        "starting_camera": "Memulai kamera...",
        "camera_active": "Kamera aktif",
        "allow_camera": "Izinkan Akses Kamera",
        "focus_mode_title": "Mode Fokus",
        "focus_mode_desc": "Kendalikan kebiasaan digitalmu dengan mode yang fokus dan profesional.",
        "about_permissions": "Tentang Izin",
        "permissions_desc": "Mode Santai memerlukan izin notifikasi. Mode Fokus, Kunci, dan Olahraga memerlukan otorisasi Waktu Layar. Mode Olahraga juga menggunakan akses kamera untuk pemeriksaan gerakan.",
        "get_started": "Mulai",
        "skip": "Lewati",
        "unlocked_for": "Terbuka selama %@",

        // Chill mode descriptions
        "chill_desc": "Pengingat harian melalui notifikasi. Tanpa kontrol aplikasi — hanya dorongan lembut untuk tetap sadar.",
        "focus_desc": "Saat kamu membuka aplikasi yang dipilih, Spike AI bertanya \"Apakah kamu yakin?\" Kamu bisa membukanya secara normal atau kembali ke tugasmu. Aplikasi tidak diblokir.",
        "lock_in_desc": "Aplikasi yang dipilih diblokir selama Mode Kunci aktif. Kamu bisa mematikan mode dari Spike AI.",
        "sweat_desc": "Aplikasi yang dipilih tetap diblokir sampai kamu menyelesaikan push-up atau stand-up yang diperiksa kamera. Setiap repetisi terverifikasi membuka 1 menit.",

        // Motivational (deactivation)
        "giving_up_title": "Kamu membuat kemajuan — jangan berhenti sekarang",
        "giving_up_msg": "Kamu masih memiliki tujuan yang belum selesai hari ini. Setiap tugas yang selesai membangun momentum. Tetap berkomitmen — dirimu di masa depan akan berterima kasih.",
        "giving_up_continue": "Tetap Fokus",
        "giving_up_stop": "Matikan Saja",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Sistem produktivitas pribadimu",
        "start_setup": "Mulai Pengaturan",
        "make_phone_work": "Jadikan ponselmu bekerja\nuntuk tujuanmu.",
        "onboarding_welcome_desc": "Kurangi scrolling tanpa tujuan, lindungi waktu fokus, dan ubah tugas nyata menjadi kemajuan yang terlihat.",
        "did_you_know": "Tahukah kamu?",
        "did_you_know_subtitle": "Seseorang menghabiskan rata-rata 7 jam per hari di ponsel mereka. Itu setara dengan",
        "hours_per_day": "jam per hari",
        "days_per_month": "hari per bulan",
        "days_per_year": "hari per tahun",
        "years_of_life": "tahun hidupmu",
        "screen_time_reality": "Dan beberapa orang menghabiskan lebih banyak lagi.",
        "dont_worry_title": "Jangan khawatir",
        "spike_has_your_back": "Spike AI mendukungmu",
        "solution_desc": "Kami akan membantumu memaksimalkan produktivitas, mendekati tujuanmu, dan membangun kebiasaan yang mengubahmu menjadi versi terbaik dirimu.",
        "screen_time_access_title": "Akses Waktu Layar",
        "grant_access": "Berikan Akses",
        "which_apps": "Pilih aplikasi\nyang mengganggu",
        "choose_apps_protect": "Pilih aplikasi yang membuang waktumu. Kami akan memblokirnya selama mode fokus.",
        "apple_screen_time_required": "Apple memerlukan akses Waktu Layar sebelum Spike AI dapat menampilkan daftar aplikasimu.",
        "save_apps": "Simpan & Lanjut",
        "change_selected_apps": "Ubah aplikasi yang dipilih",
        "ready_change_life": "Siap mengubah\nhidupmu?",
        "ready_change_desc": "Buat akun untuk menyimpan pilihanmu dan memulai perjalanan.",
        "benefit_no_distraction": "Aplikasi yang mengganggu tidak akan mengganggumu lagi",
        "benefit_discover_modes": "Temukan 4 jenis mode fokus yang berbeda",
        "benefit_track_progress": "Lacak kemajuanmu dan mendekati tujuanmu",
        "create_account": "Buat Akun",
        "protect_focus": "Lindungi Fokus",
        "block_feeds": "Blokir feed",
        "finish_tasks": "Selesaikan tugas",
        "energy_plus_three": "+3 Energi",
        "selected_count": "%d dipilih",
        "no_apps_selected": "Belum ada aplikasi yang dipilih",
        "saved_for_modes": "Disimpan untuk mode perlindungan",
        "select_apps_to_control": "Pilih aplikasi yang ingin kamu kontrol",
        "clean_room": "Bersihkan Kamar",
        "snap_proof": "Foto bukti saat selesai",
        "ai_verifies_task": "AI memverifikasi tugas",
        "energy_earned": "+3 Energi diperoleh",
        "on_track": "Sesuai rencana",
        "energy": "Energi",
        "tasks_completed": "Tugas selesai",
        "focus_protected": "Fokus terlindungi",
        "scrolling_avoided": "Scrolling dihindari",
        "continue_apple": "Lanjut dengan Apple",
        "continue_google": "Lanjut dengan Google",
        "continue_email": "Lanjut dengan email",
        "enter_email": "Masukkan emailmu",
        "send_sign_in_link": "Kami akan mengirim tautan masuk",
        "check_email": "Periksa emailmu",
        "sent_link_to": "Kami mengirim tautan masuk ke",
        "tap_link": "Ketuk tautan untuk masuk secara otomatis.",
        "open_mail": "Buka Aplikasi Mail",
        "open_with": "Buka dengan",
        "didnt_get_email": "Tidak mendapat email?",
        "resend": "Kirim ulang",
        "resend_in": "Kirim ulang dalam %d detik",
        "new_link_sent": "Tautan baru telah dikirim!",
        "valid_email": "Masukkan alamat email yang valid.",
        "by_continuing": "Dengan melanjutkan, kamu menyetujui",
        "and_word": "dan",

        // Screen Time Onboarding
        "screen_time_title": "Waktu Layar",
        "screen_time_permission_desc": "Spike AI memerlukan izin Waktu Layar untuk mode Fokus, Kunci, dan Olahraga. Ini memungkinkannya menampilkan prompt dan pemblokiran untuk aplikasi pilihanmu.",
        "screen_time_denied": "Izin ditolak. Kamu bisa mengaktifkannya di Pengaturan.",
        "ask_before_opening": "Tanya Sebelum Membuka",
        "block_apps_completely": "Blokir Aplikasi Sepenuhnya",
        "stay_accountable": "Tetap Bertanggung Jawab",
        "stay_accountable_desc": "Lacak kemajuan dan jaga kebiasaan fokusmu terlihat.",
        "skip_for_now": "Lewati untuk Sekarang",

        // Live Activity
        "daily_goals_title": "Tujuan Harian",
        "of_done": "dari %d selesai",
        "more_to_go": "+%d lagi",

        // Chill morning
        "good_morning": "Selamat pagi! Tetap sadar hari ini. Tinjau tugasmu dan tetap fokus.",

        // Onboarding (extended)
        "scrolling_adds_up": "Scrolling terlihat kecil,\ntapi menumpuk.",
        "per_day": "per hari",
        "per_month": "per bulan",
        "per_year": "per tahun",
        "thirty_days": "30 hari",
        "lost_to_checking": "hilang untuk pengecekan otomatis",
        "scrolling_cost_desc": "Spike AI membantumu menyadari momen-momen itu sebelum memakan seluruh malam.",
        "your_modes_target": "Modemu sekarang memiliki\ntarget yang jelas.",
        "app_selections_will_be_used": "%d pilihan aplikasi akan digunakan saat kamu memulai mode perlindungan.",
        "select_apps_after_login": "Pilih aplikasi sekali setelah login, semua mode perlindungan akan menggunakan daftar yang sama.",
        "focus_mode_marketing_detail": "Jeda singkat sebelum membuka aplikasi yang mengganggu.",
        "lock_in_marketing_detail": "Batasan lebih kuat saat kamu butuh fokus mendalam.",
        "sweat_marketing_detail": "Bergerak dulu untuk mendapatkan waktu akses.",
        "replace_scroll": "Ganti scrolling dengan\npencapaian nyata.",
        "habit_desc": "Ubah tindakan bermanfaat menjadi energi: bersihkan kamar, kumpulkan tugas, jalan, peregangan, atau selesaikan satu tugas.",
        "see_behavior_changing": "Lihat perilakumu\nberubah.",
        "progress_desc": "Lacak waktu fokus, penyelesaian tugas, dan streak agar kemajuan terasa nyata.",
        "ready_protected_day": "Siap untuk hari pertama\nyang terlindungi?",
        "create_account_desc": "Buat akun untuk menyimpan pilihan aplikasi, mode fokus, tugas, dan kemajuan.",
        "benefit_apps_saved": "Aplikasi yang mengganggu disimpan untuk mode",
        "benefit_start_modes": "Mulai mode Fokus, Kunci, atau Olahraga",
        "benefit_progress_synced": "Kemajuanmu tersinkronisasi",

        // General
        "error": "Kesalahan",
        "ok": "OK",
        "yes": "Ya",
        "no": "Tidak",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Beralih ke Mode Santai?",
        "stay_focused_btn": "Tetap Fokus",
        "switch_anyway_btn": "Tetap Beralih",
        "switch_to_chill_msg": "Kamu masih memiliki tujuan yang belum selesai. Beralih ke Mode Santai menghapus pemblokiran aplikasi, yang meningkatkan risiko tidak menyelesaikan tujuanmu hari ini.",
        "task_notification": "Notifikasi Tugas",
        "missed_alarm": "Alarm Terlewat",
        "quote_of_day": "Kutipan Hari Ini",
        "new_quotes_daily": "Kutipan baru hadir setiap hari pukul 05:00",
        "focus_day_label": "Hari Fokus",
        "missed_label": "Terlewat",
        "access_granted": "Akses diberikan",
        "goal_reminder": "Pengingat Tujuan",
        "spike_ai_focus": "Spike AI Fokus",
        "goals_required_title": "Tujuan Diperlukan",
        "goals_required_desc_focus": "Mode Fokus memblokir aplikasi terpilih hanya saat kamu memiliki tujuan yang belum selesai. Tambahkan tujuan di tab Beranda untuk mengaktifkan pemblokiran aplikasi.",
        "goals_required_desc_lockin": "Mode Kunci memblokir aplikasi terpilih hanya saat kamu memiliki tujuan yang belum selesai. Tambahkan tujuan di tab Beranda untuk mengaktifkan pemblokiran aplikasi.",
        "save": "Simpan",
        "no_goals_reminder_body": "Kamu belum menetapkan tujuan apa pun untuk hari ini. Luangkan waktu sejenak untuk merencanakan harimu!",
        "dont_forget": "Jangan lupa",
        "chill_morning_body": "Selamat pagi! Tetap terarah hari ini. Tinjau tugasmu dan tetap fokus.",
        "every_day": "Setiap hari",
        "weekdays": "Hari kerja",
        "weekends": "Akhir pekan",
        "time_to_focus": "Saatnya fokus!",

        // Additional UI strings
        "next_quote_in": "Kutipan berikutnya dalam %@",
        "enable_notif_chill": "Aktifkan notifikasi sebelum memulai mode Santai.",
        "enable_screen_time_mode": "Aktifkan akses Durasi Layar sebelum memulai mode ini.",
        "select_app_before_mode": "Pilih setidaknya satu aplikasi, kategori, atau situs web sebelum memulai mode ini.",
        "mode_not_ready": "Mode ini belum siap untuk dimulai.",
        "protection_stopped_no_apps": "Perlindungan dihentikan: tidak ada aplikasi yang dipilih.",
        "protection_stopped_screen_time": "Perlindungan dihentikan: akses Durasi Layar berubah.",
        "max_reminders": "Anda dapat membuat hingga %d pengingat fokus.",
        "front_camera_unavailable": "Kamera depan tidak tersedia.",
        "task_title_empty": "Judul tugas tidak boleh kosong.",
        "goal_title_empty": "Judul tujuan tidak boleh kosong.",
        "rate_limit_wait": "Tunggu %d detik sebelum membuat ringkasan lain.",
        "missed_alarm_for": "Anda melewatkan alarm untuk: %@",
        "stay_with_plan": "Tetap pada rencana.",
        "motivation_small_wins": "Kemenangan kecil terakumulasi.",
        "motivation_next_step": "Selesaikan langkah berikutnya.",
        "motivation_protect_hour": "Lindungi jam di depan Anda.",
        "motivation_consistency": "Konsistensi mengalahkan intensitas.",
        "monthly_scope_btn": "Bulanan",
        "yearly_scope_btn": "Tahunan",
        "restoring_session": "Memulihkan sesi Anda...",

        // Milestones
        "milestone_3day_streak": "Beruntun 3 hari",
        "milestone_3day_desc": "Ritme yang stabil telah dimulai.",
        "milestone_7day_streak": "Beruntun 7 hari",
        "milestone_7day_desc": "Satu minggu fokus penuh.",
        "milestone_10h_protected": "10 jam dilindungi",
        "milestone_10h_desc": "Waktu dilindungi untuk hal penting.",
        "milestone_30_focus": "30 hari fokus",
        "milestone_30_desc": "Konsistensi yang nyata.",

        // Narratives
        "narrative_improved": "Waktu layar Anda membaik dibandingkan minggu lalu.",
        "narrative_consistent": "Anda konsisten minggu ini dan melindungi fokus Anda.",
        "narrative_more_days": "Anda menyelesaikan lebih banyak hari fokus dari biasanya.",
        "narrative_building": "Anda membangun ritme satu hari fokus pada satu waktu.",

        // Screen time
        "screen_time_trend_pending": "Tren waktu layar akan muncul seiring bertambahnya riwayat penggunaan.",
        "screen_time_improved": "Waktu layar membaik %d%%",
        "screen_time_higher": "Waktu layar sedikit lebih tinggi dari biasanya",
        "screen_time_steady": "Waktu layar stabil minggu ini",

        // Benchmarks
        "benchmark_pending": "Rata-rata waktu layar akan muncul saat aplikasi mencatat riwayat penggunaan. Titik referensi global sekitar 7 jam per hari.",
        "benchmark_below": "Rata-rata 7 hari Anda adalah %@, di bawah rata-rata global 7 jam. Arah yang kuat.",
        "benchmark_above": "Rata-rata 7 hari Anda adalah %@, di atas rata-rata global 7 jam. Pengurangan kecil hari ini bisa mengubah tren.",
        "benchmark_matching": "Rata-rata 7 hari Anda adalah %@, sama dengan rata-rata global 7 jam.",

        // Task editing
        "edit_task": "Edit Tugas",
        "task_name_placeholder": "Nama tugas",
        "task_reminder_default": "Pengingat tugas",
        "time_h_m": "%dj %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Vietnamese
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let vi: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Giới thiệu về chế độ tập trung",
        "no_active_goals_title": "Không có mục tiêu đang hoạt động",
        "no_active_goals_btn": "Đã hiểu",
        "no_active_goals_msg": "Chế độ Tập trung và Khóa chỉ hoạt động khi bạn có một mục tiêu chưa hoàn thành. Hãy thêm một mục tiêu — hoặc kích hoạt lại — rồi bắt đầu phiên của bạn.",
        // Tab bar
        "tab_home": "Trang chủ",
        "tab_progress": "Tiến độ",
        "tab_mode": "Chế độ",
        "tab_profile": "Hồ sơ",

        // Home
        "today": "Hôm nay",
        "tomorrow": "Ngày mai",
        "yesterday": "Hôm qua",
        "back_to_today": "Quay về Hôm nay",
        "add_first_task": "Nhấn + để thêm nhiệm vụ đầu tiên",
        "no_tasks_this_day": "Không có nhiệm vụ trong ngày này",
        "new_task": "Nhiệm vụ mới",
        "what_to_do": "Bạn cần làm gì?",
        "task": "Nhiệm vụ",
        "schedule": "Lịch trình",
        "pick_date_hint": "Chọn bất kỳ ngày nào — hôm nay, tuần sau hoặc vài tháng tới.",
        "priority": "Mức ưu tiên",
        "low": "Thấp",
        "medium": "Trung bình",
        "high": "Cao",
        "notification": "Thông báo",
        "silent_push": "Thông báo đẩy im lặng",
        "notification_desc": "Gửi thông báo đẩy một lần vào thời gian đã lên lịch. Nó xuất hiện yên lặng trên Màn hình khóa và Trung tâm thông báo.",
        "reminder": "Nhắc nhở",
        "alarm_sound": "Báo thức với âm thanh và rung",
        "reminder_desc": "Hoạt động như báo thức — âm thanh đặc biệt sẽ phát và điện thoại sẽ rung liên tục cho đến khi bạn nhấn nút Tắt trên màn hình. Rất phù hợp cho cuộc họp và thời hạn.",
        "cancel": "Hủy",
        "add": "Thêm",
        "edit": "Sửa",
        "delete": "Xóa",
        "jump_to_date": "Chuyển đến ngày",
        "done": "Xong",
        "task_limit": "Bạn đã đạt giới hạn 25 nhiệm vụ cho ngày này.",
        "time": "Thời gian",
        "date": "Ngày",
        "select_date": "Chọn ngày",

        // Alarm
        "reminder_title": "Nhắc nhở",
        "dismiss": "Tắt",

        // Progress
        "daily_progress": "Tiến độ hàng ngày",
        "streaks": "chuỗi",
        "focus_days": "ngày tập trung",
        "consistency": "sự nhất quán",
        "set_first_goal": "Đặt mục tiêu đầu tiên cho hôm nay",
        "all_goals_completed": "Đã hoàn thành tất cả mục tiêu hàng ngày",
        "goals_completed": "trong",
        "daily_goals_completed": "mục tiêu hàng ngày đã hoàn thành",
        "daily_goals": "Mục tiêu hàng ngày",
        "remaining": "còn lại",
        "no_goals_planned": "Không có mục tiêu nào được lên kế hoạch",
        "complete_to_focus": "Hoàn thành mọi nhiệm vụ để đánh dấu hôm nay là ngày tập trung.",
        "add_task_to_start": "Thêm nhiệm vụ từ Trang chủ để bắt đầu theo dõi mục tiêu hàng ngày.",
        "daily_plan_complete": "Hoàn thành kế hoạch hàng ngày",
        "ai_weekly_summary": "Tóm tắt tuần AI",
        "creating_summary": "Đang tạo tóm tắt tuần của bạn...",
        "generate_summary": "Tạo tóm tắt",
        "refresh_summary": "Làm mới tóm tắt",
        "first_summary_coming": "Bản tóm tắt tuần AI đầu tiên của bạn đang được chuẩn bị.",
        "first_summary_desc": "Sẽ sẵn sàng vào %@ lúc 9 giờ tối. Bao gồm thông tin chi tiết về tiến độ, nhiệm vụ bỏ lỡ và chế độ tập trung tốt nhất cho bạn.",
        "next_update": "Cập nhật tiếp theo: %@",
        "weekly_recap": "Tóm tắt tuần về ngày tập trung, nhiệm vụ và xu hướng năng suất đã sẵn sàng.",
        "screen_time_7day": "Thời gian sử dụng 7 ngày",
        "best_streak": "Chuỗi tốt nhất",
        "days": "ngày",
        "milestones": "Cột mốc",
        "milestone_unlocked": "Đã mở khóa cột mốc",
        "continue_btn": "Tiếp tục",
        "history_calendar": "Lịch sử",
        "mode_used": "Chế độ đã dùng",
        "completed": "Đã hoàn thành",
        "not_completed": "Chưa hoàn thành",
        "no_completed_tasks": "Không có nhiệm vụ hoàn thành nào được ghi nhận cho ngày này.",
        "everything_completed": "Mọi thứ đã được hoàn thành.",
        "no_missed_tasks": "Không có nhiệm vụ bỏ lỡ nào được ghi nhận cho ngày này.",
        "streak_day": "Ngày chuỗi",
        "missed_day": "Ngày bỏ lỡ",
        "first_name": "Tên",
        "last_name": "Họ",
        "avatar_color": "Màu ảnh đại diện",
        "whats_your_name": "Tên bạn là gì?",
        "name_helps": "Điều này giúp cá nhân hóa trải nghiệm của bạn.",
        "name_save_failed": "Không thể lưu tên của bạn. Kiểm tra kết nối và thử lại.",
        "continue_btn_name": "Tiếp tục",
        "wins": "Thành tích",
        "next_action": "Hành động tiếp theo",
        "average": "trung bình",
        "todays_completion": "Tiến độ hôm nay",
        "streaks_this_month": "chuỗi tháng này",
        "streak_days": "ngày chuỗi",
        "non_streak_days": "ngày không chuỗi",
        "monthly_streak_summary": "%d chuỗi tháng này • %d ngày chuỗi, %d ngày không chuỗi",
        "duration_average": "%@ trung bình",

        // Profile
        "personal_details": "Thông tin cá nhân",
        "personal_info": "Thông tin cá nhân",
        "update_email_name": "Cập nhật email và họ tên của bạn.",
        "and_username": "và tên người dùng",
        "invite_friends": "Mời bạn bè",
        "refer_friend_title": "Giới thiệu bạn bè và nhận $10",
        "refer_friend_desc": "Nhận $10 cho mỗi bạn bè đăng ký bằng mã khuyến mãi của bạn.",
        "upgrade_family_plan": "Nâng cấp lên Gói gia đình",
        "goals_tracking": "Mục tiêu & Theo dõi",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Chỉnh sửa mục tiêu dinh dưỡng",
        "tracking_reminders": "Nhắc nhở theo dõi",
        "email_not_editable": "Email của bạn được liên kết với đăng nhập và không thể chỉnh sửa ở đây.",
        "theme": "Giao diện",
        "theme_desc": "Sử dụng giao diện hệ thống hoặc chọn chế độ sáng/tối cố định.",
        "appearance": "Giao diện",
        "appearance_desc": "Chọn giao diện sáng, tối hoặc hệ thống",
        "live_activity_profile_desc": "Hiển thị tiến độ hàng ngày trên Màn hình khóa và Dynamic Island",
        "system": "Hệ thống",
        "light": "Sáng",
        "dark": "Tối",
        "live_activity": "Live Activity",
        "live_activity_desc": "Hiển thị mục tiêu hôm nay, chuỗi và động lực mới trên Màn hình khóa.",
        "privacy_policy": "Chính sách bảo mật",
        "privacy_desc": "Xem lại cách dữ liệu ứng dụng và quyền thiết bị được sử dụng.",
        "terms_of_service": "Điều khoản dịch vụ",
        "terms_desc": "Đọc các quy tắc sử dụng ứng dụng và công cụ tập trung.",
        "follow_us": "Theo dõi chúng tôi",
        "sign_out": "Đăng xuất",
        "sign_out_desc": "Kết thúc phiên trên thiết bị hiện tại.",
        "delete_account": "Xóa tài khoản",
        "delete_account_desc": "Xóa vĩnh viễn tài khoản và dữ liệu ứng dụng đã đồng bộ.",
        "delete_account_title": "Xóa tài khoản",
        "delete_account_msg": "Hành động này là vĩnh viễn. Tất cả dữ liệu của bạn sẽ bị xóa và không thể khôi phục.",
        "delete_account_continue": "Tiếp tục",
        "delete_account_final_title": "Xóa vĩnh viễn?",
        "delete_account_final_msg": "Vui lòng xác nhận thêm một lần nữa. Nếu bạn xóa tài khoản, Spike AI sẽ đăng xuất và đưa bạn trở lại trang đăng nhập.",
        "deleting_account": "Đang xóa tài khoản...",
        "delete_failed": "Xóa tài khoản thất bại. Vui lòng thử lại hoặc liên hệ bộ phận hỗ trợ.",
        "language": "Ngôn ngữ",
        "language_desc": "Chọn ngôn ngữ cho tất cả nội dung ứng dụng.",
        "set_name": "Đặt tên của bạn",
        "profile_name_prompt": "Chúng tôi nên gọi bạn là gì?",
        "profile_name_desc": "Thêm tên mà Spike AI sẽ sử dụng trong hồ sơ và trải nghiệm năng suất của bạn.",
        "full_name": "Họ và tên",
        "display_name": "Tên hiển thị",
        "email": "Email",
        "save_changes": "Lưu thay đổi",
        "save_footer": "Các thay đổi được lưu vào hồ sơ của bạn và được sử dụng ở bất kỳ nơi nào danh tính của bạn xuất hiện trong ứng dụng.",
        "signed_in": "Đã đăng nhập",
        "account": "Tài khoản",
        "preferences": "Tùy chọn",
        "support_legal": "Hỗ trợ & Pháp lý",
        "account_actions": "Thao tác tài khoản",
        "pref_show_completed": "Hiện nhiệm vụ đã hoàn thành",
        "pref_show_completed_desc": "Giữ hiển thị các nhiệm vụ đã hoàn thành trong danh sách hàng ngày.",
        "pref_quotes": "Câu nói truyền cảm hứng",
        "pref_quotes_desc": "Hiển thị câu nói truyền cảm hứng trên màn hình tiến độ.",
        "legal_updated": "Cập nhật lần cuối: 25 tháng 5, 2026",
        "privacy_body": """
        Cập nhật lần cuối: 25 tháng 5, 2026

        Spike AI là ứng dụng năng suất và tập trung. Chính sách Bảo mật này giải thích cách Spike AI xử lý thông tin được sử dụng để cung cấp tài khoản, lập kế hoạch nhiệm vụ, nhắc nhở, chế độ tập trung, kiểm soát Thời gian sử dụng, theo dõi tiến độ và tóm tắt năng suất do AI tạo ra.

        Thông tin chúng tôi thu thập: mã định danh tài khoản như địa chỉ email và ID người dùng; chi tiết hồ sơ mà bạn chọn cung cấp, như tên hiển thị và họ tên; nhiệm vụ, mục tiêu, nhắc nhở, lịch sử hoàn thành, cài đặt chế độ tập trung, token chọn ứng dụng và chỉ số tiến độ. Chúng tôi cũng có thể lưu trữ các bản ghi kỹ thuật cần thiết để duy trì dịch vụ đáng tin cậy và an toàn.

        Thời gian sử dụng và lựa chọn ứng dụng: lựa chọn ứng dụng, danh mục và tên miền web được xử lý thông qua các framework FamilyControls và ManagedSettings của Apple. Spike AI lưu trữ các token do Apple cung cấp cần thiết để áp dụng các chế độ tập trung bạn đã chọn. Chúng tôi không sử dụng các lựa chọn này cho mục đích quảng cáo.

        Sử dụng camera trong Chế độ Vận động viên: quyền truy cập camera được sử dụng để kiểm tra tư thế cơ thể trên thiết bị để bạn có thể kiếm quyền truy cập ứng dụng tạm thời thông qua vận động. Spike AI không tải lên khung hình video cho tính năng này và không sử dụng dữ liệu camera cho mục đích quảng cáo.

        Thông báo và nhắc nhở: Spike AI sử dụng quyền thông báo để gửi nhắc nhở nhiệm vụ, báo thức và gợi ý tập trung mà bạn cấu hình. Bạn có thể thay đổi quyền truy cập thông báo trong Cài đặt iOS bất kỳ lúc nào.

        Tóm tắt AI: nếu bạn tạo tóm tắt tiến độ, các chỉ số nhiệm vụ, mục tiêu, tập trung và năng suất gần đây có thể được xử lý bởi backend của Spike AI để tạo tóm tắt. Tránh nhập thông tin cá nhân nhạy cảm vào tên nhiệm vụ hoặc mục tiêu nếu bạn không muốn nó được xử lý cho các tính năng năng suất.

        Cách chúng tôi sử dụng thông tin: để xác thực bạn, đồng bộ tài khoản, cung cấp công cụ tập trung, lên lịch nhắc nhở, hiển thị tiến độ, cá nhân hóa thông tin chi tiết về năng suất, bảo vệ chống lạm dụng, khắc phục sự cố và tuân thủ các nghĩa vụ pháp lý. Spike AI không bán thông tin cá nhân của bạn.

        Xóa dữ liệu: bạn có thể đăng xuất hoặc yêu cầu xóa tài khoản vĩnh viễn từ Hồ sơ. Xóa tài khoản sẽ xóa tài khoản xác thực và dữ liệu ứng dụng đã đồng bộ liên quan đến tài khoản đó, với việc lưu giữ hạn chế cần thiết cho bảo mật, phòng chống gian lận, giải quyết tranh chấp hoặc tuân thủ pháp luật.

        Lựa chọn của bạn: bạn có thể chỉnh sửa chi tiết hồ sơ, thay đổi tùy chọn ngôn ngữ và giao diện, tắt Live Activity, thu hồi quyền thiết bị trong Cài đặt, ngừng sử dụng các chế độ tập trung cụ thể hoặc xóa tài khoản.

        Liên hệ: đối với câu hỏi về quyền riêng tư hoặc vấn đề xóa tài khoản, vui lòng liên hệ bộ phận hỗ trợ Spike AI thông qua kênh hỗ trợ do ứng dụng hoặc danh sách App Store cung cấp.
        """,
        "terms_body": """
        Cập nhật lần cuối: 25 tháng 5, 2026

        Các Điều khoản Dịch vụ này điều chỉnh việc sử dụng Spike AI của bạn, bao gồm nhiệm vụ, nhắc nhở, chế độ tập trung, lời nhắc và chặn ứng dụng Thời gian sử dụng, kiểm tra vận động Chế độ Vận động viên, theo dõi tiến độ và tóm tắt do AI tạo ra.

        Điều kiện và tài khoản: bạn chịu trách nhiệm về tài khoản bạn tạo và việc giữ an toàn quyền truy cập vào email và thiết bị. Sử dụng thông tin chính xác khi ứng dụng yêu cầu chi tiết hồ sơ.

        Mục đích năng suất: Spike AI được thiết kế để hỗ trợ năng suất cá nhân và sử dụng thiết bị có chủ đích. Đây không phải dịch vụ y tế, sức khỏe tâm thần, khẩn cấp, an toàn, kiểm soát của phụ huynh, giám sát việc làm hoặc quản lý thiết bị. Không dựa vào Spike AI khi sự cố nhắc nhở, chặn, lời nhắc, kiểm tra camera, thông báo, yêu cầu mạng hoặc quyền Apple có thể gây hại.

        Trách nhiệm của bạn: chọn cài đặt tập trung phù hợp với tình huống của bạn; xem lại lựa chọn ứng dụng trước khi kích hoạt chế độ; tắt chế độ khi không còn phù hợp; tuân thủ luật pháp hiện hành và điều khoản nền tảng Apple; và tránh nhập thông tin nhạy cảm vào nhiệm vụ hoặc mục tiêu trừ khi bạn thoải mái sử dụng nó trong ứng dụng.

        Sử dụng chấp nhận được: không lạm dụng Spike AI, can thiệp vào thiết bị hoặc tài khoản của người khác, cố gắng vượt qua các hạn chế bảo mật hoặc nền tảng, dịch ngược các phần được bảo vệ của dịch vụ, gây quá tải backend hoặc sử dụng ứng dụng cho hoạt động bất hợp pháp, lạm dụng, lừa đảo hoặc có hại.

        Quyền và tính khả dụng: một số tính năng yêu cầu quyền iOS như Thời gian sử dụng, thông báo, camera, Live Activities và truy cập mạng. Apple, cài đặt thiết bị, hành vi hệ điều hành, kết nối và tính khả dụng của backend có thể ảnh hưởng đến việc các tính năng hoạt động như mong đợi.

        Nội dung do AI tạo ra: tóm tắt tiến độ có thể được tạo bằng hệ thống tự động. Chúng chỉ dành cho việc suy ngẫm và hướng dẫn năng suất. Xem xét chúng với phán đoán của riêng bạn trước khi dựa vào.

        Xóa tài khoản và chấm dứt: bạn có thể yêu cầu xóa tài khoản từ Hồ sơ. Spike AI có thể tạm ngưng hoặc chấm dứt quyền truy cập nếu được yêu cầu bởi luật pháp, quy tắc nền tảng, lo ngại bảo mật hoặc lạm dụng nghiêm trọng.

        Thay đổi: Spike AI có thể cập nhật các Điều khoản này khi ứng dụng phát triển. Tiếp tục sử dụng sau khi cập nhật có nghĩa là bạn chấp nhận các Điều khoản đã cập nhật.

        Liên hệ: đối với câu hỏi về các Điều khoản này, vui lòng liên hệ bộ phận hỗ trợ Spike AI thông qua kênh hỗ trợ do ứng dụng hoặc danh sách App Store cung cấp.
        """,

        // Focus Mode
        "focus_title": "Tập trung",
        "select_mode": "Chọn chế độ",
        "chill": "Thư giãn",
        "focus": "Tập trung",
        "lock_in": "Khóa",
        "sweat": "Vận động viên",
        "gentle_nudges": "Nhắc nhở nhẹ nhàng",
        "confirm_intent": "Xác nhận ý định",
        "no_bypass": "Không thể bỏ qua",
        "move_to_unlock": "Vận động để mở khóa",
        "activate_focus": "Kích hoạt chế độ tập trung",
        "deactivate_focus": "Tắt chế độ tập trung",
        "mode_active": "Chế độ đang hoạt động",
        "reminders_scheduled": "Đã lên lịch nhắc nhở",
        "apps_prompt_active": "ứng dụng — lời nhắc \"Bạn có chắc không?\" đang hoạt động",
        "apps_blocked": "ứng dụng bị chặn",
        "temp_access_active": "Quyền truy cập tạm thời đang hoạt động",
        "apps_require_movement": "ứng dụng yêu cầu vận động để mở khóa",
        "notifications_label": "Thông báo",
        "notifications_enabled": "Đã bật thông báo",
        "notifications_denied": "Thông báo bị từ chối",
        "enable_notif_settings": "Bật thông báo trong Cài đặt.",
        "allow_notif_desc": "Cho phép thông báo để Spike AI có thể gửi nhắc nhở tập trung cho bạn.",
        "enable_notifications": "Bật thông báo",
        "screen_time_access": "Truy cập Thời gian sử dụng",
        "screen_time_authorized": "Thời gian sử dụng đã được ủy quyền",
        "allow_screen_time": "Cho phép Thời gian sử dụng",
        "tap_to_allow": "Nhấn bên dưới để cho phép truy cập Thời gian sử dụng.",
        "open_settings_manual": "Hoặc mở Cài đặt để bật thủ công",
        "open_settings": "Mở Cài đặt",
        "app_selection": "Chọn ứng dụng",
        "selections": "lựa chọn",
        "choose_apps_confirm": "Chọn ứng dụng cần xác nhận trước khi mở.",
        "choose_apps_block": "Chọn ứng dụng cần chặn.",
        "choose_apps_movement": "Chọn ứng dụng mở khóa bằng vận động.",
        "change_selection": "Thay đổi lựa chọn",
        "select_apps": "Chọn ứng dụng",
        "movement_unlock": "Mở khóa bằng vận động",
        "movement_desc": "Hít đất và đứng lên được theo dõi bằng AI nhận diện cơ thể. Mỗi lần lặp lại được xác nhận sẽ thêm 1 phút truy cập vào các ứng dụng đã chọn.",
        "access_available": "Truy cập khả dụng trong %@",
        "open_camera": "Mở kiểm tra camera",
        "lock_in_mode": "Chế độ khóa",
        "lock_in_warning": "Ứng dụng hiển thị màn hình đỏ không thể bỏ qua. Bạn phải quay lại đây để tắt chế độ Khóa.",
        "sweat_mode": "Chế độ Vận động viên",
        "do_exercises": "Hít đất hoặc đứng lên để kiếm thời gian",
        "add_minutes": "Thêm %d phút",
        "keep_in_view": "Giữ vai, cánh tay hoặc hông trong tầm nhìn",
        "camera_required": "Cần quyền truy cập camera cho kiểm tra vận động.",
        "camera_disabled": "Quyền truy cập camera bị tắt. Bật trong Cài đặt để sử dụng chế độ Vận động.",
        "camera_unavailable": "Không thể truy cập camera.",
        "starting_camera": "Đang khởi động camera...",
        "camera_active": "Camera đang hoạt động",
        "allow_camera": "Cho phép truy cập camera",
        "focus_mode_title": "Chế độ tập trung",
        "focus_mode_desc": "Kiểm soát thói quen số của bạn với các chế độ tập trung, chuyên nghiệp.",
        "about_permissions": "Về quyền",
        "permissions_desc": "Chế độ Thư giãn yêu cầu quyền thông báo. Chế độ Tập trung, Khóa và Vận động yêu cầu ủy quyền Thời gian sử dụng. Chế độ Vận động cũng sử dụng quyền truy cập camera cho kiểm tra vận động.",
        "get_started": "Bắt đầu",
        "skip": "Bỏ qua",
        "unlocked_for": "Đã mở khóa trong %@",

        // Chill mode descriptions
        "chill_desc": "Nhắc nhở hàng ngày qua thông báo. Không kiểm soát ứng dụng — chỉ là gợi ý nhẹ nhàng để sống có chủ đích.",
        "focus_desc": "Khi bạn mở ứng dụng đã chọn, Spike AI hỏi \"Bạn có chắc không?\" Bạn có thể mở bình thường hoặc quay lại nhiệm vụ. Ứng dụng không bị chặn.",
        "lock_in_desc": "Các ứng dụng đã chọn bị chặn khi chế độ Khóa đang hoạt động. Bạn có thể tắt chế độ từ Spike AI.",
        "sweat_desc": "Các ứng dụng đã chọn vẫn bị chặn cho đến khi bạn hoàn thành hít đất hoặc đứng lên được camera kiểm tra. Mỗi lần lặp lại được xác nhận sẽ mở khóa 1 phút.",

        // Motivational (deactivation)
        "giving_up_title": "Bạn đang tiến bộ — đừng dừng lại",
        "giving_up_msg": "Bạn vẫn còn mục tiêu chưa hoàn thành trong hôm nay. Mỗi nhiệm vụ hoàn thành đều tạo đà. Hãy kiên trì — bạn trong tương lai sẽ cảm ơn bạn.",
        "giving_up_continue": "Giữ tập trung",
        "giving_up_stop": "Vẫn tắt",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Hệ thống năng suất cá nhân của bạn",
        "start_setup": "Bắt đầu thiết lập",
        "make_phone_work": "Biến điện thoại thành công cụ\nphục vụ mục tiêu của bạn.",
        "onboarding_welcome_desc": "Giảm lướt vô nghĩa, bảo vệ thời gian tập trung và biến nhiệm vụ thực thành tiến bộ rõ ràng.",
        "did_you_know": "Bạn có biết không?",
        "did_you_know_subtitle": "Một người trung bình dùng điện thoại 7 giờ mỗi ngày. Tương đương",
        "hours_per_day": "giờ mỗi ngày",
        "days_per_month": "ngày mỗi tháng",
        "days_per_year": "ngày mỗi năm",
        "years_of_life": "năm cuộc đời bạn",
        "screen_time_reality": "Và một số người còn dùng nhiều hơn.",
        "dont_worry_title": "Đừng lo lắng",
        "spike_has_your_back": "Spike AI sẵn sàng hỗ trợ bạn",
        "solution_desc": "Chúng tôi sẽ giúp bạn tối đa hóa năng suất, tiến gần hơn đến mục tiêu và xây dựng thói quen biến bạn thành phiên bản tốt nhất của chính mình.",
        "screen_time_access_title": "Truy cập Thời gian sử dụng",
        "grant_access": "Cấp quyền truy cập",
        "which_apps": "Chọn ứng dụng\ngây xao nhãng",
        "choose_apps_protect": "Chọn các ứng dụng lãng phí thời gian. Chúng tôi sẽ chặn chúng trong chế độ tập trung.",
        "apple_screen_time_required": "Apple yêu cầu quyền Thời gian sử dụng trước khi Spike AI có thể hiển thị danh sách ứng dụng.",
        "save_apps": "Lưu & Tiếp tục",
        "change_selected_apps": "Thay đổi ứng dụng đã chọn",
        "ready_change_life": "Sẵn sàng thay đổi\ncuộc sống?",
        "ready_change_desc": "Tạo tài khoản để lưu lựa chọn của bạn và bắt đầu hành trình.",
        "benefit_no_distraction": "Các ứng dụng gây xao nhãng sẽ không còn làm phiền bạn",
        "benefit_discover_modes": "Khám phá 4 loại chế độ tập trung khác nhau",
        "benefit_track_progress": "Theo dõi tiến độ và tiến gần hơn đến mục tiêu",
        "create_account": "Tạo tài khoản",
        "protect_focus": "Bảo vệ tập trung",
        "block_feeds": "Chặn bảng tin",
        "finish_tasks": "Hoàn thành nhiệm vụ",
        "energy_plus_three": "+3 Năng lượng",
        "selected_count": "%d đã chọn",
        "no_apps_selected": "Chưa chọn ứng dụng nào",
        "saved_for_modes": "Đã lưu cho chế độ bảo vệ",
        "select_apps_to_control": "Chọn ứng dụng bạn muốn kiểm soát",
        "clean_room": "Dọn phòng",
        "snap_proof": "Chụp ảnh chứng minh khi hoàn thành",
        "ai_verifies_task": "AI xác minh nhiệm vụ",
        "energy_earned": "+3 Năng lượng kiếm được",
        "on_track": "Đúng tiến độ",
        "energy": "Năng lượng",
        "tasks_completed": "Nhiệm vụ đã hoàn thành",
        "focus_protected": "Tập trung được bảo vệ",
        "scrolling_avoided": "Đã tránh lướt",
        "continue_apple": "Tiếp tục với Apple",
        "continue_google": "Tiếp tục với Google",
        "continue_email": "Tiếp tục với email",
        "enter_email": "Nhập email của bạn",
        "send_sign_in_link": "Chúng tôi sẽ gửi liên kết đăng nhập cho bạn",
        "check_email": "Kiểm tra email của bạn",
        "sent_link_to": "Chúng tôi đã gửi liên kết đăng nhập đến",
        "tap_link": "Nhấn liên kết để đăng nhập tự động.",
        "open_mail": "Mở ứng dụng Mail",
        "open_with": "Mở bằng",
        "didnt_get_email": "Không nhận được email?",
        "resend": "Gửi lại",
        "resend_in": "Gửi lại sau %d giây",
        "new_link_sent": "Đã gửi liên kết mới!",
        "valid_email": "Nhập địa chỉ email hợp lệ.",
        "by_continuing": "Bằng việc tiếp tục, bạn đồng ý với",
        "and_word": "và",

        // Screen Time Onboarding
        "screen_time_title": "Thời gian sử dụng",
        "screen_time_permission_desc": "Spike AI cần quyền Thời gian sử dụng cho chế độ Tập trung, Khóa và Vận động. Điều này cho phép hiển thị lời nhắc và chặn ứng dụng bạn chọn.",
        "screen_time_denied": "Quyền bị từ chối. Bạn có thể bật trong Cài đặt.",
        "ask_before_opening": "Hỏi trước khi mở",
        "block_apps_completely": "Chặn ứng dụng hoàn toàn",
        "stay_accountable": "Giữ trách nhiệm",
        "stay_accountable_desc": "Theo dõi tiến độ và giữ thói quen tập trung của bạn rõ ràng.",
        "skip_for_now": "Bỏ qua lúc này",

        // Live Activity
        "daily_goals_title": "Mục tiêu hàng ngày",
        "of_done": "%d đã xong",
        "more_to_go": "+%d nữa",

        // Chill morning
        "good_morning": "Chào buổi sáng! Hãy sống có chủ đích hôm nay. Xem lại nhiệm vụ và giữ tập trung.",

        // Onboarding (extended)
        "scrolling_adds_up": "Lướt có vẻ nhỏ nhặt,\nnhưng tích lũy dần.",
        "per_day": "mỗi ngày",
        "per_month": "mỗi tháng",
        "per_year": "mỗi năm",
        "thirty_days": "30 ngày",
        "lost_to_checking": "mất cho việc kiểm tra tự động",
        "scrolling_cost_desc": "Spike AI giúp bạn nhận ra những khoảnh khắc đó trước khi chúng chiếm cả buổi tối.",
        "your_modes_target": "Giờ chế độ của bạn đã có\nmục tiêu rõ ràng.",
        "app_selections_will_be_used": "%d lựa chọn ứng dụng sẽ được sử dụng khi bạn bắt đầu chế độ bảo vệ.",
        "select_apps_after_login": "Chọn ứng dụng một lần sau khi đăng nhập, tất cả chế độ bảo vệ sẽ sử dụng danh sách đó.",
        "focus_mode_marketing_detail": "Dừng lại một chút trước khi mở ứng dụng gây xao nhãng.",
        "lock_in_marketing_detail": "Ranh giới mạnh hơn khi cần làm việc sâu.",
        "sweat_marketing_detail": "Vận động trước để kiếm thời gian truy cập.",
        "replace_scroll": "Thay thế lướt bằng\nthành tựu thực sự.",
        "habit_desc": "Biến hành động có ích thành năng lượng: dọn phòng, nộp bài, đi bộ, vận động hoặc hoàn thành một nhiệm vụ.",
        "see_behavior_changing": "Xem hành vi của bạn\nđang thay đổi.",
        "progress_desc": "Theo dõi thời gian tập trung, hoàn thành nhiệm vụ và chuỗi để tiến bộ rõ ràng.",
        "ready_protected_day": "Sẵn sàng cho ngày đầu tiên\nđược bảo vệ?",
        "create_account_desc": "Tạo tài khoản để lưu lựa chọn ứng dụng, chế độ tập trung, nhiệm vụ và tiến độ.",
        "benefit_apps_saved": "Ứng dụng gây xao nhãng được lưu cho các chế độ",
        "benefit_start_modes": "Bắt đầu chế độ Tập trung, Khóa hoặc Vận động",
        "benefit_progress_synced": "Tiến độ của bạn được đồng bộ",

        // General
        "error": "Lỗi",
        "ok": "OK",
        "yes": "Có",
        "no": "Không",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Chuyển sang Chế độ Thư giãn?",
        "stay_focused_btn": "Giữ Tập trung",
        "switch_anyway_btn": "Vẫn Chuyển",
        "switch_to_chill_msg": "Bạn vẫn còn mục tiêu chưa hoàn thành. Chuyển sang Chế độ Thư giãn sẽ gỡ chặn ứng dụng, làm tăng nguy cơ không hoàn thành mục tiêu hôm nay.",
        "task_notification": "Thông báo Nhiệm vụ",
        "missed_alarm": "Báo thức bị bỏ lỡ",
        "quote_of_day": "Câu nói trong ngày",
        "new_quotes_daily": "Câu nói mới đến hàng ngày lúc 5:00 sáng",
        "focus_day_label": "Ngày Tập trung",
        "missed_label": "Bỏ lỡ",
        "access_granted": "Đã cấp quyền truy cập",
        "goal_reminder": "Nhắc nhở Mục tiêu",
        "spike_ai_focus": "Spike AI Tập trung",
        "goals_required_title": "Cần có Mục tiêu",
        "goals_required_desc_focus": "Chế độ Tập trung chỉ chặn ứng dụng đã chọn khi bạn có mục tiêu chưa hoàn thành. Thêm mục tiêu trong tab Trang chủ để kích hoạt chặn ứng dụng.",
        "goals_required_desc_lockin": "Chế độ Khóa chỉ chặn ứng dụng đã chọn khi bạn có mục tiêu chưa hoàn thành. Thêm mục tiêu trong tab Trang chủ để kích hoạt chặn ứng dụng.",
        "save": "Lưu",
        "no_goals_reminder_body": "Bạn chưa đặt mục tiêu nào cho hôm nay. Hãy dành chút thời gian để lên kế hoạch cho ngày của bạn!",
        "dont_forget": "Đừng quên",
        "chill_morning_body": "Chào buổi sáng! Hãy sống có chủ đích hôm nay. Xem lại nhiệm vụ và giữ tập trung.",
        "every_day": "Mỗi ngày",
        "weekdays": "Ngày trong tuần",
        "weekends": "Cuối tuần",
        "time_to_focus": "Đến lúc tập trung!",

        // Additional UI strings
        "next_quote_in": "Trích dẫn tiếp theo sau %@",
        "enable_notif_chill": "Bật thông báo trước khi bắt đầu chế độ Thư giãn.",
        "enable_screen_time_mode": "Bật quyền truy cập Thời gian sử dụng trước khi bắt đầu chế độ này.",
        "select_app_before_mode": "Chọn ít nhất một ứng dụng, danh mục hoặc trang web trước khi bắt đầu chế độ này.",
        "mode_not_ready": "Chế độ này chưa sẵn sàng để bắt đầu.",
        "protection_stopped_no_apps": "Bảo vệ đã dừng: chưa chọn ứng dụng nào.",
        "protection_stopped_screen_time": "Bảo vệ đã dừng: quyền truy cập Thời gian sử dụng đã thay đổi.",
        "max_reminders": "Bạn có thể tạo tối đa %d nhắc nhở tập trung.",
        "front_camera_unavailable": "Camera trước không khả dụng.",
        "task_title_empty": "Tiêu đề nhiệm vụ không được để trống.",
        "goal_title_empty": "Tiêu đề mục tiêu không được để trống.",
        "rate_limit_wait": "Vui lòng đợi %d giây trước khi tạo báo cáo mới.",
        "missed_alarm_for": "Bạn đã bỏ lỡ báo thức: %@",
        "stay_with_plan": "Bám sát kế hoạch.",
        "motivation_small_wins": "Chiến thắng nhỏ tích lũy dần.",
        "motivation_next_step": "Hoàn thành bước tiếp theo.",
        "motivation_protect_hour": "Bảo vệ giờ phía trước bạn.",
        "motivation_consistency": "Sự kiên định thắng cường độ.",
        "monthly_scope_btn": "Hàng tháng",
        "yearly_scope_btn": "Hàng năm",
        "restoring_session": "Đang khôi phục phiên của bạn...",

        // Milestones
        "milestone_3day_streak": "Chuỗi 3 ngày",
        "milestone_3day_desc": "Nhịp độ ổn định đã bắt đầu.",
        "milestone_7day_streak": "Chuỗi 7 ngày",
        "milestone_7day_desc": "Một tuần tập trung trọn vẹn.",
        "milestone_10h_protected": "10 giờ được bảo vệ",
        "milestone_10h_desc": "Thời gian bảo vệ cho điều quan trọng.",
        "milestone_30_focus": "30 ngày tập trung",
        "milestone_30_desc": "Sự kiên định thực sự.",

        // Narratives
        "narrative_improved": "Thời gian sử dụng màn hình của bạn đã cải thiện so với tuần trước.",
        "narrative_consistent": "Bạn đã duy trì sự nhất quán tuần này và bảo vệ sự tập trung.",
        "narrative_more_days": "Bạn đã hoàn thành nhiều ngày tập trung hơn bình thường.",
        "narrative_building": "Bạn đang xây dựng nhịp độ từng ngày tập trung một.",

        // Screen time
        "screen_time_trend_pending": "Xu hướng thời gian màn hình sẽ xuất hiện khi lịch sử sử dụng tăng lên.",
        "screen_time_improved": "Thời gian màn hình cải thiện %d%%",
        "screen_time_higher": "Thời gian màn hình hơi cao hơn bình thường",
        "screen_time_steady": "Thời gian màn hình ổn định tuần này",

        // Benchmarks
        "benchmark_pending": "Thời gian màn hình trung bình sẽ xuất hiện khi ứng dụng ghi nhận lịch sử sử dụng. Điểm tham chiếu toàn cầu là khoảng 7 giờ mỗi ngày.",
        "benchmark_below": "Trung bình 7 ngày của bạn là %@, dưới mức trung bình toàn cầu 7 giờ. Đó là hướng đi mạnh mẽ.",
        "benchmark_above": "Trung bình 7 ngày của bạn là %@, trên mức trung bình toàn cầu 7 giờ. Giảm nhẹ hôm nay có thể thay đổi xu hướng.",
        "benchmark_matching": "Trung bình 7 ngày của bạn là %@, bằng mức trung bình toàn cầu 7 giờ.",

        // Task editing
        "edit_task": "Chỉnh sửa nhiệm vụ",
        "task_name_placeholder": "Tên nhiệm vụ",
        "task_reminder_default": "Nhắc nhở nhiệm vụ",
        "time_h_m": "%dg %dp",
        "time_m": "%dp",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Kazakh (Latin script)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let kk: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Фокус режимдері туралы",
        "no_active_goals_title": "Белсенді мақсаттар жоқ",
        "no_active_goals_btn": "Түсінікті",
        "no_active_goals_msg": "«Фокус» және «Блоктау» режимдері сізде аяқталмаған мақсат болғанда ғана жұмыс істейді. Мақсат қосыңыз — немесе оны қайта белсендіріңіз — содан кейін сессияны бастаңыз.",
        // Tab bar
        "tab_home": "Basty", "tab_progress": "Ilgerılew", "tab_mode": "Rejım", "tab_profile": "Profıl",

        // Home
        "today": "Búgın", "tomorrow": "Erteń", "yesterday": "Keşe",
        "back_to_today": "Búgınge qaıta oralw",
        "add_first_task": "Birınşı tapsyrmanı qosw úşın + basıńyz",
        "no_tasks_this_day": "Bul kúnge tapsyrma joq",
        "new_task": "Jańa Tapsyrma",
        "what_to_do": "Ne ıstew kerek?",
        "task": "Tapsyrma", "schedule": "Kestesı",
        "pick_date_hint": "Kelez kelgen bolashaq kúndı tańdańyz — búgın, kelesi apta nemese aılar keıın.",
        "priority": "Basymdy", "low": "Tómen", "medium": "Orta", "high": "Joğary",
        "notification": "Xabarlandyrw", "silent_push": "Únsız push xabarlandyrw",
        "notification_desc": "Josparlanğan waqytta bir ret push xabarlandyrw jiberedi. Ol Qulyptaw Ekranynda jáne Xabarlandyrw Ortalyğynda tynıyş körinedi.",
        "reminder": "Eskertwme", "alarm_sound": "Dybys pen dırıldemeli oıatyş",
        "reminder_desc": "Oıatyş sıaqty jumys isteidı — arnaıy dybys oınap, telefonyńyz ekrandağy Jopw túımesin basqanşa úzdıksız dırıldeidı. Jınalystar men merzimderge taptyrmas.",
        "cancel": "Boldyrmaw", "add": "Qosw", "edit": "Ózgertw", "delete": "Joyw",
        "jump_to_date": "Kúnge ótw", "done": "Daıyn",
        "task_limit": "Bul kún úşın 25 tapsyrma şegıne jettıńız.",
        "time": "Waqyt", "date": "Kún", "select_date": "Kúndı tańdaw",

        // Alarm
        "reminder_title": "Eskertwme", "dismiss": "Jopw",

        // Progress
        "daily_progress": "Kúndelikti Ilgerılew", "streaks": "serıalar", "focus_days": "fokws kúnderı",
        "consistency": "turaqtylıq",
        "set_first_goal": "Búgınge birınşı maqsatyńyzdy belgilenız",
        "all_goals_completed": "Barlyq kúndelikti maqsattar oryndaldı",
        "goals_completed": "den", "daily_goals_completed": "kúndelikti maqsat oryndaldı",
        "daily_goals": "Kúndelikti Maqsattar", "remaining": "qaldı",
        "no_goals_planned": "Josparlanğan maqsat joq",
        "complete_to_focus": "Búgındı fokws kúnı dep belgilew úşın barlyq tapsyrmalardy oryndańyz.",
        "add_task_to_start": "Kúndelikti maqsattardy baqylaw úşın Basty betten tapsyrma qosyńyz.",
        "daily_plan_complete": "Kúndelikti jospar oryndaldı",
        "ai_weekly_summary": "JI Aptalyq Qorytyndy",
        "creating_summary": "Aptalyq qorytyndyńyz jasalwda...",
        "generate_summary": "Qorytyndy jasaw", "refresh_summary": "Qorytyndyny jańartw",
        "first_summary_coming": "Birınşı JI aptalyq qorytyndyńyz jolda.",
        "first_summary_desc": "Ol %@ keşki sağat 9-da daıyn bolady. Ilgerılewińız, ötip ketken tapsyrmalar jáne sız úşın eń jaramdy fokws rejımı twraly málimet beredi.",
        "next_update": "Kelesi jańartw: %@",
        "weekly_recap": "Fokws kúnderı, tapsyrmalar jáne ónımdılık tendensıalary boıynşa aptalyq qorytyndy daıyn.",
        "screen_time_7day": "7 Kúndık Ekran Waqyty", "best_streak": "Eń jaqsy serıa",
        "days": "kún", "milestones": "JetisTıkter", "milestone_unlocked": "Jetistık aşyldı",
        "continue_btn": "Jalğastyrw", "history_calendar": "Tarıx kúntızbesı",
        "mode_used": "Qoldanylğan rejım", "completed": "Oryndaldı", "not_completed": "Oryndalğan joq",
        "no_completed_tasks": "Bul kún úşın oryndalğan tapsyrma jazylmağan.",
        "everything_completed": "Bári oryndaldı.",
        "no_missed_tasks": "Bul kún úşın ótkerılgen tapsyrma jazylmağan.",
        "streak_day": "Serıa kúnı", "missed_day": "Ótkerılgen kún",
        "first_name": "Aty", "last_name": "Jóni",
        "avatar_color": "Avatar túsı",
        "whats_your_name": "Atyńyz kim?",
        "name_helps": "Bul tájirıbeńızdı daralandyrwğa kómektesedı.",
        "name_save_failed": "Atyńyz saqtalğan joq. Baylanysyńyzdy tekseriñız jáne qaıta bayqap kóriñız.",
        "continue_btn_name": "Jalğastyrw",
        "wins": "Jeńıster", "next_action": "Kelesi ádis", "average": "ortaşa",
        "todays_completion": "Búgıngi oryndalw",
        "streaks_this_month": "bul aıdağy serıalar",
        "streak_days": "serıa kúnderı", "non_streak_days": "serıasyz kúnder",
        "monthly_streak_summary": "%d serıa bul aıda • %d serıa kúnı, %d serıasyz kún",
        "duration_average": "%@ ortaşa",

        // Profile
        "personal_details": "Jeke Málimet", "personal_info": "Jeke Aqparat",
        "update_email_name": "Elektrondyq poşta jáne tolyq atyńyzdy jańartyńyz.",
        "and_username": "jáne paıdalanwşy aty",
        "invite_friends": "Dostardy şaqyrw",
        "refer_friend_title": "Dosyńyzdy usynyńyz jáne $10 tabıńyz",
        "refer_friend_desc": "Promo kodyńyz arqyly tirkelgen ár dos úşın $10 tabıńyz.",
        "upgrade_family_plan": "Otbasy jobaryna jańartw",
        "goals_tracking": "Maqsattar jáne Baqylaw",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Tamaqtanw maqsattaryn ózgertw",
        "tracking_reminders": "Baqylaw eskertwmelerı",
        "email_not_editable": "Elektrondyq poştańyz kirw derekterıńızge baılanysty jáne mynda ózgertwge bolmaıdy.",
        "theme": "Taqyryp", "theme_desc": "Júıe körinisın paıdalanyńyz nemese turaqty jaryq/qaranğy rejımdı tańdańyz.",
        "appearance": "Körinıs", "appearance_desc": "Jaryq, qaranğy nemese júıe körinisın tańdańyz",
        "live_activity_profile_desc": "Kúndelikti ilgerılewıńızdı Qulyptaw Ekranynda jáne Dynamic Island-ta kórsetıńız",
        "system": "Júıe", "light": "Jaryq", "dark": "Qaranğy",
        "live_activity": "Tirı Áreket",
        "live_activity_desc": "Qulyptaw Ekranynda búgıngi maqsattardy, serıany jáne jańa motıvasıany kórsetıńız.",
        "privacy_policy": "Qupıalylıq Saasaty",
        "privacy_desc": "Qoldanba derekterı men qurylğy ruqsattary qalaı paıdalanylğanyn qarap şyğyńyz.",
        "terms_of_service": "Qyzmet Kórsetw Şarttary",
        "terms_desc": "Qoldanba men fokws quraldaryn paıdalanw erejelerin oqyńyz.",
        "follow_us": "Bizdi baqylańyz",
        "sign_out": "Şyğw", "sign_out_desc": "Ağymdağy qurylğydağy sessıany ayaqtaw.",
        "delete_account": "Tirkelgını joyw",
        "delete_account_desc": "Tirkelgı men úndestırılgen qoldanba derekterın turaqty joyw.",
        "delete_account_title": "Tirkelgını joyw",
        "delete_account_msg": "Bul áreket turaqty. Barlyq derekterıńız joıylady jáne qaıtarwğa bolmaıdy.",
        "delete_account_continue": "Jalğastyrw",
        "delete_account_final_title": "Turaqty joıylsyn ba?",
        "delete_account_final_msg": "Tağy bir ret rastańyz. Tirkelgıńızdı joısańyz, Spike AI sızdı şyğaradı jáne kirw betıne qaıta jiberedı.",
        "deleting_account": "Tirkelgı joıylwda...",
        "delete_failed": "Tirkelgını joyw sátsizdıkke uşyradı. Qaıtalap kóriñız nemese qoldaw qyzmetıne xabarlasynyz.",
        "language": "Tıl", "language_desc": "Barlyq qoldanba mazmunı úşın tıldı tańdańyz.",
        "set_name": "Atyńyzdy engiziñız",
        "profile_name_prompt": "Sızdı qalaı ataw kerek?",
        "profile_name_desc": "Spike AI profılıñızde jáne ónımdılık tájirıbesınde paıdalanatyn atyńyzdy qosyńyz.",
        "full_name": "Tolyq aty", "display_name": "Kórsetu aty",
        "email": "Elektrondyq poşta",
        "save_changes": "Ózgerısterdı saqtaw",
        "save_footer": "Ózgerıster profılıñızge saqtalady jáne qoldanbada jeke bastyńyz körinetın jer bolğan saiyn paıdalanylady.",
        "signed_in": "Kirılgen",
        "account": "Tirkelgı", "preferences": "Talğaw",
        "support_legal": "Qoldaw jáne Huqyqtıq",
        "account_actions": "Tirkelgı áreketter",
        "pref_show_completed": "Oryndalğandy kórsetw",
        "pref_show_completed_desc": "Oryndalğan tapsyrmalardy kúndelikti tizımde körinetın qaldyrw.",
        "pref_quotes": "Motıvasıalyq dáıeksózder",
        "pref_quotes_desc": "Ilgerılew ekranynda ruhlandyratyn dáıeksóz kórsetw.",
        "legal_updated": "Sońğy jańartw: 25 mamyr 2026",
        "privacy_body": """
        Sońğy jańartw: 25 mamyr 2026

        Spike AI — ónımdılık jáne fokws qoldanbasy. Bul Qupıalylıq Saıasaty Spike AI tirkelgilerdi, tapsyrma josparyn, eskertwmelerdı, fokws rejımderın, Ekran Waqyty basqarwlaryn, ilgerılew baqylawın jáne JI ónımdılık qorytyndylaryn usınyp otyrw úşın paıdalanylatyn aqparatty qalaı basqaratynyn túsındıredı.

        Bız jınaıtyn aqparat: tirkelgı anyqtawıştar, mısaly elektrondyq poşta mekenjaıyńyz ben paıdalanwşy ID-ıńız; profıl málimetterin, mısaly kórsetw aty jáne tolyq aty; tapsyrmalar, maqsattar, eskertwmeler, oryndalw tarıxy, fokws rejımı parametrlerı, qoldanba tańdaw tokenderı jáne ilgerılew kórsetkışterı. Bız sondaı-aq qyzmettiń senımdı jáne qawıpsız bolw úşın qajet texnıkalyq jazbalrdy saqtaı alamyz.

        Ekran Waqyty jáne qoldanba tańdawlary: qoldanba, sanattama jáne web-domen tańdawlary Apple-diń FamilyControls jáne ManagedSettings frameworkterı arqyly óńdeledı. Spike AI tańdalğan fokws rejımderıńızdı qoldanw úşın qajet Apple usınğan tokenderdı saqtaıdy. Bız bul tańdawlardy jarnama úşın paıdalanbaımyz.

        Ter Rejımınde kamerany paıdalanw: kamera múmkındıgı qurylğyda dene qalpy tekserwlerı úşın paıdalanylady, sonday-aq sız qozğalys arqyly qoldanbalarğa waqytşa múmkındık ala alasyz. Spike AI bul múmkındık úşın video kadrlardı júktemeıdı jáne kamera derekterın jarnama úşın paıdalanbaıdy.

        Xabarlandyrwlar men eskertwmeler: Spike AI sız konfigwrasıalaıtyn tapsyrma eskertwmelerin, oıatylardı jáne fokws túrtkılerın jiberw úşın xabarlandyrw ruqsatyn paıdalanady. Xabarlandyrw múmkındıgın kelez kelgen waqytta iOS Parametrlerınde ózgertw múmkın.

        JI qorytyndylary: ilgerılew qorytyndysyn jasasańyz, sońğy tapsyrma, maqsat, fokws jáne ónımdılık kórsetkışterı qorytyndyny jasap şyğarw úşın Spike AI serverımde óńdelwı múmkın. Ónımdılık múmkındıkterı úşın óńdelwın qalamasa, tapsyrma attaryna nemese maqsattarğa qupıa jeke aqparatty engızwden aqlanyńyz.

        Aqparatty qalaı paıdalamyz: sızdı tekserwge, tirkelgıńızdı úndestırwge, fokws quraldaryn usınwğa, eskertwmelerdı josparğa, ilgerılew kórsetwge, ónımdılık túsınıkterın daralandyrwğa, teris paıdalanwdan qorğawğa, aqaulardy şeşwge jáne huqyqtıq mındetterdı oryndawğa. Spike AI jeke aqparatyńyzdy satpaıdy.

        Derekterdi joyw: Profılden şyğa alasyz nemese tirkelgını turaqty joıwdy suranyp ala alasyz. Tirkelgını joyw awtentefıkasıa tirkelgıñızdı jáne sol tirkelgıge baılanysty úndestırılgen qoldanba derekterın alyp taslaıdy; qawıpsızdık, aldawdyń aldyn alw, dawlar şeşw nemese huqyqtıq sáıkestık úşın kerek bolar şektewli saqtawdan basqa.

        Tańdawlaryńyz: profıl málimetterın ózgertw, tıl men kórinıs talğawlaryn ózgertw, tirı árekettı óşırw, Parametrlerde qurylğy ruqsattaryn bolma, belgili fokws rejımderın paıdalanwdy toqtatw nemese tirkelgıñızdı joıw múmkın.

        Baılanys: qupıalylıq suraqtary nemese tirkelgını joıw máselelerı úşın qoldanba nemese App Store tizımı arqyly berilgen qoldaw arnasy arqyly Spike AI qoldaw qyzmetıne xabarlasynyz.
        """,
        "terms_body": """
        Sońğy jańartw: 25 mamyr 2026

        Bul Qyzmet Kórsetw Şarttary Spike AI paıdalanwyńyzdy basqarady, onyń işınde tapsyrmalar, eskertwmeler, fokws rejımderı, Ekran Waqyty qoldanba eskertpelerı men qalqanşalary, Ter Rejımı qozğalys tekserwlerı, ilgerılew baqylawy jáne JI qorytyndylary bar.

        Kelisımdılık jáne tirkelgı: sız jasağan tirkelgıge jáne elektrondyq poşta men qurylğyńyzğa qol jetımdılıktı qawıpsız saqtawğa jawaptysyz. Qoldanba profıl málimetterın surağanda naqty aqparatty paıdalanyńyz.

        Ónımdılık maqsaty: Spike AI jeke ónımdılık pen ádeılegen qurylğy paıdalanwdy qoldaw úşın ján-jaqtyly jasalğan. Ol medısınalıq, psıxıkalyq densawlyq, tótenşe jağdaı, qawıpsızdık, ata-ana baqylawy, jumys ornyn baqylaw nemese qurylğyny basqarw qyzmetı emes. Eskertwme, bötew, eskertpe, kamera tekserw, xabarlandyrw, jelike suranymy nemese Apple ruqsatynyń sátsızdıgı zyian keltiretın jağdaılarda Spike AI-ğa senmóiız.

        Jawaptylıqtaryńyz: jağdaıyńyzğa saı fokws parametrlerın tańdańyz; rejımdı qospas burun qoldanba tańdawlaryn qarap şyğyńyz; rejımder qajettilıkterine saı kelmegenşe oşırıńız; qoldanystawdağy zańğa jáne Apple platformasynyń şarttaryna saı bolıńyz; jáne qoldanbada paıdalanwğa qolaısyz bolmasa, tapsyrmalarğa nemese maqsattarğa qupıa aqparatty engızwden aqlanyńyz.

        Qoldawly paıdalanw: Spike AI-dy teris paıdalanbaıyz, basqa adamnyń qurylğysyna nemese tirkelgısıne aralyspańyz, qawıpsızdık nemese platforma şektewlerın aınalyp ótpek bolmańyz, qyzmettiń qorğalğan bólıkterin keri injenerıa etpóiız, serverdi artyk júktemeńız nemese qoldanbany zańsyz, qorlawşy, aldawşy nemese zyıandy áreket úşın paıdalanpańyz.

        Ruqsattar men qol jetımdılık: keıbir múmkındıkter Ekran Waqyty, xabarlandyrwlar, kamera, tirı áreketter jáne jelike qol jetımdılıgı sıaqty iOS ruqsattaryn qajet etedı. Apple, qurylğy parametrlerı, operasıalyq júıe minezı, baılanys jáne server qol jetımdılıgı múmkındıkterdiń kútılgendey jumys ıstewıne áser etwı múmkın.

        JI jasağan mazmuny: ilgerılew qorytyndylary avtomattandyrılğan júıeler arqyly jasalwı múmkın. Olar tek oılanw jáne ónımdılık baılaw múmkındığı úşın. Oğan sıanbasburun óz bailamyńyz arqyly qarap şyğyńyz.

        Tirkelgını joyw jáne toqtatw: Profılden tirkelgını joıwdy suranyp ala alasyz. Zań, platforma erejeleri, qawıpsızdık mánselelerı nemese ırı awyqymalyq teris paıdalanw talap etse, Spike AI qol jetımdılıktı toqtata nemese ayaqtaı alady.

        Ózgerıster: qoldanba damyğan saıyn Spike AI bul Şarttardy jańarta alady. Jańartılğannan keıın paıdalanwdy jalğastyrw jańartılğan Şarttardy qabıldağanyńyzdy bildıredı.

        Baılanys: bul Şarttar twraly suraqtar úşın qoldanba nemese App Store tizımı arqyly berilgen qoldaw arnasy arqyly Spike AI qoldaw qyzmetıne xabarlasynyz.
        """,

        // Focus Mode
        "focus_title": "Fokws", "select_mode": "Rejımdı tańdaw",
        "chill": "Tynyş", "focus": "Fokws", "lock_in": "Qulyptaw", "sweat": "Sportşy",
        "gentle_nudges": "Jwmsaq eskertwler", "confirm_intent": "Nıettı rastaw",
        "no_bypass": "Aınalyp ótw joq", "move_to_unlock": "Aşw úşın qozğalyńyz",
        "activate_focus": "Fokws Rejımın Qosw", "deactivate_focus": "Fokws Rejımın Óşırw",
        "mode_active": "Rejım Belgendı", "reminders_scheduled": "Eskertwmeler josparlandı",
        "apps_prompt_active": "qoldanba — \"Senenızbe?\" eskertpesı belgendı",
        "apps_blocked": "qoldanba bógelgen", "temp_access_active": "Waqytşa múmkındık belgendı",
        "apps_require_movement": "qoldanba aşw úşın qozğalys qajet",
        "notifications_label": "Xabarlandyrwlar", "notifications_enabled": "Xabarlandyrwlar qosylğan",
        "notifications_denied": "Xabarlandyrwlar qabyldanğan joq",
        "enable_notif_settings": "Parametrlerde xabarlandyrwlardy qosyńyz.",
        "allow_notif_desc": "Spike AI fokws eskertwmelerin jiberw úşın xabarlandyrwlarğa ruqsat beriñız.",
        "enable_notifications": "Xabarlandyrwlardy qosw",
        "screen_time_access": "Ekran Waqyty Múmkındıgı",
        "screen_time_authorized": "Ekran Waqyty ruqsat etılgen",
        "allow_screen_time": "Ekran Waqytyna Ruqsat Berw",
        "tap_to_allow": "Ekran Waqyty múmkındıgın berw úşın tómendı basyńyz.",
        "open_settings_manual": "Nemese qolmen qosw úşın Parametrlerdı aşyńyz",
        "open_settings": "Parametrlerdı aşw",
        "app_selection": "Qoldanba Tańdawy", "selections": "tańdaw",
        "choose_apps_confirm": "Aşpas burun rastalatyn qoldanbalardy tańdańyz.",
        "choose_apps_block": "Bógelenetın qoldanbalardy tańdańyz.",
        "choose_apps_movement": "Qozğalysmen aşylatyn qoldanbalardy tańdańyz.",
        "change_selection": "Tańdawdy ózgertw", "select_apps": "Qoldanbalardy tańdaw",
        "movement_unlock": "Qozğalysmen Aşw",
        "movement_desc": "Jatyrğa otyrw men turw JI dene anyqtaw arqyly baqylanady. Ár rastaylğan qaıtaław tańdalğan qoldanbalarğa 1 mınwt múmkındık qosady.",
        "access_available": "%@ úşın múmkındık bar",
        "open_camera": "Kamera Tekserwın Aşw",
        "lock_in_mode": "Qulyptaw rejımı",
        "lock_in_warning": "Qoldanbalar aınalyp ótpey qyzyl ekran kórsetedı. Qulyptaw Rejımın óşırw úşın osy jerge qaıta oralwınyz qajet.",
        "sweat_mode": "Sportşy Rejımı",
        "do_exercises": "Waqyt tabw úşın jatyrğa otyrw nemese turw jasańyz",
        "add_minutes": "%d Mınwt Qosw",
        "keep_in_view": "Iıığyńyzdy, qoldardy nemese jambasyńyzdy kadrda ustańyz",
        "camera_required": "Qozğalys tekserwlerı úşın kamera múmkındıgı qajet.",
        "camera_disabled": "Kamera múmkındıgı óşırılgen. Ter Rejımın paıdalanw úşın Parametrlerde qosyńyz.",
        "camera_unavailable": "Kamera múmkındıgı qol jetımsız.",
        "starting_camera": "Kamera bastalwda...",
        "camera_active": "Kamera belgendı",
        "allow_camera": "Kamerağa Ruqsat Berw",
        "focus_mode_title": "Fokws Rejımı",
        "focus_mode_desc": "Sandyq ádetterıñızdı fokustalğan, kásıbi rejımdermeń basqaryńyz.",
        "about_permissions": "Ruqsattar twraly",
        "permissions_desc": "Tynyş Rejımı xabarlandyrw ruqsatyn qajet etedı. Fokws, Qulyptaw jáne Ter rejımderıne Ekran Waqyty ruqsaty kerek. Ter Rejımı qozğalys tekserw úşın kamerany da paıdalanady.",
        "get_started": "Bastaw", "skip": "Ótkızıp jiberw",
        "unlocked_for": "%@ úşın aşyldy",

        // Chill mode descriptions
        "chill_desc": "Xabarlandyrwlar arqyly kúndelikti eskertwler. Qoldanba baqylawy joq — tek maqsatqa baıyty bolw úşın jwmsaq túrtkıler.",
        "focus_desc": "Tańdalğan qoldanbany aşqanda Spike AI \"Senenızbe?\" dep suradı. Ony ádettegıdey aşa alasyz nemese tapsyrmalarğa qaıta orala alasyz. Qoldanbalar bógelınbeıdı.",
        "lock_in_desc": "Qulyptaw belgendı kezde tańdalğan qoldanbalar bógeledı. Rejımdı Spike AI-den óşırwge bolady.",
        "sweat_desc": "Tańdalğan qoldanbalar kameramen teksırilgen jatyrğa otyrw nemese turwdy oryndağanşa bógelıngen kúıde qalady. Ár rastylğan qaıtalaw 1 mınwtty aşady.",

        // Motivational (deactivation)
        "giving_up_title": "Sız ilgerı barasyz — qazır toqtamańyz",
        "giving_up_msg": "Búgınge áli oryndalmaşan maqsattaryńyz bar. Ár tapsyrma oryndalğan saıyn ılgeri itermeleıdı. Berık bolıńyz — bolashaqtağy ózıñız razı bolady.",
        "giving_up_continue": "Fokwsta Qalw", "giving_up_stop": "Báribiır Óşırw",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Jeke ónımdılık júıeńız",
        "start_setup": "Ornatylymdy bastaw",
        "make_phone_work": "Telefonyńyzdy maqsattaryńyz\núşın jumys ıstew.",
        "onboarding_welcome_desc": "Mánsiız aılyrwdy azaıtyńyz, fokws waqytyn qorğańyz jáne şyn tapsyrmalardy kórinetın ilgerılewge aınalyyrtyńyz.",
        "did_you_know": "Bilesız be?",
        "did_you_know_subtitle": "Adam kúnıne ortaşa 7 sağat telefonynda ótkeizedı. Bul",
        "hours_per_day": "sağat kúnıne",
        "days_per_month": "kún aıyna",
        "days_per_year": "kún jylyna",
        "years_of_life": "ómirizdiń jyly",
        "screen_time_reality": "Al keıbir adamdar bunnan da kóp waqyt jıberedı.",
        "dont_worry_title": "Mazyrdanpańyz",
        "spike_has_your_back": "Spike AI sız úşın",
        "solution_desc": "Ónımdılıgıñızdı máksımwmğa jetizwge, maqsattaryńyzğa jaqyndawğa jáne sızdı ózıñızdiń eń jaqsy versıasyna aınalyratyn ádetterdi qalyptastyrwğa kómektesemız.",
        "screen_time_access_title": "Ekran Waqyty Múmkındıgı",
        "grant_access": "Múmkındık berw",
        "which_apps": "Alyńdatatyn\nqoldanbalardy tańdańyz",
        "choose_apps_protect": "Waqytyńyzdy boşqa ótkeizıletın qoldanbalardy tańdańyz. Fokws rejımderı kezınde olardy bógeimız.",
        "apple_screen_time_required": "Spike AI qoldanba tizimiñızdı kórsetwge Apple Ekran Waqyty múmkındıgı qajet.",
        "save_apps": "Saqtaw jáne Jalğastyrw",
        "change_selected_apps": "Tańdalğan qoldanbalardy ózgertw",
        "ready_change_life": "Ómiıńızdı ózgertwge\ndaıynsyz ba?",
        "ready_change_desc": "Tańdawlaryńyzdy saqtaw jáne sapardy bastaw úşın tirkelgıñızdı jasańyz.",
        "benefit_no_distraction": "Alyńdatatyn qoldanbalar endi sızdı mazalamaiıdy",
        "benefit_discover_modes": "Fokws rejımderiniń 4 túrlı túrın aşyńyz",
        "benefit_track_progress": "Ilgerılewıñızdı baqylańyz jáne maqsattaryńyzğa jaqyndańyz",
        "create_account": "Tirkelgı Jasaw",
        "protect_focus": "Fokwsty Qorğaw", "block_feeds": "Lentalardy Bógew",
        "finish_tasks": "Tapsyrmalardy Bıtırw", "energy_plus_three": "+3 Energıa",
        "selected_count": "%d tańdaldy", "no_apps_selected": "Ázi qoldanba tańdalğan joq",
        "saved_for_modes": "Qorğanys rejımderı úşın saqtaldı",
        "select_apps_to_control": "Basqarğyńyz keletın qoldanbalardy tańdańyz",
        "clean_room": "Bólmedı jıynaw", "snap_proof": "Bıtırgenniń dálelin túsırıñız",
        "ai_verifies_task": "JI tapsyrmany tekseredı",
        "energy_earned": "+3 Energıa alyndı",
        "on_track": "Jolynda", "energy": "Energıa",
        "tasks_completed": "Oryndalğan tapsyrmalar", "focus_protected": "Fokws qorğaldı",
        "scrolling_avoided": "Aılyrwdan qulty boldy",
        "continue_apple": "Apple arqyly jalğastyrw",
        "continue_google": "Google arqyly jalğastyrw", "continue_email": "Poşta arqyly jalğastyrw",
        "enter_email": "Poştańyzdy engiziñız",
        "send_sign_in_link": "Sızge kırw siltemesın jiberemız",
        "check_email": "Poştańyzdy tekseriñız",
        "sent_link_to": "Kırw siltemesı jiberıldı:",
        "tap_link": "Avtomatty kırw úşın siltemenı basyńyz.",
        "open_mail": "Poşta Qoldanbasyn Aşw",
        "open_with": "Munymeń aşw",
        "didnt_get_email": "Xat kelmedi me?",
        "resend": "Qaıta jiberw",
        "resend_in": "%ds keıın qaıta jiberw",
        "new_link_sent": "Jańa silteme jiberildi!",
        "valid_email": "Jaramdy elektrondyq poşta mekenjaıyn engiziñız.",
        "by_continuing": "Jalğastyra otyryp, sız Spike AI",
        "and_word": "jáne",

        // Screen Time Onboarding
        "screen_time_title": "Ekran Waqyty",
        "screen_time_permission_desc": "Spike AI Fokws, Qulyptaw jáne Ter rejımderı úşın Ekran Waqyty ruqsatyn qajet etedı. Bul tańdalğan qoldanbalar úşın eskertpeler men bógelwler kórsetwge múmkındık beredı.",
        "screen_time_denied": "Ruqsat berilmedi. Parametrlerde qoswğa bolady.",
        "ask_before_opening": "Aşpas Burun Suraw",
        "block_apps_completely": "Qoldanbalardy Tolyq Bógew",
        "stay_accountable": "Jawaptı Bolıńyz",
        "stay_accountable_desc": "Ilgerılewdı baqylańyz jáne fokws ádetterıñızdı kórinetın ustańyz.",
        "skip_for_now": "Qazırge Ótkızw",

        // Live Activity
        "daily_goals_title": "Kúndelikti Maqsattar",
        "of_done": "%d oryndaldı",
        "more_to_go": "+%d qaldı",

        // Chill morning
        "good_morning": "Qayırlı tań! Búgın maqsatqa baıyty bolıńyz. Tapsyrmalardy qarap şyğyńyz jáne fokwstalyńyz.",

        // General
        "error": "Qate", "ok": "OK", "yes": "Ia", "no": "Joq",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Демалыс режиміне ауысу керек пе?",
        "stay_focused_btn": "Назар аудару",
        "switch_anyway_btn": "Бәрібір ауысу",
        "switch_to_chill_msg": "Сізде әлі аяқталмаған мақсаттар бар. Демалыс режиміне ауысу қолданбаларды бұғаттауды алып тастайды, бүгінгі мақсаттарыңызды аяқтамау қаупін арттырады.",
        "task_notification": "Тапсырма хабарламасы",
        "missed_alarm": "Өткізіп алынған дабыл",
        "quote_of_day": "Күннің дәйексөзі",
        "new_quotes_daily": "Жаңа дәйексөздер күн сайын таңғы 5:00-де келеді",
        "focus_day_label": "Назар аудару күні",
        "missed_label": "Өткізілген",
        "access_granted": "Рұқсат берілді",
        "goal_reminder": "Мақсат еске салғышы",
        "spike_ai_focus": "Spike AI Назар аудару",
        "goals_required_title": "Мақсаттар қажет",
        "goals_required_desc_focus": "Назар аудару режимі таңдалған қолданбаларды тек аяқталмаған мақсаттарыңыз болған кезде бұғаттайды. Қолданбаларды бұғаттауды іске қосу үшін мақсаттар қосыңыз.",
        "goals_required_desc_lockin": "Құлыптау режимі таңдалған қолданбаларды тек аяқталмаған мақсаттарыңыз болған кезде бұғаттайды. Қолданбаларды бұғаттауды іске қосу үшін мақсаттар қосыңыз.",
        "save": "Сақтау",
        "no_goals_reminder_body": "Сіз бүгінге ешқандай мақсат қоймадыңыз. Күніңізді жоспарлауға бір сәт уақыт бөліңіз!",
        "dont_forget": "Ұмытпаңыз",
        "chill_morning_body": "Қайырлы таң! Бүгін мақсатқа бағытты болыңыз. Тапсырмаларды қарап шығыңыз және фокусталыңыз.",
        "every_day": "Күн сайын",
        "weekdays": "Жұмыс күндері",
        "weekends": "Демалыс күндері",
        "time_to_focus": "Фокустану уақыты!",

        // Additional UI strings
        "next_quote_in": "Келесі дәйексөз %@ кейін",
        "enable_notif_chill": "Жайлы режимді бастамас бұрын хабарландыруларды қосыңыз.",
        "enable_screen_time_mode": "Бұл режимді бастамас бұрын Экран уақытына рұқсатты қосыңыз.",
        "select_app_before_mode": "Бұл режимді бастамас бұрын кемінде бір қолданба, санат немесе веб-сайт таңдаңыз.",
        "mode_not_ready": "Бұл режим әлі бастауға дайын емес.",
        "protection_stopped_no_apps": "Қорғау тоқтатылды: қолданбалар таңдалмаған.",
        "protection_stopped_screen_time": "Қорғау тоқтатылды: Экран уақытына рұқсат өзгерді.",
        "max_reminders": "Сіз ең көбі %d фокус еске салғышын жасай аласыз.",
        "front_camera_unavailable": "Алдыңғы камера қол жетімсіз.",
        "task_title_empty": "Тапсырма тақырыбы бос болуы мүмкін емес.",
        "goal_title_empty": "Мақсат тақырыбы бос болуы мүмкін емес.",
        "rate_limit_wait": "Жаңа есеп жасамас бұрын %d секунд күтіңіз.",
        "missed_alarm_for": "Сіз оятқышты жіберіп алдыңыз: %@",
        "stay_with_plan": "Жоспарды ұстаныңыз.",
        "motivation_small_wins": "Кіші жеңістер жинақталады.",
        "motivation_next_step": "Келесі қадамды аяқтаңыз.",
        "motivation_protect_hour": "Алдыңыздағы сағатты қорғаңыз.",
        "motivation_consistency": "Тұрақтылық қарқынды жеңеді.",
        "monthly_scope_btn": "Айлық",
        "yearly_scope_btn": "Жылдық",
        "restoring_session": "Сеанс қалпына келтірілуде...",

        // Milestones
        "milestone_3day_streak": "3 күндік тізбек",
        "milestone_3day_desc": "Тұрақты ырғақ басталды.",
        "milestone_7day_streak": "7 күндік тізбек",
        "milestone_7day_desc": "Толық бір апта фокус.",
        "milestone_10h_protected": "10 сағат қорғалды",
        "milestone_10h_desc": "Маңызды нәрселер үшін қорғалған уақыт.",
        "milestone_30_focus": "30 фокус күні",
        "milestone_30_desc": "Нағыз салмағы бар тұрақтылық.",

        // Narratives
        "narrative_improved": "Экран уақытыңыз өткен аптамен салыстырғанда жақсарды.",
        "narrative_consistent": "Бұл аптада тұрақты болдыңыз және фокусыңызды қорғадыңыз.",
        "narrative_more_days": "Әдеттегіден көп фокус күндерін аяқтадыңыз.",
        "narrative_building": "Сіз ырғақты бір-бірден фокус күнімен құрып жатырсыз.",

        // Screen time
        "screen_time_trend_pending": "Пайдалану тарихы өскен сайын экран уақытының трендтері пайда болады.",
        "screen_time_improved": "Экран уақыты %d%% жақсарды",
        "screen_time_higher": "Экран уақыты әдеттегіден сәл жоғары",
        "screen_time_steady": "Бұл апта экран уақыты тұрақты",

        // Benchmarks
        "benchmark_pending": "Орташа экран уақыты қолданба пайдалану тарихын жазған кезде көрсетіледі. Жаһандық нұсқау нүктесі — күніне шамамен 7 сағат.",
        "benchmark_below": "7 күндік орташаңыз %@, жаһандық 7 сағат орташадан төмен. Бұл күшті бағыт.",
        "benchmark_above": "7 күндік орташаңыз %@, жаһандық 7 сағат орташадан жоғары. Бүгін аз ғана азайту трендті өзгерте алады.",
        "benchmark_matching": "7 күндік орташаңыз %@, жаһандық 7 сағат орташаға тең.",

        // Task editing
        "edit_task": "Тапсырманы өңдеу",
        "task_name_placeholder": "Тапсырма атауы",
        "task_reminder_default": "Тапсырма еске салғышы",
        "time_h_m": "%dс %dм",
        "time_m": "%dм",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Malay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let ms: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Tentang mod fokus",
        "no_active_goals_title": "Tiada matlamat aktif",
        "no_active_goals_btn": "Faham",
        "no_active_goals_msg": "Mod Fokus dan Kunci Masuk hanya berjalan selagi anda mempunyai matlamat yang belum selesai. Tambah matlamat — atau aktifkan semula — kemudian mulakan sesi anda.",
        // Tab bar
        "tab_home": "Utama",
        "tab_progress": "Kemajuan",
        "tab_mode": "Mod",
        "tab_profile": "Profil",

        // Home
        "today": "Hari ini",
        "tomorrow": "Esok",
        "yesterday": "Semalam",
        "back_to_today": "Kembali ke Hari ini",
        "add_first_task": "Ketik + untuk menambah tugasan pertama anda",
        "no_tasks_this_day": "Tiada tugasan pada hari ini",
        "new_task": "Tugasan Baharu",
        "what_to_do": "Apa yang perlu anda lakukan?",
        "task": "Tugasan",
        "schedule": "Jadual",
        "pick_date_hint": "Pilih mana-mana tarikh — hari ini, minggu depan, atau beberapa bulan akan datang.",
        "priority": "Keutamaan",
        "low": "Rendah",
        "medium": "Sederhana",
        "high": "Tinggi",
        "notification": "Pemberitahuan",
        "silent_push": "Pemberitahuan tolak senyap",
        "notification_desc": "Menghantar pemberitahuan tolak sekali pada masa yang dijadualkan. Ia muncul secara senyap di Skrin Kunci dan Pusat Pemberitahuan.",
        "reminder": "Peringatan",
        "alarm_sound": "Penggera dengan bunyi & getaran",
        "reminder_desc": "Berfungsi seperti penggera — bunyi khas akan dimainkan dan telefon anda akan bergetar berterusan sehingga anda menekan butang Tolak di skrin. Sesuai untuk mesyuarat dan tarikh akhir.",
        "cancel": "Batal",
        "add": "Tambah",
        "edit": "Sunting",
        "delete": "Padam",
        "jump_to_date": "Lompat ke Tarikh",
        "done": "Selesai",
        "task_limit": "Anda telah mencapai had 25 tugasan untuk tarikh ini.",
        "time": "Masa",
        "date": "Tarikh",
        "select_date": "Pilih Tarikh",

        // Alarm
        "reminder_title": "Peringatan",
        "dismiss": "Tolak",

        // Progress
        "daily_progress": "Kemajuan Harian",
        "streaks": "kesinambungan",
        "focus_days": "hari fokus",
        "consistency": "konsistensi",
        "set_first_goal": "Tetapkan matlamat pertama anda untuk hari ini",
        "all_goals_completed": "Semua matlamat harian telah dicapai",
        "goals_completed": "daripada",
        "daily_goals_completed": "matlamat harian dicapai",
        "daily_goals": "Matlamat Harian",
        "remaining": "berbaki",
        "no_goals_planned": "Tiada matlamat yang dirancang",
        "complete_to_focus": "Selesaikan semua tugasan untuk menandakan hari ini sebagai hari fokus.",
        "add_task_to_start": "Tambah tugasan dari Utama untuk mula menjejak matlamat harian.",
        "daily_plan_complete": "Rancangan harian selesai",
        "ai_weekly_summary": "Ringkasan Mingguan AI",
        "creating_summary": "Mencipta ringkasan mingguan anda...",
        "generate_summary": "Jana Ringkasan",
        "refresh_summary": "Muat Semula Ringkasan",
        "first_summary_coming": "Ringkasan mingguan AI pertama anda sedang dalam perjalanan.",
        "first_summary_desc": "Ia akan siap pada %@ jam 9 malam. Ia termasuk cerapan tentang kemajuan anda, tugasan yang terlepas, dan mod fokus terbaik untuk anda.",
        "next_update": "Kemaskini seterusnya: %@",
        "weekly_recap": "Rekap mingguan hari fokus, tugasan, dan aliran produktiviti anda sudah sedia.",
        "screen_time_7day": "Masa Skrin 7 Hari",
        "best_streak": "Kesinambungan Terbaik",
        "days": "hari",
        "milestones": "Pencapaian",
        "milestone_unlocked": "Pencapaian Dibuka",
        "continue_btn": "Teruskan",
        "history_calendar": "Kalendar Sejarah",
        "monthly_scope_btn": "Bulanan",
        "yearly_scope_btn": "Tahunan",
        "mode_used": "Mod Digunakan",
        "completed": "Selesai",
        "not_completed": "Belum Selesai",
        "no_completed_tasks": "Tiada tugasan selesai direkodkan untuk hari ini.",
        "everything_completed": "Semuanya telah diselesaikan.",
        "no_missed_tasks": "Tiada tugasan terlepas direkodkan untuk hari ini.",
        "streak_day": "Hari Kesinambungan",
        "missed_day": "Hari Terlepas",
        "first_name": "Nama Pertama",
        "last_name": "Nama Keluarga",
        "avatar_color": "Warna Avatar",
        "whats_your_name": "Siapakah nama anda?",
        "name_helps": "Ini membantu memperibadikan pengalaman anda.",
        "name_save_failed": "Kami tidak dapat menyimpan nama anda. Semak sambungan dan cuba semula.",
        "continue_btn_name": "Teruskan",
        "restoring_session": "Memulihkan sesi anda...",
        "wins": "Kemenangan",
        "next_action": "Tindakan Seterusnya",
        "average": "purata",
        "todays_completion": "Penyelesaian hari ini",
        "streaks_this_month": "kesinambungan bulan ini",
        "streak_days": "hari kesinambungan",
        "non_streak_days": "hari tanpa kesinambungan",
        "monthly_streak_summary": "%d kesinambungan bulan ini • %d hari kesinambungan, %d hari tanpa kesinambungan",
        "duration_average": "%@ purata",

        // Profile
        "personal_details": "Butiran Peribadi",
        "personal_info": "Maklumat Peribadi",
        "update_email_name": "Kemaskini e-mel dan nama penuh anda.",
        "and_username": "dan nama pengguna",
        "invite_friends": "Jemput Rakan",
        "refer_friend_title": "Rujuk rakan dan peroleh $10",
        "refer_friend_desc": "Peroleh $10 untuk setiap rakan yang mendaftar dengan kod promosi anda.",
        "upgrade_family_plan": "Naik taraf ke Pelan Keluarga",
        "goals_tracking": "Matlamat & Penjejakan",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Sunting Matlamat Pemakanan",
        "tracking_reminders": "Peringatan Penjejakan",
        "email_not_editable": "E-mel anda disambungkan ke log masuk dan tidak boleh disunting di sini.",
        "theme": "Tema",
        "theme_desc": "Gunakan penampilan sistem atau pilih mod cerah/gelap tetap.",
        "appearance": "Penampilan",
        "appearance_desc": "Pilih penampilan cerah, gelap, atau sistem",
        "live_activity_profile_desc": "Papar kemajuan harian anda di Skrin Kunci dan Dynamic Island",
        "system": "Sistem",
        "light": "Cerah",
        "dark": "Gelap",
        "live_activity": "Live Activity",
        "live_activity_desc": "Papar matlamat hari ini, kesinambungan, dan motivasi baharu di Skrin Kunci.",
        "privacy_policy": "Dasar Privasi",
        "privacy_desc": "Semak cara data aplikasi dan kebenaran peranti digunakan.",
        "terms_of_service": "Terma dan Syarat",
        "terms_desc": "Baca peraturan penggunaan aplikasi dan alat fokusnya.",
        "follow_us": "Ikuti Kami",
        "sign_out": "Log Keluar",
        "sign_out_desc": "Tamatkan sesi ini pada peranti semasa.",
        "delete_account": "Padam Akaun",
        "delete_account_desc": "Padam akaun anda dan data aplikasi yang disegerakkan secara kekal.",
        "delete_account_title": "Padam Akaun",
        "delete_account_msg": "Tindakan ini kekal. Semua data anda akan dipadamkan dan tidak boleh dipulihkan.",
        "delete_account_continue": "Teruskan",
        "delete_account_final_title": "Padam Secara Kekal?",
        "delete_account_final_msg": "Sila sahkan sekali lagi. Jika anda memadamkan akaun, Spike AI akan log keluar dan membawa anda kembali ke halaman log masuk.",
        "deleting_account": "Memadamkan akaun...",
        "delete_failed": "Pemadaman akaun gagal. Sila cuba lagi atau hubungi sokongan.",
        "language": "Bahasa",
        "language_desc": "Pilih bahasa untuk semua kandungan aplikasi.",
        "set_name": "Tetapkan nama anda",
        "profile_name_prompt": "Apa yang patut kami panggil anda?",
        "profile_name_desc": "Tambah nama yang Spike AI akan gunakan merentas profil dan pengalaman produktiviti anda.",
        "full_name": "Nama Penuh",
        "display_name": "Nama Paparan",
        "email": "E-mel",
        "save_changes": "Simpan Perubahan",
        "save_footer": "Perubahan disimpan ke profil anda dan digunakan di mana-mana identiti anda muncul dalam aplikasi.",
        "signed_in": "Telah log masuk",
        "account": "Akaun",
        "preferences": "Keutamaan",
        "support_legal": "Sokongan & Undang-undang",
        "account_actions": "Tindakan Akaun",
        "pref_show_completed": "Papar Tugasan Selesai",
        "pref_show_completed_desc": "Kekalkan tugasan yang telah selesai kelihatan dalam senarai harian anda.",
        "pref_quotes": "Petikan Motivasi",
        "pref_quotes_desc": "Papar petikan inspirasi pada skrin kemajuan anda.",
        "legal_updated": "Kemaskini terakhir: 25 Mei 2026",
        "privacy_body": """
        Kemaskini terakhir: 25 Mei 2026

        Spike AI ialah aplikasi produktiviti dan fokus. Dasar Privasi ini menerangkan cara Spike AI mengendalikan maklumat yang digunakan untuk menyediakan akaun, perancangan tugasan, peringatan, mod fokus, kawalan Masa Skrin, penjejakan kemajuan, dan ringkasan produktiviti yang dijana AI.

        Maklumat yang kami kumpul: pengecam akaun seperti alamat e-mel dan ID pengguna; butiran profil yang anda pilih untuk berikan, seperti nama paparan dan nama penuh; tugasan, matlamat, peringatan, sejarah penyelesaian, tetapan mod fokus, token pemilihan aplikasi, dan metrik kemajuan. Kami juga boleh menyimpan rekod teknikal yang diperlukan untuk memastikan perkhidmatan kekal boleh dipercayai dan selamat.

        Masa Skrin dan pemilihan aplikasi: pemilihan aplikasi, kategori, dan domain web dikendalikan melalui rangka kerja FamilyControls dan ManagedSettings Apple. Spike AI menyimpan token yang disediakan Apple yang diperlukan untuk menggunakan mod fokus pilihan anda. Kami tidak menggunakan pemilihan ini untuk pengiklanan.

        Penggunaan kamera dalam Mod Atlet: akses kamera digunakan untuk semakan pose badan pada peranti supaya anda boleh memperoleh akses aplikasi sementara melalui pergerakan. Spike AI tidak memuat naik bingkai video untuk ciri ini dan tidak menggunakan data kamera untuk pengiklanan.

        Pemberitahuan dan peringatan: Spike AI menggunakan kebenaran pemberitahuan untuk menghantar peringatan tugasan, penggera, dan dorongan fokus yang anda konfigurasikan. Anda boleh menukar akses pemberitahuan dalam Tetapan iOS pada bila-bila masa.

        Ringkasan AI: jika anda menjana ringkasan kemajuan, metrik tugasan, matlamat, fokus, dan produktiviti terkini mungkin diproses oleh bahagian belakang Spike AI untuk menghasilkan ringkasan tersebut. Elakkan memasukkan maklumat peribadi sensitif ke dalam nama tugasan atau matlamat jika anda tidak mahu ia diproses untuk ciri produktiviti.

        Cara kami menggunakan maklumat: untuk mengesahkan identiti anda, menyegerakkan akaun anda, menyediakan alat fokus, menjadualkan peringatan, memaparkan kemajuan, memperibadikan cerapan produktiviti, melindungi daripada penyalahgunaan, menyelesaikan masalah, dan mematuhi kewajipan undang-undang. Spike AI tidak menjual maklumat peribadi anda.

        Pemadaman data: anda boleh log keluar atau meminta pemadaman akaun kekal daripada Profil. Pemadaman akaun membuang akaun pengesahan dan data aplikasi yang disegerakkan yang berkaitan dengan akaun tersebut, tertakluk kepada pengekalan terhad yang diperlukan untuk keselamatan, pencegahan penipuan, penyelesaian pertikaian, atau pematuhan undang-undang.

        Pilihan anda: anda boleh menyunting butiran profil, menukar keutamaan bahasa dan penampilan, menyahaktifkan Live Activity, membatalkan kebenaran peranti dalam Tetapan, berhenti menggunakan mod fokus tertentu, atau memadamkan akaun anda.

        Hubungi: untuk soalan privasi atau isu pemadaman akaun, hubungi sokongan Spike AI melalui saluran sokongan yang disediakan oleh aplikasi atau senarai App Store.
        """,
        "terms_body": """
        Kemaskini terakhir: 25 Mei 2026

        Terma Perkhidmatan ini mentadbir penggunaan anda terhadap Spike AI, termasuk tugasan, peringatan, mod fokus, gesaan dan perisai aplikasi Masa Skrin, semakan pergerakan Mod Atlet, penjejakan kemajuan, dan ringkasan yang dijana AI.

        Kelayakan dan akaun: anda bertanggungjawab ke atas akaun yang anda cipta dan untuk menjaga keselamatan akses kepada e-mel dan peranti anda. Gunakan maklumat yang tepat apabila aplikasi meminta butiran profil.

        Tujuan produktiviti: Spike AI direka bentuk untuk menyokong produktiviti peribadi dan penggunaan peranti yang bertujuan. Ia bukan perkhidmatan perubatan, kesihatan mental, kecemasan, keselamatan, kawalan ibu bapa, pemantauan pekerjaan, atau pengurusan peranti. Jangan bergantung pada Spike AI apabila kegagalan peringatan, sekatan, gesaan, semakan kamera, pemberitahuan, permintaan rangkaian, atau kebenaran Apple boleh menyebabkan kemudaratan.

        Tanggungjawab anda: pilih tetapan fokus yang sesuai dengan situasi anda; semak pemilihan aplikasi sebelum mengaktifkan mod; matikan mod apabila ia tidak lagi memenuhi keperluan anda; patuhi undang-undang yang terpakai dan terma platform Apple; dan elakkan memasukkan maklumat sensitif ke dalam tugasan atau matlamat melainkan anda selesa menggunakannya dalam aplikasi.

        Penggunaan yang boleh diterima: jangan menyalahgunakan Spike AI, mengganggu peranti atau akaun orang lain, cuba memintas keselamatan atau sekatan platform, kejuruteraan songsang bahagian perkhidmatan yang dilindungi, membebankan bahagian belakang, atau menggunakan aplikasi untuk aktiviti yang menyalahi undang-undang, kesat, menipu, atau berbahaya.

        Kebenaran dan ketersediaan: sesetengah ciri memerlukan kebenaran iOS seperti Masa Skrin, pemberitahuan, kamera, Live Activities, dan akses rangkaian. Apple, tetapan peranti, kelakuan sistem operasi, kesambungan, dan ketersediaan bahagian belakang boleh mempengaruhi sama ada ciri berfungsi seperti yang dijangkakan.

        Kandungan yang dijana AI: ringkasan kemajuan mungkin dijana menggunakan sistem automatik. Ia hanya untuk refleksi dan bimbingan produktiviti. Semak dengan pertimbangan anda sendiri sebelum bergantung padanya.

        Pemadaman dan penamatan akaun: anda boleh meminta pemadaman akaun daripada Profil. Spike AI boleh menggantung atau menamatkan akses jika dikehendaki oleh undang-undang, peraturan platform, kebimbangan keselamatan, atau penyalahgunaan serius.

        Perubahan: Spike AI boleh mengemaskini Terma ini seiring perkembangan aplikasi. Penggunaan berterusan selepas kemaskini bermakna anda menerima Terma yang dikemaskini.

        Hubungi: untuk soalan tentang Terma ini, hubungi sokongan Spike AI melalui saluran sokongan yang disediakan oleh aplikasi atau senarai App Store.
        """,

        // Focus Mode
        "focus_title": "Fokus",
        "select_mode": "Pilih Mod",
        "chill": "Santai",
        "focus": "Fokus",
        "lock_in": "Kunci Masuk",
        "sweat": "Atlet",
        "gentle_nudges": "Dorongan lembut",
        "confirm_intent": "Sahkan niat",
        "no_bypass": "Tiada pintasan",
        "move_to_unlock": "Bergerak untuk membuka kunci",
        "activate_focus": "Aktifkan Mod Fokus",
        "deactivate_focus": "Nyahaktifkan Mod Fokus",
        "mode_active": "Mod Aktif",
        "reminders_scheduled": "Peringatan dijadualkan",
        "apps_prompt_active": "aplikasi — gesaan \"Adakah anda pasti?\" aktif",
        "apps_blocked": "aplikasi disekat",
        "temp_access_active": "Akses sementara aktif",
        "apps_require_movement": "aplikasi memerlukan pergerakan untuk dibuka kunci",
        "notifications_label": "Pemberitahuan",
        "notifications_enabled": "Pemberitahuan diaktifkan",
        "notifications_denied": "Pemberitahuan ditolak",
        "enable_notif_settings": "Aktifkan pemberitahuan dalam Tetapan.",
        "allow_notif_desc": "Benarkan pemberitahuan supaya Spike AI boleh menghantar peringatan fokus kepada anda.",
        "enable_notifications": "Aktifkan Pemberitahuan",
        "screen_time_access": "Akses Masa Skrin",
        "screen_time_authorized": "Masa Skrin dibenarkan",
        "allow_screen_time": "Benarkan Akses Masa Skrin",
        "tap_to_allow": "Ketik di bawah untuk membenarkan akses Masa Skrin.",
        "open_settings_manual": "Atau buka Tetapan untuk mengaktifkan secara manual",
        "open_settings": "Buka Tetapan",
        "app_selection": "Pemilihan Aplikasi",
        "selections": "pilihan",
        "choose_apps_confirm": "Pilih aplikasi yang perlu disahkan sebelum dibuka.",
        "choose_apps_block": "Pilih aplikasi yang hendak disekat.",
        "choose_apps_movement": "Pilih aplikasi yang dibuka kunci dengan pergerakan.",
        "change_selection": "Tukar Pilihan",
        "select_apps": "Pilih Aplikasi",
        "movement_unlock": "Buka Kunci dengan Pergerakan",
        "movement_desc": "Tekan tubi dan bangun berdiri dijejak dengan pengesanan badan AI. Setiap ulangan yang disahkan menambah 1 minit akses kepada aplikasi yang dipilih.",
        "access_available": "Akses tersedia selama %@",
        "open_camera": "Buka Semakan Kamera",
        "lock_in_mode": "Mod Kunci Masuk",
        "lock_in_warning": "Aplikasi memaparkan skrin merah tanpa pintasan. Anda mesti kembali ke sini untuk mematikan Mod Kunci Masuk.",
        "sweat_mode": "Mod Atlet",
        "do_exercises": "Lakukan tekan tubi atau bangun berdiri untuk memperoleh masa",
        "add_minutes": "Tambah %d Minit",
        "keep_in_view": "Pastikan bahu, lengan, atau pinggul anda kelihatan",
        "camera_required": "Akses kamera diperlukan untuk semakan pergerakan.",
        "camera_disabled": "Akses kamera dinyahaktifkan. Aktifkan dalam Tetapan untuk menggunakan Mod Peluh.",
        "camera_unavailable": "Akses kamera tidak tersedia.",
        "starting_camera": "Memulakan kamera...",
        "camera_active": "Kamera aktif",
        "allow_camera": "Benarkan Akses Kamera",
        "focus_mode_title": "Mod Fokus",
        "focus_mode_desc": "Kawal tabiat digital anda dengan mod yang fokus dan profesional.",
        "about_permissions": "Tentang Kebenaran",
        "permissions_desc": "Mod Santai memerlukan kebenaran pemberitahuan. Mod Fokus, Kunci Masuk, dan Peluh memerlukan kebenaran Masa Skrin. Mod Peluh juga menggunakan akses kamera untuk semakan pergerakan.",
        "get_started": "Mula",
        "skip": "Langkau",
        "unlocked_for": "Dibuka kunci selama %@",

        // Chill mode descriptions
        "chill_desc": "Peringatan harian melalui pemberitahuan. Tanpa kawalan aplikasi — hanya dorongan lembut untuk kekal bertujuan.",
        "focus_desc": "Apabila anda membuka aplikasi yang dipilih, Spike AI bertanya \"Adakah anda pasti?\" Anda boleh membukanya seperti biasa atau kembali ke tugasan anda. Aplikasi tidak disekat.",
        "lock_in_desc": "Aplikasi yang dipilih disekat selagi Kunci Masuk aktif. Anda boleh mematikan mod dari Spike AI.",
        "sweat_desc": "Aplikasi yang dipilih kekal disekat sehingga anda menyelesaikan tekan tubi atau bangun berdiri yang disemak kamera. Setiap ulangan yang disahkan membuka kunci 1 minit.",

        // Motivational (deactivation)
        "giving_up_title": "Anda sedang membuat kemajuan — jangan berhenti sekarang",
        "giving_up_msg": "Anda masih mempunyai matlamat yang belum selesai hari ini. Setiap tugasan yang disiapkan membina momentum. Kekal komited — diri anda pada masa hadapan akan berterima kasih.",
        "giving_up_continue": "Kekal Fokus",
        "giving_up_stop": "Matikan Sahaja",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Sistem produktiviti peribadi anda",
        "start_setup": "Mula Persediaan",
        "make_phone_work": "Jadikan telefon anda bekerja\nuntuk matlamat anda.",
        "onboarding_welcome_desc": "Kurangkan penatalan tanpa tujuan, lindungi masa fokus, dan ubah tugasan sebenar menjadi kemajuan yang kelihatan.",
        "did_you_know": "Tahukah anda?",
        "did_you_know_subtitle": "Seseorang menghabiskan purata 7 jam sehari di telefon mereka. Itu bersamaan",
        "hours_per_day": "jam sehari",
        "days_per_month": "hari sebulan",
        "days_per_year": "hari setahun",
        "years_of_life": "tahun hayat anda",
        "screen_time_reality": "Dan sesetengah orang menghabiskan lebih banyak lagi.",
        "dont_worry_title": "Jangan risau",
        "spike_has_your_back": "Spike AI menyokong anda",
        "solution_desc": "Kami akan membantu anda memaksimumkan produktiviti, mendekati matlamat anda, dan membina tabiat yang mengubah anda menjadi versi terbaik diri anda.",
        "screen_time_access_title": "Akses Masa Skrin",
        "grant_access": "Berikan Akses",
        "which_apps": "Pilih aplikasi\nyang mengganggu anda",
        "choose_apps_protect": "Pilih aplikasi yang membazir masa anda. Kami akan menyekatnya semasa mod fokus.",
        "apple_screen_time_required": "Apple memerlukan akses Masa Skrin sebelum Spike AI boleh memaparkan senarai aplikasi anda.",
        "save_apps": "Simpan & Teruskan",
        "change_selected_apps": "Tukar aplikasi yang dipilih",
        "ready_change_life": "Bersedia untuk mengubah\nhidup anda?",
        "ready_change_desc": "Cipta akaun untuk menyimpan pilihan anda dan mulakan perjalanan anda.",
        "benefit_no_distraction": "Aplikasi yang mengganggu tidak akan mengacau anda lagi",
        "benefit_discover_modes": "Temui 4 jenis mod fokus yang berbeza",
        "benefit_track_progress": "Jejak kemajuan anda dan mendekati matlamat anda",
        "create_account": "Cipta Akaun",
        "protect_focus": "Lindungi Fokus",
        "block_feeds": "Sekat suapan",
        "finish_tasks": "Siapkan tugasan",
        "energy_plus_three": "+3 Tenaga",
        "selected_count": "%d dipilih",
        "no_apps_selected": "Belum ada aplikasi dipilih",
        "saved_for_modes": "Disimpan untuk mod perlindungan",
        "select_apps_to_control": "Pilih aplikasi yang anda mahu kawal",
        "clean_room": "Kemaskan Bilik",
        "snap_proof": "Gambar bukti apabila selesai",
        "ai_verifies_task": "AI mengesahkan tugasan",
        "energy_earned": "+3 Tenaga diperoleh",
        "on_track": "Mengikut rancangan",
        "energy": "Tenaga",
        "tasks_completed": "Tugasan selesai",
        "focus_protected": "Fokus dilindungi",
        "scrolling_avoided": "Penatalan dielakkan",
        "continue_apple": "Teruskan dengan Apple",
        "continue_google": "Teruskan dengan Google",
        "continue_email": "Teruskan dengan e-mel",
        "enter_email": "Masukkan e-mel anda",
        "send_sign_in_link": "Kami akan menghantar pautan log masuk",
        "check_email": "Semak e-mel anda",
        "sent_link_to": "Kami telah menghantar pautan log masuk ke",
        "tap_link": "Ketik pautan untuk log masuk secara automatik.",
        "open_mail": "Buka Aplikasi Mel",
        "open_with": "Buka dengan",
        "didnt_get_email": "Tidak menerima e-mel?",
        "resend": "Hantar semula",
        "resend_in": "Hantar semula dalam %d saat",
        "new_link_sent": "Pautan baharu telah dihantar!",
        "valid_email": "Masukkan alamat e-mel yang sah.",
        "by_continuing": "Dengan meneruskan, anda bersetuju dengan",
        "and_word": "dan",

        // Screen Time Onboarding
        "screen_time_title": "Masa Skrin",
        "screen_time_permission_desc": "Spike AI memerlukan kebenaran Masa Skrin untuk mod Fokus, Kunci Masuk, dan Peluh. Ini membolehkannya memaparkan gesaan dan sekatan untuk aplikasi pilihan anda.",
        "screen_time_denied": "Kebenaran ditolak. Anda boleh mengaktifkannya dalam Tetapan.",
        "ask_before_opening": "Tanya Sebelum Membuka",
        "block_apps_completely": "Sekat Aplikasi Sepenuhnya",
        "stay_accountable": "Kekal Bertanggungjawab",
        "stay_accountable_desc": "Jejak kemajuan dan pastikan tabiat fokus anda kelihatan.",
        "skip_for_now": "Langkau Buat Sekarang",

        // Live Activity
        "daily_goals_title": "Matlamat Harian",
        "of_done": "daripada %d selesai",
        "more_to_go": "+%d lagi",

        // Chill morning
        "good_morning": "Selamat pagi! Kekal bertujuan hari ini. Semak tugasan anda dan kekal fokus.",

        // Onboarding (extended)
        "scrolling_adds_up": "Penatalan nampak kecil,\ntetapi ia bertambah.",
        "per_day": "sehari",
        "per_month": "sebulan",
        "per_year": "setahun",
        "thirty_days": "30 hari",
        "lost_to_checking": "hilang untuk semakan automatik",
        "scrolling_cost_desc": "Spike AI membantu anda menyedari detik-detik itu sebelum ia memakan seluruh malam.",
        "your_modes_target": "Mod anda kini mempunyai\nsasaran yang jelas.",
        "app_selections_will_be_used": "%d pilihan aplikasi akan digunakan apabila anda memulakan mod perlindungan.",
        "select_apps_after_login": "Pilih aplikasi sekali selepas log masuk, semua mod perlindungan akan menggunakan senarai yang sama.",
        "focus_mode_marketing_detail": "Jeda sebentar sebelum membuka aplikasi yang mengganggu.",
        "lock_in_marketing_detail": "Sempadan lebih kukuh apabila anda perlukan fokus mendalam.",
        "sweat_marketing_detail": "Bergerak dahulu untuk memperoleh masa akses.",
        "replace_scroll": "Gantikan penatalan dengan\npencapaian sebenar.",
        "habit_desc": "Ubah tindakan bermanfaat menjadi tenaga: kemaskan bilik, kumpul tugasan, berjalan, regangan, atau siapkan satu tugasan.",
        "see_behavior_changing": "Lihat tingkah laku anda\nberubah.",
        "progress_desc": "Jejak masa fokus, penyelesaian tugasan, dan kesinambungan supaya kemajuan terasa nyata.",
        "ready_protected_day": "Bersedia untuk hari pertama\nyang dilindungi?",
        "create_account_desc": "Cipta akaun untuk menyimpan pilihan aplikasi, mod fokus, tugasan, dan kemajuan.",
        "benefit_apps_saved": "Aplikasi yang mengganggu disimpan untuk mod",
        "benefit_start_modes": "Mulakan mod Fokus, Kunci Masuk, atau Peluh",
        "benefit_progress_synced": "Kemajuan anda disegerakkan",

        // General
        "error": "Ralat",
        "ok": "OK",
        "yes": "Ya",
        "no": "Tidak",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Tukar ke Mod Santai?",
        "stay_focused_btn": "Kekal Fokus",
        "switch_anyway_btn": "Tukar Sahaja",
        "switch_to_chill_msg": "Anda masih mempunyai matlamat yang belum selesai. Bertukar ke Mod Santai membuang sekatan aplikasi, yang meningkatkan risiko tidak menyiapkan matlamat anda hari ini.",
        "task_notification": "Pemberitahuan Tugasan",
        "missed_alarm": "Penggera Terlepas",
        "quote_of_day": "Petikan Hari Ini",
        "new_quotes_daily": "Petikan baharu tiba setiap hari pada jam 5:00 pagi",
        "focus_day_label": "Hari Fokus",
        "missed_label": "Terlepas",
        "access_granted": "Akses diberikan",
        "goal_reminder": "Peringatan Matlamat",
        "spike_ai_focus": "Spike AI Fokus",
        "goals_required_title": "Matlamat Diperlukan",
        "goals_required_desc_focus": "Mod Fokus menyekat aplikasi terpilih hanya apabila anda mempunyai matlamat yang belum selesai. Tambah matlamat di tab Utama untuk mengaktifkan sekatan aplikasi.",
        "goals_required_desc_lockin": "Mod Kunci Masuk menyekat aplikasi terpilih hanya apabila anda mempunyai matlamat yang belum selesai. Tambah matlamat di tab Utama untuk mengaktifkan sekatan aplikasi.",
        "save": "Simpan",
        "no_goals_reminder_body": "Anda belum menetapkan sebarang matlamat untuk hari ini. Luangkan sedikit masa untuk merancang hari anda!",
        "dont_forget": "Jangan lupa",
        "chill_morning_body": "Selamat pagi! Kekal bertujuan hari ini. Semak tugasan anda dan kekal fokus.",
        "every_day": "Setiap hari",
        "weekdays": "Hari bekerja",
        "weekends": "Hujung minggu",
        "time_to_focus": "Masa untuk fokus!",

        // Additional UI strings
        "next_quote_in": "Petikan seterusnya dalam %@",
        "enable_notif_chill": "Aktifkan pemberitahuan sebelum memulakan mod Santai.",
        "enable_screen_time_mode": "Aktifkan akses Masa Skrin sebelum memulakan mod ini.",
        "select_app_before_mode": "Pilih sekurang-kurangnya satu aplikasi, kategori, atau laman web sebelum memulakan mod ini.",
        "mode_not_ready": "Mod ini belum bersedia untuk dimulakan.",
        "protection_stopped_no_apps": "Perlindungan dihentikan kerana tiada aplikasi dipilih.",
        "protection_stopped_screen_time": "Perlindungan dihentikan kerana akses Masa Skrin berubah.",
        "max_reminders": "Anda boleh menyimpan sehingga %d peringatan fokus.",
        "front_camera_unavailable": "Kamera hadapan tidak tersedia.",
        "task_title_empty": "Tajuk tugasan tidak boleh kosong.",
        "goal_title_empty": "Tajuk matlamat tidak boleh kosong.",
        "rate_limit_wait": "Sila tunggu %d saat sebelum menjana ringkasan lain.",
        "missed_alarm_for": "Anda terlepas penggera untuk: %@",
        "stay_with_plan": "Kekal dengan rancangan.",
        "motivation_small_wins": "Kemenangan kecil bertambah.",
        "motivation_next_step": "Siapkan langkah seterusnya yang jelas.",
        "motivation_protect_hour": "Lindungi jam di hadapan anda.",
        "motivation_consistency": "Konsistensi mengatasi keamatan.",

        // Milestones
        "milestone_3day_streak": "Kesinambungan 3 hari",
        "milestone_3day_desc": "Irama yang mantap telah bermula.",
        "milestone_7day_streak": "Kesinambungan 7 hari",
        "milestone_7day_desc": "Satu minggu penuh fokus.",
        "milestone_10h_protected": "10 jam dilindungi",
        "milestone_10h_desc": "Masa dilindungi untuk perkara yang penting.",
        "milestone_30_focus": "30 hari fokus",
        "milestone_30_desc": "Konsistensi yang benar-benar bermakna.",

        // Narratives
        "narrative_improved": "Masa skrin anda bertambah baik berbanding minggu lepas.",
        "narrative_consistent": "Anda kekal konsisten minggu ini dan melindungi fokus anda.",
        "narrative_more_days": "Anda menyiapkan lebih banyak hari fokus daripada biasa.",
        "narrative_building": "Anda membina irama satu hari fokus pada satu masa.",

        // Screen time
        "screen_time_trend_pending": "Aliran masa skrin akan muncul apabila sejarah penggunaan bertambah.",
        "screen_time_improved": "Masa skrin bertambah baik sebanyak %d%%",
        "screen_time_higher": "Masa skrin sedikit lebih tinggi daripada biasa",
        "screen_time_steady": "Masa skrin stabil minggu ini",

        // Benchmarks
        "benchmark_pending": "Purata masa skrin akan muncul apabila aplikasi merekodkan sejarah penggunaan. Titik rujukan global ialah kira-kira 7 jam sehari.",
        "benchmark_below": "Purata 7 hari anda ialah %@, iaitu di bawah purata global 7 jam. Itu arah yang kukuh.",
        "benchmark_above": "Purata 7 hari anda ialah %@, melebihi purata global 7 jam. Pengurangan kecil hari ini boleh mengubah aliran.",
        "benchmark_matching": "Purata 7 hari anda ialah %@, sepadan dengan purata global 7 jam.",

        // Task editing
        "edit_task": "Sunting Tugasan",
        "task_name_placeholder": "Nama tugasan",
        "task_reminder_default": "Peringatan tugasan",
        "time_h_m": "%dj %dm",
        "time_m": "%dm",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tajik
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let tg: [String: String] = [
        // Focus / no active goals (added for full localization parity)
        "focus_info_btn": "Дар бораи ҳолатҳои тамаркуз",
        "no_active_goals_title": "Ҳадафҳои фаъол нест",
        "no_active_goals_btn": "Фаҳмидам",
        "no_active_goals_msg": "Ҳолатҳои «Тамаркуз» ва «Қулф» танҳо вақте кор мекунанд, ки шумо ҳадафи иҷронашуда дошта бошед. Ҳадаф илова кунед — ё онро аз нав фаъол созед — сипас сессияро оғоз кунед.",
        // Tab bar
        "tab_home": "Асосӣ", "tab_progress": "Пешрафт", "tab_mode": "Режим", "tab_profile": "Профил",

        // Home
        "today": "Имрӯз", "tomorrow": "Пагоҳ", "yesterday": "Дирӯз",
        "back_to_today": "Бозгашт ба имрӯз",
        "add_first_task": "Барои илова кардани вазифаи аввалин + -ро пахш кунед",
        "no_tasks_this_day": "Дар ин рӯз вазифае нест",
        "new_task": "Вазифаи нав",
        "what_to_do": "Шумо чӣ бояд кунед?",
        "task": "Вазифа", "schedule": "Ҷадвал",
        "pick_date_hint": "Ҳар сана-ро интихоб кунед — имрӯз, ҳафтаи оянда ё чанд моҳ пас.",
        "priority": "Муҳимият", "low": "Паст", "medium": "Миёна", "high": "Баланд",
        "notification": "Огоҳинома",
        "silent_push": "Огоҳиномаи бесадо",
        "notification_desc": "Дар вақти муайяншуда огоҳиномаи якдафъаина мефиристад. Он дар экрани қулфшуда ва Маркази огоҳиномаҳо бесадо пайдо мешавад.",
        "reminder": "Ёдовар",
        "alarm_sound": "Сигнал бо овоз ва ларзиш",
        "reminder_desc": "Мисли сигнал кор мекунад — овози махсус садо медиҳад ва телефон то пахши тугмаи «Бастан» ларзиш мекунад. Барои вохӯриҳо ва мӯҳлатҳо аъло аст.",
        "cancel": "Бекор кардан", "add": "Илова кардан", "edit": "Таҳрир", "delete": "Нест кардан",
        "jump_to_date": "Гузариш ба сана", "done": "Тайёр",
        "task_limit": "Шумо ба ҳадди 25 вазифа барои ин сана расидед.",
        "time": "Вақт", "date": "Сана", "select_date": "Интихоби сана",

        // Alarm
        "reminder_title": "Ёдовар", "dismiss": "Бастан",

        // Progress
        "daily_progress": "Пешрафти рӯзона", "streaks": "силсилаҳо", "focus_days": "рӯзҳои тамаркуз",
        "consistency": "пайдарпаӣ",
        "set_first_goal": "Ҳадафи аввалини худро барои имрӯз муайян кунед",
        "all_goals_completed": "Ҳамаи ҳадафҳои рӯзона иҷро шуданд",
        "goals_completed": "аз",
        "daily_goals_completed": "ҳадафи рӯзона иҷро шуд",
        "daily_goals": "Ҳадафҳои рӯзона", "remaining": "боқимонда",
        "no_goals_planned": "Ҳадафе нақша нашудааст",
        "complete_to_focus": "Барои қайд кардани имрӯз ҳамчун рӯзи тамаркуз ҳамаи вазифаҳоро иҷро кунед.",
        "add_task_to_start": "Барои оғоз кардани пайгирии ҳадафҳои рӯзона аз саҳифаи асосӣ вазифа илова кунед.",
        "daily_plan_complete": "Нақшаи рӯзона иҷро шуд",
        "ai_weekly_summary": "Ҳисоботи ҳафтаинаи ЗС",
        "creating_summary": "Ҳисоботи ҳафтаинаи шумо сохта истодааст...",
        "generate_summary": "Сохтани ҳисобот",
        "refresh_summary": "Навсозии ҳисобот",
        "first_summary_coming": "Аввалин ҳисоботи ҳафтаинаи ЗС-и шумо омада истодааст.",
        "first_summary_desc": "Он дар %@ соати 21:00 тайёр мешавад. Он маълумот дар бораи пешрафти шумо, вазифаҳои гузаронидашуда ва беҳтарин режими тамаркуз барои шуморо дар бар мегирад.",
        "next_update": "Навсозии навбатӣ: %@",
        "weekly_recap": "Хулосаи ҳафтаинаи рӯзҳои тамаркуз, вазифаҳо ва тамоюлҳои самаранокӣ тайёр аст.",
        "screen_time_7day": "Вақти экран дар 7 рӯз",
        "best_streak": "Беҳтарин силсила", "days": "рӯз",
        "milestones": "Дастовардҳо", "milestone_unlocked": "Дастоварди нав кушода шуд",
        "continue_btn": "Идома додан",
        "history_calendar": "Тақвими таърих",
        "monthly_scope_btn": "Моҳона",
        "yearly_scope_btn": "Солона",
        "mode_used": "Режими истифодашуда",
        "completed": "Иҷро шуд", "not_completed": "Иҷро нашуд",
        "no_completed_tasks": "Барои ин рӯз вазифаҳои иҷрошуда сабт нашудаанд.",
        "everything_completed": "Ҳама чиз иҷро шуд.",
        "no_missed_tasks": "Барои ин рӯз вазифаҳои гузаронидашуда сабт нашудаанд.",
        "streak_day": "Рӯзи силсила", "missed_day": "Рӯзи гузаронидашуда",
        "first_name": "Ном", "last_name": "Насаб",
        "avatar_color": "Ранги аватар",
        "whats_your_name": "Номи шумо чист?",
        "name_helps": "Ин барои шахсӣ кардани таҷрибаи шумо кӯмак мекунад.",
        "name_save_failed": "Номи шумо сабт нашуд. Пайвастшавиро тафтиш кунед ва дубора кӯшиш кунед.",
        "continue_btn_name": "Идома додан",
        "restoring_session": "Барқарорсозии ҷаласа...",
        "wins": "Ғалабаҳо", "next_action": "Қадами навбатӣ",
        "average": "миёна",
        "todays_completion": "Иҷрои имрӯза",
        "streaks_this_month": "силсилаҳо дар ин моҳ",
        "streak_days": "рӯзҳои силсила", "non_streak_days": "рӯзҳои бесилсила",
        "monthly_streak_summary": "%d силсила дар ин моҳ • %d рӯзи силсила, %d рӯзи бесилсила",
        "duration_average": "%@ миёна",

        // Profile
        "personal_details": "Маълумоти шахсӣ",
        "personal_info": "Маълумоти шахсӣ",
        "update_email_name": "Почтаи электронӣ ва номи пурраи худро навсозӣ кунед.",
        "and_username": "ва номи корбар",
        "invite_friends": "Даъвати дӯстон",
        "refer_friend_title": "Дӯстро даъват кунед ва $10 гиред",
        "refer_friend_desc": "Барои ҳар дӯсте, ки бо рамзи таблиғии шумо номнавис мешавад, $10 гиред.",
        "upgrade_family_plan": "Гузариш ба нақшаи оилавӣ",
        "goals_tracking": "Ҳадафҳо ва пайгирӣ",
        "apple_health": "Apple Health",
        "edit_nutrition_goals": "Таҳрири ҳадафҳои ғизоӣ",
        "tracking_reminders": "Ёдоварҳои пайгирӣ",
        "email_not_editable": "Почтаи электронии шумо ба ҳисоби шумо пайваст аст ва дар ин ҷо таҳрир карда намешавад.",
        "theme": "Мавзӯъ",
        "theme_desc": "Намуди системавиро истифода баред ё режими доимии равшан/торикро интихоб кунед.",
        "appearance": "Намуд",
        "appearance_desc": "Намуди равшан, торик ё системавиро интихоб кунед",
        "live_activity_profile_desc": "Пешрафти рӯзонаро дар экрани қулфшуда ва Dynamic Island нишон диҳед",
        "system": "Системавӣ", "light": "Равшан", "dark": "Торик",
        "live_activity": "Фаъолияти зинда",
        "live_activity_desc": "Ҳадафҳо, силсила ва ҳавасмандиро дар экрани қулфшуда нишон диҳед.",
        "privacy_policy": "Сиёсати махфият",
        "privacy_desc": "Бубинед, ки маълумоти барнома ва иҷозатҳои дастгоҳ чӣ тавр истифода мешаванд.",
        "terms_of_service": "Шартҳои истифода",
        "terms_desc": "Қоидаҳои истифодаи барнома ва воситаҳои тамаркузро хонед.",
        "follow_us": "Моро пайгирӣ кунед",
        "sign_out": "Баромадан",
        "sign_out_desc": "Ҷаласаро дар дастгоҳи ҷорӣ тамом кардан.",
        "delete_account": "Нест кардани ҳисоб",
        "delete_account_desc": "Ҳисоб ва маълумоти ҳамоҳангшудаи барномаро бебозгашт нест кардан.",
        "delete_account_title": "Нест кардани ҳисоб",
        "delete_account_msg": "Ин амал бебозгашт аст. Ҳамаи маълумоти шумо нест карда мешавад ва барқарор карда намешавад.",
        "delete_account_continue": "Идома додан",
        "delete_account_final_title": "Ҳамешагӣ нест карда шавад?",
        "delete_account_final_msg": "Лутфан боз як бор тасдиқ кунед. Агар шумо ҳисобро нест кунед, Spike AI шуморо аз система мебарорад ва ба саҳифаи воридшавӣ бармегардонад.",
        "deleting_account": "Нест кардани ҳисоб...",
        "delete_failed": "Нест кардани ҳисоб иҷро нашуд. Дубора кӯшиш кунед ё ба хадамоти дастгирӣ муроҷиат кунед.",
        "language": "Забон",
        "language_desc": "Забонро барои ҳамаи мӯҳтавои барнома интихоб кунед.",
        "set_name": "Номи худро ворид кунед",
        "profile_name_prompt": "Шуморо чӣ ном барем?",
        "profile_name_desc": "Номеро, ки Spike AI дар профил ва таҷрибаи самаранокии шумо истифода мебарад, ворид кунед.",
        "full_name": "Номи пурра",
        "display_name": "Номи намоишӣ",
        "email": "Почтаи электронӣ",
        "save_changes": "Сабти тағйирот",
        "save_footer": "Тағйирот дар профили шумо сабт мешавад ва дар ҳама ҷое, ки шахсияти шумо дар барнома нишон дода мешавад, истифода мешавад.",
        "signed_in": "Воридшавӣ иҷро шуд",
        "account": "Ҳисоб", "preferences": "Танзимот",
        "support_legal": "Дастгирӣ ва маълумоти ҳуқуқӣ",
        "account_actions": "Амалҳои ҳисоб",
        "pref_show_completed": "Нишон додани вазифаҳои иҷрошуда",
        "pref_show_completed_desc": "Вазифаҳои иҷрошударо дар рӯйхати рӯзона намоён нигоҳ доштан.",
        "pref_quotes": "Иқтибосҳои ҳавасмандкунанда",
        "pref_quotes_desc": "Иқтибоси илҳомбахшро дар саҳифаи пешрафт нишон додан.",
        "legal_updated": "Навсозии охирин: 25 маи 2026",
        "privacy_body": """
        Навсозии охирин: 25 маи 2026

        Spike AI барномаи самаранокӣ ва тамаркуз аст. Ин Сиёсати махфият тавзеҳ медиҳад, ки Spike AI маълумоти истифодашударо барои пешниҳоди ҳисобҳо, нақшаи вазифаҳо, ёдоварҳо, режимҳои тамаркуз, идоракунии вақти экран, пайгирии пешрафт ва ҳисоботҳои самаранокии зеҳни сунъӣ чӣ тавр идора мекунад.

        Маълумоте, ки мо ҷамъ мекунем: муайянкунандаҳои ҳисоб, аз қабили суроғаи почтаи электронӣ ва ID-и корбар; тафсилоти профиле, ки шумо интихоб мекунед, аз қабили номи намоишӣ ва номи пурра; вазифаҳо, ҳадафҳо, ёдоварҳо, таърихи иҷро, танзимоти режимҳои тамаркуз, токенҳои интихоби барнома ва нишондиҳандаҳои пешрафт. Мо инчунин метавонем сабтҳои техникии барои боэътимод ва бехатар нигоҳ доштани хизмат заруриро нигоҳ дорем.

        Вақти экран ва интихоби барнома: интихоби барнома, категория ва домени вебсайт тавассути чаҳорчӯбаҳои Apple FamilyControls ва ManagedSettings иҷро мешавад. Spike AI токенҳои Apple-ро барои татбиқи режимҳои тамаркузи интихобкардаи шумо нигоҳ медорад. Мо ин интихобҳоро барои таблиғот истифода намебарем.

        Истифодаи камера дар режими «Арақ»: дастрасии камера барои тафтиши ҳолати бадан дар дастгоҳ истифода мешавад, то шумо тавассути ҳаракат ба барномаҳо дастрасии муваққатӣ гиред. Spike AI кадрҳои видеоро барои ин хусусият бор намекунад ва маълумоти камераро барои таблиғот истифода намебарад.

        Огоҳиномаҳо ва ёдоварҳо: Spike AI иҷозати огоҳиномаро барои фиристодани ёдоварҳои вазифа, сигналҳо ва пешниҳодҳои тамаркузе, ки шумо танзим мекунед, истифода мебарад. Шумо метавонед дастрасии огоҳиномаро дар ҳар вақт дар Танзимоти iOS тағйир диҳед.

        Ҳисоботҳои ЗС: агар шумо ҳисоботи пешрафтро созед, маълумоти вазифаҳо, ҳадафҳо, режимҳои тамаркуз ва нишондиҳандаҳои самаранокии охирин метавонанд дар сервери Spike AI барои сохтани ҳисобот коркард шаванд. Агар шумо намехоҳед, ки маълумоти шахсии махфии шумо барои хусусиятҳои самаранокӣ коркард шавад, онро дар номи вазифаҳо ё ҳадафҳо ворид накунед.

        Тарзи истифодаи маълумот: барои тасдиқи ҳувият, ҳамоҳангсозии ҳисоб, пешниҳоди воситаҳои тамаркуз, нақшаи ёдоварҳо, нишон додани пешрафт, шахсигардонии таҳлилҳои самаранокӣ, муҳофизат аз суиистеъмол, ислоҳи мушкилот ва риояи ӯҳдадориҳои ҳуқуқӣ. Spike AI маълумоти шахсии шуморо намефурӯшад.

        Нест кардани маълумот: шумо метавонед аз система баромадед ё нест кардани доимии ҳисобро аз Профил дархост кунед. Нест кардани ҳисоб ҳисоби тасдиқшаваи шумо ва маълумоти ҳамоҳангшудаи барномаро нест мекунад, ба истиснои нигоҳдории маҳдуде, ки барои бехатарӣ, пешгирии фиреб, ҳалли баҳсҳо ё мувофиқати қонунӣ зарур аст.

        Интихоби шумо: шумо метавонед тафсилоти профилро таҳрир кунед, афзалиятҳои забон ва намудро тағйир диҳед, фаъолияти зиндаро хомӯш кунед, иҷозатҳои дастгоҳро дар Танзимот бекор кунед, истифодаи режимҳои муайяни тамаркузро қатъ кунед ё ҳисоби худро нест кунед.

        Тамос: барои саволҳои марбут ба махфият ё нест кардани ҳисоб ба хадамоти дастгирии Spike AI тавассути канали дастгирии дар барнома ё саҳифаи App Store зикршуда муроҷиат кунед.
        """,
        "terms_body": """
        Навсозии охирин: 25 маи 2026

        Ин Шартҳои истифода истифодаи шумо аз Spike AI-ро танзим мекунанд, аз ҷумла вазифаҳо, ёдоварҳо, режимҳои тамаркуз, пешниҳодҳо ва экранҳои блоки вақти экран, тафтиши ҳаракат дар режими «Арақ», пайгирии пешрафт ва ҳисоботҳои зеҳни сунъӣ.

        Ҳуқуқ ва ҳисоб: шумо барои ҳисоби сохташуда ва нигоҳ доштани дастрасии бехатар ба почтаи электронӣ ва дастгоҳи худ масъулед. Ҳангоми дархости тафсилоти профил дар барнома маълумоти дақиқ истифода баред.

        Мақсади самаранокӣ: Spike AI барои дастгирии самаранокии шахсӣ ва истифодаи мақсадноки дастгоҳ сохта шудааст. Ин хадамоти тиббӣ, саломатии равонӣ, ҳолати фавқулодда, бехатарӣ, назорати волидон, мониторинги кор ё идоракунии дастгоҳ нест. Дар ҳолатҳое, ки нокомии ёдовар, блок, пешниҳод, тафтиши камера, огоҳинома, дархости шабака ё иҷозати Apple метавонад зарар расонад, ба Spike AI такя накунед.

        Масъулиятҳои шумо: танзимоти тамаркузеро интихоб кунед, ки ба вазъияти шумо мувофиқ аст; пеш аз фаъолсозии режим интихоби барномаро тафтиш кунед; вақте ки режимҳо ба ниёзҳои шумо мувофиқ нестанд, онҳоро хомӯш кунед; қонунгузории амалкунанда ва шартҳои платформаи Apple-ро риоя кунед; ва маълумоти махфиро ба вазифаҳо ё ҳадафҳо ворид накунед, агар шумо аз истифодаи он дар барнома ноқулай бошед.

        Истифодаи мақбул: Spike AI-ро суиистеъмол накунед, ба кори дастгоҳ ё ҳисоби шахси дигар дахолат накунед, кӯшиш накунед, ки аз ҳифз ё маҳдудиятҳои платформа гузаред, қисмҳои ҳифзшудаи хизматро муҳандисии баръакс накунед, серверро зиёд бор накунед ва барномаро барои фаъолияти ғайриқонунӣ, таҳқиромез, фиребкорона ё зараровар истифода набаред.

        Иҷозатҳо ва дастрасӣ: барои баъзе хусусиятҳо иҷозатҳои iOS аз қабили вақти экран, огоҳиномаҳо, камера, фаъолиятҳои зинда ва дастрасии шабака лозим аст. Apple, танзимоти дастгоҳ, рафтори системаи амалиётӣ, пайвастшавӣ ва дастрасии сервер метавонанд ба кори дурусти хусусиятҳо таъсир расонанд.

        Мӯҳтавои ЗС: ҳисоботҳои пешрафт метавонанд тавассути системаҳои автоматикӣ сохта шаванд. Онҳо танҳо барои худтаҳлилӣ ва роҳнамоии самаранокӣ мебошанд. Пеш аз такя кардан ба онҳо бо ақидаи худ баҳо диҳед.

        Нест кардани ҳисоб ва қатъи дастрасӣ: шумо метавонед нест кардани ҳисобро аз Профил дархост кунед. Spike AI метавонад дастрасиро боздорад ё қатъ кунад, агар қонун, қоидаҳои платформа, нигаронии бехатарӣ ё суиистеъмоли ҷиддӣ талаб кунад.

        Тағйирот: Spike AI метавонад ин Шартҳоро ҳамзамон бо рушди барнома навсозӣ кунад. Идомаи истифода пас аз навсозӣ маънои қабули Шартҳои навсозишударо дорад.

        Тамос: барои саволҳо дар бораи ин Шартҳо ба хадамоти дастгирии Spike AI тавассути канали дастгирии дар барнома ё саҳифаи App Store зикршуда муроҷиат кунед.
        """,

        // Focus Mode
        "focus_title": "Тамаркуз", "select_mode": "Интихоби режим",
        "chill": "Осоишта", "focus": "Тамаркуз", "lock_in": "Қулф", "sweat": "Варзишгар",
        "gentle_nudges": "Ёдоварҳои мулоим", "confirm_intent": "Тасдиқи ният",
        "no_bypass": "Бидуни гузариш", "move_to_unlock": "Барои кушодан ҳаракат кунед",
        "activate_focus": "Фаъолсозии режими тамаркуз",
        "deactivate_focus": "Хомӯшсозии режими тамаркуз",
        "mode_active": "Режим фаъол аст",
        "reminders_scheduled": "Ёдоварҳо нақша шудаанд",
        "apps_prompt_active": "барнома — пурсиши «Шумо боварӣ доред?» фаъол аст",
        "apps_blocked": "барнома блок шуд",
        "temp_access_active": "Дастрасии муваққатӣ фаъол аст",
        "apps_require_movement": "барнома барои кушодан ҳаракат лозим аст",
        "notifications_label": "Огоҳиномаҳо",
        "notifications_enabled": "Огоҳиномаҳо фаъоланд",
        "notifications_denied": "Огоҳиномаҳо рад шуданд",
        "enable_notif_settings": "Огоҳиномаҳоро дар Танзимот фаъол кунед.",
        "allow_notif_desc": "Барои фиристодани ёдоварҳои тамаркуз ба Spike AI иҷозати огоҳинома диҳед.",
        "enable_notifications": "Фаъолсозии огоҳиномаҳо",
        "screen_time_access": "Дастрасӣ ба вақти экран",
        "screen_time_authorized": "Вақти экран иҷозат дода шуд",
        "allow_screen_time": "Иҷозат ба вақти экран",
        "tap_to_allow": "Барои иҷозат додан ба вақти экран тугмаи поёнро пахш кунед.",
        "open_settings_manual": "Ё барои фаъолсозии дастӣ Танзимотро кушоед",
        "open_settings": "Кушодани Танзимот",
        "app_selection": "Интихоби барнома",
        "selections": "интихоб",
        "choose_apps_confirm": "Барномаҳоеро интихоб кунед, ки пеш аз кушодан тасдиқ лозим аст.",
        "choose_apps_block": "Барномаҳоеро барои блок кардан интихоб кунед.",
        "choose_apps_movement": "Барномаҳоеро интихоб кунед, ки бо ҳаракат кушода мешаванд.",
        "change_selection": "Тағйири интихоб",
        "select_apps": "Интихоби барномаҳо",
        "movement_unlock": "Кушодан бо ҳаракат",
        "movement_desc": "Шиноварзӣ ва бархостан бо ёрии шиносоии бадани ЗС пайгирӣ мешаванд. Ҳар такрори тасдиқшуда 1 дақиқа дастрасӣ ба барномаҳои интихобшуда илова мекунад.",
        "access_available": "Дастрасӣ барои %@ мавҷуд аст",
        "open_camera": "Кушодани тафтиши камера",
        "lock_in_mode": "Режими қулф",
        "lock_in_warning": "Барномаҳо экрани сурхро бидуни гузариш нишон медиҳанд. Шумо бояд барои хомӯш кардани режими қулф ба ин ҷо баргардед.",
        "sweat_mode": "Режими «Варзишгар»",
        "do_exercises": "Барои гирифтани вақт шиноварзӣ ё бархостан кунед",
        "add_minutes": "Илова кардани %d дақиқа",
        "keep_in_view": "Китфҳо, дастҳо ё тани худро дар кадр нигоҳ доред",
        "camera_required": "Барои тафтиши ҳаракат дастрасии камера лозим аст.",
        "camera_disabled": "Дастрасии камера хомӯш аст. Барои истифодаи режими «Арақ» онро дар Танзимот фаъол кунед.",
        "camera_unavailable": "Дастрасии камера мавҷуд нест.",
        "starting_camera": "Оғози камера...",
        "camera_active": "Камера фаъол аст",
        "allow_camera": "Иҷозати дастрасӣ ба камера",
        "focus_mode_title": "Режими тамаркуз",
        "focus_mode_desc": "Одатҳои рақамии худро бо режимҳои касбии тамаркузӣ идора кунед.",
        "about_permissions": "Дар бораи иҷозатҳо",
        "permissions_desc": "Режими «Осоишта» иҷозати огоҳиномаро талаб мекунад. Режимҳои «Тамаркуз», «Қулф» ва «Арақ» иҷозати вақти экранро талаб мекунанд. Режими «Арақ» инчунин камераро барои тафтиши ҳаракат истифода мебарад.",
        "get_started": "Оғоз кардан", "skip": "Гузаштан",
        "unlocked_for": "Барои %@ кушода шуд",

        // Chill mode descriptions
        "chill_desc": "Ёдоварҳои рӯзона тавассути огоҳиномаҳо. Барномаҳо назорат намешаванд — танҳо ёдоварҳои мулоим барои мақсаднок будан.",
        "focus_desc": "Вақте ки шумо барномаи интихобшударо мекушоед, Spike AI мепурсад: «Шумо боварӣ доред?» Шумо метавонед онро чун одат кушоед ё ба вазифаҳо баргардед. Барномаҳо блок намешаванд.",
        "lock_in_desc": "Барномаҳои интихобшуда ҳангоми фаъол будани режими қулф блок мешаванд. Шумо метавонед режимро аз дохили Spike AI хомӯш кунед.",
        "sweat_desc": "Барномаҳои интихобшуда то анҷоми шиноварзӣ ё бархостани тафтишшудаи камера блок мемонанд. Ҳар такрори тасдиқшуда 1 дақиқаро мекушояд.",

        // Motivational (deactivation)
        "giving_up_title": "Шумо пешрафт доред — нагиред",
        "giving_up_msg": "Шумо ҳанӯз ҳадафҳои иҷронашуда барои имрӯз доред. Ҳар вазифаи анҷомшуда ниру месозад. Содиқ бимонед — худи ояндаи шумо сипосгузор мешавад.",
        "giving_up_continue": "Дар тамаркуз монед",
        "giving_up_stop": "Бо ҳар ҳол хомӯш кунед",

        // Auth
        "spike_ai": "Spike AI",
        "productivity_system": "Системаи шахсии самаранокии шумо",
        "start_setup": "Оғози танзим",
        "make_phone_work": "Телефони худро барои\nҳадафҳоятон кор кунед.",
        "onboarding_welcome_desc": "Варақгардонии бемаъниро кам кунед, вақти тамаркузро ҳифз кунед ва вазифаҳои воқеиро ба пешрафти намоён табдил диҳед.",
        "scrolling_adds_up": "Варақгардонӣ хурд менамояд,\nаммо ҷамъ мешавад.",
        "per_day": "дар рӯз",
        "per_month": "дар моҳ",
        "per_year": "дар сол",
        "thirty_days": "30 рӯз",
        "lost_to_checking": "ба тафтиши худкор сарф мешавад",
        "scrolling_cost_desc": "Spike AI ба шумо кӯмак мекунад, ки ин лаҳзаҳоро пеш аз он ки тамоми бегоҳро ишғол кунанд, эҳсос кунед.",
        "did_you_know": "Оё шумо медонед?",
        "did_you_know_subtitle": "Одам дар як рӯз дар миёна 7 соат дар телефон вақт мегузаронад. Ин",
        "hours_per_day": "соат дар рӯз",
        "days_per_month": "рӯз дар моҳ",
        "days_per_year": "рӯз дар сол",
        "years_of_life": "сол аз умри шумо",
        "screen_time_reality": "Ва баъзеҳо боз ҳам бештар вақт сарф мекунанд.",
        "dont_worry_title": "Ташвиш накашед",
        "spike_has_your_back": "Spike AI шуморо дастгирӣ мекунад",
        "solution_desc": "Мо ба шумо кӯмак мекунем, ки самаранокиро ба ҳадди аксар расонед, ба ҳадафҳо наздик шавед ва одатҳое созед, ки шуморо ба беҳтарин версияи худ табдил медиҳанд.",
        "screen_time_access_title": "Дастрасӣ ба вақти экран",
        "grant_access": "Додани дастрасӣ",
        "which_apps": "Барномаҳои\nҳалокунандаи шуморо интихоб кунед",
        "choose_apps_protect": "Барномаҳоеро, ки вақти шуморо талаф мекунанд, интихоб кунед. Мо онҳоро ҳангоми режимҳои тамаркуз блок мекунем.",
        "apple_screen_time_required": "Apple пеш аз он ки Spike AI рӯйхати барномаҳоро нишон диҳад, дастрасии вақти экранро талаб мекунад.",
        "save_apps": "Сабт кардан ва идома додан",
        "change_selected_apps": "Тағйири барномаҳои интихобшуда",
        "your_modes_target": "Режимҳои шумо акнун\nҳадафи муайян доранд.",
        "app_selections_will_be_used": "%d интихоби барнома ҳангоми оғози режими ҳифз истифода мешавад.",
        "select_apps_after_login": "Пас аз воридшавӣ барномаҳоро як бор интихоб кунед, ҳамаи режимҳои ҳифз ин рӯйхатро истифода мебаранд.",
        "focus_mode_marketing_detail": "Таваққуфи кӯтоҳ пеш аз кушодани барномаҳои ҳалокунанда.",
        "lock_in_marketing_detail": "Ҳудудҳои қавитар вақте ки кори амиқ лозим аст.",
        "sweat_marketing_detail": "Аввал ҳаракат кунед, сипас вақти дастрасӣ гиред.",
        "replace_scroll": "Ба ҷои варақгардонӣ\nнатиҷаи воқеӣ гиред.",
        "habit_desc": "Амалҳои муфидро ба энергия табдил диҳед: хонаро тоза кунед, вазифаро супоред, қадам занед, кашиш кунед ё як вазифаро тамом кунед.",
        "see_behavior_changing": "Бубинед, ки рафтори шумо\nтағйир меёбад.",
        "progress_desc": "Вақти тамаркуз, иҷрои вазифаҳо ва силсилаҳоро пайгирӣ кунед, то пешрафт аён бошад.",
        "ready_change_life": "Барои тағйири\nҳаёти худ тайёред?",
        "ready_change_desc": "Барои сабти интихобҳо ва оғози сафари худ ҳисоб созед.",
        "ready_protected_day": "Барои аввалин рӯзи\nҳифзшуда тайёред?",
        "create_account_desc": "Барои сабти интихоби барнома, режимҳои тамаркуз, вазифаҳо ва пешрафт ҳисоб созед.",
        "benefit_no_distraction": "Барномаҳои ҳалокунанда дигар шуморо безобита намекунанд",
        "benefit_discover_modes": "4 навъи гуногуни режимҳои тамаркузро кашф кунед",
        "benefit_track_progress": "Пешрафтро пайгирӣ кунед ва ба ҳадафҳоятон наздик шавед",
        "benefit_apps_saved": "Барномаҳои ҳалокунандаи шумо барои режимҳо сабт мешаванд",
        "benefit_start_modes": "Режими Focus, Lock-in ё Варзишгар-ро оғоз кунед",
        "benefit_progress_synced": "Пешрафти шумо ҳамоҳанг сабт мешавад",
        "create_account": "Сохтани ҳисоб",
        "protect_focus": "Ҳифзи тамаркуз",
        "block_feeds": "Блоки лентаҳо",
        "finish_tasks": "Анҷоми вазифаҳо",
        "energy_plus_three": "+3 Энергия",
        "selected_count": "%d интихоб шуд",
        "no_apps_selected": "Ҳанӯз барнома интихоб нашудааст",
        "saved_for_modes": "Барои режимҳои ҳифз сабт шуд",
        "select_apps_to_control": "Барномаҳоеро, ки мехоҳед назорат кунед, интихоб кунед",
        "clean_room": "Тоза кардани хона",
        "snap_proof": "Пас аз тамом кардан акс гиред",
        "ai_verifies_task": "ЗС вазифаро тафтиш мекунад",
        "energy_earned": "+3 Энергия гирифта шуд",
        "on_track": "Дар нақша",
        "energy": "Энергия",
        "tasks_completed": "Вазифаҳо иҷро шуданд",
        "focus_protected": "Тамаркуз ҳифз шуд",
        "scrolling_avoided": "Варақгардонӣ пешгирӣ шуд",
        "continue_apple": "Идома бо Apple",
        "continue_google": "Идома бо Google",
        "continue_email": "Идома бо почтаи электронӣ",
        "enter_email": "Почтаи электронии худро ворид кунед",
        "send_sign_in_link": "Мо ба шумо истиноди воридшавӣ мефиристем",
        "check_email": "Почтаи электронии худро тафтиш кунед",
        "sent_link_to": "Мо истиноди воридшавиро фиристодем ба",
        "tap_link": "Барои воридшавии худкор истинодро пахш кунед.",
        "open_mail": "Кушодани барномаи почта",
        "open_with": "Кушодан бо",
        "didnt_get_email": "Мактуб нагирифтед?",
        "resend": "Дубора фиристодан",
        "resend_in": "Дубора фиристодан пас аз %ds",
        "new_link_sent": "Истиноди нав фиристода шуд!",
        "valid_email": "Суроғаи дурусти почтаи электрониро ворид кунед.",
        "by_continuing": "Бо идома додан шумо бо",
        "and_word": "ва",

        // Screen Time Onboarding
        "screen_time_title": "Вақти экран",
        "screen_time_permission_desc": "Spike AI барои режимҳои «Тамаркуз», «Қулф» ва «Арақ» иҷозати вақти экранро лозим дорад. Ин имкон медиҳад, ки пешниҳодҳо ва блокҳо барои барномаҳои интихобкардаи шумо нишон дода шаванд.",
        "screen_time_denied": "Иҷозат рад шуд. Шумо метавонед онро дар Танзимот фаъол кунед.",
        "ask_before_opening": "Пеш аз кушодан пурсидан",
        "block_apps_completely": "Барномаҳоро пурра блок кардан",
        "stay_accountable": "Масъулиятнок бимонед",
        "stay_accountable_desc": "Пешрафтро пайгирӣ кунед ва одатҳои тамаркузи худро намоён нигоҳ доред.",
        "skip_for_now": "Ҳоло гузаштан",

        // Live Activity
        "daily_goals_title": "Ҳадафҳои рӯзона",
        "of_done": "аз %d иҷро шуд",
        "more_to_go": "+%d боқимонда",

        // Chill morning
        "good_morning": "Субҳ бахайр! Имрӯз мақсаднок бошед. Вазифаҳои худро бубинед ва тамаркуз кунед.",

        // General
        "error": "Хатогӣ", "ok": "Хуб", "yes": "Ҳа", "no": "Не",

        // Switch to Chill / Notifications / Goals Required
        "switch_to_chill_title": "Ба режими Осоишта гузарем?",
        "stay_focused_btn": "Дар тамаркуз мондан",
        "switch_anyway_btn": "Бо ҳар ҳол гузаштан",
        "switch_to_chill_msg": "Шумо ҳанӯз ҳадафҳои иҷронашуда доред. Гузариш ба режими Осоишта блоки барномаҳоро мебардорад, ки хатари иҷро накардани ҳадафҳоро имрӯз зиёд мекунад.",
        "task_notification": "Огоҳиномаи вазифа",
        "missed_alarm": "Сигнали гузаронидашуда",
        "quote_of_day": "Иқтибоси рӯз",
        "new_quotes_daily": "Иқтибосҳои нав ҳар рӯз соати 5:00 меоянд",
        "focus_day_label": "Рӯзи тамаркуз",
        "missed_label": "Гузаронида шуд",
        "access_granted": "Дастрасӣ дода шуд",
        "goal_reminder": "Ёдовари ҳадаф",
        "spike_ai_focus": "Spike AI Тамаркуз",
        "goals_required_title": "Ҳадафҳо лозиманд",
        "goals_required_desc_focus": "Режими Тамаркуз барномаҳои интихобшударо танҳо ҳангоми мавҷудияти ҳадафҳои иҷронашуда блок мекунад. Барои фаъолсозии блоки барномаҳо дар ҷадвали Асосӣ ҳадаф илова кунед.",
        "goals_required_desc_lockin": "Режими Қулф барномаҳои интихобшударо танҳо ҳангоми мавҷудияти ҳадафҳои иҷронашуда блок мекунад. Барои фаъолсозии блоки барномаҳо дар ҷадвали Асосӣ ҳадаф илова кунед.",
        "save": "Сабт кардан",
        "no_goals_reminder_body": "Шумо барои имрӯз ягон ҳадаф нагузоштаед. Лаҳзае вақт ҷудо кунед ва рӯзи худро нақша кунед!",
        "dont_forget": "Фаромӯш накунед",
        "chill_morning_body": "Субҳ бахайр! Имрӯз мақсаднок бошед. Вазифаҳои худро бубинед ва тамаркуз кунед.",
        "every_day": "Ҳар рӯз",
        "weekdays": "Рӯзҳои корӣ",
        "weekends": "Рӯзҳои истироҳат",
        "time_to_focus": "Вақти тамаркуз!",

        // Additional UI strings
        "next_quote_in": "Иқтибоси навбатӣ пас аз %@",
        "enable_notif_chill": "Пеш аз оғози режими «Осоишта» огоҳиномаҳоро фаъол кунед.",
        "enable_screen_time_mode": "Пеш аз оғози ин режим дастрасии вақти экранро фаъол кунед.",
        "select_app_before_mode": "Пеш аз оғози ин режим ақаллан як барнома, категория ё вебсайт интихоб кунед.",
        "mode_not_ready": "Ин режим ҳанӯз барои оғоз тайёр нест.",
        "protection_stopped_no_apps": "Ҳифз қатъ шуд: барномае интихоб нашудааст.",
        "protection_stopped_screen_time": "Ҳифз қатъ шуд: дастрасии вақти экран тағйир ёфт.",
        "max_reminders": "Шумо метавонед то %d ёдовари тамаркуз созед.",
        "front_camera_unavailable": "Камераи пеш дастрас нест.",
        "task_title_empty": "Номи вазифа холӣ буда наметавонад.",
        "goal_title_empty": "Номи ҳадаф холӣ буда наметавонад.",
        "rate_limit_wait": "Лутфан %d сония пеш аз сохтани ҳисоботи нав интизор шавед.",
        "missed_alarm_for": "Шумо сигналро гузаронидед: %@",
        "stay_with_plan": "Ба нақша содиқ бимонед.",
        "motivation_small_wins": "Ғалабаҳои хурд ҷамъ мешаванд.",
        "motivation_next_step": "Қадами навбатиро тамом кунед.",
        "motivation_protect_hour": "Соати пеши худро ҳифз кунед.",
        "motivation_consistency": "Пайдарпаӣ аз шиддат бартар аст.",

        // Milestones
        "milestone_3day_streak": "Силсилаи 3-рӯза",
        "milestone_3day_desc": "Ритми устувор оғоз шуд.",
        "milestone_7day_streak": "Силсилаи 7-рӯза",
        "milestone_7day_desc": "Як ҳафтаи пурраи тамаркуз.",
        "milestone_10h_protected": "10 соат ҳифз шуд",
        "milestone_10h_desc": "Вақт барои чизҳои муҳим ҳифз шуд.",
        "milestone_30_focus": "30 рӯзи тамаркуз",
        "milestone_30_desc": "Пайдарпаии воқеӣ бо арзиш.",

        // Narratives
        "narrative_improved": "Вақти экрани шумо нисбат ба ҳафтаи гузашта беҳтар шуд.",
        "narrative_consistent": "Шумо дар ин ҳафта пайдарпай будед ва тамаркузи худро ҳифз кардед.",
        "narrative_more_days": "Шумо рӯзҳои тамаркузи бештар аз одат тамом кардед.",
        "narrative_building": "Шумо ритмро як рӯзи тамаркузӣ дар як вақт месозед.",

        // Screen time
        "screen_time_trend_pending": "Тамоюли вақти экран ҳамзамон бо афзоиши таърихи истифода пайдо мешавад.",
        "screen_time_improved": "Вақти экран ба %d%% беҳтар шуд",
        "screen_time_higher": "Вақти экран аз одат каме зиёдтар аст",
        "screen_time_steady": "Вақти экран дар ин ҳафта устувор аст",

        // Benchmarks
        "benchmark_pending": "Миёнаи вақти экран ҳамзамон бо сабти таърихи истифода пайдо мешавад. Нуқтаи истиноди ҷаҳонӣ тақрибан 7 соат дар рӯз аст.",
        "benchmark_below": "Миёнаи 7-рӯзаи шумо %@ аст, ки аз миёнаи ҷаҳонии 7 соат пасттар аст. Ин самти қавист.",
        "benchmark_above": "Миёнаи 7-рӯзаи шумо %@ аст, ки аз миёнаи ҷаҳонии 7 соат болотар аст. Кам кардани андак имрӯз метавонад тамоюлро тағйир диҳад.",
        "benchmark_matching": "Миёнаи 7-рӯзаи шумо %@ аст ва бо миёнаи ҷаҳонии 7 соат мувофиқ аст.",

        // Task editing
        "edit_task": "Таҳрири вазифа",
        "task_name_placeholder": "Номи вазифа",
        "task_reminder_default": "Ёдовари вазифа",
        "time_h_m": "%dс %dд",
        "time_m": "%dд",
    ]
}
