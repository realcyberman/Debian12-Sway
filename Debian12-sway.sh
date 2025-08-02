#!/bin/bash
# Debian 13 Sway: Ubuntu Sway Remix experience, blue theme & wallpaper, NO Fish shell

set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing core Sway packages..."
sudo apt install -y sway swaybg swayidle swaylock waybar \
  mako-notifier wofi thunar thunar-archive-plugin foot alacritty \
  lxappearance pavucontrol fuzzel imv \
  fonts-font-awesome papirus-icon-theme file-roller curl git unzip

echo "🧩 Installing clipboard manager..."
sudo apt install -y nwg-clipman

echo "🔐 Installing greetd (optional, for auto-login to Sway)..."
sudo apt install -y greetd
sudo systemctl enable greetd

echo "📁 Fetching Sway Remix configs..."
mkdir -p ~/.config
cd /tmp
rm -rf remix-tmp
git clone --depth 1 https://github.com/Ubuntu-Sway/Ubuntu-Sway-Remix.git remix-tmp

echo "🔄 Copying config files..."
for folder in sway waybar mako fuzzel nwg-clipman; do
    if [ -d "remix-tmp/usr/share/ubuntu-sway/defaults/$folder" ]; then
        cp -r "remix-tmp/usr/share/ubuntu-sway/defaults/$folder" ~/.config/
    else
        echo "⚠️  Warning: $folder config not found, skipping."
    fi
done

rm -rf remix-tmp

# ---- THEME SECTION ----

# 1. Blue abstract wallpaper (Fedora Sway style, copyright safe)
echo "🖼️  Downloading blue abstract wallpaper..."
mkdir -p "$HOME/.config/sway"
WALLPAPER_URL="https://images.unsplash.com/photo-1506744038136-46273834b3fb?fit=crop&w=1920&q=80"
WALLPAPER_PATH="$HOME/.config/sway/wallpaper-blue.jpg"
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"
sed -i "s|^\(output \* bg \).*|\1 $WALLPAPER_PATH fill|" ~/.config/sway/config || true

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
sed -i '/^bar {/,/^}/s/background .*/background #19243a/' ~/.config/sway/config || true
sed -i '/^bar {/,/^}/s/statusline .*/statusline #67b0ff/' ~/.config/sway/config || true
sed -i '/^bar {/,/^}/s/focused_workspace .*/focused_workspace #283753 #67b0ff #ffffff/' ~/.config/sway/config || true

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

echo "✅ All done! Log out and into Sway (or reboot) to enjoy your blue, Remix-style desktop. No fish shell setup included."
