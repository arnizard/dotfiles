#!/usr/bin/env bash
# setup-rice.sh - full black & white glass-pill Hyprland rice, in one script.
#
# Run with:   bash setup-rice.sh            (NOT pasted into fish)
#   MODE=black bash setup-rice.sh           keeps a pure black wallpaper instead of the dark gradient
#
# Steps:
#   1 Hyprland / Waybar / fuzzel / mako / alacritty / wlogout / hyprlock / starship / wallpaper
#   2 GTK (adw-gtk3 + Papirus)     3 Qt (Kvantum "BlackWhite")     4 Cursor (Bibata Ice)
#   5 Vesktop theme                6 fastfetch + fish colours + Ly
#   7 Glass (blur, translucency, layer rules, gradient wallpaper)
#   8 Waybar glass pills (grouped capsules)
#   9 Waybar tools: system monitor, caffeine, colour picker
# Audio (OpenWave / Carla / PipeWire routing) is deliberately NOT touched.
# Every step runs in its own subshell; failures are listed at the end. Backups go to ~/.config-backup-*.
set -uo pipefail
FAILED=()
run() { local name="$1"; shift; echo; echo "===== $name ====="; if ( set -e; "$@" ); then echo "[ok] $name"; else echo "[FAILED] $name"; FAILED+=("$name"); fi; }
aur_or_pacman() {
  sudo pacman -S --needed --noconfirm "$@" 2>/dev/null && return 0
  if command -v paru >/dev/null; then paru -S --needed --noconfirm "$@"
  elif command -v yay >/dev/null; then yay -S --needed --noconfirm "$@"
  else echo "Could not install $* (no AUR helper)"; return 1; fi
}
MODE="${MODE:-gradient}"

step1() {
C="$HOME/.config"
BK="$HOME/.config-backup-white-$(date +%s)"
w() { mkdir -p "$(dirname "$1")"; cat > "$1"; }

mkdir -p "$BK"
for d in waybar fuzzel mako alacritty wlogout; do [ -e "$C/$d" ] && cp -a "$C/$d" "$BK/$d"; done
[ -e "$C/hypr" ] && cp -a "$C/hypr" "$BK/hypr"
[ -e "$C/starship.toml" ] && cp -a "$C/starship.toml" "$BK/"

sudo pacman -S --needed --noconfirm hyprpicker playerctl brightnessctl ttf-jetbrains-mono-nerd

# ---- Hyprland colours (both old palettes -> white) ----
H="$C/hypr/hyprland.lua"
if [ -f "$H" ]; then
  sed -i -E \
    -e 's/rgb\((fe8019|e11d2e)\)/rgb(ffffff)/g' \
    -e 's/rgb\((fabd2f|ff3b4a)\)/rgb(bbbbbb)/g' \
    -e 's/rgb\((504945|33181d)\)/rgb(222222)/g' \
    -e 's/rgba\((1d2021cc|e11d2e55)\)/rgba(00000066)/g' \
    -e 's/active_opacity = [0-9.]+/active_opacity = 1.0/' \
    -e 's/inactive_opacity = [0-9.]+/inactive_opacity = 0.92/' \
    -e 's/rounding = [0-9]+/rounding = 4/' \
    "$H"
fi

# ---- Waybar ----
w "$C/waybar/config.jsonc" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 38,
    "margin": 0,
    "spacing": 0,
    "modules-left":   [ "hyprland/window" ],
    "modules-center": [ "cpu", "memory", "temperature", "custom/media", "hyprland/workspaces", "clock" ],
    "modules-right":  [ "custom/shot", "custom/picker", "tray", "network", "pulseaudio", "battery", "custom/power" ],
    "include": [ "~/.config/waybar/modules.json" ]
}
EOF

w "$C/waybar/modules.json" <<'EOF'
{
    "hyprland/window": {
        "format": "<span size='x-small' alpha='55%'>{class}</span>\n{title}",
        "max-length": 50,
        "separate-outputs": true,
        "icon": true,
        "icon-size": 20,
        "tooltip": false
    },
    "cpu":         { "format": " {usage}", "interval": 2, "tooltip": false },
    "memory":      { "format": " {percentage}", "interval": 4, "tooltip": false },
    "temperature": { "format": " {temperatureC}", "critical-threshold": 85, "tooltip": false },
    "custom/media": {
        "exec": "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'No media'",
        "interval": 2,
        "max-length": 32,
        "on-click": "playerctl play-pause",
        "tooltip": false
    },
    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": { "active": "●", "default": "•", "urgent": "○" },
        "persistent-workspaces": { "*": 5 },
        "on-scroll-up": "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })' 1>/dev/null",
        "on-scroll-down": "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })' 1>/dev/null"
    },
    "clock": {
        "format": "{:%I:%M %p  •  %a, %d/%m}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>"
    },
    "custom/shot":   { "format": "", "on-click": "sh -c 'grim -g \"$(slurp)\" - | wl-copy'", "tooltip": false },
    "custom/picker": { "format": "", "on-click": "hyprpicker -a", "tooltip": false },
    "tray": { "icon-size": 16, "spacing": 10 },
    "network": {
        "format-wifi": "",
        "format-ethernet": "",
        "format-disconnected": "",
        "tooltip-format": "{essid} {ipaddr}"
    },
    "pulseaudio": {
        "format": "{icon}",
        "format-muted": "",
        "format-icons": { "default": ["", ""] },
        "on-click": "pavucontrol",
        "scroll-step": 5
    },
    "battery": {
        "format": "{capacity}",
        "format-charging": " {capacity}",
        "states": { "critical": 15 }
    },
    "custom/power": { "format": "", "on-click": "wlogout", "tooltip": false }
}
EOF

w "$C/waybar/style.css" <<'EOF'
/* Black & white minimal */
@define-color fg  #ffffff;
@define-color dim #8a8a8a;
@define-color line #2a2a2a;

* {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 14px;
    font-weight: 500;
    border: none;
    border-radius: 0;
    min-height: 0;
    box-shadow: none;
}

window#waybar {
    background-color: #000000;
    color: @fg;
}

#window { padding: 0 16px; }

#cpu, #memory, #temperature, #custom-media, #clock,
#custom-shot, #custom-picker, #tray, #network, #pulseaudio, #battery, #custom-power {
    padding: 0 10px;
    color: @fg;
    background: transparent;
}

#custom-media { color: @dim; padding: 0 28px; }
#clock { padding: 0 24px 0 28px; }

#workspaces { padding: 0 12px; }
#workspaces button {
    padding: 0 5px;
    color: @dim;
    background: transparent;
    font-size: 16px;
}
#workspaces button.active { color: @fg; }
#workspaces button.urgent { color: @fg; }
#workspaces button:hover { background: transparent; color: @fg; }

#custom-shot:hover, #custom-picker:hover, #custom-power:hover,
#network:hover, #pulseaudio:hover { color: @dim; }

#temperature.critical, #battery.critical { color: @fg; background: #3a3a3a; }
#custom-power { padding: 0 16px 0 10px; }
tooltip { background: #000000; border: 1px solid @line; }
tooltip label { color: @fg; }
EOF

# ---- Launcher / notifications / terminal ----
w "$C/fuzzel/fuzzel.ini" <<'EOF'
[main]
font=JetBrainsMono Nerd Font:size=12
prompt="  "
width=40
lines=10
horizontal-pad=20
vertical-pad=14
inner-pad=8

[colors]
background=000000f5
text=ffffffff
prompt=ffffffff
placeholder=777777ff
input=ffffffff
match=ffffffff
selection=1a1a1aff
selection-text=ffffffff
selection-match=ffffffff
border=ffffffff

[border]
width=1
radius=4
EOF

w "$C/mako/config" <<'EOF'
font=JetBrainsMono Nerd Font 11
anchor=top-right
layer=overlay
width=320
height=100
margin=12
padding=10,14
border-size=1
border-radius=4
icons=0
max-visible=3
default-timeout=4000
ignore-timeout=1
format=<b>%s</b>\n%b

background-color=#000000f5
text-color=#ffffff
border-color=#ffffff

[urgency=low]
border-color=#333333
default-timeout=2500

[urgency=high]
border-color=#ffffff
default-timeout=0
EOF

w "$C/alacritty/alacritty.toml" <<'EOF'
[window]
opacity = 1.0
padding = { x = 14, y = 14 }
dynamic_padding = true

[font]
size = 10.5

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font"
style = "Bold"

[colors.primary]
background = "#000000"
foreground = "#ffffff"

[colors.cursor]
text = "#000000"
cursor = "#ffffff"

[colors.selection]
text = "#000000"
background = "#ffffff"

[colors.normal]
black   = "#000000"
red     = "#cfcfcf"
green   = "#bdbdbd"
yellow  = "#e0e0e0"
blue    = "#a8a8a8"
magenta = "#c4c4c4"
cyan    = "#d6d6d6"
white   = "#e6e6e6"

[colors.bright]
black   = "#6b6b6b"
red     = "#ffffff"
green   = "#f0f0f0"
yellow  = "#ffffff"
blue    = "#dcdcdc"
magenta = "#eeeeee"
cyan    = "#f5f5f5"
white   = "#ffffff"
EOF

w "$C/wlogout/style.css" <<'EOF'
* { background-image: none; box-shadow: none; }
window { background-color: rgba(0, 0, 0, 0.92); }
button {
    border-radius: 4px;
    border: 1px solid #2a2a2a;
    margin: 8px;
    color: #ffffff;
    background-color: #000000;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
}
button:focus, button:active, button:hover {
    background-color: #ffffff;
    border-color: #ffffff;
    outline-style: none;
}
#lock     { background-image: image(url("/usr/share/wlogout/icons/lock.png")); }
#logout   { background-image: image(url("/usr/share/wlogout/icons/logout.png")); }
#suspend  { background-image: image(url("/usr/share/wlogout/icons/suspend.png")); }
#shutdown { background-image: image(url("/usr/share/wlogout/icons/shutdown.png")); }
#reboot   { background-image: image(url("/usr/share/wlogout/icons/reboot.png")); }
EOF

w "$C/hypr/hyprlock.conf" <<'EOF'
general { hide_cursor = true }

background {
    monitor =
    path = screenshot
    color = rgba(0, 0, 0, 1.0)
    blur_passes = 3
    blur_size = 6
    brightness = 0.4
}

label {
    monitor =
    text = $TIME
    color = rgba(255, 255, 255, 1.0)
    font_size = 82
    font_family = JetBrainsMono Nerd Font
    position = 0, 160
    halign = center
    valign = center
}

label {
    monitor =
    text = $USER
    color = rgba(138, 138, 138, 1.0)
    font_size = 16
    font_family = JetBrainsMono Nerd Font
    position = 0, -20
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 280, 48
    outline_thickness = 1
    dots_size = 0.25
    dots_spacing = 0.3
    outer_color = rgba(255, 255, 255, 1.0)
    inner_color = rgba(0, 0, 0, 0.9)
    font_color = rgba(255, 255, 255, 1.0)
    check_color = rgba(200, 200, 200, 1.0)
    fail_color = rgba(120, 120, 120, 1.0)
    fade_on_empty = true
    placeholder_text = <span foreground="##777777">password</span>
    rounding = 4
    position = 0, -100
    halign = center
    valign = center
}
EOF

w "$C/starship.toml" <<'EOF'
add_newline = false
format = """
$directory$git_branch$git_status$cmd_duration
$character"""

[directory]
style = "bold white"
truncation_length = 3
format = "[$path]($style) "

[git_branch]
style = "#8a8a8a"
format = "[ $branch]($style) "

[git_status]
style = "#8a8a8a"
format = "[$all_status$ahead_behind]($style) "

[cmd_duration]
style = "#6b6b6b"
format = "[$duration]($style)"

[character]
success_symbol = "[❯](bold white)"
error_symbol = "[❯](bold #8a8a8a)"
EOF

# Pure black wallpaper
mkdir -p "$HOME/Pictures/wallpapers"
magick -size 2560x1600 xc:black "$HOME/Pictures/wallpapers/black.png" 2>/dev/null \
  || convert -size 2560x1600 xc:black "$HOME/Pictures/wallpapers/black.png" 2>/dev/null || true
HP="$C/hypr/hyprpaper.conf"
if [ -f "$HP" ]; then
  if grep -q '^wallpaper' "$HP" || grep -q 'path' "$HP"; then
    sed -i -E "s|^(\s*path\s*=).*|\1 $HOME/Pictures/wallpapers/black.png|" "$HP"
  fi
fi

hyprctl reload 2>/dev/null || true
~/.config/waybar/waybar.sh 2>/dev/null || { pkill -x waybar; (waybar >/dev/null 2>&1 &); }
echo "Done. Backup: $BK"
}

step2_gtk() {
  aur_or_pacman adw-gtk-theme papirus-icon-theme
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
  rm -f ~/.config/gtk-4.0/gtk.css   # may be a symlink from nwg-look
  cat > ~/.config/gtk-3.0/gtk.css <<'EOF'
@define-color accent_color #ffffff;
@define-color accent_bg_color #ffffff;
@define-color accent_fg_color #000000;
@define-color window_bg_color #000000;
@define-color window_fg_color #ffffff;
@define-color view_bg_color #000000;
@define-color view_fg_color #ffffff;
@define-color headerbar_bg_color #000000;
@define-color headerbar_fg_color #ffffff;
@define-color headerbar_border_color #2a2a2a;
@define-color card_bg_color #0d0d0d;
@define-color card_fg_color #ffffff;
@define-color popover_bg_color #0d0d0d;
@define-color popover_fg_color #ffffff;
@define-color dialog_bg_color #0d0d0d;
@define-color dialog_fg_color #ffffff;
@define-color sidebar_bg_color #000000;
@define-color sidebar_fg_color #ffffff;
@define-color sidebar_backdrop_color #000000;
@define-color sidebar_border_color #2a2a2a;
EOF
  cp ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css
  command -v papirus-folders >/dev/null && papirus-folders -C grey --theme Papirus-Dark || true
}

step3_qt() {
sudo pacman -S --needed --noconfirm kvantum qt6ct

SRC=""
for d in /usr/share/Kvantum/KvGnomeDark /usr/share/Kvantum/KvFlatDark /usr/share/Kvantum/KvAdaptaDark; do
  [ -d "$d" ] && { SRC="$d"; break; }
done
[ -z "$SRC" ] && { echo "No dark base theme found in /usr/share/Kvantum"; exit 1; }
BASE=$(basename "$SRC")
DST="$HOME/.config/Kvantum/BlackWhite"
rm -rf "$DST"; mkdir -p "$DST"
cp "$SRC/$BASE.kvconfig" "$DST/BlackWhite.kvconfig"
[ -f "$SRC/$BASE.svg" ] && cp "$SRC/$BASE.svg" "$DST/BlackWhite.svg"

python3 -I - "$DST" <<'PY'
import re, sys, colorsys, os
d = sys.argv[1]

# 1. Recolor the SVG: grayscale everything, push dark to black, accents to white
svg = os.path.join(d, "BlackWhite.svg")
if os.path.exists(svg):
    s = open(svg, encoding="utf-8").read()
    def conv(m):
        h = m.group(1)
        if len(h) == 3: h = "".join(c*2 for c in h)
        r, g, b = (int(h[i:i+2], 16)/255 for i in (0, 2, 4))
        _, sat, _ = colorsys.rgb_to_hsv(r, g, b)
        L = 0.299*r + 0.587*g + 0.114*b
        if sat > 0.25:            # accent / selection colours -> white
            v = 1.0
        elif L < 0.55:            # dark surfaces -> deeper black
            v = L * 0.35
        else:                     # light parts -> keep light
            v = L
        x = int(round(v*255))
        return "#%02x%02x%02x" % (x, x, x)
    s = re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", conv, s)
    open(svg, "w", encoding="utf-8").write(s)

# 2. Force the palette in the kvconfig
cfg = os.path.join(d, "BlackWhite.kvconfig")
t = open(cfg, encoding="utf-8").read()
colors = {
 "window.color": "#000000", "base.color": "#000000", "alt.base.color": "#0d0d0d",
 "button.color": "#0d0d0d", "light.color": "#2a2a2a", "mid.light.color": "#1a1a1a",
 "dark.color": "#000000", "mid.color": "#111111", "highlight.color": "#ffffff",
 "inactive.highlight.color": "#bbbbbb", "text.color": "#ffffff",
 "window.text.color": "#ffffff", "button.text.color": "#ffffff",
 "disabled.text.color": "#6b6b6b", "tooltip.base.color": "#000000",
 "tooltip.text.color": "#ffffff", "highlight.text.color": "#000000",
 "link.color": "#ffffff", "link.visited.color": "#bbbbbb",
}
if "[GeneralColors]" not in t:
    t += "\n[GeneralColors]\n"
for k, v in colors.items():
    if re.search(r"^%s=.*$" % re.escape(k), t, re.M):
        t = re.sub(r"^%s=.*$" % re.escape(k), "%s=%s" % (k, v), t, flags=re.M)
    else:
        t = t.replace("[GeneralColors]", "[GeneralColors]\n%s=%s" % (k, v), 1)
# Rounded corners down for a flatter look
t = re.sub(r"^(small_icon_size|toolbar_icon_size)=.*$", r"\1=16", t, flags=re.M)
open(cfg, "w", encoding="utf-8").write(t)
PY

mkdir -p "$HOME/.config/Kvantum"
printf '[General]\ntheme=BlackWhite\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"

# Tell qt6ct to use the kvantum style (keeps other qt6ct settings if the file exists)
Q="$HOME/.config/qt6ct/qt6ct.conf"
mkdir -p "$(dirname "$Q")"
if [ -f "$Q" ]; then
  grep -q '^style=' "$Q" && sed -i 's/^style=.*/style=kvantum/' "$Q" || sed -i '0,/^\[Appearance\]/s//[Appearance]\nstyle=kvantum/' "$Q"
else
  printf '[Appearance]\nstyle=kvantum\ncolor_scheme_path=\ncustom_palette=false\n' > "$Q"
fi

echo "Done. Base: $BASE. Restart a Qt app (e.g. 'dolphin') to see it."
echo "Preview/tweak with: kvantummanager"
}

step4_cursor() {
  aur_or_pacman bibata-cursor-theme
  T="Bibata-Modern-Ice"
  gsettings set org.gnome.desktop.interface cursor-theme "$T"
  mkdir -p ~/.icons/default
  printf '[Icon Theme]\nName=Default\nInherits=%s\n' "$T" > ~/.icons/default/index.theme
  [ -f ~/.config/hypr/hyprland.lua ] && sed -i -E "s/(hl.env\(\"XCURSOR_THEME\", \")[^\"]*(\"\))/\1$T\2/" ~/.config/hypr/hyprland.lua
  hyprctl setcursor "$T" 24 2>/dev/null || true
}

step5_vesktop() {
  mkdir -p ~/.config/vesktop/themes
  cat > ~/.config/vesktop/themes/blackwhite.theme.css <<'EOF'
/**
 * @name Black & White
 * @description Minimal monochrome
 */
:root, .theme-dark, .theme-light {
  --background-primary: #000000;
  --background-secondary: #000000;
  --background-secondary-alt: #0a0a0a;
  --background-tertiary: #000000;
  --background-floating: #0d0d0d;
  --background-accent: #1a1a1a;
  --background-modifier-hover: rgba(255,255,255,0.06);
  --background-modifier-selected: rgba(255,255,255,0.12);
  --background-modifier-accent: #2a2a2a;
  --bg-base-primary: #000000;
  --bg-base-secondary: #000000;
  --bg-base-tertiary: #000000;
  --chat-background-default: #000000;
  --channeltextarea-background: #0d0d0d;
  --header-primary: #ffffff;
  --header-secondary: #8a8a8a;
  --text-normal: #ffffff;
  --text-muted: #8a8a8a;
  --text-link: #ffffff;
  --interactive-normal: #bbbbbb;
  --interactive-hover: #ffffff;
  --interactive-active: #ffffff;
  --brand-experiment: #ffffff;
  --brand-500: #ffffff;
  --brand-360: #ffffff;
  --scrollbar-thin-thumb: #2a2a2a;
  --scrollbar-auto-thumb: #2a2a2a;
}
EOF
  echo "Enable it in Vesktop: Settings -> Vencord -> Themes -> Black & White (toggle on)."
}

step6_shell() {
  mkdir -p ~/.config/fastfetch
  cat > ~/.config/fastfetch/config.jsonc <<'EOF'
{
  "logo": { "color": { "1": "white", "2": "white" } },
  "display": { "color": { "keys": "white", "title": "white" }, "separator": "  " },
  "modules": [ "title", "separator", "os", "host", "kernel", "uptime", "packages", "shell", "wm", "terminal", "cpu", "gpu", "memory", "break", "colors" ]
}
EOF
  rm -f ~/.config/fish/conf.d/redrice.fish
  fish -c '
    set -U fish_color_command ffffff
    set -U fish_color_param bbbbbb
    set -U fish_color_error ffffff --underline
    set -U fish_color_comment 6b6b6b
    set -U fish_color_quote 8a8a8a
    set -U fish_color_operator ffffff
    set -U fish_color_autosuggestion 6b6b6b
    set -U fish_color_end ffffff
    set -U fish_color_redirection bbbbbb
    set -U fish_pager_color_selection --background=2a2a2a
  ' || true
  if [ -f /etc/ly/config.ini ]; then
    sudo sed -i -e 's/^bg = .*/bg = 0x00000000/' -e 's/^fg = .*/fg = 0x00FFFFFF/' \
      -e 's/^border_fg = .*/border_fg = 0x00FFFFFF/' -e 's/^error_fg = .*/error_fg = 0x01FFFFFF/' /etc/ly/config.ini
  fi
}

step7_glass() {
C="$HOME/.config"
BK="$HOME/.config-backup-glass-$(date +%s)"
:
mkdir -p "$BK"
for d in hypr waybar fuzzel mako alacritty wlogout; do [ -e "$C/$d" ] && cp -a "$C/$d" "$BK/$d"; done

sudo pacman -S --needed --noconfirm imagemagick >/dev/null

# ---------- 1. Wallpaper: blur needs something behind the glass ----------
WP="$HOME/Pictures/wallpapers/glass.png"
mkdir -p "$(dirname "$WP")"
if [ "$MODE" = "black" ]; then
  WP="$HOME/Pictures/wallpapers/black.png"
else
  # very dark grey with soft light blobs + faint grain -> gives the blur something to chew on
  magick -size 2560x1600 xc:'#050505' \
    \( -size 2560x1600 xc:black -fill '#3a3a3a' -draw 'circle 600,400 600,1000' -blur 0x220 \) -compose screen -composite \
    \( -size 2560x1600 xc:black -fill '#2c2c2c' -draw 'circle 1900,1150 1900,1700' -blur 0x260 \) -compose screen -composite \
    \( -size 2560x1600 xc:black -fill '#222222' -draw 'circle 1500,300 1500,700' -blur 0x200 \) -compose screen -composite \
    \( -size 2560x1600 xc:gray50 +noise Random -colorspace gray -evaluate multiply 0.06 \) -compose screen -composite \
    "$WP" 2>/dev/null || convert -size 2560x1600 gradient:'#161616-#030303' "$WP"
fi
HP="$C/hypr/hyprpaper.conf"
[ -f "$HP" ] && sed -i -E "s|^(\s*path\s*=).*|\1 $WP|" "$HP"

# ---------- 2. Hyprland: blur, opacity, translucent borders, layer blur ----------
python3 -I - "$C/hypr/hyprland.lua" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()

# blur block (single-line or multi-line)
t = re.sub(r"blur\s*=\s*\{.*?\}",
  "blur = { enabled = true, size = 10, passes = 3, noise = 0.03, contrast = 1.0, brightness = 1.0, vibrancy = 0.2, vibrancy_darkness = 0.2, popups = true }",
  t, count=1, flags=re.S)
t = re.sub(r"active_opacity\s*=\s*[0-9.]+",   "active_opacity = 0.92",   t)
t = re.sub(r"inactive_opacity\s*=\s*[0-9.]+", "inactive_opacity = 0.80", t)
t = re.sub(r"rounding\s*=\s*[0-9]+", "rounding = 10", t, count=1)
t = re.sub(r"shadow\s*=\s*\{.*?\}",
  'shadow = { enabled = true, range = 24, render_power = 3, color = "rgba(00000099)" }',
  t, count=1, flags=re.S)
# translucent borders
t = re.sub(r"active_border\s*=\s*\{\s*colors\s*=\s*\{[^}]*\}[^}]*\}",
  'active_border = { colors = {"rgba(ffffff55)", "rgba(ffffff22)"}, angle = 45 }', t, count=1, flags=re.S)
t = re.sub(r'inactive_border\s*=\s*"[^"]*"', 'inactive_border = "rgba(ffffff14)"', t)

# layer rules block (idempotent via markers). pcall so a wrong key never breaks the whole config.
t = re.sub(r"\n-- >>> glass layer rules.*?-- <<< glass layer rules\n", "\n", t, flags=re.S)
t += '''
-- >>> glass layer rules
for _, ns in ipairs({ "waybar", "launcher", "notifications", "logout_dialog", "gtk-layer-shell" }) do
  pcall(hl.layer_rule, { name = "glass-" .. ns, match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.2 })
end
-- <<< glass layer rules
'''
open(p, "w", encoding="utf-8").write(t)
PY

# ---------- 3. Waybar: translucent bar ----------
python3 -I - "$C/waybar/style.css" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = re.sub(r"(window#waybar\s*\{[^}]*?)background-color:[^;]*;",
           r"\1background-color: rgba(10, 10, 10, 0.35);\n    border-bottom: 1px solid rgba(255, 255, 255, 0.10);", t, count=1)
open(p, "w", encoding="utf-8").write(t)
PY

# ---------- 4. Launcher / notifications / terminal / power menu ----------
sed -i -E 's/^background=.*/background=0a0a0ab0/; s/^border=.*/border=ffffff33/' "$C/fuzzel/fuzzel.ini"
sed -i -E 's/^background-color=.*/background-color=#0a0a0ab0/; 0,/^border-color=.*/s//border-color=#ffffff33/' "$C/mako/config"
sed -i -E 's/^opacity = .*/opacity = 0.72/' "$C/alacritty/alacritty.toml"
sed -i -E 's/(window \{ background-color: )[^;]*;/\1rgba(0, 0, 0, 0.55);/' "$C/wlogout/style.css"
sed -i -E 's/background-color: #000000;/background-color: rgba(0, 0, 0, 0.35);/' "$C/wlogout/style.css"

hyprctl reload 2>/dev/null || true
( pkill -x hyprpaper; sleep 0.3; nohup hyprpaper >/dev/null 2>&1 & ) 2>/dev/null || true
( ~/.config/waybar/waybar.sh 2>/dev/null || { pkill -x waybar; nohup waybar >/dev/null 2>&1 & } ) || true
pkill -x mako 2>/dev/null; ( nohup mako >/dev/null 2>&1 & ) || true

echo "Glass applied. Backup: $BK"
echo "If Hyprland shows an error banner, paste it to me - the layer-rule keys are the fragile part."
}

step8_pills() {
C="$HOME/.config"
BK="$HOME/.config-backup-pills-$(date +%s)"
mkdir -p "$BK" && cp -a "$C/waybar" "$BK/waybar"

# 1. Layout: floating bar + grouped modules
cat > "$C/waybar/config.jsonc" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "margin-top": 6,
    "margin-left": 10,
    "margin-right": 10,
    "margin-bottom": 0,
    "spacing": 8,
    "modules-left":   [ "hyprland/window" ],
    "modules-center": [ "group/stats", "custom/media", "hyprland/workspaces", "clock" ],
    "modules-right":  [ "group/tools", "tray", "group/status", "custom/power" ],
    "include": [ "~/.config/waybar/modules.json" ]
}
EOF

python3 -I - "$C/waybar/modules.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p, encoding="utf-8"))
m["group/stats"]  = {"orientation": "horizontal", "modules": ["cpu", "memory", "temperature"]}
m["group/tools"]  = {"orientation": "horizontal", "modules": ["custom/shot", "custom/picker"]}
m["group/status"] = {"orientation": "horizontal", "modules": ["network", "pulseaudio", "battery"]}
json.dump(m, open(p, "w", encoding="utf-8"), indent=4, ensure_ascii=True)
PY

# 2. Style: transparent bar, every group/module is a rounded glass capsule
cat > "$C/waybar/style.css" <<'EOF'
/* Black & white glass pills */
@define-color fg  #ffffff;
@define-color dim #8a8a8a;

* {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 14px;
    font-weight: 500;
    border: none;
    border-radius: 0;
    min-height: 0;
    box-shadow: none;
}

window#waybar { background: transparent; color: @fg; }

/* the capsules */
#window,
#stats, #group-stats,
#custom-media,
#workspaces,
#clock,
#tools, #group-tools,
#tray,
#status, #group-status,
#custom-power {
    background-color: rgba(10, 10, 10, 0.40);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 20px;
    padding: 0 6px;
    margin: 2px 0;
}

/* plain modules inside groups sit on the capsule */
#cpu, #memory, #temperature, #custom-shot, #custom-picker,
#network, #pulseaudio, #battery {
    background: transparent;
    padding: 0 9px;
    color: @fg;
}

#window { padding: 0 16px; }
#custom-media { color: @dim; padding: 0 20px; }
#clock { padding: 0 20px; }
#tray { padding: 0 12px; }
#custom-power { padding: 0 14px; }

/* workspace dots: active one is a small lit pill */
#workspaces { padding: 0 8px; }
#workspaces button {
    padding: 0 6px;
    margin: 6px 1px;
    color: @dim;
    background: transparent;
    border-radius: 12px;
    font-size: 14px;
}
#workspaces button.active {
    color: @fg;
    background: rgba(255, 255, 255, 0.16);
    padding: 0 10px;
}
#workspaces button.urgent { color: @fg; background: rgba(255, 255, 255, 0.3); }
#workspaces button:hover { color: @fg; background: rgba(255, 255, 255, 0.10); }

#custom-shot:hover, #custom-picker:hover, #network:hover, #pulseaudio:hover { color: @dim; }
#custom-power:hover { background-color: rgba(255, 255, 255, 0.85); color: #000000; }

#temperature.critical, #battery.critical { color: #000000; background: rgba(255,255,255,0.85); border-radius: 12px; }

tooltip { background: rgba(10, 10, 10, 0.85); border: 1px solid rgba(255,255,255,0.15); border-radius: 12px; }
tooltip label { color: @fg; }
EOF

# 3. Glass blur for the capsules (only matters if glass.sh's layer rules are present)
H="$C/hypr/hyprland.lua"
if [ -f "$H" ] && ! grep -q "glass layer rules" "$H"; then
  echo "Note: run glass.sh too if you want the capsules blurred."
fi

( ~/.config/waybar/waybar.sh 2>/dev/null || { pkill -x waybar; nohup waybar >/dev/null 2>&1 & } ) || true
echo "Pills applied. Backup: $BK"
}

step9_tools() {
C="$HOME/.config"
BK="$HOME/.config-backup-tools-$(date +%s)"
mkdir -p "$BK" && cp -a "$C/waybar" "$BK/waybar" && cp -a "$C/hypr" "$BK/hypr"

sudo pacman -S --needed --noconfirm btop wl-clipboard fuzzel alacritty >/dev/null

# ---------- helper scripts ----------
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/caffeine.sh" <<'EOF'
#!/usr/bin/env bash
# Caffeine = stop hypridle (no lock / screen-off / suspend). Toggle: "toggle"; status JSON: no args.
case "${1:-status}" in
  toggle)
    if pgrep -x hypridle >/dev/null; then pkill -x hypridle; else nohup hypridle >/dev/null 2>&1 & fi
    pkill -RTMIN+8 waybar 2>/dev/null
    ;;
  *)
    if pgrep -x hypridle >/dev/null; then
      printf '{"text":"\\uf0f4","class":"off","tooltip":"Auto-lock on (click: stay awake)"}\n'
    else
      printf '{"text":"\\uf0f4","class":"on","tooltip":"Staying awake (click: allow lock)"}\n'
    fi
    ;;
esac
EOF
chmod +x "$HOME/.local/bin/caffeine.sh"

# ---------- Waybar modules ----------
python3 -I - "$C/waybar/modules.json" "$C/waybar/config.jsonc" <<'PY'
import json, sys, os
mp, cp = sys.argv[1], sys.argv[2]
m = json.load(open(mp, encoding="utf-8"))
m.pop("custom/shot", None)
m["custom/monitor"] = {
    "format": "",
    "on-click": "alacritty --class sysmon -e btop",
    "tooltip-format": "System monitor"
}
m["custom/caffeine"] = {
    "exec": os.path.expanduser("~/.local/bin/caffeine.sh"),
    "return-type": "json",
    "interval": 5,
    "signal": 8,
    "on-click": os.path.expanduser("~/.local/bin/caffeine.sh") + " toggle"
}
new = ["custom/monitor", "custom/caffeine"]
if "group/tools" in m:
    mods = [x for x in m["group/tools"]["modules"] if x != "custom/shot"]
    m["group/tools"]["modules"] = new + [x for x in mods if x not in new]
json.dump(m, open(mp, "w", encoding="utf-8"), indent=4, ensure_ascii=True)

# non-grouped layout (restyle-all only): swap in config.jsonc
t = open(cp, encoding="utf-8").read()
if '"custom/shot"' in t:
    t = t.replace('"custom/shot"', '"custom/monitor", "custom/caffeine"')
    open(cp, "w", encoding="utf-8").write(t)
PY

# ---------- Waybar style ----------
python3 -I - "$C/waybar/style.css" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
ids = "#custom-monitor, #custom-caffeine"
hov = "#custom-monitor:hover, #custom-caffeine:hover"
if "#custom-monitor" not in t:
    t = t.replace("#custom-shot:hover,", hov + ",")
    t = t.replace("#custom-shot,", "#custom-shot, " + ids + ",")
    t = t.replace("#custom-shot", ids, 1) if "#custom-shot" in t and ids not in t else t
    t += """
/* caffeine: dim when auto-lock is on, bright white when staying awake */
#custom-caffeine.off { color: #6b6b6b; }
#custom-caffeine.on  { color: #ffffff; }
"""
open(p, "w", encoding="utf-8").write(t)
PY

# ---------- Hyprland: float the system monitor window ----------
python3 -I - "$C/hypr/hyprland.lua" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = re.sub(r"\n-- >>> sysmon rule.*?-- <<< sysmon rule\n", "\n", t, flags=re.S)
t += '''
-- >>> sysmon rule
pcall(hl.window_rule, { name = "sysmon-float", match = { class = "^sysmon$" }, float = true, size = {"(monitor_w*0.6)", "(monitor_h*0.7)"} })
-- <<< sysmon rule
'''
open(p, "w", encoding="utf-8").write(t)
PY

hyprctl reload 2>/dev/null || true
( ~/.config/waybar/waybar.sh 2>/dev/null || { pkill -x waybar; nohup waybar >/dev/null 2>&1 & } ) || true
echo "Done. Backup: $BK"
}

run "1 Hyprland / Waybar / launcher / terminal / lock / wallpaper" step1
run "2 GTK + icons"            step2_gtk
run "3 Qt (Kvantum)"           step3_qt
run "4 Cursor"                 step4_cursor
run "5 Vesktop"                step5_vesktop
run "6 fastfetch / fish / Ly"  step6_shell
run "7 Glass"                  step7_glass
run "8 Waybar pills"           step8_pills
run "9 Waybar tools"           step9_tools

echo
if [ ${#FAILED[@]} -eq 0 ]; then echo "All steps finished."; else echo "Failed steps: ${FAILED[*]}"; fi
echo "Log out and back in so every app picks up GTK/Qt/cursor changes."
echo "Enable the Vesktop theme: Settings -> Vencord -> Themes -> Black & White."
echo "Save to your repo: cd ~/dotfiles && ./sync.sh 'black glass rice' && git push"
