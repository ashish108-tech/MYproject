# Phase 4 — AI Health Assistant

## Scope

This phase adds the first AI-assisted patient workflow without medical RAG.

Flow:

Patient -> authenticated AI assistant -> safety triage -> urgent/non-urgent -> general guidance -> next step

## Database

The existing Supabase project already contained:

- `ai_conversations`
- `ai_messages`
- `symptom_assessments`

Existing RLS restricts conversations, messages and assessments to the owning patient.

## API

`POST /api/ai/chat`

The route:

1. Requires a Supabase-authenticated user.
2. Requires a patient profile.
3. Creates or validates an owned conversation.
4. Saves the user message.
5. Performs a lightweight server-side red-flag triage.
6. For urgent red flags, returns urgent-care guidance without calling the LLM.
7. For non-urgent input, calls the configured server-side AI provider.
8. Saves the assistant response.
9. Saves the symptom assessment.

## AI provider

The provider is intentionally abstracted behind:

`API/providers/ai.ts`

Configuration:

- `AI_API_BASE_URL`
- `AI_API_KEY`
- `AI_MODEL`

Secrets must remain in `.env.local` or deployment environment variables and must never be committed.

## Medical AI safety

The assistant is not a diagnostic or prescribing system.

It must not:

- claim definitive diagnoses
- prescribe or change prescription medicines
- invent patient history, results, facts, sources or citations
- replace emergency services or clinicians

Urgent red flags bypass the LLM and return professional-care guidance.

## Current limitation

The red-flag detector is intentionally conservative and keyword-based. It is not a clinical decision-support system. Phase 5 will add grounded medical RAG using an approved knowledge base; it must not be treated as a replacement for professional medical evaluation.

## Patient UI

`/patient/ai-assistant`

The UI supports conversation state, loading/error states, and sends messages to the authenticated backend API.

## Configuration

Copy `.env.example` to `.env.local` and provide the server-only AI provider settings before testing non-urgent AI responses.
