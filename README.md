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
