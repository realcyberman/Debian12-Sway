#!/bin/bash

# Install script to set up Debian 13 (Trixie) to resemble Ubuntu Sway Remix
# Uses Ly login manager with Nord-themed colors, Nordic Darker GTK theme, and Zafiro Nord Dark icons
# Run as root or with sudo
# Ensure internet connection and a fresh Debian 13 installation

# Exit on error
set -e

# Update system and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget python3-pip pipx build-essential gtk2-engines-murrine gtk2-engines-pixbuf libpam0g-dev libxcb-xkb-dev libxcb-util-dev

# Install Sway and core Wayland dependencies
echo "Installing Sway and Wayland dependencies..."
sudo apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland wayland-protocols

# Install Ly login manager (used by Ubuntu Sway Remix)
echo "Installing Ly login manager..."
sudo apt install -y build-essential libpam0g-dev libxcb-xkb-dev libxcb-util-dev
git clone https://github.com/fairyglade/ly.git /tmp/ly
cd /tmp/ly
make
sudo make install
sudo systemctl enable ly
cd && rm -rf /tmp/ly

# Configure Ly with Nord-themed colors
echo "Configuring Ly with Nord colors..."
sudo mkdir -p /etc/ly
cat << EOF | sudo tee /etc/ly/config.ini
# Ly configuration for Ubuntu Sway Remix-like setup
[ly]
animation=0
blank_password=false
force_wayland=true
path=/usr/local/bin:/usr/bin:/bin
term_reset_cmd=/usr/bin/tput reset
xinit=/usr/bin/Xinit
wayland_sessions=/usr/share/wayland-sessions
x_sessions=/usr/share/xsessions
default_session=sway

# Nord-themed colors
bg_color=0x2E3440
fg_color=0xD8DEE9
cursor_color=0x5E81AC
error_color=0xBF616A
prompt_color=0x81A1C1
EOF

# Install additional utilities for Ubuntu Sway Remix-like experience
echo "Installing utilities and applications..."
sudo apt install -y \
    pcmanfm-gtk3 `# File manager` \
    firefox `# Web browser (Debian package)` \
    libreoffice `# Office suite` \
    transmission-gtk `# BitTorrent client` \
    thunderbird `# Email client` \
    mpv `# Media player` \
    neovim `# Terminal text editor` \
    ranger `# Console file manager` \
    zathura `# PDF viewer` \
    audacious `# Audio player` \
    gimp `# Image editor` \
    pluma `# Text editor` \
    mate-calc `# Calculator` \
    fonts-ubuntu fonts-font-awesome `# Fonts` \
    papirus-icon-theme `# Fallback icon theme` \
    brightnessctl `# Brightness control` \
    pipewire pipewire-audio alsa-utils pavucontrol `# Audio` \
    grimshot `# Screenshot tool` \
    wofi `# Application launcher` \
    waybar `# Status bar` \
    alacritty `# Terminal emulator`

# Install NWG-Shell utilities for Ubuntu Sway Remix-like functionality
echo "Installing NWG-Shell utilities..."
pip3 install i3ipc # Required for autotiling
git clone https://github.com/nwg-piotr/autotiling.git /tmp/autotiling
sudo cp /tmp/autotiling/autotiling.py /usr/local/bin/autotiling
sudo chmod +x /usr/local/bin/autotiling
rm -rf /tmp/autotiling

# Install Azote (wallpaper manager)
echo "Installing Azote..."
sudo apt install -y python3-pil python3-send2trash
git clone https://github.com/nwg-piotr/azote.git /tmp/azote
cd /tmp/azote
sudo python3 setup.py install
cd && rm -rf /tmp/azote

# Install nwg-drawer (application menu)
echo "Installing nwg-drawer..."
sudo apt install -y libgdk-pixbuf2.0-dev
git clone https://github.com/nwg-piotr/nwg-drawer.git /tmp/nwg-drawer
cd /tmp/nwg-drawer
sudo python3 setup.py install
cd && rm -rf /tmp/nwg-drawer

# Install Nordic Darker theme
echo "Installing Nordic Darker GTK theme..."
git clone https://github.com/EliverLara/Nordic.git /tmp/Nordic
sudo cp -r /tmp/Nordic/Nordic-darker /usr/share/themes/
rm -rf /tmp/Nordic

# Install Zafiro Nord Dark icons (dark variant with blue accents)
echo "Installing Zafiro Nord Dark icon theme..."
git clone https://github.com/zayronxio/Zafiro-Nord-Dark.git /tmp/Zafiro-Nord-Dark
sudo mv /tmp/Zafiro-Nord-Dark /usr/share/icons/Zafiro-Nord-Dark
rm -rf /tmp/Zafiro-Nord-Dark

# Configure GTK themes and icons
echo "Configuring GTK themes and icons..."
mkdir -p ~/.config/gtk-3.0
cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Nordic-darker
gtk-icon-theme-name=Zafiro-Nord-Dark
gtk-font-name=Ubuntu 11
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF
# For GTK4 apps
mkdir -p ~/.config/gtk-4.0
cp -r /usr/share/themes/Nordic-darker/gtk-4.0/* ~/.config/gtk-4.0/ 2>/dev/null || true

# Configure Sway
echo "Configuring Sway..."
mkdir -p ~/.config/sway/config.d
sudo mkdir -p /usr/share/sway/scripts

# Copy default Sway config and customize
cp /etc/sway/config ~/.config/sway/config
cat << EOF > ~/.config/sway/config.d/default.conf
# Font settings
set \$gui-font Ubuntu 11
font pango:Ubuntu 8

# Terminal
set \$term alacritty
set \$term_cwd \$term --working-directory "\$(/usr/share/sway/scripts/swaycwd.sh 2>/dev/null || echo \$HOME)"

# Window settings
default_border normal
smart_borders off
smart_gaps off
gaps inner 0
gaps outer 0
hide_edge_borders both

# Waybar
bar {
    swaybar_command waybar
}

# Autotiling
exec_always autotiling

# Wallpaper (set a default or use Azote later)
output * bg \$HOME/.config/sway/wallpaper.jpg fill

# Keybindings
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaymsg exit
bindsym \$mod+d exec wofi --show drun -i
bindsym \$mod+t exec \$term
bindsym \$mod+f fullscreen
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioRaiseVolume exec wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+; pkill -RTMIN+8 waybar
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; pkill -RTMIN+8 waybar
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; pkill -RTMIN+8 waybar
EOF

# Create swaycwd.sh script (used for terminal working directory)
cat << EOF | sudo tee /usr/share/sway/scripts/swaycwd.sh
#!/bin/bash
# Get current working directory for Sway
swaymsg -t get_tree | jq -r '.. | select(.focused?) | .app_id' | xargs -I {} swaymsg -t get_tree | jq -r ".. | select(.app_id==\"{}\") | .pid" | xargs -I {} ps -p {} -o cwd= 2>/dev/null
EOF
sudo chmod +x /usr/share/sway/scripts/swaycwd.sh

# Configure Waybar with Nord colors
echo "Configuring Waybar with Nord theme..."
mkdir -p ~/.config/waybar
cat << EOF > ~/.config/waybar/config
{
    "layer": "top",
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery"],
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true
    },
    "clock": {
        "format": "{:%Y-%m-%d %H:%M}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "Muted {icon}",
        "format-icons": {
            "default": ["", "", ""]
        }
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "Ethernet ",
        "format-disconnected": "Disconnected ⚠"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    }
}
EOF

cat << EOF > ~/.config/waybar/style.css
* {
    border: none;
    border-radius: 0;
    font-family: Ubuntu, sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: #2E3440;
    color: #D8DEE9;
    transition-property: background-color;
    transition-duration: .5s;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #D8DEE9;
}

#workspaces button:hover {
    background: #3B4252;
    box-shadow: inset 0 -3px #5E81AC;
}

#clock,
#pulseaudio,
#network,
#battery {
    padding: 0 10px;
    color: #D8DEE9;
    background-color: #3B4252;
}

#pulseaudio.muted {
    color: #BF616A;
}
EOF

# Configure Alacritty with Nord colors
echo "Configuring Alacritty with Nord theme..."
mkdir -p ~/.config/alacritty
cat << EOF > ~/.config/alacritty/alacritty.yml
font:
  normal:
    family: Ubuntu
    style: Regular
  size: 11

colors:
  primary:
    background: '#2e3440'
    foreground: '#d8dee9'
    dim_foreground: '#a5abb6'
  cursor:
    text: '#2e3440'
    cursor: '#d8dee9'
  vi_mode_cursor:
    text: '#2e3440'
    cursor: '#d8dee9'
  selection:
    text: CellForeground
    background: '#4c566a'
  search:
    matches:
      foreground: CellBackground
      background: '#88c0d0'
    bar:
      background: '#434c5e'
      foreground: '#d8dee9'
  normal:
    black: '#3b4252'
    red: '#bf616a'
    green: '#a3be8c'
    yellow: '#ebcb8b'
    blue: '#81a1c1'
    magenta: '#b48ead'
    cyan: '#88c0d0'
    white: '#e5e9f0'
  bright:
    black: '#4c566a'
    red: '#bf616a'
    green: '#a3be8c'
    yellow: '#ebcb8b'
    blue: '#81a1c1'
    magenta: '#b48ead'
    cyan: '#8fbcbb'
    white: '#eceff4'
  dim:
    black: '#373e4d'
    red: '#94545d'
    green: '#809575'
    yellow: '#b29e75'
    blue: '#68809a'
    magenta: '#8c738c'
    cyan: '#6d96a5'
    white: '#aeb3bb'
EOF

# Install Mozilla Firefox from Mozilla Team PPA (to avoid Snap)
echo "Adding Mozilla Firefox PPA..."
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install -y firefox

# Set up Japanese input (optional, as seen in Ubuntu Sway Remix setups)
echo "Installing Japanese input (fcitx5-mozc)..."
sudo apt install -y fcitx5 fcitx5-mozc
mkdir -p ~/.config/sway/config.d
echo "exec fcitx5 -dr" > ~/.config/sway/config.d/fcitx5.conf

# Optimize system settings
echo "Optimizing system settings..."
sudo systemctl disable NetworkManager-wait-online.service
sudo sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=15s/g' /etc/systemd/system.conf
sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=15s/g' /etc/systemd/system.conf

# Set up Wayland session for login
echo "Setting up Wayland session..."
sudo mkdir -p /usr/share/wayland-sessions
cat << EOF | sudo tee /usr/share/wayland-sessions/sway.desktop
[Desktop Entry]
Name=Sway
Comment=A tiling Wayland compositor
Exec=sway
Type=Application
EOF

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean

# Update icon cache
echo "Updating icon cache..."
sudo gtk-update-icon-cache /usr/share/icons/Zafiro-Nord-Dark

echo "Installation complete! Reboot and Ly login manager will start automatically."
echo "To customize further, edit ~/.config/sway/config, ~/.config/waybar/config, or use lxappearance (install with sudo apt install lxappearance)."
echo "Download a wallpaper and set it in ~/.config/sway/wallpaper.jpg or use azote."