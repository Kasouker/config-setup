# config-setup

Remet toute ma config en place en une commande, sur Linux ou sur Windows avec WSL. **Pas besoin de sudo** : tout s'installe dans `~/.local`.

## Installation

Une seule ligne à copier (elle marche aussi pour mettre à jour : relance-la quand tu veux) :

```bash
{ [ -f ~/config-setup/install.sh ] || git clone https://github.com/Kasouker/config-setup.git ~/config-setup; } && git -C ~/config-setup pull -q && bash ~/config-setup/install.sh
```

Puis fermer le terminal et ouvrir WezTerm.

Sous Windows, il faut d'abord installer WSL : dans PowerShell (admin), `wsl --install -d Ubuntu`.

Le script peut être relancé sans risque : il garde ou met à jour ce qui est déjà là.

## Comment ça marche

Chaque config a son propre `install.sh`, qu'on peut aussi lancer seul (voir son README). config-setup les clone et les lance tous, puis ajoute ce qu'aucune config n'installe :

| Étape | Ce qui est installé |
|---|---|
| Outils en plus | gh, zoxide (dans `~/.local/bin`, s'ils sont absents) |
| Node | nvm + Node LTS, et typescript, pnpm, codex (`~/.nvm`) ; Claude Code |
| [zsh-config](https://github.com/Kasouker/zsh-config) | starship, fzf, eza, bat, ripgrep, fd, yazi, lazygit, les suggestions grises et la coloration des commandes, le prompt ([starship-config](https://github.com/Kasouker/starship-config)), le lien `~/.zshrc` |
| [nvim-config](https://github.com/Kasouker/nvim-config) | Neovim 0.11.6 (si absent ou trop ancien), ripgrep, lazygit, les plugins |
| zsh comme shell | `chsh` ; s'il est refusé, une ligne dans `~/.bashrc` lance zsh |
| [wezterm-config](https://github.com/Kasouker/wezterm-config) | Linux : WezTerm (nightly) et la police IosevkaTerm Nerd Font. WSL : côté Windows (`%USERPROFILE%`), avec winget et la police du compte Windows |
| [logtime.wezterm](https://github.com/Kasouker/logtime.wezterm) | `~/Projet_Perso/logtime.wezterm` (sous WSL : côté Windows) |
| Serveurs de langage | clangd, lua_ls, pyright, ts, html, css, jdtls, stylua (Mason, dans Neovim) |

## Si une partie est déjà installée

Pas besoin de rien enlever avant : le script **saute ce qui est déjà là**.

- **Les outils** (nvim, fzf, lazygit…) : gardés s'ils sont déjà installés, même avec sudo ou `apt`. Neovim est remplacé par une version dans `~/.local` seulement s'il est plus ancien que la 0.11, et fzf s'il est plus ancien que la 0.48.
- **WezTerm** : gardé s'il est déjà installé (`wezterm` sous Linux, `C:\Program Files\WezTerm` sous Windows). La config est testée avec la **nightly** `20261005` ; avec la version stable `20240203` (celle d'`apt` ou du site), elle devrait marcher mais n'a jamais été testée. Vérifie avec `wezterm --version` et, en cas d'erreur au lancement, installe la nightly.
- **La police** : gardée si IosevkaTerm Nerd Font est déjà installée.
- **Les configs** : un dossier qui est déjà un clone du dépôt est mis à jour (`git pull`) ; un autre dossier au même endroit est mis de côté (`.avant-install.<date>`).
- **Ton `~/.zshrc`** : il est remplacé par celui de zsh-config, donc **tes anciens alias ne sont plus chargés**. L'ancien fichier est gardé en `~/.zshrc.bak` : recopie les alias que tu veux garder dans `~/.zshrc.local` (chargé à la fin du nouveau `.zshrc`, jamais envoyé sur GitHub).

## Ce qu'il faut déjà avoir sur la machine

`git`, `curl`, `tar`, `unzip`, `awk`, `zsh`, `make`, `cc`. Le script prévient s'il en manque un (sans sudo, il ne peut pas les installer).

## La norminette et le header 42

Ils ne font plus partie de nvim-config : ils restent sur la machine où ils sont, dans `~/.config/nvim/lua/plugins_local/` (ignoré par git). Pour les avoir sur une nouvelle machine, copie ce dossier depuis l'ancienne, puis relance `nvim`.

## À savoir

Les alias propres à une machine (comme les alias de projets) vont dans `~/.zshrc.local`, qui reste sur la machine.
