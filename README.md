# config-setup

Remet toute ma config en place en une commande, sur Linux ou sur Windows avec WSL. **Pas besoin de sudo** : tout s'installe dans `~/.local`.

## Installation

```sh
# 1. gh, dans ~/.local/bin
mkdir -p ~/.local/bin && cd /tmp
curl -sL "$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep -o 'https://[^"]*linux_amd64\.tar\.gz' | head -1)" | tar -xz
mv gh_*_linux_amd64/bin/gh ~/.local/bin/ && export PATH="$HOME/.local/bin:$PATH"

# 2. Connexion à GitHub (config-setup, zsh-config et starship-config sont privés), puis installation
gh auth login
gh repo clone Kasouker/config-setup ~/config-setup && ~/config-setup/install.sh
```

Puis fermer le terminal et ouvrir WezTerm.

Sous Windows, il faut d'abord installer WSL : dans PowerShell (admin), `wsl --install -d Ubuntu`.

Le script peut être relancé sans risque : il garde ou met à jour ce qui est déjà là. Un fichier qu'il remplace est gardé à côté, avec `.avant-install.<date>` à la fin de son nom.

## Si une partie est déjà installée

Pas besoin de rien enlever avant : le script **saute ce qui est déjà là**.

- **Les outils** (nvim, fzf, lazygit…) : gardés s'ils sont déjà installés, même avec sudo ou `apt`. Attention, la config nvim demande **Neovim 0.11 ou plus** (`nvim --version`).
- **WezTerm** : gardé s'il est déjà installé (`wezterm` sous Linux, `C:\Program Files\WezTerm` sous Windows). La config est testée avec la **nightly** `20261005` ; avec la version stable `20240203` (celle d'`apt` ou du site), elle devrait marcher mais n'a jamais été testée. Vérifie avec `wezterm --version` et, en cas d'erreur au lancement, installe la nightly.
- **La police** : gardée si IosevkaTerm Nerd Font est déjà dans tes polices perso (`~/.local/share/fonts`, ou celles de ton compte Windows).
- **Les configs** : un dossier qui est déjà un clone du dépôt est mis à jour (`git pull`) ; un autre dossier au même endroit est mis de côté (`.avant-install.<date>`).

## Ce qu'il faut déjà avoir sur la machine

`git`, `curl`, `tar`, `unzip`, `zsh`, `make`, `cc`, `python3`. Le script prévient s'il en manque un (sans sudo, il ne peut pas les installer).

## Ce qu'il installe

| Quoi | Où |
|---|---|
| gh, neovim, fzf, eza, bat, ripgrep, fd, yazi, zoxide, lazygit, starship, pipx | `~/.local/bin` (releases GitHub), seulement s'ils sont absents |
| zsh-autosuggestions, zsh-syntax-highlighting | `~/.local/share/zsh` |
| nvm + Node LTS (typescript, pnpm, codex), Claude Code | `~/.nvm`, `~/.local` |
| [nvim-config](https://github.com/Kasouker/nvim-config) (public), [zsh-config](https://github.com/Kasouker/zsh-config), [starship-config](https://github.com/Kasouker/starship-config) | `~/.config/nvim`, `~/.config/zsh`, `~/.config/starship` |
| Plugins Neovim (versions de `lazy-lock.json`) et serveurs Mason (clangd, lua_ls, pyright, ts, html, css, jdtls, stylua) | Neovim |
| WezTerm (nightly), [wezterm-config](https://github.com/Kasouker/wezterm-config) (public), [logtime.wezterm](https://github.com/Kasouker/logtime.wezterm), police IosevkaTerm Nerd Font | Linux : `~/.local/opt/wezterm`, `~/.config/wezterm`, `~/Projet_Perso`, `~/.local/share/fonts` — WSL : côté Windows (`%USERPROFILE%`) |

## La norminette et le header 42

Ils ne font plus partie de nvim-config : ils restent sur la machine où ils sont, dans `~/.config/nvim/lua/plugins_local/` (ignoré par git). Pour les avoir sur une nouvelle machine, copie ce dossier depuis l'ancienne, puis relance `nvim`.

## À savoir

Si `chsh` est refusé, le script ajoute à `~/.bashrc` une ligne qui lance zsh.

Les alias de projets (`home`, `Plouf`, `Arbre`…) pointent vers `~/Projet_Perso` sous Linux.
