setxkbmap jaennil_rpd,ru -option "grp:alt_shift_toggle,ctrl:swapcaps"
xrdb ~/.Xresources
xinput set-prop "9" "libinput Accel Profile Enabled" 0 1 0
exec i3
