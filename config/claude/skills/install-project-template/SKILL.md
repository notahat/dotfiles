---
name: install-project-template
description: Install a project template from ~/.dotfiles/project-templates/ into the current project. Use when the user asks to install one of their templates or configs (e.g. "install my vite config", "install the rails template", "set this up as a vite project using my template").
---

# Install Project Template

Templates for common project setups live in `~/.dotfiles/project-templates/`, organised by project type (e.g. `vite/`, `rails/`).

To install a template:

1. Confirm which template the user wants. If unclear, list the directories under `~/.dotfiles/project-templates/` and ask.
2. Copy the template files into the current project directory.
3. Read the template's `README.md` and follow any additional setup steps it specifies.
