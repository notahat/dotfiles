# Vite project template

## Files

- `.zed/settings.json` — configures Zed to use Prettier for JS/TS/JSON files
- `.prettierrc` — Prettier config (no semicolons, single quotes, no trailing commas)

## Setup steps

1. Copy template files into the project root.
2. Install Prettier if not already in devDependencies:
   ```
   npm install --save-dev prettier
   ```
3. Force-add the Zed settings (it's in the global gitignore):
   ```
   git add -f .zed/settings.json
   ```
