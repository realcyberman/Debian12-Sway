#!/usr/bin/env bash
#
# Fully automated Wayland + Sway install script for Debian with:
# - Fedora Sway Remix color theme
# - Emerald wallpaper applied both for sway and GDM login screen
# - Auto-start sway after script finishes
# - GDM login screen wallpaper configured and GDM restarted to apply immediately
#
# Tested on Debian Bullseye and later
#

set -euo pipefail

USER_CONFIG_DIR="${HOME}/.config/sway"
CONFIG_FILE="${USER_CONFIG_DIR}/config"
SHELL_PROFILE=""

if [[ -n "${ZSH_VERSION-}" ]]; then
  SHELL_PROFILE="${HOME}/.zprofile"
elif [[ -n "${BASH_VERSION-}" ]]; then
  SHELL_PROFILE="${HOME}/.profile"
else
  SHELL_PROFILE="${HOME}/.profile"
fi

# Function to add backports and contrib/non-free repos
add_repos() {
  codename=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
  # Add contrib, non-free to main sources
  sudo sed -i.orig -r \
    -e "s/^(deb .+ ${codename} .+) main$/\1 main contrib non-free/" \
    -e "s/^(deb .+ ${codename}-updates .+) main$/\1 main contrib non-free/" \
    -e "s/^(deb .+ ${codename}-security .+) main$/\1 main contrib non-free/" \
    /etc/apt/sources.list || true

  # Add backports if not present
  if ! grep -Rq "${codename}-backports" /etc/apt/sources.list.d/ /etc/apt/sources.list; then
    echo "Adding ${codename}-backports repository..."
    echo "deb http://deb.debian.org/debian ${codename}-backports main contrib non-free" | sudo tee /etc/apt/sources.list.d/backports.list
  else
    echo "Backports repository already present."
  fi
}

echo "Starting Debian Wayland Sway installation script..."
add_repos

echo "Updating package lists..."
sudo apt update

echo "Upgrading packages..."
sudo apt upgrade -y

# Packages list
PKGS=(
  sway
  wayland
  weston
  wl-clipboard
  wayland-protocols
  xwayland
  foot
  wofi
  alacritty
  grim
  slurp
  mako
  swaylock
  swayidle
  network-manager
  network-manager-gnome
  bluez
  bluez-tools
  pipewire
  pipewire-pulse
  pipewire-audio-client-libraries
  pipewire-bin
  wireplumber
  pavucontrol
  light
  brightnessctl
  pulseaudio-module-bluetooth
  alsa-utils
  gst-plugins-bad
  gst-plugins-base
  gst-plugins-good
  gst-plugins-ugly
  mpv
  firefox-esr
  git
  wget
  curl
  xdg-utils
  xdg-desktop-portal
  xdg-desktop-portal-wlr
  xss-lock
  mesa-utils
  swaybg
  gdm3
)

echo "Installing required packages..."
sudo apt install -y "${PKGS[@]}"

# Enable net services
echo "Enabling NetworkManager and Bluetooth services..."
sudo systemctl enable --now NetworkManager bluetooth

# Enable PipeWire user services (may fail if no user session)
echo "Enabling PipeWire and WirePlumber user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

# Setup sway config directory
if [[ ! -d "$USER_CONFIG_DIR" ]]; then
  echo "Creating sway config directory at $USER_CONFIG_DIR"
  mkdir -p "$USER_CONFIG_DIR"
fi

# Download sway default config
echo "Downloading default sway config..."
curl -fsSL https://raw.githubusercontent.com/swaywm/sway/master/etc/sway/config -o "$CONFIG_FILE"

# Apply Fedora Sway Remix theme colors
cat >> "$CONFIG_FILE" <<'EOF'

# Fedora Sway Remix inspired colors
set $bg-color          #1a1c23
set $inactive-bg-color #2a2c37
set $text-color        #c0c5ce
set $inactive-text-color #7e8294
set $accent-color      #5a7de1
set $urgent-bg-color   #e06c75
set $floating-bg-color #44475a
set $border-color      #5a7de1
set $focused-border-color #91a7ff
set $focused-bg-color  #21242b

bar {
    position top
    colors {
        background $bg-color
        statusline $text-color
        separator  $accent-color

        focused_workspace  $accent-color $focused-bg-color $text-color
        active_workspace   $inactive-bg-color $inactive-bg-color $accent-color
        inactive_workspace $inactive-bg-color $inactive-bg-color $inactive-text-color
        urgent_workspace   $urgent-bg-color $urgent-bg-color $text-color
    }
    status_command wofi --show=window
    font pango:Monospace 10
}

# Window colors inspired by Fedora Sway Remix
client.focused          $accent-color $focused-bg-color $text-color $focused-border-color
client.focused_inactive $inactive-bg-color $inactive-bg-color $inactive-text-color $border-color
client.unfocused        $inactive-bg-color $inactive-bg-color $inactive-text-color $border-color
client.urgent           $urgent-bg-color $urgent-bg-color $text-color $urgent-bg-color
client.placeholder      $inactive-bg-color $inactive-bg-color $inactive-text-color $border-color

floating_modifier $mod
client.background      $floating-bg-color

EOF

# Setup Emerald wallpaper
EMERALD_WALLPAPER_URL="https://wiki.debian.org/DebianArt/Themes/Emerald?action=AttachFile&do=view&target=Emerald-wallpaper_1920x1080.png"
WALLPAPER_DIR="${HOME}/.local/share/backgrounds"
WALLPAPER_PATH="${WALLPAPER_DIR}/Emerald-wallpaper_1920x1080.png"

echo "Setting up wallpaper..."

mkdir -p "$WALLPAPER_DIR"
if [[ ! -f "$WALLPAPER_PATH" ]]; then
  echo "Downloading Emerald wallpaper..."
  curl -fsSL "$EMERALD_WALLPAPER_URL" -o "$WALLPAPER_PATH"
fi

# Remove existing swaybg exec lines from config to avoid duplicates
sed -i '/^exec_always swaybg/d' "$CONFIG_FILE"

# Add swaybg exec line to config for wallpaper
echo "exec_always swaybg -i $WALLPAPER_PATH -m fill" >> "$CONFIG_FILE"

echo "Wallpaper configured for sway."

# Configure GDM login screen wallpaper
echo "Configuring GDM login screen..."

GDM_CUSTOM_DIR="/usr/share/gnome-shell/theme"
GDM_WALLPAPER_PATH="${GDM_CUSTOM_DIR}/Emerald-login-background.png"

sudo cp "$WALLPAPER_PATH" "$GDM_WALLPAPER_PATH"
sudo chmod 644 "$GDM_WALLPAPER_PATH"

GDM_CSS="${GDM_CUSTOM_DIR}/gdm3.css"

if [[ ! -f "${GDM_CSS}.bak" ]]; then
  echo "Backing up original gdm3.css..."
  sudo cp "$GDM_CSS" "${GDM_CSS}.bak"
fi

# Remove previous background-image lines under #lockDialogGroup
sudo sed -i '/#lockDialogGroup {/,/}/ s|background-image: url(.*);||g' "$GDM_CSS"

# Insert new background-image line under #lockDialogGroup
sudo sed -i "/#lockDialogGroup {/a \  background-image: url('file://${GDM_WALLPAPER_PATH}');" "$GDM_CSS"

# Restart GDM to apply new wallpaper immediately
echo "Restarting GDM to apply login screen wallpaper..."
sudo systemctl restart gdm3

# Add environment variables for Wayland in user shell profile
echo "Adding environment variables for Wayland session..."

env_vars=(
  "export XDG_SESSION_TYPE=wayland"
  "export GDK_BACKEND=wayland"
  "export CLUTTER_BACKEND=wayland"
  "export QT_QPA_PLATFORM=wayland"
  "export MOZ_ENABLE_WAYLAND=1"
)

for ev in "${env_vars[@]}"; do
  grep -qxF "$ev" "$SHELL_PROFILE" || echo "$ev" >> "$SHELL_PROFILE"
done

echo "Starting sway session now..."

# Start sway in background or foreground
# Warning: Starting sway will take over your terminal session if run in console.
# It's recommended to run this script from TTY or add safety checks to your workflow.
exec sway

# End of script
