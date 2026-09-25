export function getEmailConfig() { return { configured: Boolean(process.env.EMAIL_API_KEY), apiKey: process.env.EMAIL_API_KEY }; }
