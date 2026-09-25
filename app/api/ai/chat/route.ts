import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  generateAiResponse,
  getAiConfig,
  type AiChatMessage,
} from "@/API/providers/ai";
import {
  HEALTH_ASSISTANT_SYSTEM_PROMPT,
  triageSymptoms,
} from "@/lib/ai/safety";

type ChatBody = {
  conversationId?: string;
  message?: string;
};

export async function POST(request: Request) {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  const body = (await request.json()) as ChatBody;
  const message = body.message?.trim();

  if (!message) {
    return NextResponse.json({ error: "Message is required" }, { status: 400 });
  }

  if (message.length > 4000) {
    return NextResponse.json({ error: "Message is too long" }, { status: 400 });
  }

  const { data: patient } = await supabase
    .from("patients")
    .select("id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!patient) {
    return NextResponse.json(
      { error: "Only registered patients can use the health assistant" },
      { status: 403 },
    );
  }

  let conversationId = body.conversationId;

  if (conversationId) {
    const { data: conversation } = await supabase
      .from("ai_conversations")
      .select("id")
      .eq("id", conversationId)
      .eq("patient_id", patient.id)
      .maybeSingle();

    if (!conversation) {
      return NextResponse.json({ error: "Conversation not found" }, { status: 404 });
    }
  } else {
    const { data: conversation, error } = await supabase
      .from("ai_conversations")
      .insert({ patient_id: patient.id, title: message.slice(0, 80) })
      .select("id")
      .single();

    if (error || !conversation) {
      return NextResponse.json({ error: "Could not create conversation" }, { status: 500 });
    }

    conversationId = conversation.id;
  }

  const triage = triageSymptoms(message);

  const { data: history } = await supabase
    .from("ai_messages")
    .select("role,content")
    .eq("conversation_id", conversationId)
    .eq("patient_id", patient.id)
    .order("created_at", { ascending: true })
    .limit(20);

  const aiMessages: AiChatMessage[] = [
    { role: "system", content: HEALTH_ASSISTANT_SYSTEM_PROMPT },
    ...(history ?? []).map((item) => ({
      role: item.role as AiChatMessage["role"],
      content: item.content,
    })),
    { role: "user", content: message },
  ];

  const { error: userMessageError } = await supabase.from("ai_messages").insert({
    conversation_id: conversationId,
    patient_id: patient.id,
    role: "user",
    content: message,
  });

  if (userMessageError) {
    return NextResponse.json({ error: "Could not save message" }, { status: 500 });
  }

  let assistantContent: string;

  if (triage.classification === "urgent") {
    assistantContent =
      `This may require urgent medical attention. ${triage.recommendedNextStep} I can provide general information, but I cannot diagnose or treat an emergency.`;
  } else {
    if (!getAiConfig().configured) {
      return NextResponse.json(
        {
          error:
            "AI provider is not configured. Add AI_API_BASE_URL, AI_API_KEY and AI_MODEL to .env.local.",
        },
        { status: 503 },
      );
    }

    try {
      assistantContent = (await generateAiResponse(aiMessages)).content;
    } catch {
      return NextResponse.json(
        { error: "The AI service is temporarily unavailable. Please try again." },
        { status: 502 },
      );
    }
  }

  const { error: assistantMessageError } = await supabase.from("ai_messages").insert({
    conversation_id: conversationId,
    patient_id: patient.id,
    role: "assistant",
    content: assistantContent,
  });

  if (assistantMessageError) {
    return NextResponse.json(
      { error: "AI response was generated but could not be saved" },
      { status: 500 },
    );
  }

  const { error: assessmentError } = await supabase
    .from("symptom_assessments")
    .insert({
      conversation_id: conversationId,
      patient_id: patient.id,
      classification: triage.classification,
      red_flags: triage.redFlags,
      recommended_next_step: triage.recommendedNextStep,
    });

  if (assessmentError) {
    return NextResponse.json(
      { error: "Assessment could not be saved" },
      { status: 500 },
    );
  }

  return NextResponse.json({
    conversationId,
    classification: triage.classification,
    redFlags: triage.redFlags,
    recommendedNextStep: triage.recommendedNextStep,
    message: assistantContent,
  });
}
