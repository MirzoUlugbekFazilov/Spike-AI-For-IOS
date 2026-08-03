import { createClient } from "npm:@supabase/supabase-js@2";

type ProgressSummaryRequest = {
  period_start: string;
  period_end: string;
  current_streak: number;
  best_streak: number;
  monthly_consistency_percent: number;
  monthly_focus_days: number;
  monthly_missed_days: number;
  completed_tasks: string[];
  missed_tasks: string[];
  screen_time_trend: string;
  average_screen_time_minutes: number;
  goals: string[];
  force_refresh?: boolean;
  language?: string;
};

type ProgressSummaryResult = {
  title: string;
  summary: string;
  wins: string[];
  next_action: string;
};

type ProgressSummaryRow = {
  id: string;
  user_id: string;
  period_start: string;
  period_end: string;
  title: string;
  summary: string;
  wins: string[];
  next_action: string;
  created_at: string;
  updated_at: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
      console.error("[generate-progress-summary] Missing Supabase env");
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
    if (!body) {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const validationError = validateBody(body);
    if (validationError) {
      return json({ error: validationError }, 400);
    }

    if (!body.force_refresh) {
      try {
        const { data: existing } = await supabase
          .from("progress_summaries")
          .select()
          .eq("user_id", userData.user.id)
          .eq("period_start", body.period_start)
          .eq("period_end", body.period_end)
          .maybeSingle();

        if (existing) {
          return json(existing);
        }
      } catch (error) {
        console.error("[generate-progress-summary] cache read failed:", error);
      }
    }

    let generated: ProgressSummaryResult;
    try {
      if (!hfToken) throw new Error("Missing HF_TOKEN function secret");
      generated = await generateWithHuggingFace(body, hfToken);
    } catch (error) {
      console.error("[generate-progress-summary] model failed:", error);
      generated = buildFallbackSummary(body);
    }

    const record = buildSyntheticRow({
      userId: userData.user.id,
      body,
      generated,
    });

    try {
      const { data: saved } = await supabase
        .from("progress_summaries")
        .upsert({
          user_id: userData.user.id,
          period_start: body.period_start,
          period_end: body.period_end,
          title: generated.title,
          summary: generated.summary,
          wins: generated.wins.slice(0, 3),
          next_action: generated.next_action,
          updated_at: new Date().toISOString(),
        }, { onConflict: "user_id,period_start,period_end" })
        .select()
        .single();

      if (saved) {
        return json(saved);
      }
    } catch (error) {
      console.error("[generate-progress-summary] save failed:", error);
    }

    return json(record);
  } catch (error) {
    console.error("[generate-progress-summary] unhandled error:", error);
    return json({ error: "Progress summary failed" }, 500);
  }
});

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

function validateBody(body: ProgressSummaryRequest) {
  if (!body || typeof body !== "object") return "Invalid request";
  if (!body.period_start || !body.period_end) return "Missing summary period";
  if (!Array.isArray(body.completed_tasks)) return "Missing completed tasks";
  if (!Array.isArray(body.missed_tasks)) return "Missing missed tasks";
  if (!Array.isArray(body.goals)) return "Missing goals";
  if (!isISODate(body.period_start) || !isISODate(body.period_end)) return "Invalid summary period";
  if (body.completed_tasks.length > 50 || body.missed_tasks.length > 50 || body.goals.length > 50) {
    return "Too many items in summary request";
  }
  if (![body.completed_tasks, body.missed_tasks, body.goals].every(isSafeTextArray)) {
    return "Summary request contains invalid text";
  }
  if (typeof body.screen_time_trend !== "string" || body.screen_time_trend.length > 240) {
    return "Invalid screen time trend";
  }
  for (const value of [
    body.current_streak,
    body.best_streak,
    body.monthly_consistency_percent,
    body.monthly_focus_days,
    body.monthly_missed_days,
    body.average_screen_time_minutes,
  ]) {
    if (!Number.isFinite(value) || value < 0) return "Invalid summary metrics";
  }
  return undefined;
}

function isISODate(value: string) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function isSafeTextArray(values: string[]) {
  return values.every((value) => typeof value === "string" && value.trim().length > 0 && value.length <= 160);
}

async function generateWithHuggingFace(body: ProgressSummaryRequest, token: string) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("Hugging Face request timed out"), 12_000);

  const completionRate = body.completed_tasks.length + body.missed_tasks.length > 0
    ? Math.round((body.completed_tasks.length / (body.completed_tasks.length + body.missed_tasks.length)) * 100)
    : 0;

  const langMap: Record<string, string> = {
    en: "English", es: "Spanish", fr: "French", de: "German", pt: "Portuguese",
    ru: "Russian", uz: "Uzbek", zh: "Chinese", ja: "Japanese", ko: "Korean",
    ar: "Arabic", hi: "Hindi", tr: "Turkish", it: "Italian", pl: "Polish",
    uk: "Ukrainian", nl: "Dutch", sv: "Swedish", id: "Indonesian", th: "Thai",
    vi: "Vietnamese", ms: "Malay", tg: "Tajik", kk: "Kazakh",
  };
  const userLang = body.language && langMap[body.language] ? langMap[body.language] : "English";
  const langInstruction = userLang !== "English"
    ? `\nIMPORTANT: Write the ENTIRE response in ${userLang}. All text — title, summary, wins, and next action — must be in ${userLang}. Do NOT use English.\n`
    : "";

  const prompt = `
You are the AI coach inside Spike AI, a productivity and focus app with four focus modes:
- Chill: gentle notification reminders, no app blocking
- Focus: asks "Are you sure?" before opening distracting apps
- Lock-in: fully blocks selected apps with no bypass
- Sweat: blocks apps until the user does push-ups or stand-ups on camera
${langInstruction}
Your job: write a weekly progress summary that feels personal, insightful, and motivating. The user should feel like you truly understand their week and are giving them a clear path forward.

Rules:
- Be concise, specific, and supportive. Never shame the user.
- Do not make medical, mental health, addiction, or diagnostic claims.
- Mention only information present in the input.
- In the SUMMARY, include: what went well, what patterns you notice (e.g. missed tasks piling up, inconsistent days), and recommend the best focus mode for next week with a short reason why.
- WINS should highlight specific achievements from the data.
- NEXT_ACTION should be one concrete, actionable productivity tip for the coming week.
- Return plain text in this exact format:
TITLE: short motivating title (max 8 words)
SUMMARY: one paragraph (3-5 sentences). Include progress analysis, pattern insights, and a focus mode recommendation.
WINS:
- win one
- win two
- win three
NEXT_ACTION: one specific action for next week

Data for ${body.period_start} to ${body.period_end}:
Current streak: ${body.current_streak} days
Best streak: ${body.best_streak} days
Monthly consistency: ${body.monthly_consistency_percent}%
Focus days this month: ${body.monthly_focus_days}
Missed days this month: ${body.monthly_missed_days}
Task completion rate: ${completionRate}%
Completed tasks: ${body.completed_tasks.join(", ") || "None recorded"}
Missed tasks: ${body.missed_tasks.join(", ") || "None recorded"}
Screen time trend: ${body.screen_time_trend}
Average daily screen time: ${body.average_screen_time_minutes} minutes
Active goals: ${body.goals.join(", ") || "None set"}
`;

  try {
    const response = await fetch("https://router.huggingface.co/v1/chat/completions", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: "google/gemma-2-2b-it:cheapest",
        temperature: 0.25,
        max_tokens: 420,
        messages: [
          {
            role: "system",
            content: "Return exactly the requested plain text format. No markdown, no code fences, no extra commentary.",
          },
          { role: "user", content: prompt },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Hugging Face request failed: ${errorText}`);
    }

    const payload = await response.json();
    const text = extractAssistantText(payload);
    if (!text) throw new Error("Hugging Face returned an empty response");

    return parseSummary(text);
  } finally {
    clearTimeout(timeout);
  }
}

function parseSummary(text: string): ProgressSummaryResult {
  const json = tryExtractJson(text);
  if (json) {
    try {
      const parsed = JSON.parse(json) as Partial<ProgressSummaryResult>;
      return {
        title: cleanText(parsed.title, "7-day progress summary", 80),
        summary: cleanText(parsed.summary, "Your progress summary is ready.", 360),
        wins: Array.isArray(parsed.wins)
          ? parsed.wins.map((win) => cleanText(win, "", 90)).filter(Boolean).slice(0, 3)
          : ["Progress tracked"],
        next_action: cleanText(parsed.next_action, "Choose one clear task to complete next.", 160),
      };
    } catch {
      // Fall through to plain-text parsing.
    }
  }

  const parsedText = parsePlainTextSummary(text);
  if (parsedText) return parsedText;

  return {
    title: "7-day progress summary",
    summary: cleanText(text, "Your progress summary is ready.", 360),
    wins: [],
    next_action: "Choose one clear task to complete next.",
  };
}

function tryExtractJson(text: string) {
  const trimmed = text.trim();
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) return trimmed;

  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start >= 0 && end > start) {
    return trimmed.slice(start, end + 1);
  }

  return undefined;
}

function parsePlainTextSummary(text: string): ProgressSummaryResult | undefined {
  const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const titleLine = lines.find((line) => line.toUpperCase().startsWith("TITLE:"));
  const summaryLine = lines.find((line) => line.toUpperCase().startsWith("SUMMARY:"));
  const nextActionLine = lines.find((line) => line.toUpperCase().startsWith("NEXT_ACTION:"));
  const winsIndex = lines.findIndex((line) => line.toUpperCase().startsWith("WINS:"));

  const wins = winsIndex >= 0
    ? lines
        .slice(winsIndex + 1)
        .filter((line) => line.startsWith("-"))
        .map((line) => line.replace(/^-+\s*/, "").trim())
        .filter(Boolean)
        .slice(0, 3)
    : [];

  if (!titleLine && !summaryLine && !nextActionLine && wins.length === 0) return undefined;

  return {
    title: cleanText(titleLine?.replace(/^TITLE:\s*/i, ""), "7-day progress summary", 80),
    summary: cleanText(summaryLine?.replace(/^SUMMARY:\s*/i, ""), "Your progress summary is ready.", 360),
    wins,
    next_action: cleanText(nextActionLine?.replace(/^NEXT_ACTION:\s*/i, ""), "Choose one clear task to complete next.", 160),
  };
}

function buildFallbackSummary(body: ProgressSummaryRequest): ProgressSummaryResult {
  const totalTasks = body.completed_tasks.length + body.missed_tasks.length;
  const completionRate = totalTasks > 0
    ? Math.round((body.completed_tasks.length / totalTasks) * 100)
    : 0;

  // Pick a recommended mode based on the data
  let modeRec: string;
  if (completionRate >= 90 && body.current_streak >= 5) {
    modeRec = "Chill mode should work well — you're already disciplined.";
  } else if (completionRate >= 60) {
    modeRec = "Focus mode would help — it adds a gentle check before opening distracting apps.";
  } else if (body.missed_tasks.length > body.completed_tasks.length) {
    modeRec = "Lock-in mode could be the push you need — it fully blocks distracting apps so you can finish your tasks.";
  } else {
    modeRec = "Try Focus mode to stay intentional without feeling restricted.";
  }

  const wins = [
    body.completed_tasks.length > 0
      ? `Completed ${body.completed_tasks.length} task${body.completed_tasks.length === 1 ? "" : "s"} this week`
      : "Kept the focus workflow active",
    body.current_streak > 0
      ? `Built a ${body.current_streak}-day streak`
      : "Reset and restarted cleanly",
    body.monthly_consistency_percent >= 50
      ? `Monthly consistency at ${body.monthly_consistency_percent}%`
      : undefined,
  ].filter(Boolean).slice(0, 3) as string[];

  const summaryParts = [
    `Your task completion rate was ${completionRate}% with ${body.monthly_consistency_percent}% monthly consistency.`,
  ];

  if (body.completed_tasks.length > 0) {
    summaryParts.push(`You completed ${body.completed_tasks.slice(0, 3).join(", ")}.`);
  }
  if (body.missed_tasks.length > 0) {
    summaryParts.push(`Tasks like ${body.missed_tasks.slice(0, 2).join(" and ")} were left unfinished — consider breaking them into smaller steps.`);
  }
  summaryParts.push(modeRec);

  const nextAction = body.missed_tasks[0]
    ? `Start next week by finishing "${body.missed_tasks[0]}" first thing — clearing unfinished tasks builds momentum.`
    : body.goals[0]
      ? `Focus on "${body.goals[0]}" early in the day when willpower is highest.`
      : "Pick your most important task tonight and start with it tomorrow morning.";

  return {
    title: completionRate >= 80 ? "Strong week — keep the momentum" : "Room to grow — here's your plan",
    summary: summaryParts.join(" "),
    wins,
    next_action: nextAction,
  };
}

function buildSyntheticRow(options: {
  userId: string;
  body: ProgressSummaryRequest;
  generated?: ProgressSummaryResult;
}): ProgressSummaryRow {
  const generated = options.generated ?? buildFallbackSummary(options.body);
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    user_id: options.userId,
    period_start: options.body.period_start,
    period_end: options.body.period_end,
    title: generated.title,
    summary: generated.summary,
    wins: generated.wins.slice(0, 3),
    next_action: generated.next_action,
    created_at: now,
    updated_at: now,
  };
}

async function safeReadBody(req: Request): Promise<ProgressSummaryRequest | undefined> {
  try {
    return await req.json() as ProgressSummaryRequest;
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
  return trimmed.length > maxLength ? `${trimmed.slice(0, maxLength - 1)}...` : trimmed;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}
