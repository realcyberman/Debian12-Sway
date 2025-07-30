#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing core packages..."
sudo apt install -y \
  sway waybar foot wofi grim slurp wl-clipboard \
  light pipewire wireplumber pavucontrol \
  thunar thunar-archive-plugin file-roller \
  lxappearance imv vlc unzip curl git wget \
  gtk2-engines-murrine gtk2-engines-pixbuf \
  papirus-icon-theme fonts-noto fonts-noto-color-emoji \
  fonts-noto-cjk fonts-noto-mono xdg-desktop-portal-wlr \
  xdg-desktop-portal file dbus-user-session network-manager \
  policykit-1 systemd-container bluez blueman \
  firmware-iwlwifi intel-media-va-driver \
  mesa-va-drivers vainfo mesa-utils

echo "🔧 Enabling contrib/non-free repos for firmware..."
sudo sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
sudo apt update
sudo apt install -y firmware-linux firmware-linux-nonfree

echo "🖥️ Installing GDM3..."
sudo apt install -y gdm3
sudo systemctl enable gdm3

echo "🧠 Setting default session to Sway..."
sudo mkdir -p /usr/share/wayland-sessions
cat <<EOF | sudo tee /usr/share/wayland-sessions/sway.desktop
[Desktop Entry]
Name=Sway
Comment=An i3-compatible Wayland compositor
Exec=sway
Type=Application
DesktopNames=sway
EOF

echo "🔒 Enabling auto-login (optional)..."
sudo mkdir -p /etc/gdm3
sudo bash -c "cat <<EOF > /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$USER
EOF"

echo "🛠️ Installing mako build dependencies..."
sudo apt install -y meson ninja-build scdoc pkg-config cmake \
  libwayland-dev wayland-protocols-dev libxkbcommon-dev \
  libpixman-1-dev libsystemd-dev libdbus-1-dev libpango1.0-dev

echo "🧱 Cloning and building mako from source..."
git clone https://github.com/emersion/mako.git /tmp/mako
cd /tmp/mako
meson setup build
ninja -C build
sudo ninja -C build install
cd ~
rm -rf /tmp/mako

echo "🎨 Setting up theme..."
mkdir -p ~/.config
git clone https://github.com/adi1090x/rofi.git /tmp/rofi
mkdir -p ~/.config/wofi
cp -r /tmp/rofi/files/shared/themes/blue ~/.config/wofi/theme
rm -rf /tmp/rofi

echo "🎛 Configuring GTK theme..."
mkdir -p ~/.config/gtk-3.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Papirus
gtk-font-name=Noto Sans 10
EOF

echo "🖼 Setting Debian wallpaper..."
mkdir -p ~/Pictures
wget -O ~/Pictures/debian-wallpaper.jpg "https://wiki.debian.org/DebianArt/Themes/Emerald?action=AttachFile&do=get&target=Emerald_login_1920x1080.png"

echo "🧩 Setting up basic Sway config..."
mkdir -p ~/.config/sway
cat <<EOF > ~/.config/sway/config
exec dbus-run-session -- sway
output * bg ~/Pictures/debian-wallpaper.jpg fill
bindsym \$mod+Return exec foot
bindsym \$mod+d exec wofi --show drun
EOF

echo "💻 Optimizing for Dell XPS 9305..."
sudo apt install -y tlp thermald
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

echo "📦 Installing Flatpak..."
sudo apt install -y flatpak gnome-software-plugin-flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "🔁 Cloning Ubuntu Sway Remix configuration..."
git clone https://github.com/ubuntu-sway/ubuntu-sway /tmp/ubuntu-sway-remix

echo "📂 Applying Sway, Waybar, and Mako configs..."
mkdir -p ~/.config/sway ~/.config/waybar ~/.config/mako
cp -r /tmp/ubuntu-sway-remix/config/sway/* ~/.config/sway/
cp -r /tmp/ubuntu-sway-remix/config/waybar/* ~/.config/waybar/
cp -r /tmp/ubuntu-sway-remix/config/mako/* ~/.config/mako/

echo "🎨 Applying GTK theme and styles from Remix..."
mkdir -p ~/.config/gtk-3.0 ~/.themes ~/.icons
cp -r /tmp/ubuntu-sway-remix/config/gtk-3.0/* ~/.config/gtk-3.0/ || true
cp -r /tmp/ubuntu-sway-remix/themes/* ~/.themes/ || true
cp -r /tmp/ubuntu-sway-remix/icons/* ~/.icons/ || true

echo "🧹 Cleaning up..."
rm -rf /tmp/ubuntu-sway-remix
sudo apt autoremove -y

echo "✅ Installation complete! Reboot to enter Sway via GDM."
