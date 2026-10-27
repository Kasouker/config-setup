#!/usr/bin/env bash
# install.sh : remet toute la config en place, sur Linux ou sur Windows + WSL, sans sudo.
# Tout s'installe dans le dossier personnel (~/.local) à partir des versions publiées sur GitHub.
# À lancer après `gh auth login`. Peut être relancé sans risque : ce qui est déjà là est gardé ou mis à jour.
set -euo pipefail

GH_USER="Kasouker"
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
mkdir -p "$BIN" "$OPT"
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

# Crée un lien symbolique, en mettant de côté le fichier qui était là
link() {
	local target=$1 name=$2
	if [ -e "$name" ] && [ ! -L "$name" ]; then
		mv "$name" "$name.avant-install.$(date +%s)"
	fi
	ln -sfn "$target" "$name"
}

# Télécharge l'archive d'une release GitHub et met les programmes demandés dans ~/.local/bin
# release_bin <repo> <motif du fichier> <programme>...
release_bin() {
	local repo=$1 pattern=$2 tmp f
	shift 2
	tmp=$(mktemp -d)
	gh release download -R "$repo" -p "$pattern" -D "$tmp"
	f=$(ls "$tmp")
	case "$f" in
		*.zip) unzip -q "$tmp/$f" -d "$tmp/x" ;;
		*) mkdir "$tmp/x" && tar -xf "$tmp/$f" -C "$tmp/x" ;;
	esac
	for b in "$@"; do
		install -m 755 "$(find "$tmp/x" -type f -name "$b" | head -1)" "$BIN/$b"
	done
	rm -rf "$tmp"
}

# --- 1. Ce qu'il faut déjà avoir (on ne peut pas l'installer sans sudo) ---
step "Vérification des outils de base"
for b in git curl tar unzip zsh make cc; do
	have "$b" || warn "$b est absent : demande-le à l'admin de la machine"
done
have git && have curl && have tar || { warn "git, curl et tar sont indispensables, arrêt."; exit 1; }

# --- 2. Outils, depuis leurs releases GitHub ---
step "gh"
have gh || release_bin cli/cli 'gh_*_linux_amd64.tar.gz' gh
# git passe par gh pour s'identifier sur GitHub (repos privés)
gh auth setup-git

step "Neovim"
if ! have nvim; then
	tmp=$(mktemp -d)
	gh release download -R neovim/neovim -p 'nvim-linux-x86_64.tar.gz' -D "$tmp"
	rm -rf "$OPT/nvim" && mkdir -p "$OPT/nvim"
	tar -xf "$tmp"/nvim-linux-x86_64.tar.gz -C "$OPT/nvim" --strip-components=1
	ln -sfn "$OPT/nvim/bin/nvim" "$BIN/nvim"
	rm -rf "$tmp"
fi

step "fzf, eza, bat, ripgrep, fd, yazi, zoxide, lazygit"
have fzf || release_bin junegunn/fzf 'fzf-*-linux_amd64.tar.gz' fzf
have eza || release_bin eza-community/eza 'eza_x86_64-unknown-linux-musl.tar.gz' eza
have bat || have batcat || release_bin sharkdp/bat 'bat-*-x86_64-unknown-linux-musl.tar.gz' bat
have rg || release_bin BurntSushi/ripgrep 'ripgrep-*-x86_64-unknown-linux-musl.tar.gz' rg
have fd || have fdfind || release_bin sharkdp/fd 'fd-*-x86_64-unknown-linux-musl.tar.gz' fd
have yazi || release_bin sxyazi/yazi 'yazi-x86_64-unknown-linux-musl.zip' yazi ya
have zoxide || release_bin ajeetdsouza/zoxide 'zoxide-*-x86_64-unknown-linux-musl.tar.gz' zoxide
have lazygit || release_bin jesseduffield/lazygit 'lazygit_*_linux_x86_64.tar.gz' lazygit

step "Starship"
have starship || curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$BIN"

step "Plugins zsh : autosuggestions et syntax-highlighting"
clone_or_pull zsh-users/zsh-autosuggestions ~/.local/share/zsh/zsh-autosuggestions
clone_or_pull zsh-users/zsh-syntax-highlighting ~/.local/share/zsh/zsh-syntax-highlighting

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

# --- 3. Configs ---
step "Configs : nvim, zsh, starship"
mkdir -p ~/.config
clone_or_pull "$GH_USER/nvim-config" ~/.config/nvim
clone_or_pull "$GH_USER/zsh-config" ~/.config/zsh
clone_or_pull "$GH_USER/starship-config" ~/.config/starship
link ~/.config/zsh/.zshrc ~/.zshrc
link ~/.config/starship/starship.toml ~/.config/starship.toml

step "Zsh comme shell"
ZSH_BIN=$(command -v zsh || true)
if [ -n "$ZSH_BIN" ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$ZSH_BIN" ]; then
	# chsh demande seulement ton mot de passe ; s'il est refusé, bash lancera zsh à l'ouverture
	if ! chsh -s "$ZSH_BIN" 2>/dev/null; then
		grep -q 'exec zsh' ~/.bashrc 2>/dev/null ||
			printf '\n# Lance zsh (chsh impossible sur cette machine)\n[ -t 1 ] && command -v zsh >/dev/null && exec zsh\n' >> ~/.bashrc
	fi
fi

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
	if ! have wezterm; then
		# AppImage décompressée : pas besoin de FUSE ni de sudo
		tmp=$(mktemp -d)
		gh release download nightly -R wez/wezterm -p 'WezTerm-nightly-Ubuntu20.04.AppImage' -D "$tmp"
		chmod +x "$tmp"/*.AppImage
		(cd "$tmp" && ./*.AppImage --appimage-extract >/dev/null)
		rm -rf "$OPT/wezterm" && mv "$tmp/squashfs-root" "$OPT/wezterm"
		ln -sfn "$OPT/wezterm/usr/bin/wezterm" "$BIN/wezterm"
		ln -sfn "$OPT/wezterm/usr/bin/wezterm-gui" "$BIN/wezterm-gui"
		rm -rf "$tmp"
		# Pour que WezTerm apparaisse dans le menu des applications
		mkdir -p ~/.local/share/applications
		cat > ~/.local/share/applications/wezterm.desktop <<-EOF
			[Desktop Entry]
			Name=WezTerm
			Exec=$BIN/wezterm start --cwd .
			Icon=$OPT/wezterm/usr/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png
			Type=Application
			Categories=System;TerminalEmulator;
		EOF
	fi
fi

mkdir -p "$TERM_HOME/.config" "$TERM_HOME/Projet_Perso"
clone_or_pull "$GH_USER/wezterm-config" "$TERM_HOME/.config/wezterm"
# Le plugin est chargé depuis ce dossier par logtime_plugin.lua
[ -d "$TERM_HOME/Projet_Perso/logtime.wezterm" ] || git clone "https://github.com/$GH_USER/logtime.wezterm.git" "$TERM_HOME/Projet_Perso/logtime.wezterm"

step "Police IosevkaTerm Nerd Font"
if ! ls "$FONT_DIR"/IosevkaTermNerdFont-* >/dev/null 2>&1; then
	tmp=$(mktemp -d)
	gh release download -R ryanoasis/nerd-fonts -p 'IosevkaTerm.zip' -D "$tmp"
	unzip -q "$tmp/IosevkaTerm.zip" 'IosevkaTermNerdFont-*.ttf' -d "$tmp/ttf"
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
		have fc-cache && fc-cache -f "$FONT_DIR"
	fi
	rm -rf "$tmp"
fi

# --- 5. Plugins Neovim et serveurs LSP ---
step "Plugins Neovim (versions de lazy-lock.json) et serveurs Mason"
nvim --headless "+Lazy! restore" +qa
# Mason n'est chargé qu'à l'ouverture d'un fichier : on charge lspconfig (qui le configure) avant d'installer
nvim --headless "+Lazy! load nvim-lspconfig" \
	"+MasonInstall clangd css-lsp html-lsp jdtls lua-language-server pyright stylua typescript-language-server" +qa

step "Terminé : ferme le terminal, puis ouvre WezTerm."
