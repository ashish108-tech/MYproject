export type ApiProvider = "supabase" | "ai" | "maps" | "email" | "sms";
export interface ApiProviderStatus { provider: ApiProvider; configured: boolean; phase: number; }
