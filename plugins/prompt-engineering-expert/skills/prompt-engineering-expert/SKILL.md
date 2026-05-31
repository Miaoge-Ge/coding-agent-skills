---
name: prompt-engineering-expert
description: "Expert prompt engineering: prompt structure, few-shot, chain-of-thought, structured output, and iteration. Trigger keywords: prompt, prompt engineering, system prompt, few-shot, chain-of-thought, output format, JSON schema, structured output, instructions, role, examples, eval. Use for writing, debugging, or optimizing prompts for LLMs."
---

# Prompt Engineering Expert

> Examples beat adjectives; structure beats length. Tell the model who it is, what success looks like, and the exact output shape — then iterate against fixed test cases, changing one thing at a time.

## When to Use
- Writing or improving a system/user prompt.
- Inconsistent, off-format, verbose, or low-quality model output.
- Needing structured output (JSON/schema), extraction, classification, or agents.
- Reducing hallucination or steering tone/length/reasoning.

## When NOT to Use
- Retrieval/context assembly → `rag-expert`.
- Quantitative eval/regression harness → `llm-testing-expert`.
- Model training/fine-tuning → `deep-learning-expert`.
- Anthropic SDK wiring + caching → `claude-api` (built-in).

## Core Principles

### 1. Structure the prompt
- State **role, task, and success criteria** explicitly. Durable rules → system prompt; the variable task/data → user turn.
- Separate sections with clear delimiters (markdown headings or XML-like tags `<context>…</context>`) so instructions, data, and examples don't blur.
- Be specific about constraints: length, tone, audience, and what to do on ambiguity or missing info. Prefer positive instructions ("respond in valid JSON") over a pile of "don't".

### 2. Steer with examples & reasoning
- **Few-shot**: 2–5 representative, diverse examples that demonstrate the exact format and tricky edge cases. Examples teach format faster than descriptions.
- For reasoning-heavy tasks, let the model think before answering (chain-of-thought / a scratchpad), but keep the **final** output concise — or separate reasoning from the user-visible answer.
- Put the most important instruction near the start or end; long middles get "lost".

### 3. Reliable structured output
- For machine consumption, define a strict schema and use the provider's structured-output/JSON mode or tool-calling. Show **one** example of the exact shape.
- Provide a fallback so the model doesn't invent values: "if a field is unknown, use null; do not guess."

### 4. Iterate like an engineer
- Build a small fixed test set including hard/adversarial cases. Change **one variable at a time**, compare outputs, and **version** prompts. Don't trust a single lucky run.
- Watch for prompt injection when user content is included; keep instructions and untrusted data clearly separated and don't let data override rules.

## Common Mistakes
- **Vague asks** ("make it good") → specify criteria, format, length.
- **Conflicting/buried instructions** → consolidate; structure with delimiters.
- **No examples for format-sensitive tasks** → add few-shot.
- **Forcing CoT into the user-facing answer** → separate or hide reasoning.
- **Over-stuffing** the prompt → signal drops; trim to what changes behavior.
- **Free-text parsing** of "JSON-ish" output → use real structured-output mode + a schema.
- **Tuning on one example** → use a test set; one input overfits.

## Examples

**Structured extraction with schema + fallback**
```text
System: You extract structured data. Output ONLY valid JSON matching the schema.
Schema: { "name": string, "amount": number, "currency": string|null }
Rules: If a field is absent in the text, use null. Do not guess or add fields.

User:
<text>
Invoice from Acme Corp for $1,250.00, net 30.
</text>
```
Expected: `{ "name": "Acme Corp", "amount": 1250.0, "currency": "USD" }`

**Few-shot classifier (format by example)**
```text
Classify sentiment as positive | neutral | negative.
"Loved it" -> positive
"It arrived" -> neutral
"Broke in a day" -> negative
"Does the job, nothing special" ->
```

## See Also
- `rag-expert` — grounding prompts with retrieved, cited context.
- `llm-testing-expert` — evaluating prompt changes objectively.
- `claude-api` (built-in) — Anthropic SDK, tool use, and prompt caching.
