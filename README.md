### .xinitrc inside .config

add this line to ~/.zshenv / .bashrc / other shell:

`export XINITRC=/home/jaennil/.config/.xinitrc`

### Tmux

`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

then

`tmux`

then prefix-I (default prefix is ctrl-b)

### Fish ssh agent

Add this line to `~/.ssh/config`
```
AddKeysToAgent yes
```
With option enabled keys used by ssh will be automatically added to ssh-agent. No need to call `ssh-add`.

### Telegram shortcuts

put `./telegram/shortcuts-custom.json` in `~/.local/share/TelegramDesktop/tdata/`
