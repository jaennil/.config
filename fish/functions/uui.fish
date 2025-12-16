function uui --description 'apt update, upgrade, and install package'
  sudo apt update && sudo apt upgrade && sudo apt install $argv
end
