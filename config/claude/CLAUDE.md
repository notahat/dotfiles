# Claude Instructions

Good code is code that is easy to understand. Everything else in these guidelines follows from that.

## Structure

- Prefer functional cohesion when grouping code — functions, methods, classes, and modules should each do one well-defined thing.
- The functional core, imperative shell pattern is a good default: push logic into pure functions, and keep side effects (reading, writing, I/O) at the edges. Adapt as needed for the paradigm.

## Function and Method Design

- A function should have a single, clearly defined job. If it's hard to name, it's probably doing too much.
- Keep functions under 35 lines. If you can't, that's a signal to break it up.
- Minimise the number of things a reader has to hold in their head at once — avoid deep nesting, complex conditionals, and functions that require understanding a lot of context to follow.
- Use guard clauses and early returns to reduce nesting.
- Be clear about whether a function is pure or has side effects. Prefer pure functions where possible.
- Keep parameter counts low. Only group parameters into a structure if they have a natural logical relationship worth expressing, not just to shorten an argument list.

## Naming

- Prioritise clarity over brevity. Avoid abbreviations.
- No single-letter names, even for loop variables.
- Boolean names should use prefixes like `is`, `has`, or `should` to make their type clear.
- Functions and methods should use verb-first names.
- Plural nouns for collections are fine; only disambiguate (e.g. `userList` vs `userMap`) when the data structure matters.
- Avoid generic words like "data", "info", "manager".
- Names should describe what something does, not what pattern or mechanism it uses internally. `UserCache` is fine; `UserCacheFactoryImpl` is not.
- Follow language and project conventions for casing, acronyms, and private member naming.

## Comments

- Always write in complete sentences with proper punctuation.
- Good comments explain *why* the code is the way it is, or capture context that the code itself can't convey.
- Classes and modules must always have a comment that makes their responsibilities clear — including what is explicitly out of scope, where that might otherwise be assumed.
- Functions and methods should generally have a header comment. Skip it if the name and signature make the intent completely obvious.
- Inline comments are fine, but always prefer making the code clear enough not to need them.
- Explaining non-obvious or complex code with a comment is fine, but prefer simplifying the code instead.
- Use language-appropriate doc comment formats.
- Commented-out code should not be committed unless accompanied by a comment explaining a compelling reason.
- Wrap comment text at 80 characters.

## Testing

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

## Project Templates

Templates for common project setups live in ~/.dotfiles/project-templates/, organised
by project type (e.g. vite/). When asked to install a template (e.g. "install my vite
config"), copy the template files into the current project directory and follow any
additional steps in the template's README.md.
