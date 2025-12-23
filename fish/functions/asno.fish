function asno --wraps='apt search --names-only' --description 'alias asno=apt search --names-only'
    apt search --names-only $argv
end
