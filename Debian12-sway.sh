#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing core system packages..."
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
  mesa-va-drivers vainfo mesa-utils build-essential

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

echo "⬇️ Downloading and building wayland-protocols 1.32..."
cd /tmp
wget https://gitlab.freedesktop.org/wayland/wayland-protocols/-/archive/1.32/wayland-protocols-1.32.tar.gz
tar -xzf wayland-protocols-1.32.tar.gz
cd wayland-protocols-1.32
meson setup build
ninja -C build
sudo ninja -C build install
cd ~
rm -rf /tmp/wayland-protocols*

echo "🛠️ Installing mako build dependencies..."
sudo apt install -y meson ninja-build scdoc pkg-config cmake \
  libwayland-dev libxkbcommon-dev libpixman-1-dev \
  libsystemd-dev libdbus-1-dev libpango1.0-dev

echo "🧱 Cloning and building mako from source..."
git clone https://github.com/emersion/mako.git /tmp/mako
cd /tmp/mako
meson setup build
ninja -C build
sudo ninja -C build install
cd ~
rm -rf /tmp/mako

echo "🎨 Creating Wofi theme..."
mkdir -p ~/.config/wofi
cat <<EOF > ~/.config/wofi/style.css
window {
    margin: 0px;
    border: 2px solid #306998;
    background-color: #1e1e2e;
}
#input {
    margin: 5px;
    border: none;
    background-color: #313244;
    color: #ffffff;
}
#entry {
    padding: 5px;
    margin: 2px;
    border: none;
    background-color: transparent;
    color: #ffffff;
}
#entry:selected {
    background-color: #306998;
    color: #ffffff;
}
EOF

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

echo "🧩 Creating Sway config..."
mkdir -p ~/.config/sway
cat <<EOF > ~/.config/sway/config
set \$mod Mod4

output * bg ~/Pictures/debian-wallpaper.jpg fill

exec mako
exec waybar

bindsym \$mod+Return exec foot
bindsym \$mod+d exec wofi --show drun
bindsym \$mod+q kill
bindsym \$mod+Shift+e exit

floating_modifier \$mod
focus_follows_mouse yes

for_window [class=".*"] border pixel 2
EOF

echo "🧩 Creating Waybar config..."
mkdir -p ~/.config/waybar
cat <<EOF > ~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "modules-left": ["sway/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "battery", "network"],
  "clock": { "format": "%a %b %d, %H:%M" },
  "pulseaudio": { "format": " {volume}%" },
  "battery": { "format": "{capacity}%", "format-charging": " {capacity}%" },
  "network": { "format": "{ifname}   {signalStrength}%" }
}
EOF

echo "🧩 Creating Waybar style..."
cat <<EOF > ~/.config/waybar/style.css
* {
  font-family: "Noto Sans", sans-serif;
  font-size: 14px;
  color: white;
}
window {
  background-color: #1e1e2e;
}
#workspaces button {
  padding: 5px;
  border: none;
  background: transparent;
}
#workspaces button.focused {
  background: #306998;
}
EOF

echo "📦 Installing Flatpak..."
sudo apt install -y flatpak gnome-software-plugin-flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "💻 Optimizing for Dell XPS 9305..."
sudo apt install -y tlp thermald
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

echo "🧹 Cleaning up..."
sudo apt autoremove -y

echo "✅ Installation complete! Reboot to enter Sway via GDM."
