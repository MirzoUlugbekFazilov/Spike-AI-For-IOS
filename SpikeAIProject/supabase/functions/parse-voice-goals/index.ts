import { createClient } from "npm:@supabase/supabase-js@2";

// ─────────────────────────────────────────────────────────────────────────────
// parse-voice-goals
//
// Turns a spoken transcript ("today I'm planning to visit my professor and also
// call my relatives and lastly use the gym") into short, structured goals:
//
//   Visit professor  ·  Call relatives  ·  Gym session
//
// Design notes:
//  - Titles are capped at 4 words. Spoken language is padded with filler
//    ("I'm planning to", "and also", "what else like") and a raw transcript
//    makes a terrible task title.
//  - The model never does calendar arithmetic. It returns a relative
//    `day_offset` plus an optional wall-clock `time`, and the client builds the
//    real Date in the user's own timezone. Small instruct models are unreliable
//    at date math but fine at "today or tomorrow".
// ─────────────────────────────────────────────────────────────────────────────

type ParseVoiceGoalsRequest = {
  transcript: string;
  /** User's local date, "yyyy-MM-dd". */
  today: string;
  /** User's local time, "HH:mm" (24h). */
  now_time: string;
  /** App language code, e.g. "en", "ru", "uz". */
  language?: string;
};

type ParsedGoal = {
  title: string;
  priority: "low" | "medium" | "high";
  /** 0 = today, 1 = tomorrow, … */
  day_offset: number;
  /** "HH:mm" in 24h local time, or null when the user gave no time. */
  time: string | null;
  /** User wants to be reminded. Implied by naming a time. */
  notify: boolean;
  /** User wants a ringing alarm rather than a quiet notification. */
  alarm: boolean;
};

type ParseVoiceGoalsResult = {
  goals: ParsedGoal[];
  /** One short sentence describing the batch, shown above the review list. */
  summary: string;
  /** True when the model failed and goals came from the heuristic splitter. */
  fallback: boolean;
  /** Why the model path was abandoned. Empty when the model succeeded. */
  fallback_reason?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_GOALS = 10;
const MAX_TITLE_WORDS = 4;
const MAX_TITLE_LENGTH = 48;
const MAX_SUMMARY_LENGTH = 140;
const MAX_TRANSCRIPT_LENGTH = 2000;
const MAX_DAY_OFFSET = 365;
/** Per-attempt ceiling. */
const MODEL_TIMEOUT_MS = 12000;
/** Ceiling across all attempts — three 20s stalls used to leave the user
 *  staring at a spinner for a minute before failing. Past this we stop trying
 *  and answer from the heuristic parser instead. */
const MODEL_BUDGET_MS = 26000;

/**
 * Tried in order, all verified as live on the HF router. Qwen 2.5 72B leads
 * because this app ships in 23 languages and it is the strongest multilingual
 * option here at strict JSON; the smaller model is a cheap last resort.
 *
 * Note: do NOT reintroduce google/gemma-2-2b-it — the router stopped serving it.
 */
const MODELS = [
  // Llama 3.3 70B leads on provider coverage (6 live providers vs 2), so
  // `:cheapest` almost always finds a healthy route. Strong multilingual
  // instruction following, which matters across 23 app languages.
  "meta-llama/Llama-3.3-70B-Instruct:cheapest",
  "Qwen/Qwen2.5-72B-Instruct:cheapest",
  "Qwen/Qwen2.5-7B-Instruct:cheapest",
];

/** Spoken lead-ins that must never survive into a task title. */
const FILLER_PATTERNS = [
  /^(?:and|also|then|lastly|finally|next|so|um+|uh+|okay|ok|well|plus)\b/i,
  /^(?:today|tomorrow|tonight|this morning|this afternoon|this evening)\b\s*(?:i|i'?m)?\b/i,
  /^(?:apart from that|besides that|other than that|what else)\b/i,
  // A leading clock time is an attribute, never the start of a title:
  // "Today at 6 PM I'm planning to hit the gym" -> "hit the gym". A preposition,
  // minutes or a meridiem is required, so "10 push ups" keeps its count.
  /^(?:at\s+\d{1,2}(?:[:.]\d{2})?(?:\s*(?:a\.?m\.?|p\.?m\.?))?|\d{1,2}[:.]\d{2}(?:\s*(?:a\.?m\.?|p\.?m\.?))?|\d{1,2}\s*(?:a\.?m\.?|p\.?m\.?))/i,
  /^i'?m\s+(?:also\s+)?(?:planning|going|gonna|hoping|trying|supposed)\s+to\b/i,
  /^i\s+(?:am\s+)?(?:also\s+)?(?:plan|planning|need|want|have|plann?ed)\s+to\b/i,
  /^i\s+(?:will|would like to|should|must)\b/i,
  // Left behind once an earlier pattern or a sentence split eats the "I":
  // "Today I am planning to …" -> "am planning to …", "and also I'm …" -> "m …".
  /^(?:am|'m|m|'ll|ll)\s+(?:also\s+)?(?:planning|going|gonna|hoping|trying|supposed)\s+to\b/i,
  /^(?:am|'m|m)\s+(?:also\s+)?(?:planning|going)\b/i,
  /^i'?ll\b/i,
  /^(?:need|want|have|got)\s+to\b/i,
  /^(?:let me|remind me to)\b/i,
  // "have a meeting with X" -> "meeting with X": the light verb carries no
  // meaning once the object is there.
  /^(?:have|having|do|doing|make|making|get|getting)\s+(?:a|an|the)\b/i,
  // Leading articles left dangling after the verb phrase is removed.
  /^(?:a|an|the)\b/i,
];

/** A title must not end mid-phrase after the word cap chops it. */
const DANGLING_TAIL =
  /\s+(?:with|at|for|to|in|on|of|and|or|by|from|about|the|a|an|my|our|his|her|their|this|that)$/i;

/** Priority words are metadata, never part of the title. */
const TRAILING_ATTRIBUTE_PATTERNS = [
  /\b(?:whenever|if i have time|no rush|sometime|at some point)\b\s*$/i,
  /\b(?:it'?s\s+)?(?:urgent|important|critical)\b\s*$/i,
  /\b(?:high|low|medium)\s+priority\b\s*$/i,
];

// ── Scheduling phrases ───────────────────────────────────────────────────────
//
// WHEN something happens is carried by `notification_time` and `day_offset`, so
// it must never also sit in the title: "Breakfast at 5:52 AM" should read
// "Breakfast", with 05:52 on the reminder.
//
// These match ANYWHERE in the string, not just at the ends. Anchored patterns
// were the original bug — "have breakfast at 5:52 am tomorrow" has the time in
// the middle, so nothing stripped it and the four-word cap then preserved it
// exactly. Times are only recognised where they are unambiguous, so counts and
// measurements ("Run 5 km", "Buy 2 tickets") are left alone.

const TIME_PREPOSITION = String.raw`(?:at|by|around|about|from|till|until|before|after)`;

/** "in the morning", "at night" — qualifies a time, or stands in for one. */
const DAYPART = String.raw`(?:in\s+the\s+(?:morning|afternoon|evening)|at\s+night)`;

/** Relative days and weekday names — all of this lives in `day_offset`. */
const DAY_WORDS =
  String.raw`(?:the\s+day\s+after\s+tomorrow|day\s+after\s+tomorrow|today|tomorrow|tonight|next\s+week|this\s+(?:morning|afternoon|evening)|monday|tuesday|wednesday|thursday|friday|saturday|sunday)`;

const MERIDIEM = String.raw`(?:a\.?m\.?|p\.?m\.?)`;

/** An hour, spoken as a figure or as a word. */
const HOUR_TOKEN =
  String.raw`(?:\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)`;

const NUMBER_WORDS: Record<string, number> = {
  one: 1, two: 2, three: 3, four: 4, five: 5, six: 6,
  seven: 7, eight: 8, nine: 9, ten: 10, eleven: 11, twelve: 12,
};

/**
 * Minutes, a meridiem or "o'clock" marks a reading as a clock time beyond
 * doubt, so it needs no preposition to be recognised.
 */
const SELF_EVIDENT_TIME = [
  String.raw`\b\d{1,2}[:.]\d{2}(?:\s*${MERIDIEM})?`,
  String.raw`\b${HOUR_TOKEN}\s*${MERIDIEM}`,
  String.raw`\b${HOUR_TOKEN}\s*o'?\s?clock`,
  String.raw`\b(?:half|quarter)\s+(?:past|to)\s+${HOUR_TOKEN}`,
  String.raw`\b(?:noon|midday|midnight)\b`,
].join("|");

/**
 * A bare hour is only a time when nothing but scheduling words follow it —
 * "gym at 6", "breakfast at six tomorrow". Without this guard "Look at 3
 * options" would lose its object.
 */
const BARE_HOUR_WITH_PREPOSITION =
  String.raw`\b${TIME_PREPOSITION}\s+${HOUR_TOKEN}(?=\s*(?:$|[,.;])|\s+(?:${DAYPART}|${DAY_WORDS})\b)`;

/**
 * Every form `extractSpokenTime` can read, and no more: stripping a time the
 * extractor cannot capture would delete the user's intent instead of moving it
 * to the reminder.
 */
const TIME_PHRASE = new RegExp(
  "(?:" +
    `(?:\\b${TIME_PREPOSITION}\\s+(?:${SELF_EVIDENT_TIME})|${BARE_HOUR_WITH_PREPOSITION}|${SELF_EVIDENT_TIME})` +
    `(?:\\s+${DAYPART})?` +
    `|${DAYPART}` +
  ")",
  "gi",
);

const DAY_PHRASE = new RegExp(
  String.raw`\b(?:(?:on|this|next|by)\s+)?${DAY_WORDS}\b`,
  "gi",
);

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = getSupabasePublishableKey();
    const hfToken = Deno.env.get("HF_TOKEN");

    if (!supabaseUrl || !supabaseKey) {
      console.error("[parse-voice-goals] Missing Supabase env");
      return json({ error: "Server is not configured" }, 500);
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: "Invalid user session" }, 401);
    }

    const body = await safeReadBody(req);
    if (!body) return json({ error: "Invalid JSON body" }, 400);

    const validationError = validateBody(body);
    if (validationError) return json({ error: validationError }, 400);

    const transcript = body.transcript.trim().slice(0, MAX_TRANSCRIPT_LENGTH);

    let goals: ParsedGoal[] = [];
    let summary = "";
    let fallback = false;
    let fallbackReason = "";

    try {
      if (!hfToken) throw new Error("Missing HF_TOKEN function secret");
      const parsed = await parseWithHuggingFace({ ...body, transcript }, hfToken);
      goals = parsed.goals;
      summary = parsed.summary;
    } catch (error) {
      // Surfaced in the response so the client can log WHY it degraded. Without
      // this the only symptom is a silently worse result.
      fallbackReason = String(error instanceof Error ? error.message : error).slice(0, 300);
      console.error("[parse-voice-goals] model failed:", error);
      goals = [];
    }

    // The model can succeed at the HTTP level but return nothing usable.
    if (goals.length === 0) {
      goals = buildFallbackGoals(transcript);
      fallback = true;
      summary = "";
    }

    // Last resort: the user definitely said something, so give them one draft
    // to edit rather than an error screen. Returning a failure here is what
    // produced the "couldn't process that" dead end.
    if (goals.length === 0) {
      const whole = condenseTitle(transcript);
      // Still refuse to invent a goal out of pure filler or configuration talk.
      if (whole.length > 1 && !isInstructionSegment(whole)) {
        const attributes = readAttributes(transcript);
        goals = [{
          title: whole,
          priority: attributes.priority,
          day_offset: 0,
          time: attributes.time,
          notify: attributes.notify,
          alarm: attributes.alarm,
        }];
        fallback = true;
      }
    }

    if (goals.length === 0) {
      return json({ error: "No goals found in transcript" }, 422);
    }

    const result: ParseVoiceGoalsResult = { goals, summary, fallback, fallback_reason: fallbackReason };
    return json(result);
  } catch (error) {
    console.error("[parse-voice-goals] unhandled:", error);
    return json({ error: "Unexpected server error" }, 500);
  }
});

// ── Model ────────────────────────────────────────────────────────────────────

async function parseWithHuggingFace(
  body: ParseVoiceGoalsRequest,
  token: string,
): Promise<{ goals: ParsedGoal[]; summary: string }> {
  const prompt = buildPrompt(body);

  let lastError: unknown;
  const startedAt = Date.now();

  for (const model of MODELS) {
    const remaining = MODEL_BUDGET_MS - (Date.now() - startedAt);
    if (remaining <= 1500) {
      console.warn("[parse-voice-goals] model budget exhausted, using fallback");
      break;
    }

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      Math.min(MODEL_TIMEOUT_MS, remaining),
    );
    try {
      const response = await fetch("https://router.huggingface.co/v1/chat/completions", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${token}`,
        },
        signal: controller.signal,
        body: JSON.stringify({
          model,
          temperature: 0,
          max_tokens: 700,
          // NOTE: deliberately no `response_format`. Checked against the router's
          // live capability list: no provider serving Qwen2.5-72B supports
          // structured output, and `:cheapest` can land on a non-supporting
          // provider for the others — sending it makes every attempt 400 and
          // drops the whole feature onto the heuristic parser. `tryExtractJson`
          // already tolerates code fences and stray prose.
          messages: [
            {
              role: "system",
              content:
                "You extract short to-do items from speech. Return ONLY a JSON object. " +
                "No markdown, no code fences, no explanation before or after.",
            },
            { role: "user", content: prompt },
          ],
        }),
      });

      if (!response.ok) {
        throw new Error(`${model} failed: ${await response.text()}`);
      }

      const payload = await response.json();
      const text = extractAssistantText(payload);
      if (!text) throw new Error(`${model} returned an empty response`);

      const parsed = parseModelOutput(text);
      if (parsed.goals.length > 0) return parsed;

      throw new Error(`${model} returned no usable goals`);
    } catch (error) {
      lastError = error;
      console.error(`[parse-voice-goals] ${model}:`, error);
    } finally {
      clearTimeout(timeout);
    }
  }

  throw lastError ?? new Error("All models failed");
}

function buildPrompt(body: ParseVoiceGoalsRequest): string {
  return `You are an AI system that extracts structured daily goals from user speech.

Your task is to convert messy natural language into CLEAN, MINIMAL, and ACTIONABLE goals.

Today is ${body.today}. The current local time is ${body.now_time} (24-hour).

---

## CORE DEFINITION

A GOAL is a short actionable task (verb + object).

Examples:
- "Visit bank"
- "Call John"
- "Go to gym"

---

## STRICT RULES

### 1. GOAL FORMAT
- Each goal MUST be ${MAX_TITLE_WORDS} words MAX
- Must contain a clear action (verb + object)
- DO NOT include filler words
- Keep the SAME LANGUAGE the user spoke

INVALID:
- "At 5 PM"
- "High priority"
- "Planning to go"
- "Make a call please"
- "Today I am planning to have"
- "Make sure this goal is this"
- "It has notification"
- "Plus alarm"

VALID:
- "Call John"
- "Visit bank"
- "Go to gym"
- "Meeting with professor"

### 1b. NEVER PUT THE TIME OR THE DAY IN THE TITLE (CRITICAL)

The title says WHAT. "notification_time" and "day_offset" say WHEN. A title that
repeats the time is wrong even though it reads naturally — the user sees that
time on the reminder, so in the title it is noise.

WRONG -> RIGHT:
- "Breakfast at 5:52 AM"      -> "Breakfast"        (notification_time "05:52")
- "Gym at 6pm tomorrow"        -> "Go to gym"        (notification_time "18:00", day_offset 1)
- "Call mum tomorrow"          -> "Call mum"         (day_offset 1)
- "Meeting 3 o'clock Monday"   -> "Meeting"          (notification_time "15:00")
- "Lunch at noon"              -> "Lunch"            (notification_time "12:00")
- "Study in the evening"       -> "Study"            (notification_time null)

Numbers that are NOT times stay in the title: "Run 5 km", "Buy 2 tickets".

### 2. NO DESCRIPTION FIELD
- Do NOT generate descriptions
- Only extract the goal title and attributes

### 3. HARD FILTER (CRITICAL)

DO NOT create goals from:
- instructions ("make it high priority", "make the priority low")
- system requests ("turn on alarm", "set notification", "turn on notification")
- filler ("I am planning", "maybe", "please", "last night I was thinking")
- time phrases ("at 6 PM", "tomorrow morning")

These are NOT goals. These are ATTRIBUTES.

Phrases that configure a goal and must never become goals, in any language:
"make sure this goal is ...", "make sure it has ...", "it has notification",
"plus alarm", "with an alarm", "turn on alarm", "turn on notification",
"set a reminder for it", "make the priority high", "make the priority low",
"please make priority high", "mark it urgent", "remind me about it",
"for that one".

### 3b. MERGE RELATED INPUT
If the user says multiple things about ONE task, combine them into ONE goal.

Example:
"I will go to the bank at 3 PM, make it high priority, turn on alarm"
-> ONE goal: "Visit bank" (priority high, notification_time "15:00", alarm true)

### 3c. ATTRIBUTE BINDING (MOST IMPORTANT)

You MUST assign attributes ONLY to the correct goal.

1. LOCALITY RULE — an attribute applies to the CLOSEST relevant goal in
   sentence order, normally the goal named just before it.
2. DO NOT GLOBALIZE — "make it low priority" applies ONLY to the nearest goal,
   never to all of them. Each goal keeps its own defaults unless the user said
   otherwise about THAT goal.
3. MULTIPLE GOALS — evaluate each goal independently.
4. AMBIGUITY RULE — if it is unclear which goal an attribute belongs to, IGNORE
   the attribute rather than guessing.

### 3d. DEDUPLICATION
Do NOT create duplicate goals. Merge repeated mentions of the same task.

### 4. ATTRIBUTES

Each goal must include:

- "title": ${MAX_TITLE_WORDS} words MAX
- "priority": "low" | "medium" | "high". Default = "medium".
    "high" for urgent / important / critical / must / high priority.
    "low" for low priority / whenever / if I have time / no rush.
- "notification_time": time if mentioned ("HH:mm", 24-hour). Otherwise null.
- "alarm": true if the user explicitly asks for an alarm, to be woken, or for it
    to ring. Otherwise false.
- "notify": true if the user wants any reminder at all. A stated time implies
    true. An alarm implies true. Otherwise false.
- "day_offset": 0 for today or unspecified, 1 for tomorrow, 2 for the day after,
    and so on. Use the smallest matching offset for weekday names.

### 5. TIME HANDLING
- If the user mentions a time, assign it to notification_time
- Convert to "HH:mm" (24-hour): "3pm" -> "15:00", "half past 8 in the morning" -> "08:30"
- Never invent a time. Vague phrases ("sometime today", "during the day", "at
  some point") mean null.

### 6. CLEAN INPUT
REMOVE: "I am planning", "please", "make sure", "maybe", "later", "and then",
"lastly", "apart from that", "what else like".
KEEP: only actionable intent.

### 7. IGNORE NON-GOALS
Do NOT output anything that is not a real goal. Prefer FEWER, correct goals over
many fragments. If unsure whether a fragment is its own goal, it belongs to the
previous one.

---

## OUTPUT FORMAT (STRICT JSON)

Return ONLY this JSON object. No markdown, no code fences, no text around it.

{
  "summary": "one short sentence, max 12 words, in the user's language",
  "goals": [
    {
      "title": "...",
      "priority": "low | medium | high",
      "notification_time": "HH:mm or null",
      "alarm": true | false,
      "notify": true | false,
      "day_offset": 0
    }
  ]
}

If the transcript contains no actual goal, return {"summary":"","goals":[]}.

---

## EXAMPLES

Input:
"I am planning to visit the bank at 3 AM tomorrow. Please make it high priority and turn on alarm."

Output:
{"summary":"One goal tomorrow: the bank.","goals":[{"title":"Visit bank","priority":"high","notification_time":"03:00","alarm":true,"notify":true,"day_offset":1}]}

Input:
"Today I am planning to have a meeting with my professor, make sure this goal is this, it has notification, plus alarm, and make sure priorities high for that. Apart from that I'm planning to visit my relatives house at 6pm."

Output:
{"summary":"Two goals today: professor meeting and family visit.","goals":[{"title":"Meeting with professor","priority":"high","notification_time":null,"alarm":true,"notify":true,"day_offset":0},{"title":"Visit relatives house","priority":"medium","notification_time":"18:00","alarm":false,"notify":true,"day_offset":0}]}

That second example has TWO goals, not seven. "make sure this goal is this",
"it has notification", "plus alarm" and "make sure priorities high for that" all
configured the FIRST goal.

Input:
"Today at 6 PM I'm planning to hit the gym. Also visit the bank at 6 PM. Make the bank low priority and turn on alarm for it. Also I was thinking about school last night."

Output:
{"summary":"Two goals today: gym and bank.","goals":[{"title":"Go to gym","priority":"medium","notification_time":"18:00","alarm":false,"notify":true,"day_offset":0},{"title":"Visit bank","priority":"low","notification_time":"18:00","alarm":true,"notify":true,"day_offset":0}]}

That example shows the LOCALITY RULE. "Make the bank low priority and turn on
alarm for it" names the bank, so it configures ONLY the bank — the gym keeps
medium priority and no alarm. "I was thinking about school last night" is a
reflection about the past, not a goal, so it produces nothing.

Input:
"Tomorrow I want to have breakfast at 5:52 am and then hit the gym at 7."

Output:
{"summary":"Two goals tomorrow: breakfast and gym.","goals":[{"title":"Breakfast","priority":"medium","notification_time":"05:52","alarm":false,"notify":true,"day_offset":1},{"title":"Hit gym","priority":"medium","notification_time":"07:00","alarm":false,"notify":true,"day_offset":1}]}

Note the titles: "Breakfast", NOT "Breakfast at 5:52 AM". The time is on
notification_time and the day is on day_offset — never repeated in the title.

---

Now process the following input:
"""
${body.transcript}
"""

JSON:`;
}

// ── Parsing / sanitising ─────────────────────────────────────────────────────

function parseModelOutput(text: string): { goals: ParsedGoal[]; summary: string } {
  const raw = tryExtractJson(text);
  if (!raw) return { goals: [], summary: "" };

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { goals: [], summary: "" };
  }

  // Accept both {"goals":[...]} and a bare [...] — small models drift between them.
  const container = Array.isArray(parsed) ? { goals: parsed, summary: "" } : parsed as {
    goals?: unknown;
    summary?: unknown;
  };

  const list = container?.goals;
  if (!Array.isArray(list)) return { goals: [], summary: "" };

  const goals: ParsedGoal[] = [];
  for (const entry of list) {
    const goal = sanitizeGoal(entry);
    if (goal) goals.push(goal);
    if (goals.length >= MAX_GOALS) break;
  }

  return {
    goals,
    summary: cleanText(container?.summary, "", MAX_SUMMARY_LENGTH),
  };
}

function sanitizeGoal(entry: unknown): ParsedGoal | undefined {
  if (!entry || typeof entry !== "object") return undefined;
  const record = entry as Record<string, unknown>;

  const rawTitle = typeof record.title === "string" ? record.title : "";
  const title = condenseTitle(rawTitle);
  if (!title) return undefined;

  // The prompt forbids titles like "High priority" or "It has notification",
  // but prompts are guidance, not a guarantee. Reject anything that names no
  // activity here so a slip never reaches the user's goal list.
  if (isInstructionSegment(title)) return undefined;

  // The prompt asks for "notification_time"; accept the older "time" key too so
  // a model that echoes either shape still parses. Falling back to the raw
  // title rescues the case this whole path exists for: a model that wrote
  // "Breakfast at 5:52 AM" and left notification_time null. The time comes out
  // of the title either way — this keeps it on the reminder instead of losing it.
  const time = normalizeTime(record.notification_time) ??
    normalizeTime(record.time) ??
    extractSpokenTime(rawTitle);
  const alarm = normalizeBool(record.alarm);
  // A named time means the user expects to be reminded, and an alarm is a
  // reminder by definition — enforce both invariants here rather than trusting
  // the model to keep the flags consistent.
  const notify = normalizeBool(record.notify) || alarm || time !== null;

  // Same reasoning as `time`: "tomorrow" is stripped out of the title, so if the
  // model left the offset at 0 the day would otherwise be lost. A stated offset
  // always wins — this only fills a gap.
  const dayOffset = normalizeDayOffset(record.day_offset) || dayOffsetFromText(rawTitle);

  return {
    title,
    priority: normalizePriority(record.priority),
    day_offset: dayOffset,
    time,
    notify,
    alarm,
  };
}

/** Relative day named in free text. 0 when none is, which is also the default. */
function dayOffsetFromText(text: string): number {
  if (/\bday\s+after\s+tomorrow\b/i.test(text)) return 2;
  if (/\btomorrow\b/i.test(text)) return 1;
  return 0;
}

function normalizeBool(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const raw = value.trim().toLowerCase();
    return raw === "true" || raw === "yes" || raw === "1";
  }
  if (typeof value === "number") return value === 1;
  return false;
}

/**
 * Last line of defence on title length: strip spoken lead-ins, then hard-cap at
 * MAX_TITLE_WORDS. Runs on model output too, because small models drift.
 */
function condenseTitle(raw: string): string {
  let text = raw.trim().replace(/\s+/g, " ").replace(/^["'“”]+|["'“”.,!]+$/g, "");

  // Peel off filler lead-ins repeatedly ("and also I'm planning to visit …").
  let changed = true;
  while (changed) {
    changed = false;
    for (const pattern of FILLER_PATTERNS) {
      const stripped = text.replace(pattern, "").trim();
      if (stripped !== text && stripped.length > 0) {
        text = stripped;
        changed = true;
      }
    }
  }

  // "Buy groceries whenever" -> "Buy groceries": the trailing word set the
  // priority, it is not part of what the user has to do.
  changed = true;
  while (changed) {
    changed = false;
    for (const pattern of TRAILING_ATTRIBUTE_PATTERNS) {
      const stripped = text.replace(pattern, "").trim();
      if (stripped !== text && stripped.length > 0) {
        text = stripped;
        changed = true;
      }
    }
  }

  // Before the word cap, not after: cutting "breakfast at 5:52 am tomorrow" to
  // four words first is what froze the time into the title.
  text = stripSchedulingPhrases(text);

  const words = text.split(" ").filter(Boolean);
  if (words.length === 0) return "";

  let title = words.slice(0, MAX_TITLE_WORDS).join(" ");
  if (title.length > MAX_TITLE_LENGTH) title = title.slice(0, MAX_TITLE_LENGTH).trim();

  // The word cap can leave punctuation glued to the last kept word
  // ("Meeting with my professor,").
  title = title.replace(/[\s,;:.!?—–-]+$/u, "").trim();

  // "Call my mum at" -> "Call my mum". Repeat: chopping one tail can expose
  // another ("meeting with the" -> "meeting with" -> "meeting").
  let trimmed = title.replace(DANGLING_TAIL, "").trim();
  while (trimmed !== title && trimmed.length > 0) {
    title = trimmed;
    trimmed = title.replace(DANGLING_TAIL, "").trim();
  }

  // Sentence case, leaving existing capitals (names, acronyms) alone.
  return title.charAt(0).toUpperCase() + title.slice(1);
}

/**
 * Removes clock times and day references from a title, wherever they sit.
 *
 * Reverts if the result names no activity: "Noon" or "Tomorrow" as an entire
 * title is odd, but handing back an empty string is worse — `sanitizeGoal`
 * rejects instruction-only titles anyway, and a bad title the user can edit
 * beats a goal that silently vanished.
 */
function stripSchedulingPhrases(text: string): string {
  const stripped = tidySeams(text.replace(TIME_PHRASE, " ").replace(DAY_PHRASE, " "));
  if (!stripped || isInstructionSegment(stripped)) return text;
  return stripped;
}

/**
 * Closes the gap left by a phrase removed from the middle, and drops the
 * connective that was holding it there: "Meeting with professor at 5 pm on
 * Monday" -> "Meeting with professor".
 */
function tidySeams(text: string): string {
  return text
    .replace(/\s{2,}/g, " ")
    .replace(/\s+([,.;:!?])/g, "$1")
    .replace(/^[\s,.;:!?-]+|[\s,.;:!?-]+$/g, "")
    .replace(DANGLING_TAIL, "")
    .trim();
}

function normalizePriority(value: unknown): "low" | "medium" | "high" {
  const raw = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (raw === "low" || raw === "high") return raw;
  return "medium";
}

function normalizeDayOffset(value: unknown): number {
  const raw = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(raw)) return 0;
  const rounded = Math.trunc(raw);
  if (rounded < 0) return 0;
  return rounded > MAX_DAY_OFFSET ? MAX_DAY_OFFSET : rounded;
}

function normalizeTime(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const match = value.trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function tryExtractJson(text: string): string | undefined {
  const trimmed = text.trim().replace(/^```(?:json)?/i, "").replace(/```$/, "").trim();

  const objectStart = trimmed.indexOf("{");
  const objectEnd = trimmed.lastIndexOf("}");
  const arrayStart = trimmed.indexOf("[");
  const arrayEnd = trimmed.lastIndexOf("]");

  // Prefer whichever container starts first and is well-formed.
  const objectValid = objectStart !== -1 && objectEnd > objectStart;
  const arrayValid = arrayStart !== -1 && arrayEnd > arrayStart;

  if (objectValid && (!arrayValid || objectStart < arrayStart)) {
    return trimmed.slice(objectStart, objectEnd + 1);
  }
  if (arrayValid) return trimmed.slice(arrayStart, arrayEnd + 1);
  return undefined;
}

/**
 * Deterministic last resort, used only when every model is unreachable. Splits
 * on the connectives people actually speak, then condenses each piece with the
 * same title rules the model is asked to follow.
 */
/**
 * Boundaries that genuinely start a new goal. Deliberately NOT a bare "and":
 * "a meeting with my professor and my advisor" is one goal, and splitting on
 * every "and" is what turned a two-goal sentence into ten fragments.
 */
const GOAL_BOUNDARY =
  /[.;\n]+|\bapart from that\b|\bbesides that\b|\bother than that\b|\band then\b|\bafter that\b|\b(?:and\s+)?lastly\b|\bfinally\b|\bwhat else\b|\band(?:\s+also)?\s+(?:i|i'?m|i am|i'?ll)\b|\balso\s+i\b/i;

/**
 * Words that only ever describe HOW a goal should be configured. A segment made
 * up of nothing but these is an instruction ("make sure it has notification
 * plus alarm"), not a goal — it belongs to the goal before it.
 */
const ATTRIBUTE_VOCAB =
  /\b(?:make|makes|making|sure|ensure|please|this|that|these|those|goal|goals|task|tasks|one|it|its|it's|is|are|was|were|has|have|had|with|plus|and|also|for|the|a|an|be|being|should|must|need|needs|set|sets|setting|put|puts|add|adds|turn|turns|turning|switch|enable|disable|activate|on|off|to|too|of|my|me|i|high|higher|highest|medium|low|lower|urgent|important|critical|priority|priorities|level|notification|notifications|notify|notified|remind|reminds|reminder|reminders|alarm|alarms|alert|alerts|sound|ring|ringing|as|well)\b/gi;

/** True when a segment configures a goal instead of naming one. */
function isInstructionSegment(segment: string): boolean {
  const leftover = segment
    .toLowerCase()
    .replace(ATTRIBUTE_VOCAB, " ")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .split(/\s+/)
    .filter((word) => word.length > 1);

  // Nothing but configuration vocabulary survived — no activity was named.
  return leftover.length === 0;
}

/** Reflections about the past are not intentions. */
const NOT_AN_INTENTION =
  /\b(?:was thinking|were thinking|had been thinking|last night|yesterday|i thought)\b/i;

function meaningfulWords(text: string): string[] {
  return text
    .toLowerCase()
    .replace(ATTRIBUTE_VOCAB, " ")
    .replace(/[^\p{L}\p{N}\s']/gu, " ")
    .split(/\s+/)
    .filter((word) => word.length > 1);
}

/**
 * Index of the goal a clause refers to by name. "Make the bank low priority"
 * contributes only "bank", which "Visit the bank" already contains — so it
 * configures that goal instead of becoming one.
 */
function goalReferencedBy(clause: string, goals: ParsedGoal[]): number {
  const contentWords = new Set(meaningfulWords(clause));
  if (contentWords.size === 0 || contentWords.size > 3) return -1;

  for (let index = goals.length - 1; index >= 0; index--) {
    const titleWords = new Set(
      goals[index].title.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((w) => w.length > 1),
    );
    let subset = true;
    for (const word of contentWords) {
      if (!titleWords.has(word)) { subset = false; break; }
    }
    if (subset) return index;
  }
  return -1;
}

function buildFallbackGoals(transcript: string): ParsedGoal[] {
  // Clauses, not sentences: "visit the bank, make the priority low, alarm" is
  // one sentence but a goal plus two instructions about it.
  const clauses = splitOnBoundaries(transcript)
    .flatMap((segment) => segment.split(","))
    .map((clause) => clause.trim())
    .filter((clause) => clause.length > 1);

  const seen = new Set<string>();
  const goals: ParsedGoal[] = [];

  for (const clause of clauses) {
    const attributes = readAttributes(clause);

    // HARD FILTER: pure configuration binds to the most recent goal.
    if (isInstructionSegment(clause)) {
      applyAttributes(goals[goals.length - 1], attributes);
      continue;
    }

    // LOCALITY by name: bind to the goal the clause actually names.
    const referenced = goalReferencedBy(clause, goals);
    if (referenced >= 0) {
      applyAttributes(goals[referenced], attributes);
      continue;
    }

    if (NOT_AN_INTENTION.test(clause)) continue;

    const title = condenseTitle(clause);
    // A title that is pure filler ("Today I am planning to") names no activity.
    if (title.length <= 1 || isInstructionSegment(title)) continue;

    const key = title.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    goals.push({
      title,
      priority: attributes.priority,
      day_offset: dayOffsetFromText(clause),
      time: attributes.time,
      notify: attributes.notify,
      alarm: attributes.alarm,
    });
    if (goals.length >= MAX_GOALS) break;
  }

  return goals;
}

type SpokenAttributes = {
  priority: "low" | "medium" | "high";
  time: string | null;
  notify: boolean;
  alarm: boolean;
  sawPriority: boolean;
};

function readAttributes(segment: string): SpokenAttributes {
  const time = extractSpokenTime(segment);
  const alarm = /\b(alarm|wake me|ring|don'?t let me sleep)\b/i.test(segment);
  const priority = extractSpokenPriority(segment);
  return {
    priority,
    time,
    alarm,
    notify: alarm || time !== null ||
      /\b(remind|reminder|notify|notification|ping me|let me know)\b/i.test(segment),
    sawPriority: priority !== "medium",
  };
}

/** Folds an instruction segment's settings into the goal it refers to. */
function applyAttributes(goal: ParsedGoal | undefined, attributes: SpokenAttributes) {
  if (!goal) return;
  if (attributes.sawPriority) goal.priority = attributes.priority;
  if (attributes.time && !goal.time) goal.time = attributes.time;
  if (attributes.alarm) goal.alarm = true;
  if (attributes.notify) goal.notify = true;
  if (goal.alarm) goal.notify = true;
}

function splitOnBoundaries(transcript: string): string[] {
  return transcript.split(new RegExp(GOAL_BOUNDARY.source, "gi"));
}

function extractSpokenPriority(segment: string): "low" | "medium" | "high" {
  // People say it in both orders: "high priority" and "priority is high",
  // "make sure priorities high". Match the words near each other rather than
  // requiring one fixed phrase.
  const highNearPriority =
    /\bpriorit(?:y|ies)\b[^.]{0,20}?\b(high|urgent|top|max(?:imum)?)\b/i.test(segment) ||
    /\b(high|urgent|top|max(?:imum)?)\b[^.]{0,20}?\bpriorit(?:y|ies)\b/i.test(segment);
  const lowNearPriority =
    /\bpriorit(?:y|ies)\b[^.]{0,20}?\b(low|minor)\b/i.test(segment) ||
    /\b(low|minor)\b[^.]{0,20}?\bpriorit(?:y|ies)\b/i.test(segment);

  if (highNearPriority) return "high";
  if (lowNearPriority) return "low";
  if (/\b(urgent|important|critical|asap)\b/i.test(segment)) return "high";
  if (/\b(whenever|no rush|if i have time|sometime|not urgent)\b/i.test(segment)) return "low";
  return "medium";
}

/**
 * Reads a wall-clock time out of free text: "at 3pm", "15:30", "half past 8",
 * "quarter to nine", "noon".
 *
 * Understands exactly the forms TIME_PHRASE strips out of titles — the two must
 * stay in step, or a title would lose a time that never reached the reminder.
 * Ordered most specific first so "5:52 am" is not misread as "52 am".
 */
function extractSpokenTime(segment: string): string | null {
  const reading = readClock(segment);
  if (!reading) return null;
  const [hour, minute] = applyDaypart(reading, segment);
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function readClock(segment: string): [number, number] | null {
  if (/\b(?:noon|midday)\b/i.test(segment)) return [12, 0];
  if (/\bmidnight\b/i.test(segment)) return [0, 0];

  // "half past eight", "quarter to nine"
  const fraction = segment.match(
    new RegExp(String.raw`\b(half|quarter)\s+(past|to)\s+(${HOUR_TOKEN})\b`, "i"),
  );
  if (fraction) {
    const base = hourValue(fraction[3]);
    if (base !== null) {
      const minute = fraction[1].toLowerCase() === "half" ? 30 : 15;
      return fraction[2].toLowerCase() === "to"
        ? normalizeClock((base + 23) % 24, 60 - minute)   // the hour before, wrapping at midnight
        : normalizeClock(base, minute);
    }
  }

  // "5:52 am", "17.30"
  const clock = segment.match(new RegExp(String.raw`\b(\d{1,2})[:.](\d{2})\s*(${MERIDIEM})?`, "i"));
  if (clock) {
    const found = normalizeClock(Number(clock[1]), Number(clock[2]), clock[3]);
    if (found) return found;
  }

  // "6pm", "eight am"
  const withMeridiem = segment.match(
    new RegExp(String.raw`\b(${HOUR_TOKEN})\s*(${MERIDIEM})`, "i"),
  );
  if (withMeridiem) {
    const hour = hourValue(withMeridiem[1]);
    if (hour !== null) {
      const found = normalizeClock(hour, 0, withMeridiem[2]);
      if (found) return found;
    }
  }

  // "7 o'clock"
  const oclock = segment.match(new RegExp(String.raw`\b(${HOUR_TOKEN})\s*o'?\s?clock`, "i"));
  if (oclock) {
    const hour = hourValue(oclock[1]);
    if (hour !== null) return normalizeClock(hour, 0);
  }

  // "at 6", "by six" — only where a preposition and what follows make it
  // unambiguous, matching the strip rule exactly.
  const bare = segment.match(new RegExp(BARE_HOUR_WITH_PREPOSITION.replace(
    HOUR_TOKEN,
    `(${HOUR_TOKEN})`,
  ), "i"));
  if (bare) {
    const hour = hourValue(bare[1]);
    if (hour !== null) return normalizeClock(hour, 0);
  }

  return null;
}

function hourValue(token: string): number | null {
  const figure = Number(token);
  if (Number.isInteger(figure)) return figure;
  const word = NUMBER_WORDS[token.toLowerCase()];
  return word === undefined ? null : word;
}

function normalizeClock(hour: number, minute: number, meridiem?: string): [number, number] | null {
  const suffix = (meridiem ?? "").toLowerCase().replace(/\./g, "");
  if (suffix.startsWith("p") && hour < 12) hour += 12;
  if (suffix.startsWith("a") && hour === 12) hour = 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return [hour, minute];
}

/**
 * "six in the evening" is 18:00, not 06:00. Only nudges a morning hour that
 * carried no explicit am/pm.
 */
function applyDaypart([hour, minute]: [number, number], segment: string): [number, number] {
  if (hour < 1 || hour > 11) return [hour, minute];
  if (new RegExp(String.raw`\b${MERIDIEM}`, "i").test(segment)) return [hour, minute];
  if (!/\b(?:in\s+the\s+(?:afternoon|evening)|at\s+night|tonight)\b/i.test(segment)) {
    return [hour, minute];
  }
  return [hour + 12, minute];
}

// ── Helpers (shared conventions with generate-progress-summary) ──────────────

function validateBody(body: ParseVoiceGoalsRequest) {
  if (!body || typeof body !== "object") return "Invalid request";
  if (typeof body.transcript !== "string" || !body.transcript.trim()) {
    return "Missing transcript";
  }
  if (typeof body.today !== "string" || !isISODate(body.today)) {
    return "Invalid today date";
  }
  if (typeof body.now_time !== "string" || !/^\d{2}:\d{2}$/.test(body.now_time)) {
    return "Invalid current time";
  }
  return undefined;
}

function isISODate(value: string) {
  return /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function getSupabasePublishableKey() {
  const legacyAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (legacyAnonKey) return legacyAnonKey;

  const publishableKeys = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (!publishableKeys) return undefined;

  try {
    const parsed = JSON.parse(publishableKeys) as Record<string, string>;
    return parsed.default ?? Object.values(parsed)[0];
  } catch {
    return undefined;
  }
}

async function safeReadBody(req: Request): Promise<ParseVoiceGoalsRequest | undefined> {
  try {
    return await req.json() as ParseVoiceGoalsRequest;
  } catch {
    return undefined;
  }
}

function extractAssistantText(payload: unknown): string {
  const data = payload as {
    choices?: Array<{
      message?: {
        content?: string | Array<{ text?: string }>;
      };
    }>;
  };

  const content = data.choices?.[0]?.message?.content;
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content.map((part) => part.text ?? "").join("").trim();
  }

  return "";
}

function cleanText(value: unknown, fallback: string, maxLength: number) {
  if (typeof value !== "string") return fallback;
  const trimmed = value.trim();
  if (!trimmed) return fallback;
  return trimmed.length > maxLength ? `${trimmed.slice(0, maxLength - 1)}…` : trimmed;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}
