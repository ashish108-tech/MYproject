export function getSmsConfig() { return { configured: Boolean(process.env.SMS_API_KEY), apiKey: process.env.SMS_API_KEY }; }
