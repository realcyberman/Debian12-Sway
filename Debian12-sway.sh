#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing required packages..."
sudo apt install -y sway waybar mako foot wl-clipboard light grim slurp \
  wofi pipewire wireplumber pavucontrol fonts-font-awesome unzip curl git \
  papirus-icon-theme gtk2-engines-murrine gtk2-engines-pixbuf \
  fonts-noto fonts-noto-color-emoji fonts-noto-cjk fonts-noto-mono \
  lxappearance imv vlc thunar thunar-archive-plugin file-roller \
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk qt5ct qt6ct \
  gnome-themes-extra libpam0g-dev build-essential intel-media-va-driver-non-free \
  intel-gpu-tools iio-sensor-proxy tlp powertop

echo "🎨 Installing Catppuccin themes and GTK theming..."
mkdir -p ~/.themes ~/.icons ~/.config
cd ~/.themes
if [ ! -d "catppuccin-gtk" ]; then
  git clone --depth=1 https://github.com/catppuccin/gtk.git catppuccin-gtk
fi
cd ~/.icons
if [ ! -d "catppuccin-icon-theme" ]; then
  git clone --depth=1 https://github.com/catppuccin/catppuccin-icon-theme.git
  cd catppuccin-icon-theme
  ./install.sh
fi

echo "🖼️ Setting Debian Emerald wallpaper..."
mkdir -p ~/Pictures/wallpapers
wget -q -O ~/Pictures/wallpapers/emerald-wallpaper.png "https://wiki.debian.org/DebianArt/Themes/Emerald?action=AttachFile&do=get&target=Emerald_login_1920x1080.png"

echo "🧾 Cloning Ubuntu Sway Remix config..."
mkdir -p ~/.config
cd ~
if [ ! -d "ubuntusway" ]; then
  git clone --depth=1 https://github.com/ubuntusway/ubuntusway.git
fi
cp -r ubuntusway/data/config/* ~/.config/
rm -rf ubuntusway

echo "🎨 Adapting color scheme to match Fedora Sway Spin blue theme..."
# Update GTK settings for blue Catppuccin-Frappe
cat <<EOF > ~/.gtkrc-2.0
gtk-theme-name="Catppuccin-Frappe"
gtk-icon-theme-name="Papirus"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
EOF

cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Catppuccin-Frappe
gtk-icon-theme-name=Papirus
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
EOF

# Custom Waybar color scheme for Fedora-like blue
mkdir -p ~/.config/waybar
cat <<EOF > ~/.config/waybar/style.css
* {
  font-family: "Noto Sans", sans-serif;
  font-size: 13px;
  color: #d0d7de; /* light blue-grey text */
  background-color: #1e2a38; /* dark blue background */
}
#window, #workspaces, #clock, #battery, #pulseaudio, #network, #tray {
  border: none;
  padding: 4px 10px;
  background-color: #2c3e50; /* medium dark blue */
  border-radius: 8px;
  margin: 2px 5px;
}
#clock {
  color: #58a6ff; /* bright blue highlight */
}
#battery.charging {
  color: #3fb950; /* keep green for charging */
}
EOF

# Update sway config wallpaper line to Emerald
sed -i '/^output \* bg /d' ~/.config/sway/config
echo "output * bg ~/Pictures/wallpapers/emerald-wallpaper.png fill" >> ~/.config/sway/config

echo "🔧 Adding Dell XPS 9305 specific optimizations..."

# Set scale for HiDPI display (adjust if your display is different)
if ! grep -q "output eDP-1 scale" ~/.config/sway/config; then
  echo "output eDP-1 scale 1.5" >> ~/.config/sway/config
fi

# Enable tap-to-click and natural scrolling for touchpad
mkdir -p ~/.config/libinput
cat <<EOF > ~/.config/libinput/local-overrides.quirks
[Touchpad Tapping and Natural Scrolling]
MatchName=*
AttrTapEnable=1
AttrNaturalScrolling=1
EOF

# Enable TLP (power management)
sudo systemctl enable tlp
sudo systemctl start tlp

# Optimize CPU frequency scaling governor for battery
sudo cpupower frequency-set -g powersave || echo "cpupower not installed or no permission"

echo "🎯 Installing fonts..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Noto.zip
unzip -q Noto.zip
fc-cache -fv

echo "✅ Setup complete. Reboot or restart Sway for all changes to take effect."
