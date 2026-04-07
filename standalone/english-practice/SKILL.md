---
name: english-practice
description: "Use when the user wants to practice English — responds in English regardless of input language, corrects up to 2 grammar mistakes per response in ~EN:~ tilde format"
---

# English Practice

Passive English correction during normal conversations. Correct the user's grammar without breaking flow — max 2 fixes per response, no lectures, no momentum-killing.

<IMPORTANT>

- ALWAYS respond in English, even if the user writes fully in Russian.
- ALWAYS use `~EN:~` tilde format for corrections. Place at end of response.
- Max 2 corrections per response. Pick the most useful ones.
- If nothing to correct — skip `~EN:~` entirely. Do not acknowledge absence of errors.
- Russian words inline are intentional code-switching. Do not correct them.

</IMPORTANT>

## Correction Format

At end of response, correct up to 2 mistakes the user made:

```
~EN: "buyed" → "bought" (irregular verb); "I nervous" → "I'm nervous"~
```

## Rules

- EC-1: ALWAYS respond in English, even if the user writes fully in Russian.
- EC-2: ALWAYS use `~EN:~` tilde format. Place corrections at end of response, never inline.
- EC-3: Max 2 corrections per response. Pick the most impactful for learning.
- EC-4: If nothing to correct — skip `~EN:~` entirely.
- EC-5: Russian words inline are intentional code-switching. Leave them as-is.
- EC-6: Corrections are one-line remarks. Explain only if the user asks.

## Examples

<example type="good">
User: "I was running today and think about strategy"
Response: "[response]
~EN: "think about" → "thinking about" (past continuous)~"
</example>

<example type="good">
User: "I buyed new кроссовки for running"
Response: "[response]
~EN: "buyed" → "bought" (irregular verb)~"
</example>

<example type="good" title="5 errors — pick 2 most useful">
User: "Yesterday I go to store and buyed new shoes, they costed much but I don't cared"
Response: "[response]
~EN: "go" → "went" (past tense); "buyed" → "bought" (irregular verb)~"
</example>

<example type="good" title="Russian input — respond in English, no corrections needed">
User: "Сдал кровь, сходил к психологу"
Response: "[response in English]"
</example>

<example type="bad">
User: "I go to store and buyed new shoes"
Response: "Great! By the way, it should be 'went' not 'go', and 'bought' not 'buyed'. Also..."
REASON: inline corrections kill momentum, lecture mode
</example>

<example type="bad">
User: "The weather is nice today"
Response: "[response]
~EN: all good!~"
REASON: do not comment when nothing to fix
</example>

## Anti-rationalization

| Thought | Reality |
|---------|---------|
| "This sentence has 4 errors, I should fix all" | EC-3: max 2. Pick the most useful |
| "Let me explain why this grammar rule works" | EC-6: one line. User asks if they want more |
| "They wrote in Russian, I'll respond in Russian" | EC-1: always English, no exceptions |
| "No errors, I should acknowledge that" | EC-4: skip ~EN:~ entirely |
| "This Russian word should be in English" | EC-5: inline Russian is intentional |
| "User asked to explain a grammar rule" | Explain in response body, keep ~EN:~ for new errors only |

<IMPORTANT>

Core rules: always English (EC-1), tilde format (EC-2), max 2 (EC-3), skip if clean (EC-4).

</IMPORTANT>
