#!/usr/bin/env bash
# install.sh : remet toute la config en place, sur Linux (Ubuntu/Debian) ou sur Windows + WSL.
# À lancer depuis Linux ou WSL, après `gh auth login`. Peut être relancé sans risque : ce qui est déjà là est mis à jour.
set -euo pipefail

GH_USER="Kasouker"

# Sous WSL, WezTerm et la police vont côté Windows
if grep -qi microsoft /proc/version; then IS_WSL=1; else IS_WSL=0; fi

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
# Un paquet absent de la distribution ne bloque pas les autres
for p in \
	zsh git gh curl wget unzip tar build-essential make fontconfig gnupg \
	neovim fzf eza bat ripgrep fd-find yazi zoxide tree tmux xclip wl-clipboard \
	pipx python3-venv \
	zsh-autosuggestions zsh-syntax-highlighting; do
	sudo apt-get install -y "$p" || echo "!! paquet introuvable : $p"
done

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

# --- 4. WezTerm, sa config, le plugin logtime et la police ---
step "WezTerm"
if [ "$IS_WSL" = 1 ]; then
	TERM_HOME=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
	FONT_DIR="$TERM_HOME/AppData/Local/Microsoft/Windows/Fonts"
	[ -e "/mnt/c/Program Files/WezTerm/wezterm.exe" ] ||
		winget.exe install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements
else
	TERM_HOME=$HOME
	FONT_DIR="$HOME/.local/share/fonts"
	if ! command -v wezterm >/dev/null; then
		curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
		sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
		echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' |
			sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
		sudo apt-get update
		sudo apt-get install -y wezterm
	fi
fi

mkdir -p "$TERM_HOME/.config" "$TERM_HOME/Projet_Perso"
clone_or_pull wezterm-config "$TERM_HOME/.config/wezterm"
# Le plugin est chargé depuis ce dossier par logtime_plugin.lua
[ -d "$TERM_HOME/Projet_Perso/logtime.wezterm" ] || gh repo clone "$GH_USER/logtime.wezterm" "$TERM_HOME/Projet_Perso/logtime.wezterm"

step "Police IosevkaTerm Nerd Font"
if ! ls "$FONT_DIR"/IosevkaTermNerdFont-* >/dev/null 2>&1; then
	tmp=$(mktemp -d)
	curl -sL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip -o "$tmp/font.zip"
	unzip -q "$tmp/font.zip" 'IosevkaTermNerdFont-*.ttf' -d "$tmp/ttf"
	mkdir -p "$FONT_DIR"
	cp "$tmp"/ttf/*.ttf "$FONT_DIR/"
	if [ "$IS_WSL" = 1 ]; then
		# Police installée pour l'utilisateur Windows (pas besoin d'être admin)
		for f in "$tmp"/ttf/*.ttf; do
			name=$(basename "$f")
			reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
				/v "${name%.ttf} (TrueType)" /t REG_SZ /d "$(wslpath -w "$FONT_DIR/$name")" /f >/dev/null
		done
	else
		fc-cache -f "$FONT_DIR"
	fi
	rm -rf "$tmp"
fi

# --- 5. Plugins Neovim et serveurs LSP ---
step "Plugins Neovim (versions de lazy-lock.json) et serveurs Mason"
nvim --headless "+Lazy! restore" +qa
# Mason n'est chargé qu'à l'ouverture d'un fichier : on charge lspconfig (qui le configure) avant d'installer
nvim --headless "+Lazy! load nvim-lspconfig" \
	"+MasonInstall clangd css-lsp html-lsp jdtls lua-language-server pyright stylua typescript-language-server" +qa

step "Terminé : déconnecte-toi puis reconnecte-toi (pour zsh), et ouvre WezTerm."
