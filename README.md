to make .xinitrc work inside .config add this line to ~/.zshenv:

`export XINITRC=/home/jaennil/.config/.xinitrc`

to make tmux install plugins:

`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

then

`tmux`

then prefix-I (default prefix is ctrl-b)

to open images in firefox using open:

`xdg-mime default firefox.desktop "image/png"`

## fish ssh agent
Add this line to `~/.ssh/config`
```
AddKeysToAgent yes
```
With option enabled keys used by ssh will be automatically added to ssh-agent. No need to call `ssh-add`.
