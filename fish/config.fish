if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_better_vi_key_bindings

set -gx PATH $PATH ~/.local/share/nvim/mason/bin
set -gx BROWSER zen-browser

if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
    exec ssh-agent startx
end
