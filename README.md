# config-setup

Remet toute ma config en place sur un PC Windows avec WSL (Ubuntu), en une commande.

## Sur un PC neuf

1. Dans PowerShell (admin) : `wsl --install -d Ubuntu`, puis redémarrer et créer l'utilisateur Ubuntu.
2. Dans Ubuntu :

```sh
sudo apt update && sudo apt install -y gh git
gh auth login
gh repo clone Kasouker/config-setup ~/config-setup
~/config-setup/install.sh
```

3. Ouvrir WezTerm.

Le script peut être relancé sans risque : il met à jour ce qui est déjà là. Un fichier qu'il remplace est gardé à côté, avec `.avant-install.<date>` à la fin de son nom.

## Ce qu'il installe

| Où | Quoi |
|---|---|
| WSL, apt | zsh, neovim, fzf, eza, bat, ripgrep, fd, yazi, zoxide, tmux, pipx, gcc/make, zsh-autosuggestions, zsh-syntax-highlighting… |
| WSL, autres sources | starship, lazygit, spotify_player, nvm + Node LTS (typescript, pnpm, codex), Claude Code |
| WSL, configs | [nvim-config](https://github.com/Kasouker/nvim-config) → `~/.config/nvim`, [zsh-config](https://github.com/Kasouker/zsh-config) → `~/.config/zsh`, [starship-config](https://github.com/Kasouker/starship-config) → `~/.config/starship` |
| Neovim | les plugins aux versions de `lazy-lock.json`, puis les serveurs Mason (clangd, lua_ls, pyright, ts, html, css, jdtls, stylua) |
| Windows | WezTerm (winget), la police IosevkaTerm Nerd Font, [wezterm-config](https://github.com/Kasouker/wezterm-config) → `%USERPROFILE%\.config\wezterm`, [logtime.wezterm](https://github.com/Kasouker/logtime.wezterm) → `%USERPROFILE%\Projet_Perso\logtime.wezterm` |
