export function getMapsConfig() { return { configured: Boolean(process.env.GOOGLE_MAPS_API_KEY), apiKey: process.env.GOOGLE_MAPS_API_KEY }; }
