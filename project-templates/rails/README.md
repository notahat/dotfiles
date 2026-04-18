# Rails project template

## Files

- `.zed/settings.json` — configures Zed to use ruby-lsp for Ruby, ERB, and related file types
- `.zed/tasks.json` — adds a Zed task to run a single Rails test by name

## Setup steps

1. Copy template files into the project root.

2. Add the ruby-lsp gems:
   ```
   bundle add ruby-lsp --group development --require false
   bundle add ruby-lsp-rails --group development --require false
   ```
