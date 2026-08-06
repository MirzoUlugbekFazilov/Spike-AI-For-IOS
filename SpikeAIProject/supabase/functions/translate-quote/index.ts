import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return json("ok", 200);
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseKey = getPublishableKey();
  const hfToken = Deno.env.get("HF_TOKEN");

  if (!supabaseUrl || !supabaseKey) {
    return json({ error: "Server not configured" }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: user, error: userErr } = await supabase.auth.getUser();
  if (userErr || !user.user) {
    return json({ error: "Invalid session" }, 401);
  }

  let body: {
    quote_index: number;
    text: string;
    author: string;
    language: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  if (
    typeof body.quote_index !== "number" ||
    typeof body.text !== "string" ||
    typeof body.author !== "string" ||
    typeof body.language !== "string" ||
    body.text.length > 500 ||
    body.author.length > 100 ||
    body.language.length > 5
  ) {
    return json({ error: "Invalid request" }, 400);
  }

  // If English, return as-is
  if (body.language === "en") {
    return json({
      translated_text: body.text,
      translated_author: body.author,
    });
  }

  // Check cache first
  try {
    const { data: cached } = await supabase
      .from("quote_translations")
      .select("translated_text, translated_author")
      .eq("quote_index", body.quote_index)
      .eq("language", body.language)
      .maybeSingle();

    if (cached) {
      return json(cached);
    }
  } catch {
    // Cache miss, continue to translate
  }

  // Translate using HuggingFace
  const langMap: Record<string, string> = {
    es: "Spanish", fr: "French", de: "German", pt: "Portuguese",
    ru: "Russian", uz: "Uzbek", zh: "Chinese (Simplified)", ja: "Japanese",
    ko: "Korean", ar: "Arabic", hi: "Hindi", tr: "Turkish", it: "Italian",
    pl: "Polish", uk: "Ukrainian", nl: "Dutch", sv: "Swedish",
    id: "Indonesian", th: "Thai", vi: "Vietnamese", ms: "Malay",
    tg: "Tajik", kk: "Kazakh",
  };

  const targetLang = langMap[body.language] || "English";
  let translatedText = body.text;
  let translatedAuthor = body.author;
  let didTranslate = false;

  if (!hfToken) {
    console.error("[translate-quote] HF_TOKEN is not set — cannot translate");
    return json({
      translated_text: body.text,
      translated_author: body.author,
      untranslated: true,
    });
  }

  const prompt = `Translate ONLY the quote text into ${targetLang}. Keep the same tone and meaning. Do NOT translate the author's name — keep it exactly as provided. Return ONLY the translation in this exact format:
QUOTE: <translated quote>
AUTHOR: ${body.author}

Original quote: "${body.text}"`;

  // Tried in order, all verified as live on the HF router.
  // Note: do NOT reintroduce google/gemma-2-2b-it — the router stopped serving
  // it, which silently left every quote untranslated.
  const MODELS = [
    "Qwen/Qwen2.5-72B-Instruct:cheapest",
    "meta-llama/Llama-3.3-70B-Instruct:cheapest",
    "Qwen/Qwen2.5-7B-Instruct:cheapest",
  ];

  for (const model of MODELS) {
    if (didTranslate) break;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20_000);

    try {
      const response = await fetch(
        "https://router.huggingface.co/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: `Bearer ${hfToken}`,
          },
          signal: controller.signal,
          body: JSON.stringify({
            model,
            temperature: 0.15,
            max_tokens: 300,
            messages: [
              {
                role: "system",
                content: `You are a professional translator. Translate the quote text accurately into ${targetLang}. NEVER translate or modify the author's name — always keep it exactly as provided. Return ONLY the format requested.`,
              },
              { role: "user", content: prompt },
            ],
          }),
        }
      );

      if (response.ok) {
        const payload = await response.json();
        const text =
          typeof payload.choices?.[0]?.message?.content === "string"
            ? payload.choices[0].message.content.trim()
            : "";

        const quoteLine = text
          .split(/\r?\n/)
          .find((l: string) => l.toUpperCase().startsWith("QUOTE:"));

        if (quoteLine) {
          translatedText = quoteLine.replace(/^QUOTE:\s*/i, "").trim();
          // Remove surrounding quotes if the model added them
          if (
            (translatedText.startsWith('"') && translatedText.endsWith('"')) ||
            (translatedText.startsWith("\u201c") &&
              translatedText.endsWith("\u201d"))
          ) {
            translatedText = translatedText.slice(1, -1).trim();
          }
          // Only mark as translated if text actually changed
          if (translatedText && translatedText !== body.text) {
            didTranslate = true;
          }
        }
        // Always keep the original author name
        translatedAuthor = body.author;
      } else {
        console.error(`[translate-quote] ${model}:`, response.status, await response.text());
      }
    } catch (err) {
      console.error(`[translate-quote] ${model} failed:`, err);
    } finally {
      clearTimeout(timeout);
    }
  }

  // Only cache if we actually got a real translation
  if (didTranslate) {
    try {
      await supabase.from("quote_translations").upsert(
        {
          quote_index: body.quote_index,
          language: body.language,
          translated_text: translatedText,
          translated_author: translatedAuthor,
        },
        { onConflict: "quote_index,language" }
      );
    } catch {
      // Non-critical
    }
  }

  return json({
    translated_text: translatedText,
    translated_author: translatedAuthor,
    untranslated: !didTranslate,
  });
});

function getPublishableKey() {
  const legacy = Deno.env.get("SUPABASE_ANON_KEY");
  if (legacy) return legacy;
  const keys = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (!keys) return undefined;
  try {
    const parsed = JSON.parse(keys) as Record<string, string>;
    return parsed.default ?? Object.values(parsed)[0];
  } catch {
    return undefined;
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}
