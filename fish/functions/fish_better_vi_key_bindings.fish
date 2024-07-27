# fix that accept autosuggestion doesnt work with vi key bindings
function fish_better_vi_key_bindings
    fish_vi_key_bindings
    bind -M insert \cf accept-autosuggestion
    bind \cf accept-autosuggestion
end
