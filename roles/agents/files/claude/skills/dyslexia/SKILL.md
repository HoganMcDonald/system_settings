---
name: dyslexia
description: Format responses for a reader with dyslexia. Use whenever the user invokes /dyslexia, types $dyslexia, or asks for dyslexia-friendly / dyslexic-friendly output. Once activated, apply these rules to the ENTIRE rest of the conversation (every subsequent response), not just the next message.
---

# Dyslexia-Friendly Output

The user has dyslexia. Once this skill activates, every later response in
this conversation must follow the rules below. Do not revert to your
default style after one reply.

## How dyslexic reading actually feels

Keep this picture in mind while you write. It is why the rules exist.

- Long, dense sentences are hard to parse. The reader runs out of
  working memory before the sentence ends.
- The same line gets re-read, often without the reader noticing. Short
  lines and clear breaks make that less likely.
- Reading happens in two passes: once to decode the words, once to
  understand them. Anything that helps the first pass (short words,
  short lines, plain phrasing) pays off twice.
- Walls of prose are exhausting. Whitespace, lists, and diagrams are
  rest stops.

## Writing rules

Apply all of these:

- One idea per sentence. Aim for under 15 words.
- Prefer common, short words. "Use" beats "utilize". "Start" beats
  "initiate".
- Active voice. Subject, verb, object.
- Break prose into short paragraphs (2-4 sentences max).
- Use bulleted or numbered lists for any sequence, set of options, or
  group of related facts.
- Bold key terms. Do not use italics or underline for emphasis - they
  are harder to read.
- Expand an acronym the first time you use it.
- Leave a blank line between paragraphs, lists, headings, and code
  blocks. Whitespace is not waste.
- Use headings (`##`, `###`) to break long answers into scannable
  sections.

## Use ASCII diagrams generously

Whenever you describe a flow, a structure, or a relationship, draw it.
A diagram lets the reader grasp the shape without re-parsing prose.

Good places to draw:

- Request / response flows
- File or module layout
- Decision branches
- Before / after states
- Data shape transformations

Example - a request flow:

```
  Client  --->  API  --->  Worker  --->  DB
                 |
                 v
                Cache
```

Example - a decision branch:

```
  input
   |
   +-- valid?  -- no --> return 400
   |
   yes
   |
   v
  process
```

Keep diagrams small. One screen, no scrolling.

## Show code, often

Code examples are easier to read than prose descriptions of code.
Whenever you explain a concept that has a concrete code form, show
the code first, then a short explanation.

Prefer:

- Small, complete snippets over long ones.
- One concept per snippet.
- A short caption after the snippet, not before, so the reader sees
  the code with fresh eyes.

Example:

```ts
const user = await db.user.findById(id)
if (!user) throw new NotFoundError()
return user
```

This is the "find or fail" pattern. The caller never gets `null`.

## When prose is unavoidable

Sometimes you have to write a paragraph. When you do:

- Front-load the point. First sentence states the conclusion.
- Each later sentence adds one supporting fact.
- End the paragraph before it spills past four sentences.

## What to avoid

- Long compound sentences joined by "and", "but", "which", "however".
- Nested clauses ("the thing that, when it does X, causes Y").
- Latinate / academic vocabulary when a plain word works.
- Italics, underline, or ALL CAPS for emphasis. Use **bold**.
- Walls of text with no headings, lists, or diagrams.
- Burying the answer at the end of a long explanation.

## References

The rules above draw on:

- British Dyslexia Association Style Guide (2023)
- University of Reading dyslexia writing guidance
- Rello & Baeza-Yates, "How to present more readable text for people
  with dyslexia" (Univ. Access Inf. Soc., 2015)
- "Shorter Lines Facilitate Reading in Those Who Struggle" (Schneps
  et al., PLoS ONE, 2013)
