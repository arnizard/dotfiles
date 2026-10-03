#!/bin/sh
set -e
cd ~/dotfiles
mkdir -p .config .local/bin

# Config folders (skipping nested git data, backups and leftovers)
for d in hypr waybar fuzzel mako alacritty wlogout fish pipewire wireplumber qpwgraph xdg-desktop-portal; do
  [ -d ~/.config/$d ] && rsync -a --delete \
    --exclude='.git' --exclude='*.bak' --exclude='*.old' --exclude='*.save' \
    --exclude='fish_variables' \
    ~/.config/$d/ ~/dotfiles/.config/$d/
done

# Single files
cp ~/.config/starship.toml .config/ 2>/dev/null || true
cp ~/.local/bin/audio-start.sh .local/bin/ 2>/dev/null || true
cp ~/.local/bin/ptt.sh .local/bin/ 2>/dev/null || true
cp ~/mic-chain.carxp . 2>/dev/null || true

# Ly lives in /etc, so it needs sudo
sudo cp /etc/ly/config.ini ly-config.ini
sudo chown "$USER": ly-config.ini

# Package list for rebuilding the system later
pacman -Qqe > pkglist.txt

git add -A
git commit -m "${1:-update}" || echo "Nothing new to commit"