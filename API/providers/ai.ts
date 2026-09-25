export function getAiConfig() { return { configured: Boolean(process.env.AI_API_KEY && process.env.AI_MODEL), model: process.env.AI_MODEL ?? null, apiKey: process.env.AI_API_KEY }; }
