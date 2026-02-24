### .xinitrc inside .config

add this line to ~/.zshenv / .bashrc / other shell:

`export XINITRC=/home/jaennil/.config/.xinitrc`

### .xprofile inside .config

`ln -s ~/.config/xprofile ~/.xprofile`

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

### Disable gnome default launcher

gsettings set org.gnome.mutter overlay-key ''

### Mouse hover focus

gsettings set org.gnome.desktop.wm.preferences focus-mode 'sloppy'

### fish as default shell

echo "$(command -v fish)" | sudo tee -a /etc/shells

chsh -s "$(command -v fish)"

Then logout and log back in

### Alacritty theme

git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

### Alacritty as default terminal in Ubuntu ( not sure working )

sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $(which alacritty) 50
sudo update-alternatives --config x-terminal-emulator
gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'


### Install FireCodeNerdFont on Ubuntu

Download FiraCodeNerdFont from website: https://www.nerdfonts.com/font-downloads

mkdir -p ~/.local/share/fonts
mv ~/Downloads/FiraCode.zip ~/.local/share/fonts
unzip ~/.local/share/fonts/FiraCode.zip -d ~/.local/share/fonts/
rm ~/.local/share/fonts/FiraCode.zip
fc-cache -fv

### Ubuntu top panel workspace scroll extension

https://extensions.gnome.org/extension/701/top-panel-workspace-scroll/

### Ubuntu telegram

ln -s /opt/Telegram/Telegram ~/.local/bin/telegram

### Claude Code

```
ln -s ~/.config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/.config/CLAUDE.md ~/.claude-personal/CLAUDE.md
ln -s ~/.config/.claude/settings.local.json ~/.claude/settings.local.json
```

### i3 status bar

Custom status bar script for i3wm with CPU, RAM, battery, WiFi, VPN, Bluetooth, DNS indicators.

### Yazi git plugin

ya pkg add yazi-rs/plugins:git
