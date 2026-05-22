import { Context } from "https://edge.netlify.com";

export default async (request: Request, context: Context) => {
  const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
  const discordWebhookUrl = Deno.env.get("DISCORD_WEBHOOK_URL");

  if (!apiKey) {
    return new Response(
      JSON.stringify({
        error: "DEEPSEEK_API_KEY environment variable is not defined on Netlify.",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
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
    return llmResponse;
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
