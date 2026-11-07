# Writing code

The goal is simple code a reader can understand quickly. When a rule here would
make code more complex or harder to understand, ignore the rule. If a
project's CLAUDE.md conflicts with this one, the project's wins.

## Do less

- Solve the problem in front of you. Don't add options, hooks, abstractions or
  configuration for needs nobody has stated.
- Don't add an abstraction until there are two or three real uses for it. A
  little duplication is cheaper than the wrong abstraction.
- Don't guard against things that can't happen. Validate input where it enters
  the system, then trust it inside.
- Stay in scope. If you notice something else worth fixing, mention it instead
  of fixing it.
- Delete code that's no longer used rather than leaving it in case it's needed.

## Make it obvious

- Prefer plain, boring code to clever code. Use the language's ordinary idioms.
- Aim for functional cohesion: give each function, class and module one clear
  job. If it's hard to name, it's doing too much.
- Keep functions small enough to read in one go.
- Minimise what a reader has to hold in their head: shallow nesting, simple
  conditionals, little hidden context.
- Keep parameter counts low. Group parameters only when they belong together,
  not just to shorten the list.
- Use a functional core, imperative shell: keep logic in pure functions and
  push side effects to the edges.
- Follow the patterns already in the codebase, even if you'd do it differently
  from scratch.

## Names

- Name things for what they mean in the problem domain. Use one name per
  concept, and use it everywhere. Record project terms in `GLOSSARY.md`.
- Use full words: no abbreviations, no single letters, even for loop variables.
- Start function names with a verb. Start booleans with `is`, `has` or
  `should`.
- Avoid vague words like "data", "info" and "manager", and don't name things
  after patterns, as in `UserCacheFactoryImpl`.
- Follow the language's conventions for casing and private members.

## Comments

- Make the code explain itself first. Comments carry what the code can't: why
  it's like this, and what a caller needs to know.
- Put each comment next to the code it describes.
- Describe the code as it is now. No history, no references to planning docs,
  no commented-out code without a stated reason.
- Write short, complete sentences, wrapped at 80 characters. Name the subject
  unless it's the thing being documented. Don't use "it" or "this" where they
  could mean more than one thing.
- Use the language's doc comment format.

Every class and module gets a header comment, so a reader who opens the file
knows what it is and how to think about it. Give the concept in domain terms,
its responsibilities and what it deliberately doesn't do, how it fits with its
neighbours, its invariants or required order of use, and why it exists if
that's not obvious. Add a short example if the usage isn't obvious. Don't list
methods. Someone should be able to use the class correctly after reading only
the header.

Every function gets a header comment for its callers, except test cases. Say
what it does in terms of the caller's goal, what the signature can't express
(units, ranges, empty or missing values, ownership), side effects, how it
fails, and why, when that isn't obvious. Don't restate the name or the types.
The comment should stay true if the body is rewritten with the same behaviour.
Length follows need: one line for a trivial helper, a paragraph for tricky
edge cases.

If either comment is hard to write, the code is probably doing too much.

## Errors

- Fail early and loudly. Never swallow errors or substitute silent defaults.
- Use exceptions for things that have gone wrong, not for flow control. Follow
  the language's conventions for error handling.

## Tests

- For a behaviour change, use TDD: write a failing test first and watch it
  fail. Skip TDD when there's nothing testable or no test framework. For a
  spike, say so up front and add tests once the shape settles.
- Test behaviour through public interfaces. Wanting to test a private method
  means something should be extracted.
- Only mock things you don't control, like external services.
- Most tests should be fast unit tests of the pure logic. A few integration
  tests cover the edges.
- Each test checks one thing, with setup, action and assertion in that order.
  Name it with a plain sentence: `returns nothing when given no input`.

## Planning

- Break plans into small steps, each with its tests. Stop for review at the
  end of each step, then commit.
- Write the plan to a markdown file in the project and commit it before
  starting. Include any preparatory refactoring as its own step.

## Tools

- Use the Read, Edit and Write tools, not shell commands, to read or change
  files.
- Keep shell commands simple enough to approve at a glance. Run them one at a
  time rather than chaining them.
- Use `rg` rather than `grep`. If `psql` is missing, try `psql-18`, and the
  same for other Postgres tools.

## Before you finish

- Reread the diff as a reviewer would. Remove anything that isn't needed for
  the change.
