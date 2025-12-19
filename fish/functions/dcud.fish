function dcud --wraps='docker compose up -d' --description 'alias dcud=docker compose up -d'
    docker compose up -d $argv
end
