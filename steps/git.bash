# shellcheck shell=bash

mkdir -p ~/.config/git
link_file config/git/ignore ~/.config/git/ignore
touch ~/.config/git/config

git config --global user.name "Pete Yandell"
git config --global user.email "pete@notahat.com"
git config --global github.user notahat
git config --global difftool.prompt false
git config --global color.ui true
git config --global core.excludesfile "$HOME/.config/git/ignore"
git config --global init.defaultBranch main

# Use 1Password for commit signing.
git config --global user.signingkey 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2BA/e0q3tXws2U27FUJYj0x+Td0muwZMdJtpJu5lAi'
git config --global gpg.format ssh
git config --global gpg.ssh.program /Applications/1Password.app/Contents/MacOS/op-ssh-sign
git config --global commit.gpgsign true

# Make git push only push the current branch.
git config --global push.default current

# Make new branches do a rebase on git pull.
git config --global branch.autosetuprebase always
git config --global merge.defaultToUpstream true

# Helpful aliases.
git config --global alias.root '!pwd'
git config --global alias.merged '!git branch --merged | grep -vF "* "'
git config --global alias.prune-merged '!git merged | xargs git branch -D'
