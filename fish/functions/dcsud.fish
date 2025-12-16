function dcsud --description 'docker compose stop and up -d'
  docker compose stop $argv && docker compose up -d $argv
end
