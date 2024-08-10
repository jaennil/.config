setxkbmap jaennil_rpd,ru -option grp:alt_shift_toggle
xinput set-prop "9" "libinput Accel Profile Enabled" 0 1 0
spoof-dpi -port 8888 -enable-doh -window-size 0 -timeout 10000 &
xrandr --output DP-1 --mode 3440x1440 --rate 100 --right-of DP-3
xrandr --output DP-3 --mode 1920x1080 --rate 144
exec i3
