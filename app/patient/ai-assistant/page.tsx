"use client";

import { FormEvent, useState } from "react";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

export default function PatientAiAssistantPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      role: "assistant",
      content:
        "Hi, I’m DigiHealth’s AI health assistant. I can provide general health information and help you decide what kind of care may be appropriate. I cannot diagnose emergencies or prescribe medicines.",
    },
  ]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] = useState<string>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function sendMessage(event: FormEvent) {
    event.preventDefault();
    const message = input.trim();
    if (!message || loading) return;

    setInput("");
    setError("");
    setMessages((current) => [...current, { role: "user", content: message }]);
    setLoading(true);

    try {
      const response = await fetch("/api/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ conversationId, message }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error ?? "Unable to get a response");
      }

      setConversationId(data.conversationId);
      setMessages((current) => [
        ...current,
        { role: "assistant", content: data.message },
      ]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col px-4 py-8">
      <div className="mb-6">
        <p className="text-sm font-medium text-blue-600">DigiHealth</p>
        <h1 className="text-3xl font-bold">AI Health Assistant</h1>
        <p className="mt-2 text-sm text-slate-600">
          General health information and triage support. Not a diagnosis or emergency service.
        </p>
      </div>

      <section className="flex-1 space-y-4 rounded-2xl border bg-white p-4 shadow-sm">
        {messages.map((message, index) => (
          <div
            key={index}
            className={message.role === "user" ? "ml-auto max-w-[85%] rounded-2xl bg-blue-600 p-3 text-white" : "max-w-[85%] rounded-2xl bg-slate-100 p-3 text-slate-900"}
          >
            {message.content}
          </div>
        ))}

        {loading && (
          <div className="max-w-[85%] rounded-2xl bg-slate-100 p-3 text-slate-600">
            Thinking…
          </div>
        )}

        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
      </section>

      <form onSubmit={sendMessage} className="mt-4 flex gap-2">
        <input
          value={input}
          onChange={(event) => setInput(event.target.value)}
          maxLength={4000}
          placeholder="Describe your health concern…"
          className="min-w-0 flex-1 rounded-xl border px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          disabled={loading}
        />
        <button
          type="submit"
          disabled={loading || !input.trim()}
          className="rounded-xl bg-blue-600 px-5 py-3 font-medium text-white disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </main>
  );
}
