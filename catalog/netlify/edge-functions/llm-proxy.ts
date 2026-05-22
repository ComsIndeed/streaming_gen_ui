import { Context } from "https://edge.netlify.com";

// CORS Origin helper
function isAllowedOrigin(origin: string): boolean {
  if (!origin) return false;
  if (origin === "https://streaming.vincentsanicolas.me") return true;
  if (origin.startsWith("http://localhost") || origin.startsWith("http://127.0.0.1")) {
    return true;
  }
  return false;
}

// In-memory rate limiting map and settings
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_COUNT = 15; // Max 15 requests per minute
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute

function cleanRateLimitMap() {
  const now = Date.now();
  for (const [key, value] of rateLimitMap.entries()) {
    if (now > value.resetTime) {
      rateLimitMap.delete(key);
    }
  }
}

function handleRateLimit(ip: string) {
  cleanRateLimitMap();
  const now = Date.now();
  const data = rateLimitMap.get(ip);

  if (!data || now > data.resetTime) {
    const resetTime = now + RATE_LIMIT_WINDOW_MS;
    rateLimitMap.set(ip, { count: 1, resetTime });
    return {
      allowed: true,
      remaining: RATE_LIMIT_COUNT - 1,
      reset: Math.ceil(RATE_LIMIT_WINDOW_MS / 1000),
    };
  }

  if (data.count >= RATE_LIMIT_COUNT) {
    return {
      allowed: false,
      remaining: 0,
      reset: Math.ceil((data.resetTime - now) / 1000),
    };
  }

  data.count++;
  return {
    allowed: true,
    remaining: RATE_LIMIT_COUNT - data.count,
    reset: Math.ceil((data.resetTime - now) / 1000),
  };
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
  const corsHeaders = {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  // 3. Handle OPTIONS preflight request
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  // 4. Rate Limiting check
  const ip = context.ip || request.headers.get("x-nf-client-connection-ip") || "unknown";
  const limitResult = handleRateLimit(ip);

  const rateLimitHeaders = {
    "X-RateLimit-Limit": String(RATE_LIMIT_COUNT),
    "X-RateLimit-Remaining": String(limitResult.remaining),
    "X-RateLimit-Reset": String(limitResult.reset),
  };

  if (!limitResult.allowed) {
    return new Response(
      JSON.stringify({ error: "Too many requests. Please try again in a minute." }),
      {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          "Retry-After": String(limitResult.reset),
          ...corsHeaders,
          ...rateLimitHeaders,
        },
      }
    );
  }

  const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
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
          ...rateLimitHeaders,
        },
      },
    );
  }

  // Clone request body to forward
  const requestBody = await request.text();

  // Forward the request to DeepSeek API
  const llmResponse = await fetch("https://api.deepseek.com/v1/chat/completions", {
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
        ...rateLimitHeaders,
      },
    });
  }

  // Stream interceptor to extract usage metadata without blocking response
  const reader = llmResponse.body?.getReader();
  if (!reader) {
    return llmResponse;
  }

  const textDecoder = new TextDecoder();
  let accumulatedText = "";

  const stream = new ReadableStream({
    async start(controller) {
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) {
            break;
          }
          controller.enqueue(value);

          // Accumulate SSE chunks for parsing usage data
          const chunkStr = textDecoder.decode(value, { stream: true });
          accumulatedText += chunkStr;
        }

        controller.close();

        // Process token usage statistics asynchronously in the background
        processMetadata(accumulatedText, discordWebhookUrl).catch((err) => {
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
      ...rateLimitHeaders,
    },
  });
};

async function processMetadata(accumulatedText: string, webhookUrl?: string) {
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

  const cacheMissTokens = Math.max(0, promptTokens - cachedTokens);

  // DeepSeek V3 API Pricing (as of latest spec):
  // Input Cache Hit: $0.14 / 1M tokens
  // Input Cache Miss: $0.55 / 1M tokens
  // Output: $2.19 / 1M tokens
  const costUSD =
      (cachedTokens * 0.14 + cacheMissTokens * 0.55 + completionTokens * 2.19) /
      1000000;

  // USD to PHP Exchange Rate
  const exchangeRate = 58.50;
  const costPHP = costUSD * exchangeRate;

  console.log(
    `[LLM Usage] Cache Hit: ${cachedTokens} | Cache Miss: ${cacheMissTokens} | Completion: ${completionTokens} | Cost: $${costUSD.toFixed(6)} (${costPHP.toFixed(4)} PHP)`,
  );

  if (!webhookUrl || webhookUrl.trim().length === 0) return;

  const payload = {
    embeds: [
      {
        title: "⚡ Generative UI Streaming Session Complete",
        color: 0x003fad, // BSOD Blue
        fields: [
          {
            name: "📥 Prompt Cache Hits",
            value: `\`${cachedTokens.toLocaleString()}\` tokens`,
            inline: true,
          },
          {
            name: "📥 Prompt Cache Misses",
            value: `\`${cacheMissTokens.toLocaleString()}\` tokens`,
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
          text: "Netlify Secure LLM Proxy",
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
