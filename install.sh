#!/usr/bin/env bash
# install.sh : remet toute la config en place sur une machine Windows + WSL (Ubuntu).
# À lancer depuis WSL, après `gh auth login`. Peut être relancé sans risque : ce qui est déjà là est mis à jour.
set -euo pipefail

GH_USER="Kasouker"

step() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

# Clone un repo, ou le met à jour s'il est déjà là
clone_or_pull() {
	local repo=$1 dest=$2
	if [ -d "$dest/.git" ]; then
		git -C "$dest" pull --ff-only
	else
		[ -e "$dest" ] && mv "$dest" "$dest.avant-install.$(date +%s)"
		gh repo clone "$GH_USER/$repo" "$dest"
	fi
}

# Crée un lien symbolique, en mettant de côté le fichier qui était là
link() {
	local target=$1 name=$2
	if [ -e "$name" ] && [ ! -L "$name" ]; then
		mv "$name" "$name.avant-install.$(date +%s)"
	fi
	ln -sfn "$target" "$name"
}

# --- 1. Paquets apt ---
step "Paquets apt"
sudo apt-get update
sudo apt-get install -y \
	zsh git gh curl wget unzip tar build-essential make \
	neovim fzf eza bat ripgrep fd-find yazi zoxide tree tmux xclip \
	pipx python3-venv \
	zsh-autosuggestions zsh-syntax-highlighting

# --- 2. Outils hors apt ---
step "Starship"
command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y

step "Lazygit"
if ! command -v lazygit >/dev/null; then
	tmp=$(mktemp -d)
	version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')
	curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_linux_x86_64.tar.gz" | tar -xz -C "$tmp" lazygit
	sudo install "$tmp/lazygit" /usr/local/bin
	rm -rf "$tmp"
fi

step "spotify_player"
if ! command -v spotify_player >/dev/null; then
	mkdir -p ~/.local/bin
	curl -sL https://github.com/aome510/spotify-player/releases/latest/download/spotify_player-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C ~/.local/bin spotify_player
fi

step "Node (nvm) et paquets npm globaux"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] || curl -so- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash
# nvm n'aime pas `set -u`
set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
set -u
npm install -g typescript pnpm @openai/codex

step "Claude Code"
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

# --- 3. Configs (WSL) ---
step "Configs : nvim, zsh, starship"
mkdir -p ~/.config
clone_or_pull nvim-config ~/.config/nvim
clone_or_pull zsh-config ~/.config/zsh
clone_or_pull starship-config ~/.config/starship
link ~/.config/zsh/.zshrc ~/.zshrc
link ~/.config/starship/starship.toml ~/.config/starship.toml

step "Zsh comme shell par défaut"
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] || sudo chsh -s "$(command -v zsh)" "$USER"

# --- 4. Côté Windows : WezTerm, sa config, le plugin logtime et la police ---
step "Côté Windows"
WIN_HOME=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
mkdir -p "$WIN_HOME/.config" "$WIN_HOME/Projet_Perso"
clone_or_pull wezterm-config "$WIN_HOME/.config/wezterm"
# Le plugin est chargé depuis ce dossier par logtime_plugin.lua
[ -d "$WIN_HOME/Projet_Perso/logtime.wezterm" ] || gh repo clone "$GH_USER/logtime.wezterm" "$WIN_HOME/Projet_Perso/logtime.wezterm"

[ -e "/mnt/c/Program Files/WezTerm/wezterm.exe" ] ||
	winget.exe install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements

# Police IosevkaTerm Nerd Font, installée pour l'utilisateur Windows (pas besoin d'être admin)
FONT_DIR="$WIN_HOME/AppData/Local/Microsoft/Windows/Fonts"
if ! ls "$FONT_DIR"/IosevkaTermNerdFont-* >/dev/null 2>&1; then
	tmp=$(mktemp -d)
	curl -sL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip -o "$tmp/font.zip"
	unzip -q "$tmp/font.zip" 'IosevkaTermNerdFont-*.ttf' -d "$tmp/ttf"
	mkdir -p "$FONT_DIR"
	for f in "$tmp"/ttf/*.ttf; do
		name=$(basename "$f")
		cp "$f" "$FONT_DIR/"
		reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
			/v "${name%.ttf} (TrueType)" /t REG_SZ /d "$(wslpath -w "$FONT_DIR/$name")" /f >/dev/null
	done
	rm -rf "$tmp"
fi

# --- 5. Plugins Neovim et serveurs LSP ---
step "Plugins Neovim (versions de lazy-lock.json) et serveurs Mason"
nvim --headless "+Lazy! restore" +qa
# Mason n'est chargé qu'à l'ouverture d'un fichier : on charge lspconfig (qui le configure) avant d'installer
nvim --headless "+Lazy! load nvim-lspconfig" \
	"+MasonInstall clangd css-lsp html-lsp jdtls lua-language-server pyright stylua typescript-language-server" +qa

step "Terminé : ouvre WezTerm, tout est en place."
