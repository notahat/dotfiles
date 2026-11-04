# Claude Instructions

Good code is code that is easy to understand. Everything else in these guidelines follows from that. When a specific rule below would make a piece of code harder to understand, the principle wins. If a project's CLAUDE.md conflicts with these rules, the project's wins.

## Structure

- Prefer functional cohesion when grouping code — functions, methods, classes, and modules should each do one well-defined thing.
- The functional core, imperative shell pattern is a good default: push logic into pure functions, and keep side effects (reading, writing, I/O) at the edges. Adapt as needed for the paradigm.

## Function and Method Design

- A function should have a single, clearly defined job. If it's hard to name, it's probably doing too much.
- Keep functions under 35 lines. If you can't, that's a signal to break it up. This applies to functions you're writing or editing — don't refactor untouched code to chase the limit.
- Minimise the number of things a reader has to hold in their head at once — avoid deep nesting, complex conditionals, and functions that require understanding a lot of context to follow.
- Use guard clauses and early returns to reduce nesting.
- Be clear about whether a function is pure or has side effects. Prefer pure functions where possible.
- Keep parameter counts low. Only group parameters into a structure if they have a natural logical relationship worth expressing, not just to shorten an argument list.

## Naming

- Try to establish a ubiquitous language for the project. Document project terms in a glossary.
- Once a word has a defined meaning in the project, use it only in that meaning.
- Prioritise clarity over brevity in names. Avoid abbreviations.
- Functions and methods should use verb-first names.
- No single-letter names, even for loop variables.
- Boolean names should use prefixes like `is`, `has`, or `should` to make their type clear.
- Plural nouns for collections are fine; only disambiguate (e.g. `userList` vs `userMap`) when the data structure matters.
- Avoid generic words like "data", "info", "manager".
- Names should describe what something does, not what pattern or mechanism it uses internally. `UserCache` is fine; `UserCacheFactoryImpl` is not.
- Follow language and project conventions for casing, acronyms, and private member naming.

## Comments

- Good comments capture context that the code itself can't convey, particularly explaining *why* the code is the way it is.
- Classes and modules must always have a comment that makes their responsibilities clear, and explains what the reader needs to understand their parts.
- Structure long header comments: the concept first, then the responsibilities.
- Always write in complete sentences with proper punctuation. Don't compress comments into fragments. Each sentence should name its subject.
- Comments describe the code as it is now, never how it used to be. Don't mention what was removed, renamed, or changed — that's what the git history is for.
- Functions and methods should have a header comment, including private helpers. Test cases are the exception — the test name carries the description. Test helpers (factories, fixtures, setup) still get headers.
- Inline comments are fine, but always prefer making the code clear enough not to need them.
- Explaining non-obvious or complex code with a comment is fine, but prefer simplifying the code instead.
- Use language-appropriate doc comment formats.
- Commented-out code should not be committed unless accompanied by a comment explaining a compelling reason.
- Wrap comment text at 80 characters.

## Testing

- For behavior changes, TDD: write a failing test (or a failing reproducer for a bug) before the fix, and verify it fails before implementing. Skip TDD when the change has no testable behavior (config, docs, formatting) or when no test framework exists in the codebase. For exploratory spikes, say so up front and write tests once the shape settles.
- Tests should give confidence that code behaves correctly, enabling changes to be made with confidence. Don't aim for a coverage target.
- Test public interfaces only. If you find yourself wanting to test private methods, that's a sign there's complexity that should be extracted.
- Avoid mocks and stubs except for external services and other infrastructure you don't control. Well-designed code should otherwise be testable without them.
- Favour the testing pyramid: the bulk of tests should be fast unit tests, with relatively few integration tests to verify things hang together.
- The functional core, imperative shell pattern keeps logic in pure functions that are easy to test; higher-level orchestration code should have little logic and need little testing.
- Tests should verify behaviour, not implementation. A test that just asserts the code does A, then B, then C adds no value.
- Test setup, execution, and assertion should appear in that order and be clearly distinguishable.
- Each test should test one thing, and be named clearly enough to reflect that. Use plain sentences where the framework allows (e.g. `returns an empty array when given empty input`).
- Avoid vague names (`worksCorrectly`, `handlesEdgeCase`) and redundant prefixes (`test`, `should`).
- Prefer plain language over technical terms in names (`returns nothing when given no input` over `returnsNullOnNullInput`).

## Error Handling

- Exceptions are for exceptional cases — something has genuinely gone wrong. Don't use them for general flow control.
- Never silently swallow errors or exceptions. Always handle or propagate them explicitly.
- Fail early. It's better to surface an error clearly at the point it occurs than to recover and continue in an unknown state.
- Follow language conventions for error handling style (exceptions, error return values, etc.).

## Planning

When working in plan mode:
- The plan should be broken into incremental steps, with each step including tests where appropriate, and with review and commit happening at the end of each step. The idea is to keep commits a sensible size.
- The plan should be written to a markdown file in the project, and committed before we start work.
- Include preparatory refactoring in the plan.

## Tools

- Prefer editing files directly over using the shell to create, read, or update files.
- Keep shell commands simple enough that I can understand them at a glance when asked to approve them. Prefer running commands individually over chaining them. Chained commands are harder to read, and they don't match permission allow rules, so they trigger more prompts.
- Prefer `rg` to `grep` for finding files by content.
- If you can't find `psql`, try `psql-18`. Ditto for other Postgres tools.
