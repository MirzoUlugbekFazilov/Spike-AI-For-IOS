//
//  SpokenGoalParser.swift
//  Spike AI
//
//  On-device goal extraction, used when the parse-voice-goals edge function is
//  unreachable. This is a faithful port of the heuristics in
//  supabase/functions/parse-voice-goals/index.ts — the two must agree, because
//  the user cannot tell which one produced their list.
//
//  The rules it implements, in order of importance:
//    1. HARD FILTER  — instructions ("make the priority low"), system requests
//       ("turn on alarm") and filler are ATTRIBUTES, never goals.
//    2. LOCALITY     — an attribute binds to the closest preceding goal, never
//       to all of them.
//    3. COMPRESSION  — titles are a verb plus an object, four words at most.
//    4. DEDUPLICATION — repeated mentions collapse into one goal.
//

import Foundation

enum SpokenGoalParser {

    struct Parsed {
        var title: String
        var priority: TaskPriority
        var dayOffset: Int
        var time: (hour: Int, minute: Int)?
        var notify: Bool
        var alarm: Bool
    }

    static let maxTitleWords = 4
    static let maxGoals = 10

    // ── Vocabulary ───────────────────────────────────────────────────────

    /// Words that only ever describe HOW a goal is configured. A segment built
    /// entirely from these names no activity, so it is an instruction.
    private static let attributeVocabulary: Set<String> = [
        "make", "makes", "making", "sure", "ensure", "please", "this", "that",
        "these", "those", "goal", "goals", "task", "tasks", "one", "it", "its",
        "it's", "is", "are", "was", "were", "has", "have", "had", "with", "plus",
        "and", "also", "for", "the", "a", "an", "be", "being", "should", "must",
        "need", "needs", "set", "sets", "setting", "put", "puts", "add", "adds",
        "turn", "turns", "turning", "switch", "enable", "disable", "activate",
        "on", "off", "to", "too", "of", "my", "me", "i", "high", "higher",
        "highest", "medium", "low", "lower", "urgent", "important", "critical",
        "priority", "priorities", "level", "notification", "notifications",
        "notify", "notified", "remind", "reminds", "reminder", "reminders",
        "alarm", "alarms", "alert", "alerts", "sound", "ring", "ringing",
        "as", "well", "am", "pm", "at", "in", "today", "tomorrow", "tonight",
        "planning", "plan", "going", "gonna", "want", "wanted", "thinking",
        "thought", "night", "morning", "evening", "afternoon", "last", "about",
    ]

    /// Boundaries that genuinely start a new goal. Deliberately not a bare
    /// "and": "a meeting with my professor and my advisor" is one goal.
    private static let boundaryPattern = #"[.;\n]+|\bapart from that\b|\bbesides that\b|\bother than that\b|\band then\b|\bafter that\b|\b(?:and\s+)?lastly\b|\bfinally\b|\bwhat else\b|\balso\b|\band(?:\s+also)?\s+(?:i|i'?m|i am|i'?ll)\b"#

    /// Spoken lead-ins stripped from the front of a title.
    private static let fillerPatterns = [
        #"^(?:and|also|then|lastly|finally|next|so|um+|uh+|okay|ok|well|plus)\b"#,
        #"^(?:today|tomorrow|tonight|this morning|this afternoon|this evening)\b\s*(?:i|i'?m)?\b"#,
        #"^(?:apart from that|besides that|other than that|what else)\b"#,
        // A leading clock time is an attribute, never the start of a title. A
        // preposition, minutes or a meridiem is required, so "10 push ups"
        // keeps its count.
        #"^(?:at\s+\d{1,2}(?:[:.]\d{2})?(?:\s*(?:a\.?m\.?|p\.?m\.?))?|\d{1,2}[:.]\d{2}(?:\s*(?:a\.?m\.?|p\.?m\.?))?|\d{1,2}\s*(?:a\.?m\.?|p\.?m\.?))"#,
        #"^i'?m\s+(?:also\s+)?(?:planning|going|gonna|hoping|trying|supposed)\s+to\b"#,
        #"^i\s+(?:am\s+)?(?:also\s+)?(?:plan|planning|need|want|have|planned)\s+to\b"#,
        #"^i\s+(?:will|would like to|should|must)\b"#,
        #"^(?:am|'m|m|'ll|ll)\s+(?:also\s+)?(?:planning|going|gonna|hoping|trying|supposed)\s+to\b"#,
        #"^(?:am|'m|m)\s+(?:also\s+)?(?:planning|going)\b"#,
        #"^i'?ll\b"#,
        #"^(?:need|want|have|got)\s+to\b"#,
        #"^(?:let me|remind me to)\b"#,
        #"^(?:have|having|do|doing|make|making|get|getting)\s+(?:a|an|the)\b"#,
        #"^(?:a|an|the)\b"#,
    ]

    private static let trailingAttributePatterns = [
        #"\b(?:whenever|if i have time|no rush|sometime|at some point)\b\s*$"#,
        #"\b(?:it'?s\s+)?(?:urgent|important|critical)\b\s*$"#,
        #"\b(?:high|low|medium)\s+priority\b\s*$"#,
    ]

    // ── Scheduling phrases ───────────────────────────────────────────────
    //
    // WHEN something happens is carried by `time` and `dayOffset`, so it must
    // never also sit in the title: "Breakfast at 5:52 AM" should read
    // "Breakfast", with 05:52 on the reminder.
    //
    // These match ANYWHERE, not just at the ends. Anchored patterns were the
    // original bug — "have breakfast at 5:52 am tomorrow" has the time in the
    // middle, so nothing stripped it and the four-word cap then preserved it
    // exactly. Times are only recognised where they are unambiguous, so counts
    // and measurements ("Run 5 km", "Buy 2 tickets") are left alone.

    private static let timePreposition = #"(?:at|by|around|about|from|till|until|before|after)"#

    /// "in the morning", "at night" — qualifies a time, or stands in for one.
    private static let daypart = #"(?:in\s+the\s+(?:morning|afternoon|evening)|at\s+night)"#

    /// Relative days and weekday names — all of this lives in `dayOffset`.
    private static let dayWords =
        #"(?:the\s+day\s+after\s+tomorrow|day\s+after\s+tomorrow|today|tomorrow|tonight|next\s+week|this\s+(?:morning|afternoon|evening)|monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#

    private static let meridiem = #"(?:a\.?m\.?|p\.?m\.?)"#

    /// An hour, spoken as a figure or as a word.
    private static let hourToken =
        #"(?:\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)"#

    private static let numberWords: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
    ]

    /// Minutes, a meridiem or "o'clock" marks a reading as a clock time beyond
    /// doubt, so it needs no preposition to be recognised.
    private static var selfEvidentTime: String {
        [
            #"\b\d{1,2}[:.]\d{2}(?:\s*"# + meridiem + ")?",
            #"\b"# + hourToken + #"\s*"# + meridiem,
            #"\b"# + hourToken + #"\s*o'?\s?clock"#,
            #"\b(?:half|quarter)\s+(?:past|to)\s+"# + hourToken,
            #"\b(?:noon|midday|midnight)\b"#,
        ].joined(separator: "|")
    }

    /// A bare hour is only a time when nothing but scheduling words follow it —
    /// "gym at 6", "breakfast at six tomorrow". Without this guard "Look at 3
    /// options" would lose its object.
    private static var bareHourWithPreposition: String {
        #"\b"# + timePreposition + #"\s+"# + hourToken
            + #"(?=\s*(?:$|[,.;])|\s+(?:"# + daypart + "|" + dayWords + #")\b)"#
    }

    /// Every form `extractTime` can read, and no more: stripping a time the
    /// extractor cannot capture would delete the user's intent instead of
    /// moving it to the reminder.
    private static var timePhrase: String {
        "(?:(?:"
            + #"\b"# + timePreposition + #"\s+(?:"# + selfEvidentTime + ")"
            + "|" + bareHourWithPreposition
            + "|" + selfEvidentTime
            + #")(?:\s+"# + daypart + ")?"
            + "|" + daypart
            + ")"
    }

    private static var dayPhrase: String {
        #"\b(?:(?:on|this|next|by)\s+)?"# + dayWords + #"\b"#
    }

    private static let danglingTail =
        #"\s+(?:with|at|for|to|in|on|of|and|or|by|from|about|the|a|an|my|our|his|her|their|this|that)$"#

    /// Phrases that describe the past or a musing, not an intention.
    private static let notAnIntentionPattern =
        #"\b(?:was thinking|were thinking|had been thinking|last night|yesterday|i thought)\b"#

    // ── Entry point ──────────────────────────────────────────────────────

    static func parse(_ transcript: String) -> [Parsed] {
        var goals: [Parsed] = []
        var seen = Set<String>()

        // Clauses, not sentences. "I'm planning to visit the bank, make the
        // priority low, alarm" is one sentence but three clauses: a goal and
        // two instructions about it.
        for clause in split(transcript).flatMap(clauses(in:)) {
            let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 1 else { continue }

            let attributes = readAttributes(trimmed)

            // HARD FILTER: pure configuration binds to the most recent goal.
            if isInstruction(trimmed) {
                apply(attributes, toIndex: goals.indices.last, in: &goals)
                continue
            }

            // LOCALITY by name: "make the bank low priority" names a goal that
            // already exists, so it configures THAT goal rather than creating a
            // new one — even if another goal was mentioned more recently.
            if let index = goalReferenced(by: trimmed, in: goals) {
                apply(attributes, toIndex: index, in: &goals)
                continue
            }

            // Reflections about the past are not goals.
            if matches(notAnIntentionPattern, trimmed) { continue }

            let title = condenseTitle(trimmed)
            guard title.count > 1, !isInstruction(title) else { continue }

            let key = title.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            goals.append(Parsed(
                title: title,
                priority: attributes.priority,
                dayOffset: dayOffset(in: trimmed),
                time: attributes.time,
                notify: attributes.notify,
                alarm: attributes.alarm
            ))
            if goals.count >= maxGoals { break }
        }

        return goals
    }

    // ── Applying the rules to someone else's output ──────────────────────
    //
    // The edge function follows the same rules, but its deployment can lag the
    // app and the model behind it drifts, so the client enforces them itself
    // rather than trusting what comes back.

    /// Cleans a title produced elsewhere. Returns "" only when nothing
    /// meaningful survives, which the caller should treat as "keep the original".
    static func cleanTitle(_ raw: String) -> String {
        condenseTitle(raw)
    }

    /// Clock time named anywhere in `text`, for recovering one that was written
    /// into a title instead of into the reminder field.
    static func time(in text: String) -> (hour: Int, minute: Int)? {
        extractTime(text)
    }

    /// Relative day named anywhere in `text`. 0 when none is.
    static func relativeDayOffset(in text: String) -> Int {
        dayOffset(in: text)
    }

    /// Splits a segment on commas so an instruction tacked onto the end of a
    /// sentence doesn't bleed into the goal's title.
    private static func clauses(in segment: String) -> [String] {
        segment.components(separatedBy: ",")
    }

    /// Index of the goal a clause refers to by name, if any. A clause qualifies
    /// only when every word it contributes beyond configuration vocabulary
    /// already appears in that goal's title — "make the bank low priority"
    /// contributes just "bank", which "Visit the bank" already contains.
    private static func goalReferenced(by clause: String, in goals: [Parsed]) -> Int? {
        let contentWords = Set(meaningfulWords(clause))
        guard !contentWords.isEmpty, contentWords.count <= 3 else { return nil }

        for (index, goal) in goals.enumerated().reversed() {
            let titleWords = Set(goal.title.lowercased()
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { $0.count > 1 })
            if contentWords.isSubset(of: titleWords) { return index }
        }
        return nil
    }

    private static func meaningfulWords(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted.subtracting(CharacterSet(charactersIn: "'")))
            .filter { $0.count > 1 && !attributeVocabulary.contains($0) }
    }

    // ── Segmentation ─────────────────────────────────────────────────────

    private static func split(_ transcript: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: boundaryPattern, options: .caseInsensitive) else { return [transcript] }

        let range = NSRange(transcript.startIndex..., in: transcript)
        var segments: [String] = []
        var cursor = transcript.startIndex

        regex.enumerateMatches(in: transcript, range: range) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: transcript) else { return }
            segments.append(String(transcript[cursor..<matchRange.lowerBound]))
            cursor = matchRange.upperBound
        }
        segments.append(String(transcript[cursor...]))
        return segments
    }

    // ── Classification ───────────────────────────────────────────────────

    /// True when nothing but configuration vocabulary survives — no activity was
    /// named, so this segment configures a goal rather than being one.
    private static func isInstruction(_ segment: String) -> Bool {
        let words = segment
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted.subtracting(CharacterSet(charactersIn: "'")))
            .filter { $0.count > 1 }
        let leftover = words.filter { !attributeVocabulary.contains($0) }
        return leftover.isEmpty
    }

    // ── Attributes ───────────────────────────────────────────────────────

    private struct Attributes {
        var priority: TaskPriority = .medium
        var sawPriority = false
        var time: (hour: Int, minute: Int)?
        var notify = false
        var alarm = false
    }

    private static func readAttributes(_ segment: String) -> Attributes {
        var attributes = Attributes()

        attributes.time = extractTime(segment)
        attributes.alarm = matches(#"\b(alarm|wake me|ring|don'?t let me sleep)\b"#, segment)

        let priority = extractPriority(segment)
        attributes.priority = priority
        attributes.sawPriority = priority != .medium

        attributes.notify = attributes.alarm
            || attributes.time != nil
            || matches(#"\b(remind|reminder|notify|notification|ping me|let me know)\b"#, segment)

        return attributes
    }

    /// LOCALITY RULE: fold an instruction's settings into exactly one goal —
    /// never across the whole list.
    private static func apply(_ attributes: Attributes, toIndex index: Int?, in goals: inout [Parsed]) {
        guard let index, goals.indices.contains(index) else { return }
        if attributes.sawPriority { goals[index].priority = attributes.priority }
        if let time = attributes.time, goals[index].time == nil { goals[index].time = time }
        if attributes.alarm { goals[index].alarm = true }
        if attributes.notify { goals[index].notify = true }
        if goals[index].alarm { goals[index].notify = true }
    }

    /// Relative day named in free text. 0 when none is, which is also the default.
    private static func dayOffset(in segment: String) -> Int {
        if matches(#"\bday\s+after\s+tomorrow\b"#, segment) { return 2 }
        if matches(#"\btomorrow\b"#, segment) { return 1 }
        return 0
    }

    private static func extractPriority(_ segment: String) -> TaskPriority {
        let highNearPriority =
            matches(#"\bpriorit(?:y|ies)\b[^.]{0,20}?\b(high|urgent|top|max(?:imum)?)\b"#, segment)
            || matches(#"\b(high|urgent|top|max(?:imum)?)\b[^.]{0,20}?\bpriorit(?:y|ies)\b"#, segment)
        let lowNearPriority =
            matches(#"\bpriorit(?:y|ies)\b[^.]{0,20}?\b(low|minor)\b"#, segment)
            || matches(#"\b(low|minor)\b[^.]{0,20}?\bpriorit(?:y|ies)\b"#, segment)

        if highNearPriority { return .high }
        if lowNearPriority { return .low }
        if matches(#"\b(urgent|important|critical|asap)\b"#, segment) { return .high }
        if matches(#"\b(whenever|no rush|if i have time|sometime|not urgent)\b"#, segment) { return .low }
        return .medium
    }

    /// Reads a wall-clock time out of free text.
    ///
    /// Understands exactly the forms `timePhrase` strips out of titles — the two
    /// must stay in step, or a title would lose a time that never reached the
    /// reminder. Ordered most specific first so "5:52 am" is not misread as
    /// "52 am".
    private static func extractTime(_ segment: String) -> (hour: Int, minute: Int)? {
        guard let reading = readClock(segment) else { return nil }
        return applyDaypart(reading, in: segment)
    }

    private static func readClock(_ segment: String) -> (hour: Int, minute: Int)? {
        if matches(#"\b(?:noon|midday)\b"#, segment) { return (12, 0) }
        if matches(#"\bmidnight\b"#, segment) { return (0, 0) }

        // "half past eight", "quarter to nine"
        if let groups = capture(#"\b(half|quarter)\s+(past|to)\s+"# + "(" + hourToken + #")\b"#, segment),
           let base = hourValue(groups[3]) {
            let minute = groups[1].lowercased() == "half" ? 30 : 15
            if groups[2].lowercased() == "to" {
                let hour = (base + 23) % 24        // the hour before, wrapping at midnight
                return normalize(hour: hour, minute: 60 - minute, segment: segment)
            }
            return normalize(hour: base, minute: minute, segment: segment)
        }

        // "5:52 am", "17.30"
        if let groups = capture(#"\b(\d{1,2})[:.](\d{2})\s*("# + meridiem + #")?"#, segment),
           let hour = Int(groups[1]), let minute = Int(groups[2]) {
            return normalize(hour: hour, minute: minute, meridiem: groups[3], segment: segment)
        }

        // "6pm", "eight am"
        if let groups = capture("\\b(" + hourToken + #")\s*("# + meridiem + ")", segment),
           let hour = hourValue(groups[1]) {
            return normalize(hour: hour, minute: 0, meridiem: groups[2], segment: segment)
        }

        // "7 o'clock"
        if let groups = capture("\\b(" + hourToken + #")\s*o'?\s?clock"#, segment),
           let hour = hourValue(groups[1]) {
            return normalize(hour: hour, minute: 0, segment: segment)
        }

        // "at 6", "by six" — only where a preposition and what follows make it
        // unambiguous, matching the strip rule exactly.
        if let groups = capture("\\b" + timePreposition + "\\s+(" + hourToken + ")"
            + #"(?=\s*(?:$|[,.;])|\s+(?:"# + daypart + "|" + dayWords + #")\b)"#, segment),
           let hour = hourValue(groups[1]) {
            return normalize(hour: hour, minute: 0, segment: segment)
        }

        return nil
    }

    private static func hourValue(_ token: String) -> Int? {
        if let figure = Int(token) { return figure }
        return numberWords[token.lowercased()]
    }

    private static func normalize(
        hour: Int, minute: Int, meridiem: String = "", segment: String
    ) -> (hour: Int, minute: Int)? {
        var hour = hour
        let suffix = meridiem.lowercased().replacingOccurrences(of: ".", with: "")
        if suffix.hasPrefix("p"), hour < 12 { hour += 12 }
        if suffix.hasPrefix("a"), hour == 12 { hour = 0 }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    /// "six in the evening" is 18:00, not 06:00. Only nudges a morning hour that
    /// carried no explicit am/pm.
    private static func applyDaypart(
        _ reading: (hour: Int, minute: Int), in segment: String
    ) -> (hour: Int, minute: Int) {
        guard reading.hour >= 1, reading.hour <= 11,
              !matches(#"\b"# + meridiem, segment),
              matches(#"\b(?:in\s+the\s+(?:afternoon|evening)|at\s+night|tonight)\b"#, segment)
        else { return reading }
        return (reading.hour + 12, reading.minute)
    }

    // ── Title shaping ────────────────────────────────────────────────────

    private static func condenseTitle(_ raw: String) -> String {
        var text = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"^["'“”]+|["'“”.,!]+$"#, with: "", options: .regularExpression)

        text = stripRepeatedly(fillerPatterns, from: text, anchored: true)
        text = stripRepeatedly(trailingAttributePatterns, from: text, anchored: true)

        // Before the word cap, not after: cutting "breakfast at 5:52 am
        // tomorrow" to four words first is what froze the time into the title.
        text = stripSchedulingPhrases(text)

        let words = text.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return "" }

        var title = words.prefix(maxTitleWords).joined(separator: " ")
        title = title.replacingOccurrences(
            of: #"[\s,;:.!?—–-]+$"#, with: "", options: .regularExpression)

        var previous = ""
        while previous != title {
            previous = title
            title = title
                .replacingOccurrences(of: danglingTail, with: "", options: [.regularExpression, .caseInsensitive])
                .trimmingCharacters(in: .whitespaces)
            if title.isEmpty { return "" }
        }

        return title.prefix(1).uppercased() + title.dropFirst()
    }

    /// Removes clock times and day references from a title, wherever they sit.
    ///
    /// Reverts if the result names no activity: "Noon" or "Tomorrow" as an
    /// entire title is odd, but handing back an empty string is worse — `parse`
    /// rejects instruction-only titles anyway, and a title the user can edit
    /// beats a goal that silently vanished.
    private static func stripSchedulingPhrases(_ text: String) -> String {
        let stripped = tidySeams(
            text
                .replacingOccurrences(of: timePhrase, with: " ",
                                      options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: dayPhrase, with: " ",
                                      options: [.regularExpression, .caseInsensitive])
        )
        guard !stripped.isEmpty, !isInstruction(stripped) else { return text }
        return stripped
    }

    /// Closes the gap left by a phrase removed from the middle, and drops the
    /// connective that was holding it there: "Meeting with professor at 5 pm on
    /// Monday" → "Meeting with professor".
    private static func tidySeams(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+([,.;:!?])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"^[\s,.;:!?-]+|[\s,.;:!?-]+$"#, with: "",
                                  options: .regularExpression)
            .replacingOccurrences(of: danglingTail, with: "",
                                  options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
    }

    private static func stripRepeatedly(_ patterns: [String], from input: String, anchored: Bool) -> String {
        var text = input
        var changed = true
        while changed {
            changed = false
            for pattern in patterns {
                let stripped = text
                    .replacingOccurrences(of: pattern, with: "",
                                          options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespaces)
                if stripped != text, !stripped.isEmpty {
                    text = stripped
                    changed = true
                }
            }
        }
        return text
    }

    // ── Regex helpers ────────────────────────────────────────────────────

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Returns capture groups (index 0 = whole match) with missing groups as "".
    private static func capture(_ pattern: String, _ text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }

        return (0..<match.numberOfRanges).map { index in
            guard let range = Range(match.range(at: index), in: text) else { return "" }
            return String(text[range])
        }
    }
}
