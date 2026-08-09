---
name: diataxis
description: Apply the Diátaxis framework — tutorials, how-to guides, reference, explanation — when writing or revising user-facing documentation. Use whenever writing a README, a guide, a tutorial, API docs, or anything under docs/, and when existing docs feel muddled and need sorting out.
---

# Diátaxis

Diátaxis (https://diataxis.fr/) sorts documentation into four kinds:
tutorials, how-to guides, reference, and explanation. Each serves a
different user need, and a document that mixes two of them serves
neither well. The framework's value is in deciding, for each document,
which one kind it is — and then writing that kind properly.

Work one document at a time. Diátaxis is not an information
architecture to be laid out in advance and filled in later.

## Never scaffold the four kinds

Asked to "write the docs" for a project, the tempting move is to
create `docs/tutorials/`, `docs/how-to/`, `docs/reference/`, and
`docs/explanation/` with a stub in each. Don't. The framework names
this as the mistake to avoid: it "certainly does not mean that you
should create empty structures for tutorials/howto guides/reference/
explanation with nothing in them."

Structure accumulates from documents that were each worth writing. A
project with three how-to guides and no tutorial is in a fine state if
nobody needed a tutorial. Four thin documents written to fill four
boxes is a worse state than one good one.

So: identify a real need, write the one document that meets it, put it
somewhere sensible, and stop. Repeat when there's another need.

## The compass

For the document in hand, ask two questions:

1. Does it inform **action** (practical steps) or **cognition**
   (theoretical knowledge)?
2. Does it serve **acquisition** (the reader is studying, building
   skill) or **application** (the reader is working, with a goal
   already in mind)?

|                 | Acquisition — study | Application — work |
| --------------- | ------------------- | ------------------ |
| **Action**      | Tutorial            | How-to guide       |
| **Cognition**   | Explanation         | Reference          |

The compass also works at smaller scales. If a section, a paragraph,
or even a sentence feels wrong in a document that's otherwise sound,
run it through the same two questions — usually it belongs in a
different kind and should be cut or moved.

State the verdict and get on with writing. Only ask the user when a
document is genuinely poised between two kinds and the choice changes
what gets written.

## Start from a need, not a feature list

Derive documents from what someone is trying to do, not from the
product's surface. Walking the module list and writing a page per
module produces reference material nobody asked for and misses every
task that spans two modules.

One need often yields more than one document, and that's correct.
"How do I authenticate?" can want a how-to for the task, a reference
entry for the available options, and an explanation of why the token
model works the way it does. That's three documents because there are
three distinct needs, not because there are four boxes to fill.

## Tutorials

A lesson. The reader is a beginner who doesn't yet know what they
need to know, and the point is that they finish having done something
and gained confidence.

- It must work, every time, for every reader. A tutorial that breaks
  in the middle has failed completely — test it end to end.
- Every step produces a visible result the reader can check against.
  Show the actual expected output.
- No explanation. Link it out for afterwards; the reader can't absorb
  it now.
- No choices, options, or alternatives. One path.
- Stay concrete. Resist generalising — the general case emerges from
  the particular one later.
- First person plural and plain imperatives: "First we create…",
  "Now run…", "Notice that…".

## How-to guides

A recipe for a competent reader who already knows what they want.

- Title it with an explicit "How to…". Not "Integrating monitoring" —
  "How to integrate application performance monitoring".
- Address a real task, narrowly. "How to build a web app" is too
  broad to be useful; "How to configure reconnection back-off" is a
  guide.
- Usability beats completeness. Omit whatever isn't needed for this
  task and link to reference for the rest.
- No teaching, no background, no history.
- Conditional imperatives handle real-world variation: "If you want
  x, do y."
- It can start and end anywhere reasonable. Unlike a tutorial it
  needn't be self-contained; the reader will fit it into their own
  work.

## Reference

A description of the machinery. The reader consults it mid-task and
needs to be able to trust it.

- Mirror the structure of the product, so navigating the docs feels
  like navigating the code.
- Describe, and only describe. Facts: commands, options, flags,
  limits, error messages, behaviour.
- Be austere. Neutral, factual, consistent — the same shape for every
  entry. Reference is not the place for engaging prose.
- Accuracy and completeness are the whole job.
- Examples are fine where they illustrate. They must not instruct —
  link to a how-to for that.
- No explanation, no opinion, no instruction.

## Explanation

Discussion of a topic, read away from the keyboard. It answers "why".

- Reach for it when the honest answer to something is *why*, not
  *how*: design decisions, historical reasons, constraints, trade-offs.
- Give it a bounded topic, with an implicit "about" in the title —
  "About user authentication". The boundary keeps it from swallowing
  material that belongs elsewhere.
- Cover the alternatives that were rejected and why, not just the
  path taken.
- Opinion is allowed here, and should be owned as opinion. Weigh
  positions rather than asserting one.
- Make connections outward to related topics.
- No instructions and no technical description — those are how-to and
  reference.

## When a request straddles two kinds

Split it, and say so. "Document the deploy process" usually wants a
how-to for running a deploy and an explanation of why deploys are
staged the way they are. Writing both, separately, is the right
answer; writing one document that lurches between them is the failure
the framework exists to prevent.

Where an existing document is the muddle, the same applies: name what
kind each part is, and propose the split before rewriting.

## Not covered by this skill

Diátaxis is for documentation read by humans learning or using a
product. Don't apply it to:

- `CLAUDE.md`, `AGENTS.md`, or `SKILL.md` files — these are written
  for agents and follow different rules.
- Architecture decision records, and the plan files in `docs/plans`.
- Code comments, commit messages, and PR descriptions.

This skill governs the shape of a document — which kind it is and
what belongs in it. It says nothing about sentence-level prose
quality; `stop-slop` covers that, and applies on top of this.
