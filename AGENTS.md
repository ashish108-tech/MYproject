# DigiHealth Agent Instructions

## Fixed stack
Next.js App Router, TypeScript, Tailwind CSS, shadcn/ui-compatible components, Lucide, Supabase, Vercel.

## Phase isolation
Implement only the approved phase. Do not add future healthcare functionality early.

## Security
Never commit .env.local or secrets. Never expose Supabase secret/service-role keys to the browser. Enforce authorization server-side and with RLS once database work begins. Validate ownership on protected operations.

## Medical AI safety
No definitive diagnosis or autonomous prescribing. Do not fabricate medical facts or citations. Urgent concerns must be directed to appropriate professional/emergency care.

## API configuration
API/ documents provider configuration only. Real secrets belong in .env.local or deployment secrets.

## Verification
Run npm run typecheck and npm run build before completing a phase when a local environment is available.

## Git
Use phase-specific commits such as feat(phase-01): establish DigiHealth project foundation.
