#!/usr/bin/env bash
# install.sh : remet toute la config en place, sur Linux ou sur Windows + WSL, sans sudo.
# Tout s'installe dans le dossier personnel (~/.local) à partir des versions publiées sur GitHub.
# Chaque config s'installe avec son propre install.sh (nvim-config, zsh-config, wezterm-config) ; ce script ajoute
# le reste (gh, zoxide, Node, Claude Code, zsh comme shell, logtime, les serveurs de langage).
# Peut être relancé sans risque : ce qui est déjà là est gardé ou mis à jour.
set -euo pipefail

GH_USER="Kasouker"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

# Sous WSL, WezTerm et la police vont côté Windows (seulement si Windows répond : sinon, comme sous Linux)
if grep -qi microsoft /proc/version && command -v cmd.exe >/dev/null; then IS_WSL=1; else IS_WSL=0; fi

step() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;31m!! %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Clone un repo, ou le met à jour s'il est déjà là
clone_or_pull() {
	local repo=$1 dest=$2
	if [ -d "$dest/.git" ]; then
		git -C "$dest" pull --ff-only
	else
		[ -e "$dest" ] && mv "$dest" "$dest.avant-install.$(date +%s)"
		git clone "https://github.com/$repo.git" "$dest"
	fi
}

# dl <dépôt GitHub> <fin du nom de l'archive> <programmes...> : la dernière version, dans ~/.local/bin
dl() {
	local repo=$1 end=$2 url tmp b
	shift 2
	url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep -o "https://[^\"]*$end" | head -1)
	tmp=$(mktemp -d)
	curl -fsSL "$url" -o "$tmp/archive"
	mkdir "$tmp/x"
	tar -xf "$tmp/archive" -C "$tmp/x"
	for b in "$@"; do install -m 755 "$(find "$tmp/x" -type f -name "$b" | head -1)" "$BIN/"; done
	rm -rf "$tmp"
}

# --- 1. Ce qu'il faut déjà avoir (on ne peut pas l'installer sans sudo) ---
step "Vérification des outils de base"
for b in git curl tar unzip awk zsh make cc; do
	have "$b" || warn "$b est absent : demande-le à l'admin de la machine"
done
have git && have curl && have tar && have awk || { warn "git, curl, tar et awk sont indispensables, arrêt."; exit 1; }

# --- 2. Les outils qu'aucune config n'installe ---
step "gh et zoxide"
have gh || dl cli/cli linux_amd64.tar.gz gh
have zoxide || dl ajeetdsouza/zoxide x86_64-unknown-linux-musl.tar.gz zoxide

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
have claude || curl -fsSL https://claude.ai/install.sh | bash

# --- 3. Les configs, chacune avec son install.sh ---
mkdir -p ~/.config
step "Config zsh (et le prompt starship)"
clone_or_pull "$GH_USER/zsh-config" ~/.config/zsh
clone_or_pull "$GH_USER/starship-config" ~/.config/starship
bash ~/.config/zsh/install.sh

step "Config nvim"
clone_or_pull "$GH_USER/nvim-config" ~/.config/nvim
bash ~/.config/nvim/install.sh

step "Zsh comme shell"
ZSH_BIN=$(command -v zsh || true)
# (on compare les vrais fichiers : /bin/zsh et /usr/bin/zsh sont souvent le même)
if [ -n "$ZSH_BIN" ] && [ "$(readlink -f "$(getent passwd "$USER" | cut -d: -f7)")" != "$(readlink -f "$ZSH_BIN")" ]; then
	# chsh demande seulement ton mot de passe ; s'il est refusé, bash lancera zsh à l'ouverture
	if ! chsh -s "$ZSH_BIN" 2>/dev/null; then
		grep -q 'exec zsh' ~/.bashrc 2>/dev/null ||
			printf '\n# Lance zsh (chsh impossible sur cette machine)\n[ -t 1 ] && command -v zsh >/dev/null && exec zsh\n' >> ~/.bashrc
	fi
fi

# --- 4. WezTerm, sa config, la police et le plugin logtime ---
if [ "$IS_WSL" = 1 ]; then
	step "WezTerm et la police (côté Windows)"
	TERM_HOME=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
	[ -e "/mnt/c/Program Files/WezTerm/wezterm.exe" ] ||
		winget.exe install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements
	mkdir -p "$TERM_HOME/.config"
	clone_or_pull "$GH_USER/wezterm-config" "$TERM_HOME/.config/wezterm"
	FONT_DIR="$TERM_HOME/AppData/Local/Microsoft/Windows/Fonts"
	if ! ls "$FONT_DIR"/IosevkaTermNerdFont-* >/dev/null 2>&1; then
		tmp=$(mktemp -d)
		curl -fsSL -o "$tmp/IosevkaTerm.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip
		unzip -q "$tmp/IosevkaTerm.zip" 'IosevkaTermNerdFont-*.ttf' -d "$tmp/ttf"
		mkdir -p "$FONT_DIR"
		cp "$tmp"/ttf/*.ttf "$FONT_DIR/"
		# Police installée pour l'utilisateur Windows (pas besoin d'être admin)
		for f in "$tmp"/ttf/*.ttf; do
			name=$(basename "$f")
			reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
				/v "${name%.ttf} (TrueType)" /t REG_SZ /d "$(wslpath -w "$FONT_DIR/$name")" /f >/dev/null
		done
		rm -rf "$tmp"
	fi
else
	step "Config WezTerm (WezTerm et la police)"
	TERM_HOME=$HOME
	clone_or_pull "$GH_USER/wezterm-config" ~/.config/wezterm
	bash ~/.config/wezterm/install.sh
fi

step "logtime"
# Le plugin est chargé depuis ce dossier par logtime_plugin.lua (sinon depuis GitHub)
mkdir -p "$TERM_HOME/Projet_Perso"
[ -d "$TERM_HOME/Projet_Perso/logtime.wezterm" ] ||
	git clone "https://github.com/$GH_USER/logtime.wezterm.git" "$TERM_HOME/Projet_Perso/logtime.wezterm"

# --- 5. Les serveurs de langage ---
step "Serveurs de langage (Mason)"
# Mason n'est chargé qu'à l'ouverture d'un fichier : on charge lspconfig (qui le configure) avant d'installer
nvim --headless "+Lazy! load nvim-lspconfig" \
	"+MasonInstall clangd css-lsp html-lsp jdtls lua-language-server pyright stylua typescript-language-server" +qa

step "Terminé : ferme le terminal, puis ouvre WezTerm."
