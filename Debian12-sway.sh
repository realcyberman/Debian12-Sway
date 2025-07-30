#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing required packages..."

if apt-cache show intel-media-va-driver-non-free >/dev/null 2>&1; then
  INTEL_DRIVER="intel-media-va-driver-non-free"
else
  echo "⚠️ Package intel-media-va-driver-non-free not found, skipping."
  INTEL_DRIVER=""
fi

sudo apt install -y sway waybar mako foot wl-clipboard light grim slurp \
  wofi pipewire wireplumber pavucontrol fonts-font-awesome unzip curl git \
  papirus-icon-theme gtk2-engines-murrine gtk2-engines-pixbuf \
  fonts-noto fonts-noto-color-emoji fonts-noto-cjk fonts-noto-mono \
  lxappearance imv vlc thunar thunar-archive-plugin file-roller \
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk qt5ct qt6ct \
  gnome-themes-extra libpam0g-dev build-essential $INTEL_DRIVER \
  intel-gpu-tools iio-sensor-proxy tlp powertop

echo "🎨 Installing Catppuccin GTK theme (maintained fork)..."
mkdir -p ~/.themes
cd ~/.themes
if [ -d "Fausto-Korpsvart-Catppuccin-GTK-Theme" ]; then rm -rf Fausto-Korpsvart-Catppuccin-GTK-Theme; fi
git clone --depth=1 https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git
cd Fausto-Korpsvart-Catppuccin-GTK-Theme
./install.sh frappe blue --tweaks rimless --link

echo "🎨 Installing Catppuccin Icon Theme..."
mkdir -p ~/.icons
cd ~/.icons
if [ -d "catppuccin-icon-theme" ]; then rm -rf catppuccin-icon-theme; fi
git clone --depth=1 https://github.com/catppuccin/catppuccin-icon-theme.git
cd catppuccin-icon-theme
./install.sh || echo "⚠️ Icon theme install failed."

echo "🖼️ Setting Debian Emerald wallpaper..."
mkdir -p ~/Pictures/wallpapers
wget -q -O ~/Pictures/wallpapers/emerald-wallpaper.png "https://wiki.debian.org/DebianArt/Themes/Emerald?action=AttachFile&do=get&target=Emerald_login_1920x1080.png"

echo "🧾 Installing Ubuntu Sway Remix config..."
mkdir -p ~/.config
if [ -d ~/.config/sway ]; then mv ~/.config/sway ~/.config/sway.bak; fi
cd ~
git clone --depth=1 https://github.com/ubuntusway/ubuntusway.git
cp -r ubuntusway/data/config/* ~/.config/
rm -rf ubuntusway

echo "🎨 Updating Waybar to Fedora-style blue..."
mkdir -p ~/.config/waybar
cat <<EOF > ~/.config/waybar/style.css
* {
  font-family: "Noto Sans", sans-serif;
  font-size: 13px;
  color: #d0d7de;
  background-color: #1e2a38;
}
#window, #workspaces, #clock, #battery, #pulseaudio, #network, #tray {
  border: none;
  padding: 4px 10px;
  background-color: #2c3e50;
  border-radius: 8px;
  margin: 2px 5px;
}
#clock {
  color: #58a6ff;
}
#battery.charging {
  color: #3fb950;
}
EOF

sed -i '/^output \* bg /d' ~/.config/sway/config
echo "output * bg ~/Pictures/wallpapers/emerald-wallpaper.png fill" >> ~/.config/sway/config

echo "🔧 Dell XPS 9305 tuning..."
echo "output eDP-1 scale 1.5" >> ~/.config/sway/config

mkdir -p ~/.config/libinput
cat <<EOF > ~/.config/libinput/local-overrides.quirks
[Touchpad Tapping and Natural Scrolling]
MatchName=*
AttrTapEnable=1
AttrNaturalScrolling=1
EOF

sudo systemctl enable tlp
sudo systemctl start tlp
sudo cpupower frequency-set -g powersave || echo "⚠️ cpupower not available"

echo "🎯 Installing fonts..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Noto.zip
unzip -q Noto.zip
fc-cache -fv

echo "✅ Setup complete. You can now reboot into your new Sway environment."
