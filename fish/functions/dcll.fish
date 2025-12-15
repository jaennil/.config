function dcll --wraps='docker compose logs -tf' --description 'alias dcll=docker compose logs -tf'
  docker compose logs -tf $argv
end
