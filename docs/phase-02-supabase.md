# Phase 2 — Supabase Integration

The existing Supabase **healthcare** project (ref: `rvtueepnwzicdmnhwwys`, region: `ap-south-1`) is the intended backend. Phase 2 adds the SSR client architecture only; no healthcare tables are created.

## Local environment
Create `.env.local` in the repository root:

```env
NEXT_PUBLIC_SUPABASE_URL=<your healthcare project URL>
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<your healthcare publishable key>
SUPABASE_SECRET_KEY=<server-only secret if required later>
```

Never commit `.env.local` or a Supabase secret/service-role key.

## Client architecture
- `lib/supabase/client.ts` — browser client
- `lib/supabase/server.ts` — Server Component/Route Handler client
- `lib/supabase/proxy.ts` — session refresh helper
- `proxy.ts` — Next.js proxy entry point

Authentication and healthcare schema work remain in later phases.
