#!/bin/bash
# Debian 13 Sway: Ubuntu Sway Remix experience, blue theme, fish shell with CachyOS config

set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing core Sway packages..."
sudo apt install -y sway swaybg swayidle swaylock waybar \
  mako wofi thunar thunar-archive-plugin foot alacritty \
  lxappearance pavucontrol fuzzel imv \
  fonts-font-awesome papirus-icon-theme file-roller curl git unzip

echo "🧩 Installing clipboard manager..."
sudo apt install -y nwg-clipman

echo "🔐 Installing greetd (optional, for auto-login to Sway)..."
sudo apt install -y greetd
sudo systemctl enable greetd

echo "🐟 Installing Fish shell and Starship prompt..."
sudo apt install -y fish starship

echo "📦 Installing fish plugins: syntax highlighting and autosuggestions..."
if ! command -v fisher &>/dev/null; then
  fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
fi
fish -c "fisher install jorgebucaran/fish-autosuggestions"
fish -c "fisher install IlanCosman/tide@v6" # Tide: Modern, pretty prompt

# Make fish the default shell for your user
echo "🔄 Setting Fish as the default shell for $USER..."
chsh -s /usr/bin/fish

echo "📝 Applying CachyOS-style Fish config with Starship prompt and useful aliases..."

mkdir -p ~/.config/fish

cat > ~/.config/fish/config.fish <<'EOF'
# CachyOS / Starship Fish config for Debian
set -g theme_display_user yes
set -g theme_display_hostname yes
set -g theme_display_git yes
set -g theme_display_virtualenv yes

# Use starship for prompt
starship init fish | source

# Autosuggestions and syntax highlighting enabled via fisher

# Useful aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias update='sudo apt update && sudo apt upgrade'
alias v='nvim'
alias ip='ip -color'

# Colorful man pages
set -gx LESS_TERMCAP_mb (printf '\e[1;31m')
set -gx LESS_TERMCAP_md (printf '\e[1;36m')
set -gx LESS_TERMCAP_me (printf '\e[0m')
set -gx LESS_TERMCAP_se (printf '\e[0m')
set -gx LESS_TERMCAP_so (printf '\e[1;44;33m')
set -gx LESS_TERMCAP_ue (printf '\e[0m')
set -gx LESS_TERMCAP_us (printf '\e[1;32m')

# Add ~/.local/bin to PATH
set -Ua fish_user_paths $HOME/.local/bin
EOF

# Add Starship config for nice prompt
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
# CachyOS-inspired Starship prompt
format = """
[┌─────────────────────────────────](bold blue)
[│](bold blue)$all
[└─](bold blue)$character
"""

[directory]
style = "cyan"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
style = "bold yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold yellow)"
EOF

# Sway configs and theming as before...

echo "📁 Fetching Sway Remix configs..."
mkdir -p ~/.config
cd /tmp
git clone --depth 1 https://github.com/Ubuntu-Sway/Ubuntu-Sway-Remix.git remix-tmp

echo "🔄 Copying config files..."
cp -r remix-tmp/etc/skel/.config/sway ~/.config/
cp -r remix-tmp/etc/skel/.config/waybar ~/.config/
cp -r remix-tmp/etc/skel/.config/mako ~/.config/
cp -r remix-tmp/etc/skel/.config/fuzzel ~/.config/
cp -r remix-tmp/etc/skel/.config/nwg-clipman ~/.config/

rm -rf remix-tmp

# ---- THEME SECTION ----

# 1. Blue abstract wallpaper (Fedora Sway style, copyright safe)
echo "🖼️  Downloading blue abstract wallpaper..."
WALLPAPER_URL="https://images.unsplash.com/photo-1506744038136-46273834b3fb?fit=crop&w=1920&q=80"
WALLPAPER_PATH="$HOME/.config/sway/wallpaper-blue.jpg"
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"
sed -i "s|^\(output \* bg \).*|\1 $WALLPAPER_PATH fill|" ~/.config/sway/config

# 2. GTK theme: 'Materia-blue'
echo "🎨 Installing blue GTK theme..."
sudo apt install -y materia-gtk-theme

echo "🌐 Setting GTK theme to Materia-blue and icons to Papirus..."
gsettings set org.gnome.desktop.interface gtk-theme 'Materia-blue' || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true

# 3. Waybar blue style
cat > ~/.config/waybar/style.css <<EOF
* {
  border: none;
  border-radius: 8px;
  font-family: "Noto Sans", "FontAwesome", sans-serif;
  font-size: 15px;
  min-height: 0;
}
window {
  background: transparent;
}
#workspaces button {
  background: #1e2430;
  color: #67b0ff;
  border-radius: 8px;
  margin: 2px;
  padding: 0 8px;
}
#workspaces button.focused {
  background: #283753;
  color: #e0e8ff;
}
#mode, #battery, #clock, #pulseaudio, #tray, #network {
  background: #22314d;
  color: #7bc6ff;
  border-radius: 8px;
  margin: 2px;
  padding: 0 8px;
}
EOF

# 4. Swaybar blue
sed -i '/^bar {/,/^}/s/background .*/background #19243a/' ~/.config/sway/config
sed -i '/^bar {/,/^}/s/statusline .*/statusline #67b0ff/' ~/.config/sway/config
sed -i '/^bar {/,/^}/s/focused_workspace .*/focused_workspace #283753 #67b0ff #ffffff/' ~/.config/sway/config

# ---- END THEME SECTION ----

# Waybar auto-restart: Systemd user unit
echo "🛠️  Creating Waybar auto-restart systemd unit..."
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/waybar-restart.service <<EOF
[Unit]
Description=Waybar auto-restart

[Service]
Type=simple
ExecStart=/usr/bin/waybar
Restart=always
EOF

systemctl --user daemon-reload
systemctl --user enable --now waybar-restart.service

echo "✅ All done! Reboot or log in to Sway. Next terminal will use Fish with CachyOS/Starship polish."
echo
echo "If you see prompt errors, run 'fish' manually once to let plugins finish installing."
