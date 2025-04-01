setxkbmap jaennil_rpd,ru -option grp:alt_shift_toggle
xrdb ~/.Xresources
xinput set-prop "9" "libinput Accel Profile Enabled" 0 1 0
xrandr --output DP-3 --primary --mode 3440x1440 --rate 100
xrandr --output DP-2 --mode 1920x1080 --rate 144 --left-of DP-3
exec i3
