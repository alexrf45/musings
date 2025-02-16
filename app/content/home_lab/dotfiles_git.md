---
title: "DevOps Demo 3 - Dotfiles Git Repo"
date: 2023-05-22
draft: false
summary: "A clean way to maintain important config files for your workstation."
---

# Summary

Tired of manually copying config files to your desktop or rewriting them everytime a new VM or machine is set up?

There is easy way to back up your dotfiles and other important config: Git!

Before we begin:

> [!IMPORTANT]
> Make sure to set up an empty public repo named dotfiles,
> ensure a README is created and credentials for git access are set up (if cloning via ssh)

> [!WARNING]
> DO NOT STORE API KEYS & OTHER SENSITIVE CREDENTIALS IN YOUR DOTFILES!

# Setup

Below are some quick steps to get it set up:

```bash

#this prevents you from commiting this directory to the repo creating a weird loop
echo ".cfg" >> .gitignore

#clones the repo to the .cfg directory
git clone --bare git@github.com:ORG/dotfiles.git $HOME/.cfg

#store this alias in your shell rc or alias file
alias dev='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

#cleans up your prompt so you only see untracked files when you explicitly ask for them
dev config --local status.showUntrackedFiles no
```

A few notes on the set up above:

- Refresh your shell after adding the alias:
  Example: `echo 'alias dev='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'' >> .bashrc OR .zshrc && . ~/.bashrc or . ~/.zshrc`

- Adding files to your repo goes as follows:
  Example: `dev add FILE`

- Commit Files:
  Example: `dev commit -a`

- Push to repo:
  Example: `dev push`

- Ensure the remote origin is configured to point to the dotfiles repo before the first push.

Here is a link to my public dotfiles for reference. [dotfiles](https://github.com/alexrf45/dotfiles)

Feel free to explore and see what works for you. Until next time, stay curious my friends!
