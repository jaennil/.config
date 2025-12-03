### .xinitrc inside .config

add this line to ~/.zshenv / .bashrc / other shell:

`export XINITRC=/home/jaennil/.config/.xinitrc`

### Tmux

`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

then

`tmux`

then prefix-I (default prefix is ctrl-b)

### SSH agent

run xorg with:

`ssh-agent startx`

### Telegram shortcuts

put `./telegram/shortcuts-custom.json` in `~/.local/share/TelegramDesktop/tdata/`

### Dark theme for GTK, QT apps

install `gnome-themes-extra`, `adwaita-qt5-git`$^{AUR}$, `adwaita-qt6-git`$^{AUR}$.

### Keyboard

sudo cp ~/.config/keyboard/wayland/jaennil_rpd /usr/share/X11/xkb/symbols/
setxkbmap jaennil_rpd,ru -option "grp:alt_shift_toggle,ctrl:swapcaps"

### Gnome workspaces

gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "['<Super>0']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "['<Shift><Super>0']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Shift><Super>9']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Super>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Super>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1']"

### fish as default shell

echo "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"

Then logout and log back in
