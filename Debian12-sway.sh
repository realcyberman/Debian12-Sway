#!/bin/bash
# Debian 13: Auto-generated Sway/Waybar blue Fedora-style setup, no remix repo needed

set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "📦 Installing Sway, Waybar, blue GTK theme, and all desktop extras..."
sudo apt install -y sway swaybg swayidle swaylock waybar \
  mako-notifier wofi thunar thunar-archive-plugin foot alacritty \
  lxappearance pavucontrol fuzzel imv \
  fonts-font-awesome papirus-icon-theme file-roller curl git unzip \
  adwaita-gtk-theme nwg-clipman

echo "🔐 Installing greetd (optional, for auto-login to Sway)..."
sudo apt install -y greetd
sudo systemctl enable greetd

# Config folders
mkdir -p ~/.config/sway ~/.config/waybar ~/.config/mako ~/.config/fuzzel ~/.config/nwg-clipman

# ---- Sway CONFIG (blue, Fedora-inspired) ----
cat > ~/.config/sway/config <<'EOF'
# Sway config, Fedora-inspired blue theme

set $mod Mod4
font pango:Noto Sans 10

# Wallpaper
output * bg ~/.config/sway/wallpaper-blue.jpg fill

# Bar
bar {
    position top
    font pango:Noto Sans 10
    status_command waybar
    colors {
        background #19243a
        statusline #67b0ff
        focused_workspace #283753 #67b0ff #ffffff
        inactive_workspace #1e2430 #22314d #7bc6ff
        urgent_workspace #d72638 #d72638 #ffffff
    }
}

# Keybindings
bindsym $mod+Return exec foot
bindsym $mod+d exec fuzzel
bindsym $mod+Shift+q kill
bindsym $mod+Shift+e exec "swaymsg exit"

# Thunar file manager
bindsym $mod+e exec thunar

# Volume (pipewire)
bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +5%'
bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -5%'
bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

# Brightness
bindsym XF86MonBrightnessUp exec "light -A 5"
bindsym XF86MonBrightnessDown exec "light -U 5"

# Clipboard manager
exec_always --no-startup-id nwg-clipman

# Notification daemon
exec_always --no-startup-id mako

# Lockscreen
bindsym $mod+Shift+l exec swaylock

# Autostart
exec_always --no-startup-id thunar --daemon

# Gaps and window look
gaps inner 12
gaps outer 8

# Floating window decorations (Fedora style)
for_window [floating] border pixel 4

# Enable touchpad tap-to-click
input type:touchpad {
    tap enabled
}

# DPI fix for HiDPI
output * scale 1

# End of config
EOF

# ---- Waybar CONFIG ----
cat > ~/.config/waybar/config <<'EOF'
{
    "layer": "top",
    "position": "top",
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "pulseaudio", "network", "battery"],
    "clock": {
        "format": "{:%a %d %b %H:%M}",
        "tooltip-format": "{:%Y-%m-%d %H:%M:%S}"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% "
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}%  {icon}",
        "format-muted": ""
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "Ethernet ",
        "format-disconnected": "Disconnected "
    }
}
EOF

# ---- Waybar STYLE (blue) ----
cat > ~/.config/waybar/style.css <<'EOF'
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

# ---- Mako CONFIG (notifications) ----
cat > ~/.config/mako/config <<'EOF'
background-color=#22314dFF
text-color=#e0e8ff
border-color=#67b0ffFF
border-radius=8
border-size=2
default-timeout=5000
width=400
EOF

# ---- Fuzzel CONFIG (app launcher) ----
cat > ~/.config/fuzzel/fuzzel.ini <<'EOF'
[main]
font=Noto Sans:size=12
prompt=>
width=40
lines=12
inner-pad=16
background-color=19243aee
text-color=67b0ffff
selection-color=67b0ffbb
border-width=2
border-color=67b0ff
EOF

# ---- CLIPMAN CONFIG (nwg-clipman) ----
cat > ~/.config/nwg-clipman/config.toml <<'EOF'
# Basic nwg-clipman config
history-size = 50
EOF

# ---- WALLPAPER ----
mkdir -p "$HOME/.config/sway"
echo "🖼️  Downloading blue abstract wallpaper..."
WALLPAPER_URL="https://images.unsplash.com/photo-1506744038136-46273834b3fb?fit=crop&w=1920&q=80"
WALLPAPER_PATH="$HOME/.config/sway/wallpaper-blue.jpg"
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"

# ---- GTK THEME ----
echo "🌐 Setting GTK theme to Adwaita and icons to Papirus..."
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true

# ---- WAYBAR AUTOSTART SYSTEMD USER UNIT ----
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

echo "✅ All done! Log out and into Sway (or reboot) to enjoy your blue, Fedora-inspired Sway desktop."
