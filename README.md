# config-setup

Remet toute ma config en place en une commande, sur Linux (Ubuntu/Debian) ou sur Windows avec WSL.

## Installation

```sh
sudo apt update && sudo apt install -y gh git
gh auth login
gh repo clone Kasouker/config-setup ~/config-setup
~/config-setup/install.sh
```

Puis se déconnecter et se reconnecter (pour passer à zsh), et ouvrir WezTerm.

Sous Windows, il faut d'abord installer WSL : dans PowerShell (admin), `wsl --install -d Ubuntu`, puis lancer les commandes ci-dessus dans Ubuntu.

Le script peut être relancé sans risque : il met à jour ce qui est déjà là. Un fichier qu'il remplace est gardé à côté, avec `.avant-install.<date>` à la fin de son nom.

## Ce qu'il installe

| Quoi | Où |
|---|---|
| zsh, neovim, fzf, eza, bat, ripgrep, fd, yazi, zoxide, tmux, pipx, gcc/make, zsh-autosuggestions, zsh-syntax-highlighting… | apt |
| starship, lazygit, nvm + Node LTS (typescript, pnpm, codex), Claude Code | leurs sources officielles |
| [nvim-config](https://github.com/Kasouker/nvim-config), [zsh-config](https://github.com/Kasouker/zsh-config), [starship-config](https://github.com/Kasouker/starship-config) | `~/.config/nvim`, `~/.config/zsh`, `~/.config/starship` |
| Plugins Neovim (versions de `lazy-lock.json`) et serveurs Mason (clangd, lua_ls, pyright, ts, html, css, jdtls, stylua) | Neovim |
| WezTerm, [wezterm-config](https://github.com/Kasouker/wezterm-config), [logtime.wezterm](https://github.com/Kasouker/logtime.wezterm), police IosevkaTerm Nerd Font | Linux : apt, `~/.config/wezterm`, `~/Projet_Perso`, `~/.local/share/fonts` — WSL : les mêmes, côté Windows (`%USERPROFILE%`) |

Les alias de projets (`home`, `Plouf`, `Arbre`…) pointent vers `~/Projet_Perso` sous Linux.
