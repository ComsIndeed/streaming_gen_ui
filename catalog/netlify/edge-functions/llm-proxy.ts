import { Context } from "https://edge.netlify.com";

// CORS Origin helper
function isAllowedOrigin(origin: string): boolean {
  if (!origin) return false;
  if (origin === "null") return true; // Support mobile/privacy browsers that strip or nullify origin
  if (origin.endsWith("vincentsanicolas.me")) return true; // Support any subdomain under vincentsanicolas.me
  if (origin.endsWith("streaming-gen-ui.netlify.app")) return true;
  if (origin.startsWith("http://localhost") || origin.startsWith("http://127.0.0.1")) {
    return true;
  }
  return false;
}

// In-memory rate limiting maps
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const dailyLimitMap = new Map<string, { count: number; resetTime: number }>();

const RATE_LIMIT_COUNT = 15; // Max 15 requests per minute
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute

const DAILY_LIMIT_COUNT = 60; // 60 requests per day (daily allowance)
const DAILY_LIMIT_WINDOW_MS = 24 * 60 * 60 * 1000; // 24 hours

function cleanMaps() {
  const now = Date.now();
  for (const [key, value] of rateLimitMap.entries()) {
    if (now > value.resetTime) {
      rateLimitMap.delete(key);
    }
  }
  for (const [key, value] of dailyLimitMap.entries()) {
    if (now > value.resetTime) {
      dailyLimitMap.delete(key);
    }
  }
}

function checkRateLimit(ip: string) {
  cleanMaps();
  const now = Date.now();

  // 1. Minute Limit check
  let minData = rateLimitMap.get(ip);
  if (!minData || now > minData.resetTime) {
    minData = { count: 0, resetTime: now + RATE_LIMIT_WINDOW_MS };
    rateLimitMap.set(ip, minData);
  }

  // 2. Daily Limit check
  let dailyData = dailyLimitMap.get(ip);
  if (!dailyData || now > dailyData.resetTime) {
    dailyData = { count: 0, resetTime: now + DAILY_LIMIT_WINDOW_MS };
    dailyLimitMap.set(ip, dailyData);
  }

  const minReset = Math.ceil((minData.resetTime - now) / 1000);
  const dailyResetHours = Math.ceil((dailyData.resetTime - now) / (60 * 60 * 1000));

  const headers = {
    "X-RateLimit-Limit": String(RATE_LIMIT_COUNT),
    "X-RateLimit-Remaining": String(Math.max(0, RATE_LIMIT_COUNT - minData.count - 1)),
    "X-RateLimit-Reset": String(minReset),
    "X-DailyLimit-Limit": String(DAILY_LIMIT_COUNT),
    "X-DailyLimit-Remaining": String(Math.max(0, DAILY_LIMIT_COUNT - dailyData.count - 1)),
    "X-DailyLimit-Reset-Hours": String(dailyResetHours),
  };

  if (minData.count >= RATE_LIMIT_COUNT) {
    return {
      allowed: false,
      reason: `Too many requests. Please try again in ${minReset} seconds.`,
      headers,
    };
  }

  if (dailyData.count >= DAILY_LIMIT_COUNT) {
    return {
      allowed: false,
      reason: `Daily prompt limit reached (${DAILY_LIMIT_COUNT} prompts/day). Reset in ${dailyResetHours} hours.`,
      headers,
    };
  }

  minData.count++;
  dailyData.count++;

  return { allowed: true, headers };
}

export default async (request: Request, context: Context) => {
  const requestOrigin = request.headers.get("origin") || "";
  const isOriginAllowed = isAllowedOrigin(requestOrigin);

  // 1. Enforce origin security for browsers
  if (requestOrigin && !isOriginAllowed) {
    return new Response(
      JSON.stringify({ error: "Unauthorized origin. Access denied." }),
      {
        status: 403,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
  }

  // 2. Setup CORS headers
  const corsOrigin = isOriginAllowed ? requestOrigin : "https://streaming.vincentsanicolas.me";
  const requestedHeaders = request.headers.get("access-control-request-headers") || "Content-Type, Authorization, X-Client-ID";
  const corsHeaders = {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": requestedHeaders,
  };

  // 3. Handle OPTIONS preflight request
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  // 4. Rate Limiting checks (Minute and Daily Allowance)
  const ip = context.ip || request.headers.get("x-nf-client-connection-ip") || "unknown";
  const limitResult = checkRateLimit(ip);

  if (!limitResult.allowed) {
    return new Response(
      JSON.stringify({ error: limitResult.reason }),
      {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
          ...limitResult.headers,
        },
      }
    );
  }

  // Parse and prepare LLM Endpoint / Credentials
  let requestBody = await request.text();
  const targetUrl = "https://api.deepseek.com/v1/chat/completions";
  const targetApiKey = Deno.env.get("DEEPSEEK_API_KEY");

  try {
    const bodyObj = JSON.parse(requestBody);
    bodyObj.model = "deepseek-chat";
    // Limit output generation to 50,000 tokens max to protect budget from loops
    bodyObj.max_tokens = Math.min(bodyObj.max_tokens || 50000, 50000);
    requestBody = JSON.stringify(bodyObj);
  } catch (_) {
    // Fallback if requestBody is not valid JSON
  }

  const apiKey = targetApiKey;
  const discordWebhookUrl = Deno.env.get("DISCORD_WEBHOOK_URL");

  if (!apiKey) {
    return new Response(
      JSON.stringify({
        error: "DEEPSEEK_API_KEY environment variable is not defined on Netlify.",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
          ...limitResult.headers,
        },
      },
    );
  }

  // Forward the request to the target API
  const llmResponse = await fetch(targetUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: requestBody,
  });

  if (!llmResponse.ok) {
    const errorBody = await llmResponse.text();
    return new Response(errorBody, {
      status: llmResponse.status,
      statusText: llmResponse.statusText,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
        ...limitResult.headers,
      },
    });
  }

  // Stream interceptor to extract usage metadata and guard against stuck infinite loops
  const reader = llmResponse.body?.getReader();
  if (!reader) {
    return llmResponse;
  }

  const textDecoder = new TextDecoder();
  let accumulatedText = "";
  let accumulatedOutputLength = 0;
  
  // Guard: Stop infinite loop outputs (max 200,000 characters streamed ~ 50,000 tokens)
  const MAX_OUTPUT_CHARS = 200000;

  const stream = new ReadableStream({
    async start(controller) {
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) {
            break;
          }
          
          accumulatedOutputLength += value.length;
          if (accumulatedOutputLength > MAX_OUTPUT_CHARS) {
            // Cut off the response stream forcefully to prevent infinite loops
            console.warn(`[Proxy Warning] Output stream exceeded character limit (${MAX_OUTPUT_CHARS}). Force closing.`);
            controller.close();
            break;
          }

          controller.enqueue(value);

          // Accumulate SSE chunks for parsing usage data
          const chunkStr = textDecoder.decode(value, { stream: true });
          accumulatedText += chunkStr;
        }

        if (accumulatedOutputLength <= MAX_OUTPUT_CHARS) {
          controller.close();
        }

        // Process token usage statistics asynchronously in the background
        processMetadata(accumulatedText, "deepseek-chat", discordWebhookUrl).catch((err) => {
          console.error("Error processing metadata or sending to Discord:", err);
        });
      } catch (error) {
        controller.error(error);
      }
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      ...corsHeaders,
      ...limitResult.headers,
    },
  });
};

async function processMetadata(accumulatedText: string, modelName: string, webhookUrl?: string) {
  const lines = accumulatedText.split("\n");
  let promptTokens = 0;
  let completionTokens = 0;
  let cachedTokens = 0;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith("data:")) {
      const dataStr = trimmed.substring(5).trim();
      if (dataStr === "[DONE]") continue;

      try {
        const parsed = JSON.parse(dataStr);
        if (parsed.usage) {
          promptTokens = parsed.usage.prompt_tokens ?? promptTokens;
          completionTokens = parsed.usage.completion_tokens ?? completionTokens;
          if (parsed.usage.prompt_tokens_details) {
            cachedTokens =
                parsed.usage.prompt_tokens_details.cached_tokens ?? cachedTokens;
          }
        }
      } catch (_) {
        // Safe skip non-JSON chunks or incomplete lines
      }
    }
  }

  const modelDisplayName = "DeepSeek V3";
  let costUSD = 0;

  // DeepSeek V3 pricing
  const cacheMissTokens = Math.max(0, promptTokens - cachedTokens);
  costUSD =
      (cachedTokens * 0.14 + cacheMissTokens * 0.55 + completionTokens * 2.19) /
      1000000;

  // USD to PHP Exchange Rate
  const exchangeRate = 58.50;
  const costPHP = costUSD * exchangeRate;

  console.log(
    `[LLM Usage] Model: ${modelDisplayName} | Prompt Tokens: ${promptTokens} (Cached: ${cachedTokens}) | Completion: ${completionTokens} | Cost: $${costUSD.toFixed(6)} (${costPHP.toFixed(4)} PHP)`,
  );

  if (!webhookUrl || webhookUrl.trim().length === 0) return;

  const payload = {
    embeds: [
      {
        title: `⚡ Generative UI Streaming Session (${modelDisplayName})`,
        color: 0x003fad, // Blue for DeepSeek
        fields: [
          {
            name: "📥 Prompt Tokens",
            value: `\`${promptTokens.toLocaleString()}\` tokens${cachedTokens > 0 ? ` (Cached: ${cachedTokens.toLocaleString()})` : ""}`,
            inline: true,
          },
          {
            name: "📤 Completion Generated",
            value: `\`${completionTokens.toLocaleString()}\` tokens`,
            inline: true,
          },
          {
            name: "💰 Session Cost (USD)",
            value: `\`$${costUSD.toFixed(6)}\``,
            inline: true,
          },
          {
            name: "🇵🇭 Session Cost (PHP)",
            value: `\`₱${costPHP.toFixed(4)}\``,
            inline: true,
          },
        ],
        timestamp: new Date().toISOString(),
        footer: {
          text: `Netlify Secure LLM Proxy | Model: ${modelDisplayName}`,
        },
      },
    ],
  };

  await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}
