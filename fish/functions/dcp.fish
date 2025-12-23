function dcp --wraps='docker compose ps' --description 'alias dcp=docker compose ps'
    docker compose ps $argv
end
